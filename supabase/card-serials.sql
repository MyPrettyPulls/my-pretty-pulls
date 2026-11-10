-- Serial numbers for serialized cards (KPop Demon Hunters SE, BP and ◇CR).
-- Each person can note the number printed on each copy they own. Only they can see or change it.
-- Run this whole file once in the Supabase SQL editor.
create table if not exists public.card_serials (
  user_id uuid not null references auth.users(id) on delete cascade,
  card_uid text not null,
  serials text[] not null default '{}',
  updated_at timestamptz not null default now(),
  primary key (user_id, card_uid)
);
alter table public.card_serials enable row level security;
drop policy if exists "own serials: read" on public.card_serials;
drop policy if exists "own serials: add" on public.card_serials;
drop policy if exists "own serials: change" on public.card_serials;
drop policy if exists "own serials: remove" on public.card_serials;
create policy "own serials: read"   on public.card_serials for select using (auth.uid() = user_id);
create policy "own serials: add"    on public.card_serials for insert with check (auth.uid() = user_id);
create policy "own serials: change" on public.card_serials for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own serials: remove" on public.card_serials for delete using (auth.uid() = user_id);
