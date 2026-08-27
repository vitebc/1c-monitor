# AGENTS.md — 1c-monitor

> Мультиплатформенный монитор ошибок: ошибки пишутся в БД → приложение мгновенно уведомляет пользователя на Android / iOS / Desktop.

## Цель и поток данных

```
[1С / любой источник] --INSERT--> [БД: errors] --trigger/CDC--> [Backend Watcher] --FCM/APNs/Web Push--> [Clients]
                                                         \--WebSocket/SSE (fallback когда пуш недоступен)
```

Таблица `errors` (по ТЗ от 1С): `event_name` (<ИмяСобытия>), `level` (<Уровень>), `metadata_object` (<ОбъектМетаданных>), `data` jsonb (<Данные>), `comment_text` (<Комментарий>), `base` (<База>) + `id uuid PK`, `created_at timestamptz`, `is_read bool`. Клиент получает только новые строки (фильтр по `base`/`user_id`).

## Стек — зафиксирован: Flutter

**Клиент:** Flutter 3 + Riverpod + freezed | **БД:** Supabase (Postgres + Realtime) | **Пуши:** Firebase FCM/APNs (только для токенов и отправки) | **Бэкенд:** Supabase Edge Functions (Deno)

> Выбор от 2026-08-27: Flutter. Альтернативы (KMP/CMP, Tauri+Capacitor) отклонены — см. git log.

### Push-архитектура (Supabase + FCM гибрид)
1. 1С/источник: `INSERT INTO errors (...)` → Postgres `pg_notify` → Supabase Realtime.
2. Edge Function `watcher` (слушает Realtime) → фильтрует по `user_id` → берёт `device_tokens` из `profiles` → шлёт FCM (`firebase_admin`).
3. Клиент: `firebase_messaging` в фоне + `flutter_local_notifications` для локального показа + бейдж непрочитанных. Fallback когда FCM недоступен (десктоп/энергосбережение): Supabase Realtime WebSocket при открытом приложении — без задержки.
4. Обязательно: дедупликация по `errors.id`, экспоненциальный бэк-офф при оффлайне, хранение `last_seen_id` локально (hive/flutter_secure_storage + drift/sqlite).

## Структура (создай при старте)

```
1c-monitor/
├── app/                 # Flutter
│   └── lib/features/errors/{data,domain,presentation}/ + core/notifications/
├── supabase/
│   ├── migrations/      # SQL миграции (errors, profiles/device_tokens)
│   └── functions/watcher/ # Deno Edge Function: Realtime → FCM
└── scripts/
```

## Команды

```bash
flutter pub get
supabase start                    # локальный Postgres + Realtime (требует Docker)
supabase db push                  # миграции
supabase functions serve watcher --env-file ./supabase/.env --debug  # локальный watcher
supabase functions deploy watcher --no-verify-jwt
flutter run -d android|ios|macos|windows
flutter test                      # один тест: flutter test test/errors_watcher_test.dart
dart run build_runner build       # если codegen (freezed/riverpod)
flutter analyze                   # линт
supabase gen types dart --linked  # после изменения схемы
```

> Пока репа пустая (гринфилд) — первый шаг: `flutter create app --org ru.1cmonitor`. Не коммить `build/`, `.dart_tool/`, `.ios/`, `.android/` сгенерированные артефакты.

## Обязательные скиллы

- `flutter-apply-architecture-best-practices` → `.agents/skills/flutter-apply-architecture-best-practices/SKILL.md` — при добавлении/рефакторинге фичи следуй его чек-листу по шагам (Domain Models → Services → Repositories → ViewModel → View → DI → тесты). Не ломай `data/domain/ui` слои, не мешай UI с логикой.
- `supabase-postgres-best-practices` → `.agents/skills/supabase-postgres-best-practices/SKILL.md` — грузи ПЕРЕД любым изменением в БД: таблицы/колонки, миграции, RLS, индексы, триггеры, `pg_cron/pgmq`, `pg_restore`. Соблюдай порядок приоритетов скилла (query → conn → security → schema).
- `flutter-build-responsive-layout` → `.agents/skills/flutter-build-responsive-layout/SKILL.md` — применяй для любой верстки: `LayoutBuilder`+`constraints.maxWidth` (брейкпоинт 600), `ConstrainedBox(maxWidth:800)`+`Center` на десктопе, `Expanded/Flexible` в `Row/Column`. Не лочить ориентацию, не чекать `isTablet`.

## Конвенции для агента

- Язык кода/коммитов — русский (как в `mini-ai-1c`), сообщения кратко: `feat: ...`, `fix: ...`.
- БД: миграции только через `supabase/migrations/` — не правь схему руками.
- Нотификации: всегда проверяй пермишены (`POST_NOTIFICATIONS` на Android 13+, APNs entitlements на iOS). На десктопе — `flutter_local_notifications` + WebSocket-fallback.
- Тест на watcher обязателен: вставка в `errors` → мок FCM → клиент получил. Без этого PR не мерджить.
- Храни `FCM_SERVER_KEY` / `SUPABASE_SERVICE_ROLE_KEY` в `.env` (не в репе). Пример — `.env.example`.
- После правок кода: `flutter analyze`; после изменения схемы — `supabase gen types dart`.

## Что не делать

- Не добавляй generic-советы — только проверяемые команды выше.
- Не заводи `graphify-out/` пока нет кода (>50 файлов) — сейчас рано.
- Не путай этот репозиторий с `mini-ai-1c` (Tauri+React для 1С) и `openchamber` (bun-монорепо) — это отдельный гринфилд-проект.
