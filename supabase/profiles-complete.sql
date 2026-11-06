-- My Pretty Pulls: profiles (everything in one file)
-- Run once in Supabase: SQL Editor > New query > paste > Run.
-- The "destructive operations" warning is expected: it only replaces the old collection read rule.

-- One profile per account. Usernames are lowercase letters, numbers and underscores.
create table if not exists public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  username      text not null unique check (username ~ '^[a-z0-9_]{3,20}$'),
  display_name  text check (char_length(display_name) <= 30),
  about         text check (char_length(about) <= 160),
  fav_char      text check (char_length(fav_char) <= 30),
  avatar_card   text check (char_length(avatar_card) <= 60),
  showcase      text[] not null default '{}' check (cardinality(showcase) <= 5),
  is_public     boolean not null default false,
  age_confirmed boolean not null check (age_confirmed),   -- every account confirmed they are 13 or older
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Read public or own profile" on public.profiles;
drop policy if exists "Create own profile"         on public.profiles;
drop policy if exists "Update own profile"         on public.profiles;
drop policy if exists "Delete own profile"         on public.profiles;

-- Anyone can read a profile marked public; owners can always read their own.
create policy "Read public or own profile" on public.profiles for select to anon, authenticated
  using (is_public or auth.uid() = id);
create policy "Create own profile" on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "Update own profile" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
create policy "Delete own profile" on public.profiles for delete to authenticated using (auth.uid() = id);

grant select on public.profiles to anon, authenticated;
grant insert, update, delete on public.profiles to authenticated;

-- Collections: owners see their own; anyone can see the collection behind a public profile.
drop policy if exists "Read own cards" on public.collection_items;
drop policy if exists "Read own or public cards" on public.collection_items;
create policy "Read own or public cards" on public.collection_items for select to anon, authenticated
  using (
    auth.uid() = user_id
    or exists (select 1 from public.profiles p where p.id = collection_items.user_id and p.is_public)
  );
grant select on public.collection_items to anon;

-- Lets the sign-up form check whether a username is free, without revealing anything else.
create or replace function public.username_available(name text)
returns boolean language sql stable security definer set search_path = public as $$
  select not exists (select 1 from public.profiles where username = lower(name));
$$;
grant execute on function public.username_available(text) to anon, authenticated;

-- Remember where each person positioned their profile card
alter table public.profiles
  add column if not exists avatar_x    smallint not null default 50  check (avatar_x between 0 and 100),
  add column if not exists avatar_y    smallint not null default 30  check (avatar_y between 0 and 100),
  add column if not exists avatar_zoom smallint not null default 100 check (avatar_zoom between 60 and 300);
