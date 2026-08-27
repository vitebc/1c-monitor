// supabase/functions/watcher/index.ts
// Edge Function: Realtime/DB Webhook -> FCM
// Триггер: Database Webhook на INSERT в public.errors (POST -> /functions/v1/watcher)
// Env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, FIREBASE_SERVICE_ACCOUNT_JSON (или FIREBASE_PROJECT_ID + GOOGLE_ACCESS_TOKEN)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

// ---------- helpers: base64url, JWT for FCM v1 ----------
function base64UrlEncode(data: Uint8Array | string): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : data;
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  const b64 = btoa(binary);
  return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64UrlDecodeToString(b64url: string): string {
  const b64 = b64url.replace(/-/g, "+").replace(/_/g, "/");
  const pad = b64.length % 4 === 0 ? "" : "=".repeat(4 - (b64.length % 4));
  return atob(b64 + pad);
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  // pem: -----BEGIN PRIVATE KEY-----\nMIIE... \n-----END PRIVATE KEY-----
  const b64 = pem.replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return await crypto.subtle.importKey(
    "pkcs8",
    bytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

let cachedToken: { token: string; exp: number } | null = null;

async function getGoogleAccessToken(serviceAccountJson: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.exp - 60 > now) return cachedToken.token;

  const sa = JSON.parse(serviceAccountJson) as {
    client_email: string;
    private_key: string;
    token_uri?: string;
  };
  const header = base64UrlEncode(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = base64UrlEncode(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: sa.token_uri ?? "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  }));
  const unsigned = `${header}.${payload}`;
  const key = await importPrivateKey(sa.private_key);
  const sigBuf = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned));
  const signature = base64UrlEncode(new Uint8Array(sigBuf));
  const jwt = `${unsigned}.${signature}`;

  const res = await fetch(sa.token_uri ?? "https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    const t = await res.text();
    throw new Error(`Google OAuth failed ${res.status}: ${t}`);
  }
  const json = await res.json() as { access_token: string; expires_in: number };
  cachedToken = { token: json.access_token, exp: now + json.expires_in };
  return json.access_token;
}

// ---------- FCM send ----------
type ErrorRecord = {
  id: string;
  event_name: string;
  level: string;
  metadata_object: string | null;
  data: unknown;
  comment_text: string | null;
  base: string;
  created_at: string;
};

function buildNotification(record: ErrorRecord) {
  const title = `${record.level}: ${record.event_name}`;
  const parts = [
    record.metadata_object ?? "",
    record.comment_text ? record.comment_text.slice(0, 120) : "",
    `База: ${record.base}`,
  ].filter(Boolean);
  const body = parts.join(" • ").slice(0, 240) || "Новая ошибка";
  return { title: title.slice(0, 80), body };
}

async function sendFcmV1(opts: {
  token: string;
  notification: { title: string; body: string };
  data: Record<string, string>;
  accessToken: string;
  projectId: string;
}): Promise<{ ok: boolean; status: number; body: string }> {
  const url = `https://fcm.googleapis.com/v1/projects/${opts.projectId}/messages:send`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${opts.accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token: opts.token,
        notification: opts.notification,
        data: opts.data,
        android: { priority: "HIGH" },
        apns: { payload: { aps: { sound: "default", badge: 1 } } },
      },
    }),
  });
  const body = await res.text();
  return { ok: res.ok, status: res.status, body };
}

