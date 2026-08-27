# watcher — Edge Function: errors → FCM

Слушает `INSERT` в `public.errors` (через Database Webhook) и шлёт пуши подписчикам `base`.

## Поток
1. 1С делает `INSERT INTO errors (event_name, level, metadata_object, data, comment_text, base)`.
2. Supabase Database Webhook `POST /functions/v1/watcher` с `record`.
3. Функция вызывает `rpc get_tokens_for_base(p_base)` (security definer) → все `device_tokens` юзеров подписанных на эту `base`.
4. Дедупликация токенов → `FCM HTTP v1` (JWT из `FIREBASE_SERVICE_ACCOUNT_JSON`) или fallback `FCM legacy` (`FCM_SERVER_KEY`).
5. Невалидные токены (`UNREGISTERED`/`NOT_FOUND`) авто-удаляются из `device_tokens`.

## Настройка

### Env (Supabase Dashboard → Edge Functions → Secrets, или `.env` + `supabase secrets set`)
```
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account","project_id":"xxx",...}  # приоритет
# или для теста:
FCM_SERVER_KEY=AAAA...
GOOGLE_ACCESS_TOKEN=ya29...  # опционально, вместо JWT
```

### Database Webhook
Supabase Studio → Database → Webhooks → Create webhook:
- Table: `public.errors`
- Events: `INSERT`
- Type: `HTTP Request`
- URL: `https://<project>.supabase.co/functions/v1/watcher`
- HTTP Headers: `Authorization: Bearer <service_role>` (функция `verify_jwt=false`, проверка внутри)

Альтернатива — `pg_net` триггер, но webhook проще.

## Локально
```bash
supabase functions serve watcher --env-file ./supabase/.env --debug
# тест: вставка
curl -X POST http://localhost:54321/functions/v1/watcher \
  -H "Content-Type: application/json" \
  -d '{"type":"INSERT","table":"errors","record":{"id":"00000000-0000-0000-0000-000000000001","event_name":"ОшибкаПроведения","level":"Ошибка","metadata_object":"Документ.Заказ","data":{},"comment_text":"тест","base":"DEMO","created_at":"2026-08-27T10:00:00Z"}}'
```

## Деплой
```bash
supabase functions deploy watcher --no-verify-jwt
supabase secrets set --env-file ./supabase/.env
```
