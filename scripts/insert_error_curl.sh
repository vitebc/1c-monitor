#!/usr/bin/env bash
# Пример вставки ошибки из любого источника (curl -> Supabase REST)
# Требует: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (или ANON если RLS позволяет)
# Использование: ./scripts/insert_error_curl.sh DEMO "ОшибкаПроведения" "Ошибка" "Документ.Заказ" '{"doc":"123"}' "Коммент"

set -euo pipefail
: "${SUPABASE_URL:?Need SUPABASE_URL}"
: "${SUPABASE_SERVICE_ROLE_KEY:?Need SUPABASE_SERVICE_ROLE_KEY}"

BASE="${1:-DEMO}"
EVENT="${2:-ОшибкаПроведения}"
LEVEL="${3:-Ошибка}"
OBJ="${4:-Документ.РеализацияТоваров}"
DATA="${5:-{\"doc_id\":\"РТ-0001\"}}"
COMMENT="${6:-Тестовая ошибка из curl}"

curl -X POST "$SUPABASE_URL/rest/v1/errors" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d @- <<JSON
{
  "event_name": "$EVENT",
  "level": "$LEVEL",
  "metadata_object": "$OBJ",
  "data": $DATA,
  "comment_text": "$COMMENT",
  "base": "$BASE"
}
JSON
echo
echo "OK — watcher должен разослать FCM подписчикам base=$BASE"
