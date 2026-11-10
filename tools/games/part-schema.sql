-- My Pretty Pulls: KPop Demon Hunters versions of Guess the Secret Pull and Daily Trivia
-- Run this whole file once in Supabase: SQL Editor > New query > paste > Run.
-- Run it after trivia-no-repeat-kinds.sql. It's safe to run again (for example after editing trivia questions).
-- The "destructive operations" warning is expected: it refreshes the KPop card list and the question banks.
-- Winx games keep working exactly as before, including for anyone still on the current site.

-- Which game (franchise) each card, question and play belongs to
alter table public.game_cards add column if not exists fr text not null default 'winx';
alter table public.trivia_questions add column if not exists fr text not null default 'winx';
alter table public.secret_pull_plays add column if not exists fr text not null default 'winx';
alter table public.trivia_plays add column if not exists fr text not null default 'winx';
-- One play per person, per day, per game
alter table public.secret_pull_plays drop constraint if exists secret_pull_plays_pkey;
alter table public.secret_pull_plays add primary key (user_id, day, fr);
alter table public.trivia_plays drop constraint if exists trivia_plays_pkey;
alter table public.trivia_plays add primary key (user_id, day, fr);

-- ================= KPop Demon Hunters cards and their blurry previews =================
