-- Bohemian Fun Cup v2.1
-- Spielerprofile + Admin/Spieler-Rechte über Supabase Auth
-- Im Supabase SQL Editor ausführen.

create extension if not exists pgcrypto;

-- 1) Profile: verbindet Supabase Auth User mit Spieler aus public.players
create table if not exists public.player_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references auth.users(id) on delete cascade,
  player_id uuid unique references public.players(id) on delete cascade,

  display_name text,
  avatar_body text not null default 'black',
  avatar_belly text not null default 'white',
  head_item text not null default 'none',
  face_item text not null default 'none',
  body_item text not null default 'none',
  back_item text not null default 'none',

  bio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2) Stats: nur Admin darf schreiben/lesen, Spieler sehen das erstmal nicht
create table if not exists public.player_stats (
  player_id uuid primary key references public.players(id) on delete cascade,

  strength integer not null default 5 check (strength between 1 and 12),
  stamina integer not null default 5 check (stamina between 1 and 12),
  speed integer not null default 5 check (speed between 1 and 12),
  wisdom integer not null default 5 check (wisdom between 1 and 12),

  special_attack text not null default '',
  admin_note text,
  updated_at timestamptz not null default now()
);

-- 3) Admin-Rollen
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- 4) Hilfsfunktion: ist aktueller User Admin?
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_users
    where user_id = auth.uid()
  );
$$;

-- 5) RLS aktivieren
alter table public.player_profiles enable row level security;
alter table public.player_stats enable row level security;
alter table public.admin_users enable row level security;

-- 6) Alte Policies entfernen, damit das Script mehrfach laufen kann
drop policy if exists "profiles read own or admin" on public.player_profiles;
drop policy if exists "profiles insert admin" on public.player_profiles;
drop policy if exists "profiles update own avatar or admin" on public.player_profiles;
drop policy if exists "profiles delete admin" on public.player_profiles;

drop policy if exists "stats admin read" on public.player_stats;
drop policy if exists "stats admin write" on public.player_stats;

drop policy if exists "admin users read admin" on public.admin_users;
drop policy if exists "admin users write admin" on public.admin_users;

-- 7) Profiles Policies
create policy "profiles read own or admin"
on public.player_profiles
for select
to authenticated
using (
  user_id = auth.uid()
  or public.is_admin()
);

create policy "profiles insert admin"
on public.player_profiles
for insert
to authenticated
with check (
  public.is_admin()
);

create policy "profiles update own avatar or admin"
on public.player_profiles
for update
to authenticated
using (
  user_id = auth.uid()
  or public.is_admin()
)
with check (
  user_id = auth.uid()
  or public.is_admin()
);

create policy "profiles delete admin"
on public.player_profiles
for delete
to authenticated
using (
  public.is_admin()
);

-- 8) Stats: nur Admin
create policy "stats admin read"
on public.player_stats
for select
to authenticated
using (
  public.is_admin()
);

create policy "stats admin write"
on public.player_stats
for all
to authenticated
using (
  public.is_admin()
)
with check (
  public.is_admin()
);

-- 9) Admin-Tabelle: nur Admins sehen/admins ändern.
-- Ersten Admin unten per SQL manuell eintragen.
create policy "admin users read admin"
on public.admin_users
for select
to authenticated
using (
  public.is_admin()
);

create policy "admin users write admin"
on public.admin_users
for all
to authenticated
using (
  public.is_admin()
)
with check (
  public.is_admin()
);

-- 10) Updated_at Trigger
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_player_profiles_updated_at on public.player_profiles;
create trigger set_player_profiles_updated_at
before update on public.player_profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_player_stats_updated_at on public.player_stats;
create trigger set_player_stats_updated_at
before update on public.player_stats
for each row execute function public.set_updated_at();

-- 11) WICHTIG: Ersten Admin setzen
-- Nach dem Ausführen:
-- Supabase → Authentication → Users → deine User-ID kopieren
-- Dann folgenden Befehl mit deiner User-ID ausführen:
--
-- insert into public.admin_users (user_id)
-- values ('DEINE-USER-ID-HIER')
-- on conflict (user_id) do nothing;
