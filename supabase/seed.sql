-- Seed для локалки: supabase db reset (прогоняет migrations + seed.sql)
-- Создаёт демо-пользователя (через auth) нельзя напрямую — делаем через anon insert + демо-базы

-- Демо-ошибки (как будто из 1С). base = DEMO, TEST — их подписчик увидит после user_bases insert
insert into public.errors (event_name, level, metadata_object, data, comment_text, base, created_at, is_read) values
  ('ОшибкаПроведения', 'Ошибка', 'Документ.РеализацияТоваров', '{"doc_id":"РТ-0001","sum":125000}', 'Не хватает остатка на складе', 'DEMO', now() - interval '2 hours', false),
  ('ПроведениеУспешно', 'Информация', 'Документ.Поступление', '{"doc_id":"ПН-0042"}', 'Документ проведён', 'DEMO', now() - interval '1 hour', true),
  ('ОбменЗавершен', 'Предупреждение', 'РегистрСведений.Обмен1С', '{"exchange_id":"ex-99","duration_ms":4300}', 'Обмен занял > 4с', 'DEMO', now() - interval '30 minutes', false),
  ('Критично_Блокировка', 'Критично', 'Справочник.Номенклатура', '{"lock":"deadlock","query":"SELECT ... FOR UPDATE"}', 'Дедлок при записи', 'DEMO', now() - interval '5 minutes', false),
  ('ОшибкаПроведения', 'Ошибка', 'Документ.ЗаказПокупателя', '{"doc_id":"ЗП-123"}', 'Контрагент заблокирован', 'TEST', now() - interval '10 minutes', false)
on conflict do nothing;

-- Подсказка: чтобы увидеть ошибки, залогинься в app и добавь базу DEMO в Настройки -> Подписки
-- Или вставь напрямую (как service_role):
-- insert into public.user_bases (user_id, base) values ('<uuid из auth.users>', 'DEMO');
