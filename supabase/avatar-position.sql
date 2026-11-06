-- My Pretty Pulls: remember where each person positioned their profile card
-- Run once in Supabase: SQL Editor > New query > paste > Run.
alter table public.profiles
  add column if not exists avatar_x    smallint not null default 50  check (avatar_x between 0 and 100),
  add column if not exists avatar_y    smallint not null default 30  check (avatar_y between 0 and 100),
  add column if not exists avatar_zoom smallint not null default 100 check (avatar_zoom between 60 and 300);
