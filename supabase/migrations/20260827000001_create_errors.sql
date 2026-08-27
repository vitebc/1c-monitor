-- Migration: create errors table (1С: ИмяСобытия, Уровень, ОбъектМетаданных, Данные, Комментарий, База)
-- Best practices: schema-data-types, schema-constraints, query-*, security-rls-*, conn-*
-- См. .agents/skills/supabase-postgres-best-practices/references/

-- pgcrypto нужен для gen_random_uuid() (если нет — включи)
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- errors: одна строка = одна ошибка из 1С / любого источника
-- Колонки из ТЗ + тех-поля (id, created_at, is_read) для дедупликации/пушей
-- ---------------------------------------------------------------------------
create table public.errors (
  id uuid primary key default gen_random_uuid(),  -- pk: uuid v4 (time-ordered v7 если доступен pg_uuidv7 — заменить)
  event_name text not null,                        -- <ИмяСобытия>  e.g. 'ОшибкаПроведения'
  level text not null,                             -- <Уровень>     Информация | Предупреждение | Ошибка | Критично
  metadata_object text,                            -- <ОбъектМетаданных> e.g. 'Документ.РеализацияТоваров'
  data jsonb not null default '{}'::jsonb,         -- <Данные>      произвольный jsonb из 1С
  comment_text text,                               -- <Комментарий> text, не `comment` (зарезервировано)
  base text not null,                              -- <База>        имя ИБ, фильтр для подписчиков
  created_at timestamptz not null default now(),   -- всегда timestamptz (schema-data-types)
  is_read boolean not null default false
);

comment on table public.errors is 'Ошибки из 1С: ИмяСобытия/Уровень/ОбъектМетаданных/Данные/Комментарий/База + тех-поля';
comment on column public.errors.event_name is '<ИмяСобытия>';
comment on column public.errors.level is '<Уровень>';
comment on column public.errors.metadata_object is '<ОбъектМетаданных>';
comment on column public.errors.data is '<Данные> jsonb';
comment on column public.errors.comment_text is '<Комментарий>';
comment on column public.errors.base is '<База> — имя информационной базы, ключ для RLS/фильтра подписчиков';

-- Уровень: check вместо enum — проще мигрировать без блокировок (schema-constraints)
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'errors_level_check') then
    alter table public.errors add constraint errors_level_check
      check (level in ('Информация','Предупреждение','Ошибка','Критично'));
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Индексы (query-*): каждый — под конкретный запрос клиента/watcher-а
-- ---------------------------------------------------------------------------
-- Лента по базе + сортировка по времени (основной запрос Flutter)
create index errors_base_created_idx on public.errors (base, created_at desc);

-- Фильтр по уровню внутри базы
create index errors_level_idx on public.errors (level) where level is not null;

-- Поиск по объекту метаданных
create index errors_metadata_object_idx on public.errors (metadata_object) where metadata_object is not null;

-- Поиск внутри jsonb `data` оператором @> (query-index-types: GIN для jsonb)
create index errors_data_gin on public.errors using gin (data);

-- Непрочитанные (partial index — query-partial-indexes)
create index errors_unread_idx on public.errors (base, created_at desc) where is_read = false;

-- ---------------------------------------------------------------------------
-- RLS (security-rls-bascis / security-rls-performance)
-- Пока без auth — включаем и даём доступ service_role + anon/authenticated
-- с оптимизацией: (select auth.uid()) вместо auth.uid() чтобы не вызывался per-row
-- ---------------------------------------------------------------------------
alter table public.errors enable row level security;

-- Force RLS даже для владельца таблицы (рекомендация скилла)
-- alter table public.errors force row level security;

-- Временно: разрешаем всё service_role (Edge Function watcher пишет с service_role)
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'errors_service_all' and tablename = 'errors') then
    create policy errors_service_all on public.errors
      for all to service_role
      using (true) with check (true);
  end if;
end $$;

-- Чтение для anon/authenticated: пока без фильтра по юзеру — фильтр по base делает клиент.
-- Когда появится таблица profiles(base -> user_id), заменить на:
--   using (base in (select base from public.profiles where user_id = (select auth.uid())))
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'errors_read_authenticated' and tablename = 'errors') then
    create policy errors_read_authenticated on public.errors
      for select to authenticated, anon
      using (true);
  end if;
end $$;

-- Инсерт: 1С/источник пишет через service_role или anon (если открытый ingest)
-- Ограничь в проде: только service_role + проверенный API-ключ
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'errors_insert_anon' and tablename = 'errors') then
    create policy errors_insert_anon on public.errors
      for insert to anon, authenticated
      with check (true);
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Realtime: Supabase Realtime через WAL (publication). Триггер pg_notify опционален.
-- Supabase по дефолту слушает WAL — достаточно добавить таблицу в publication.
-- Для совместимости с прямым LISTEN/NOTIFY — триггер.
-- ---------------------------------------------------------------------------
-- Добавить в supabase_realtime publication (идемпотентно через DO)
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'errors'
  ) then
    alter publication supabase_realtime add table public.errors;
  end if;
end $$;

-- Опциональный триггер pg_notify (если watcher слушает NOTIFY вместо Realtime)
create or replace function public.notify_errors_insert()
returns trigger
language plpgsql
as $$
begin
  perform pg_notify('errors_insert', json_build_object('id', new.id, 'base', new.base, 'level', new.level)::text);
  return new;
end;
$$;

drop trigger if exists trg_notify_errors_insert on public.errors;
create trigger trg_notify_errors_insert
  after insert on public.errors
  for each row execute function public.notify_errors_insert();
