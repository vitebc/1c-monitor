-- Migration: profiles + user_bases + device_tokens (подписки на Базы + FCM токены)
-- См. .agents/skills/supabase-postgres-best-practices/references/
-- Зависит от: 20260827000001_create_errors.sql (таблица errors с колонкой base)

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- 1. profiles — профиль Supabase Auth пользователя
--    1 запись = 1 auth.users.id. Хранит отображаемое имя.
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is 'Профили пользователей (расширение auth.users)';
comment on column public.profiles.display_name is 'Имя для отображения в приложении';

-- updated_at триггер (best practice: не полагаться на клиента)
create or replace function public.handle_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.handle_updated_at();

-- ---------------------------------------------------------------------------
-- 2. user_bases — подписки пользователя на Базы (многие-ко-многим)
--    Нужна чтобы watcher по NEW.base нашёл кому слать пуш.
--    Также используется для RLS на errors: base in (select base from user_bases where user_id = auth.uid())
-- ---------------------------------------------------------------------------
create table public.user_bases (
  user_id uuid not null references auth.users (id) on delete cascade,
  base text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, base)
);

comment on table public.user_bases is 'Подписки пользователя на Базы (фильтр для errors.base)';
comment on column public.user_bases.base is '<База> — должна совпадать с errors.base';

-- Индекс для watcher: быстрый поиск user_id по base (query-missing-indexes)
create index user_bases_base_idx on public.user_bases (base);
-- Обратный индекс для списка баз пользователя (экран настроек)
create index user_bases_user_id_idx on public.user_bases (user_id);

-- ---------------------------------------------------------------------------
-- 3. device_tokens — FCM/APNs токены по устройствам (1 юзер = N устройств)
--    Хранит токен + платформу. Токен уникален глобально.
-- ---------------------------------------------------------------------------
create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null,
  platform text not null, -- android | ios | web | macos | windows | linux
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  constraint device_tokens_token_unique unique (token),
  constraint device_tokens_platform_check check (platform in ('android','ios','web','macos','windows','linux'))
);

comment on table public.device_tokens is 'FCM/APNs токены устройств для пушей';
comment on column public.device_tokens.token is 'FCM token (unique)';
comment on column public.device_tokens.platform is 'Платформа устройства';

-- Индексы для watcher: все токены юзеров подписанных на base (query-composite-indexes)
create index device_tokens_user_id_idx on public.device_tokens (user_id);
-- Для очистки старых токенов
create index device_tokens_last_seen_idx on public.device_tokens (last_seen_at);

-- updated триггер для last_seen_at можно обновлять из клиента при каждом запуске
-- (не ставим авто-триггер — клиент сам шлёт update)

-- ---------------------------------------------------------------------------
-- RLS (security-rls-basics, security-rls-performance)
-- Включаем на всех трёх таблицах. Оптимизация: (select auth.uid()) — вызывается 1 раз.
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.user_bases enable row level security;
alter table public.device_tokens enable row level security;

-- profiles: юзер видит/меняет только свой профиль
do $$ begin
  if not exists (select 1 from pg_policies where policyname = 'profiles_own_select' and tablename = 'profiles') then
    create policy profiles_own_select on public.profiles for select to authenticated
      using ((select auth.uid()) = id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_policies where policyname = 'profiles_own_upsert' and tablename = 'profiles') then
    create policy profiles_own_upsert on public.profiles for all to authenticated
      using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
  end if;
end $$;
-- service_role полный доступ (Edge Function, админка)
do $$ begin
  if not exists (select 1 from pg_policies where policyname = 'profiles_service_all' and tablename = 'profiles') then
    create policy profiles_service_all on public.profiles for all to service_role using (true) with check (true);
  end if;
end $$;

-- user_bases: юзер управляет только своими подписками
do $$ begin
  if not exists (select 1 from pg_policies where policyname = 'user_bases_own_all' and tablename = 'user_bases') then
    create policy user_bases_own_all on public.user_bases for all to authenticated
      using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_policies where policyname = 'user_bases_service_all' and tablename = 'user_bases') then
    create policy user_bases_service_all on public.user_bases for all to service_role using (true) with check (true);
  end if;
end $$;
-- чтение для anon не нужно — но watcher (service_role) читает

-- device_tokens: юзер видит/удаляет только свои токены
do $$ begin
  if not exists (select 1 from pg_policies where policyname = 'device_tokens_own_all' and tablename = 'device_tokens') then
    create policy device_tokens_own_all on public.device_tokens for all to authenticated
      using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_policies where policyname = 'device_tokens_service_all' and tablename = 'device_tokens') then
    create policy device_tokens_service_all on public.device_tokens for all to service_role using (true) with check (true);
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- RLS для errors: теперь можно ужесточить (заменить политику из 01 миграции)
-- Пользователь видит только ошибки из своих Баз.
-- Оставляем старую политику для anon — но для authenticated заменяем на фильтр по base.
-- ---------------------------------------------------------------------------
do $$ begin
  -- удаляем широкую политику если была (из 01 миграции) — заменяем на узкую
  if exists (select 1 from pg_policies where policyname = 'errors_read_authenticated' and tablename = 'errors') then
    drop policy errors_read_authenticated on public.errors;
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_policies where policyname = 'errors_read_own_base' and tablename = 'errors') then
    create policy errors_read_own_base on public.errors
      for select to authenticated
      using (
        -- service_role обходит RLS; для юзера — только свои базы
        -- Индекс user_bases(user_id) + device_tokens(user_id) уже есть — RLS быстрый (security-rls-performance)
        base in (select base from public.user_bases where user_id = (select auth.uid()))
      );
  end if;
end $$;

-- anon (незалогинен) ничего не видит — безопасно; если нужен публичный демо-доступ — добавь отдельную политику

-- ---------------------------------------------------------------------------
-- Helper для watcher: получить токены для базы (вызывается из Edge Function с service_role)
-- ---------------------------------------------------------------------------
create or replace function public.get_tokens_for_base(p_base text)
returns table (token text, platform text, user_id uuid)
language sql
security definer
set search_path = ''
as $$
  select dt.token, dt.platform, dt.user_id
  from public.device_tokens dt
  join public.user_bases ub on ub.user_id = dt.user_id
  where ub.base = p_base;
$$;

-- Запретить прямой вызов anon/authenticated — только service_role через Edge Function
revoke execute on function public.get_tokens_for_base(text) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Auto-create profile on signup (auth.users -> profiles)
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', new.email))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
