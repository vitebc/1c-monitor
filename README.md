# 1c-monitor — монитор ошибок 1С

Мультиплатформенное приложение (Android / iOS / Desktop) — ошибки пишутся в БД, клиент мгновенно уведомляет пользователя.

```
[1С] --INSERT--> [Supabase Postgres: public.errors] --Realtime/pg_notify--> [Edge Function watcher] --FCM--> [Flutter app]
                                                                                 \--Realtime WebSocket fallback
```

**Стек:** Flutter 3 + Riverpod + freezed | Supabase (Postgres + Realtime) | Firebase FCM | Supabase Edge Functions (Deno)

## Быстрый старт

```bash
# 1. БД
supabase start
supabase db push          # прогоняет 20260827* migrations
supabase db reset         # + seed.sql (демо-ошибки DEMO/TEST)

# 2. FCM
supabase secrets set --env-file ./supabase/.env
supabase functions deploy watcher --no-verify-jwt
# Studio -> Database -> Webhooks -> public.errors INSERT -> https://<project>.supabase.co/functions/v1/watcher

# 3. App
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=SUPABASE_URL=http://localhost:54321 --dart-define=SUPABASE_ANON_KEY=xxx -d android
flutter test
```

## Структура

```
supabase/migrations/  errors (event_name,level,metadata_object,data,comment_text,base) + profiles/user_bases/device_tokens + RLS + get_tokens_for_base()
supabase/functions/watcher/  Deno Edge Function: webhook -> rpc get_tokens_for_base -> FCM v1/legacy, чистит invalid токены
supabase/seed.sql     демо-данные DEMO/TEST
app/lib/              Flutter MVVM (data/domain/ui) + adaptive LayoutBuilder 600
scripts/              insert_error_curl.sh, insert_error_1c.bsl
```

## Вставка из 1С

См. `scripts/insert_error_1c.bsl` (HTTP) и `scripts/insert_error_curl.sh`:

```bash
./scripts/insert_error_curl.sh DEMO "ОшибкаПроведения" "Ошибка" "Документ.Заказ" '{"doc":"123"}' "Коммент"
```

Таблица `errors` — 6 полей ТЗ + `id, created_at, is_read`. RLS: юзер видит только `base` из своих `user_bases`.

## Тесты

```bash
flutter test                          # app/test/*_view_model_test.dart + last_seen
deno test --allow-env supabase/functions/watcher/test.ts  # мок FCM, дедупликация, 200 на мусор
```

CI: `.github/workflows/ci.yml` — flutter analyze/test + supabase lint + deno test.

## Актуальные ключи (локальная разработка)

```bash
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=<PUBLISHABLE_KEY>
SUPABASE_SERVICE_ROLE_KEY=<SERVICE_ROLE_KEY>
```

- `publishable` = `anon` — для приложения (`flutter run --dart-define=...`)
- `secret` = `service_role` — только для `watcher`/`curl`/админки, **не** в приложение

## Частые косяки

- **Windows:** `atlbase.h` не найден → поставь `C++ ATL для v143/v144` в Visual Studio Installer
- **macOS:** `Operation not permitted` при авторизации → `network.client` уже включён в `macos/Runner/*.entitlements`
- **curl с кириллицей:** всегда `Content-Type: application/json; charset=utf-8` и `--data-binary`, иначе `????` → `errors_level_check`
- **RLS 42501:** `anon` не может INSERT — используй `service_role` для вставки извне