// legacy: если задан FCM_SERVER_KEY (не рекомендуется, но работает для теста)
async function sendFcmLegacy(token: string, notification: { title: string; body: string }, data: Record<string, string>, serverKey: string) {
  const res = await fetch("https://fcm.googleapis.com/fcm/send", {
    method: "POST",
    headers: {
      "Authorization": `key=${serverKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      to: token,
      notification,
      data,
      priority: "high",
    }),
  });
  const body = await res.text();
  return { ok: res.ok, status: res.status, body };
}

// ---------- main handler ----------
Deno.serve(async (req) => {
  // Healthcheck
  if (req.method === "GET") {
    return new Response(JSON.stringify({ ok: true, service: "watcher" }), { headers: { "Content-Type": "application/json" } });
  }
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? Deno.env.get("SB_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SB_SERVICE_ROLE_KEY") ?? "";
  const saJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON") ?? "";
  const fcmServerKey = Deno.env.get("FCM_SERVER_KEY") ?? "";
  const firebaseProjectId = (() => {
    if (saJson) {
      try { return (JSON.parse(saJson) as { project_id: string }).project_id ?? ""; } catch { return ""; }
    }
    return Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
  })();
  const directAccessToken = Deno.env.get("GOOGLE_ACCESS_TOKEN") ?? ""; // для теста без JWT

  if (!supabaseUrl || !serviceRoleKey) {
    console.error("Missing SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY");
    return new Response(JSON.stringify({ error: "server misconfigured" }), { status: 500, headers: { "Content-Type": "application/json" } });
  }

  let payload: Record<string, unknown>;
  try {
    payload = await req.json() as Record<string, unknown>;
  } catch {
    return new Response(JSON.stringify({ error: "invalid json" }), { status: 400, headers: { "Content-Type": "application/json" } });
  }

  // Supabase Database Webhooks шлёт {type, table, schema, record, old_record}
  // Realtime webhook может слать {eventType, new, old} — поддержим оба
  const record = (
    (payload["record"] as ErrorRecord | undefined) ??
    (payload["new"] as ErrorRecord | undefined) ??
    ((payload["data"] as Record<string, unknown> | undefined)?.["record"] as ErrorRecord | undefined) ??
    (payload as unknown as ErrorRecord)
  ) as ErrorRecord | undefined;

  const eventType = (payload["type"] as string | undefined) ?? (payload["eventType"] as string | undefined) ?? "INSERT";

  if (!record || !record.id || !record.base) {
    console.warn("watcher: no record/base in payload", JSON.stringify(payload).slice(0, 500));
    // отвечаем 200 чтобы webhook не ретраил бесконечно на мусор
    return new Response(JSON.stringify({ ok: true, skipped: "no record/base" }), { headers: { "Content-Type": "application/json" } });
  }

  if (eventType !== "INSERT") {
    return new Response(JSON.stringify({ ok: true, skipped: `event ${eventType}` }), { headers: { "Content-Type": "application/json" } });
  }

  console.log(`watcher: new error ${record.id} base=${record.base} level=${record.level} event=${record.event_name}`);

  const supabase = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });

  // Получаем токены подписчиков базы (через security definer функцию)
  const { data: tokens, error: rpcError } = await supabase.rpc("get_tokens_for_base", { p_base: record.base });

  if (rpcError) {
    console.error("get_tokens_for_base error", rpcError);
    return new Response(JSON.stringify({ error: rpcError.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }

  const rows = (tokens as Array<{ token: string; platform: string; user_id: string }> | null) ?? [];
  // дедупликация по токену
  const uniqueTokens = [...new Map(rows.map((r) => [r.token, r])).values()];

  if (uniqueTokens.length === 0) {
    console.log(`watcher: no subscribers for base=${record.base}`);
    return new Response(JSON.stringify({ ok: true, sent: 0, base: record.base }), { headers: { "Content-Type": "application/json" } });
  }

  const notification = buildNotification(record);
  const data = {
    error_id: record.id,
    base: record.base,
    level: record.level,
    event_name: record.event_name,
    created_at: record.created_at,
  };

  // Получаем access token один раз (если нужен v1)
  let accessToken: string | null = directAccessToken || null;
  if (saJson && !accessToken) {
    try {
      accessToken = await getGoogleAccessToken(saJson);
    } catch (e) {
      console.error("Failed to get Google access token", e);
      // fallback на legacy если есть server key
      if (!fcmServerKey) {
        return new Response(JSON.stringify({ error: "FCM auth failed, no fallback" }), { status: 500, headers: { "Content-Type": "application/json" } });
      }
    }
  }

  const results = await Promise.allSettled(uniqueTokens.map(async (row) => {
    const token = row.token;
    try {
      let res: { ok: boolean; status: number; body: string };
      if (accessToken && firebaseProjectId) {
        res = await sendFcmV1({ token, notification, data, accessToken: accessToken!, projectId: firebaseProjectId });
      } else if (fcmServerKey) {
        res = await sendFcmLegacy(token, notification, data, fcmServerKey);
      } else {
        throw new Error("No FCM credentials (FIREBASE_SERVICE_ACCOUNT_JSON or FCM_SERVER_KEY)");
      }

      if (!res.ok) {
        console.error(`FCM failed token=${token.slice(0, 12)}... status=${res.status} body=${res.body.slice(0, 500)}`);
        // invalid token -> удалить из device_tokens
        if (res.status === 400 || res.status === 404 || res.body.includes("InvalidRegistration") || res.body.includes("NOT_FOUND") || res.body.includes("UNREGISTERED")) {
          const { error: delErr } = await supabase.from("device_tokens").delete().eq("token", token);
          if (delErr) console.error("delete invalid token failed", delErr);
          else console.log(`deleted invalid token ${token.slice(0, 12)}...`);
        }
        return { token, ok: false, status: res.status };
      }
      console.log(`FCM sent token=${token.slice(0, 12)}...`);
      return { token, ok: true, status: res.status };
    } catch (err) {
      console.error(`FCM exception token=${token.slice(0, 12)}...`, err);
      return { token, ok: false, error: String(err) };
    }
  }));

  const sent = results.filter((r) => r.status === "fulfilled" && (r.value as { ok: boolean }).ok).length;
  const failed = results.length - sent;

  console.log(`watcher done base=${record.base} sent=${sent} failed=${failed} total=${uniqueTokens.length}`);

  return new Response(JSON.stringify({ ok: true, sent, failed, total: uniqueTokens.length, base: record.base, error_id: record.id }), {
    headers: { "Content-Type": "application/json" },
  });
});
