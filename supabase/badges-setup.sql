-- My Pretty Pulls: badges, Sparkles and Shimmer
-- Run in Supabase: SQL Editor > New query > paste > Run. Needs every earlier setup file. Safe to run again.
-- NOTE: badges-v2.sql builds on this file. If you ever run this one again, run badges-v2.sql again right after it.
--
-- Two currencies:
--   Sparkles (✨): from the daily games, game badges, follow/share/creator badges. Can't be faked; will buy real things.
--   Shimmer (💫): from collection and milestone badges. Collections are self-reported, so Shimmer is for fun cosmetics only.
-- The leaderboard counts game Sparkles only.

-- Every badge there is (anyone can read this list)
create table if not exists public.badge_catalog (
  id text primary key, category text not null, name text not null, description text not null,
  sparkles int not null default 0, icon text not null default '🏅', sort int not null default 0
);
alter table public.badge_catalog add column if not exists currency text not null default 'shimmer' check (currency in ('sparkles','shimmer'));
alter table public.badge_catalog add column if not exists kind text not null default 'auto' check (kind in ('auto','claim','admin'));
alter table public.badge_catalog add column if not exists url text;
alter table public.badge_catalog enable row level security;
drop policy if exists "Anyone can read badges" on public.badge_catalog;
create policy "Anyone can read badges" on public.badge_catalog for select to anon, authenticated using (true);
grant select on public.badge_catalog to anon, authenticated;
insert into public.badge_catalog (id, category, name, description, sparkles, icon, sort) values
('first-card','Collecting','First Pull','Add your first card to your collection.',5,'🌱',10),
('cards-50','Collecting','Binder Builder','Own 50 different cards.',10,'📒',20),
('cards-100','Collecting','Card Keeper','Own 100 different cards.',20,'📚',30),
('winx-col25','Winx Club','Quarter Binder','Own 25% of the Winx Club Fairy Diary set.',10,'🌸',40),
('winx-col50','Winx Club','Halfway Magic','Own 50% of the Winx Club Fairy Diary set.',25,'🌷',50),
('winx-col75','Winx Club','Almost Enchanted','Own 75% of the Winx Club Fairy Diary set.',50,'🌺',60),
('winx-col100','Winx Club','Fairy Diary Complete','Own every card in the Winx Club Fairy Diary set, promos included.',150,'👑',70),
('winx-ed-daily','Winx Club','Daily Edition Complete','Own every card you can pull from Daily Edition boxes.',40,'☀️',80),
('winx-ed-magic','Winx Club','Magic Edition Complete','Own every card you can pull from Magic Edition boxes.',40,'🌙',90),
('winx-ed-promo','Winx Club','Promo Collector','Own every Winx Club promo card.',30,'🎟️',100),
('winx-rar-r','Rarity sets','Rare Set','Own every Rare card in Winx Club Fairy Diary.',10,'💠',110),
('winx-rar-qr','Rarity sets','Cute Rare Set','Own every Cute Rare card in Winx Club Fairy Diary.',15,'💠',120),
('winx-rar-sr','Rarity sets','Super Rare Set','Own every Super Rare card in Winx Club Fairy Diary.',15,'💠',130),
('winx-rar-srp','Rarity sets','Super Rare Parallel Set','Own every Super Rare Parallel card in Winx Club Fairy Diary.',20,'💠',140),
('winx-rar-fr','Rarity sets','Function Rare Set','Own every Function Rare card in Winx Club Fairy Diary.',20,'💠',150),
('winx-rar-ssr','Rarity sets','Super Spark Rare Set','Own every Super Spark Rare card in Winx Club Fairy Diary.',20,'💠',160),
('winx-rar-hr','Rarity sets','Holo Rare Set','Own every Holo Rare card in Winx Club Fairy Diary.',25,'💠',170),
('winx-rar-tr','Rarity sets','Titan Rare Set','Own every Titan Rare card in Winx Club Fairy Diary.',25,'💠',180),
('winx-rar-ur','Rarity sets','Ultra Rare Set','Own every Ultra Rare card in Winx Club Fairy Diary.',30,'💠',190),
('winx-rar-ugr','Rarity sets','Ultra Golden Rare Set','Own every Ultra Golden Rare card in Winx Club Fairy Diary.',30,'💠',200),
('winx-rar-ar','Rarity sets','Artist Rare Set','Own every Artist Rare card in Winx Club Fairy Diary.',30,'💠',210),
('winx-rar-zr','Rarity sets','Zenith Rare Set','Own every Zenith Rare card in Winx Club Fairy Diary.',30,'💠',220),
('winx-rar-cr','Rarity sets','Creative Rare Set','Own every Creative Rare card in Winx Club Fairy Diary.',30,'💠',230),
('winx-rar-bp','Rarity sets','Brush Rare Set','Own every Brush Rare card in Winx Club Fairy Diary.',30,'💠',240),
('winx-rar-se','Rarity sets','Scenario-E Set','Own every Scenario-E card in Winx Club Fairy Diary.',20,'💠',250),
('winx-rar-pr','Rarity sets','Promo Set','Own every Promo card in Winx Club Fairy Diary.',25,'💠',260),
('solve-1','Guess the Secret Pull','First Find','Solve your first Secret Pull.',5,'🃏',270),
('solve-10','Guess the Secret Pull','Card Detective','Solve 10 Secret Pulls.',20,'🔎',280),
('solve-50','Guess the Secret Pull','Secret Keeper','Solve 50 Secret Pulls.',50,'🗝️',290),
('streak-3','Streaks','On a Roll','Solve the Secret Pull 3 days in a row.',5,'🔥',300),
('streak-7','Streaks','Week of Wonder','Solve the Secret Pull 7 days in a row.',15,'🔥',310),
('streak-30','Streaks','Monthly Magic','Solve the Secret Pull 30 days in a row.',50,'🔥',320),
('streak-100','Streaks','Unstoppable','Solve the Secret Pull 100 days in a row.',150,'🔥',330),
('trivia-1','Daily Trivia','Perfect Score','Get all 5 trivia questions right in one day.',10,'💡',340),
('trivia-10','Daily Trivia','Trivia Whiz','Get a perfect trivia score on 10 different days.',30,'🧠',350),
('age-30','Collector milestones','One Month In','Collect on My Pretty Pulls for 1 month.',10,'🎂',360),
('age-180','Collector milestones','Half-Year Collector','Collect on My Pretty Pulls for 6 months.',30,'🎂',370),
('age-365','Collector milestones','One Year of Pulls','Collect on My Pretty Pulls for 1 year.',75,'🎂',380),
('public','Collector milestones','Show and Tell','Make your profile public so others can see your collection.',5,'🪪',390)
on conflict (id) do update set category = excluded.category, name = excluded.name, description = excluded.description,
  sparkles = excluded.sparkles, icon = excluded.icon, sort = excluded.sort;
-- game badges pay Sparkles; collection and milestone badges pay Shimmer
update public.badge_catalog set currency = case when id ~ '^(solve|streak|trivia)-' then 'sparkles' else 'shimmer' end, kind = 'auto'
  where kind = 'auto';
update public.badge_catalog set category = 'Winx Club · Rarity sets' where category = 'Rarity sets';
update public.badge_catalog set category = 'Winx Club' where id in ('winx-col25','winx-col50','winx-col75','winx-col100','winx-ed-daily','winx-ed-magic','winx-ed-promo');
-- sharing and creating
insert into public.badge_catalog (id, category, name, description, sparkles, icon, sort, currency, kind) values
  ('share-1','Social','Spread the Sparkle','Someone opens your profile from the link you shared.',5,'🔗',900,'sparkles','auto'),
  ('creator','Social','Content Creator','Post a video that mentions myprettypulls.com, then send us the link with "Claim a badge" on the contact page.',50,'🎬',990,'sparkles','admin')
on conflict (id) do update set category = excluded.category, name = excluded.name, description = excluded.description,
  sparkles = excluded.sparkles, icon = excluded.icon, sort = excluded.sort, currency = excluded.currency, kind = excluded.kind;
-- Follow badges (one per social account). To add or change one, edit this list and run the file again.
insert into public.badge_catalog (id, category, name, description, sparkles, icon, sort, currency, kind, url) values
  ('follow-tiktok','Social','TikTok Follower','Follow My Pretty Pulls on TikTok.',10,'🎵',910,'sparkles','claim','https://www.tiktok.com/@myprettypulls'),
  ('follow-instagram','Social','Instagram Follower','Follow My Pretty Pulls on Instagram.',10,'📸',920,'sparkles','claim','https://www.instagram.com/myprettypulls/'),
  ('follow-youtube','Social','YouTube Subscriber','Subscribe to My Pretty Pulls on YouTube.',10,'▶️',930,'sparkles','claim','https://www.youtube.com/@MyPrettyPulls'),
  ('follow-discord','Social','Discord Member','Join the My Pretty Pulls Discord.',10,'💬',940,'sparkles','claim','https://discord.gg/X2d9BKh5d')
on conflict (id) do update set category = excluded.category, name = excluded.name, description = excluded.description,
  sparkles = excluded.sparkles, icon = excluded.icon, sort = excluded.sort, currency = excluded.currency, kind = excluded.kind, url = excluded.url;

-- Badges each person has earned. Once earned, a badge is kept.
create table if not exists public.user_badges (
  user_id uuid references auth.users(id) on delete cascade,
  badge text references public.badge_catalog(id) on delete cascade,
  sparkles int not null default 0,
  earned_at timestamptz not null default now(),
  primary key (user_id, badge)
);
alter table public.user_badges add column if not exists currency text not null default 'shimmer';
update public.user_badges ub set currency = b.currency from public.badge_catalog b where b.id = ub.badge and ub.currency <> b.currency;
alter table public.user_badges enable row level security;
revoke all on public.user_badges from anon, authenticated;

-- Profiles opened through someone's share link (only the first one matters for the badge)
create table if not exists public.profile_shares (owner uuid primary key references auth.users(id) on delete cascade, first_at timestamptz not null default now());
alter table public.profile_shares enable row level security;
revoke all on public.profile_shares from anon, authenticated;
create or replace function public.profile_visit(uname text) returns void
language plpgsql security definer set search_path = public as $$
declare o uuid;
begin
  select id into o from profiles where username = lower(uname) and is_public;
  if o is null or o = auth.uid() then return; end if;
  insert into profile_shares (owner) values (o) on conflict do nothing;
  insert into user_badges (user_id, badge, sparkles, currency)
    select o, b.id, b.sparkles, b.currency from badge_catalog b where b.id = 'share-1' on conflict do nothing;
end $$;
grant execute on function public.profile_visit(text) to anon, authenticated;

-- "I followed" button for each social account (one claim per account)
create or replace function public.claim_follow(badge_id text) returns json
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); b badge_catalog;
begin
  if uid is null then return json_build_object('error', 'signed_out'); end if;
  select * into b from badge_catalog where id = badge_id and kind = 'claim';
  if b.id is null then return json_build_object('error', 'unknown'); end if;
  insert into user_badges (user_id, badge, sparkles, currency) values (uid, b.id, b.sparkles, b.currency) on conflict do nothing;
  if not found then return json_build_object('already', true); end if;
  return json_build_object('earned', json_build_array(json_build_object('id', b.id, 'name', b.name, 'icon', b.icon, 'amount', b.sparkles, 'currency', b.currency)));
end $$;
grant execute on function public.claim_follow(text) to authenticated;

-- For you only (run in the SQL Editor): give someone a badge by hand, e.g. after checking their video.
--   select give_badge('their_username', 'creator');
create or replace function public.give_badge(uname text, badge_id text) returns text
language plpgsql security definer set search_path = public as $$
declare o uuid; b badge_catalog;
begin
  select id into o from profiles where username = lower(uname);
  if o is null then return 'No profile with that username'; end if;
  select * into b from badge_catalog where id = badge_id;
  if b.id is null then return 'No badge with that id'; end if;
  insert into user_badges (user_id, badge, sparkles, currency) values (o, b.id, b.sparkles, b.currency) on conflict do nothing;
  return case when found then 'Badge given' else 'They already have it' end;
end $$;
revoke all on function public.give_badge(text, text) from public, anon, authenticated;

-- Which badges this person qualifies for right now
drop function if exists public.badge_check(uuid) cascade;
create or replace function public.badge_check(p_uid uuid) returns setof text
language plpgsql stable security definer set search_path = public as $$
declare total int; owned int; best int; solves int; perfect int; since timestamptz; pub boolean; r record;
begin
  select count(*) into total from game_cards;
  select count(*) into owned from collection_items ci join game_cards g on g.uid = ci.card_uid where ci.user_id = p_uid and ci.qty > 0;
  if owned >= 1 then return next 'first-card'; end if;
  if owned >= 50 then return next 'cards-50'; end if;
  if owned >= 100 then return next 'cards-100'; end if;
  if total > 0 and owned * 4 >= total then return next 'winx-col25'; end if;
  if total > 0 and owned * 2 >= total then return next 'winx-col50'; end if;
  if total > 0 and owned * 4 >= total * 3 then return next 'winx-col75'; end if;
  if total > 0 and owned >= total then return next 'winx-col100'; end if;
  -- whole editions and rarity sets: every card in the group is owned
  for r in
    select 'winx-ed-' || e as id from unnest(array['daily','magic','promo']) e
      where not exists (select 1 from game_cards g where e = any(g.editions)
        and not exists (select 1 from collection_items ci where ci.user_id = p_uid and ci.card_uid = g.uid and ci.qty > 0))
    union all
    select 'winx-rar-' || lower(x.rar) from (select distinct rar from game_cards) x
      where not exists (select 1 from game_cards g where g.rar = x.rar
        and not exists (select 1 from collection_items ci where ci.user_id = p_uid and ci.card_uid = g.uid and ci.qty > 0))
  loop return next r.id; end loop;
  select count(*) into solves from secret_pull_plays where user_id = p_uid and solved;
  if solves >= 1 then return next 'solve-1'; end if;
  if solves >= 10 then return next 'solve-10'; end if;
  if solves >= 50 then return next 'solve-50'; end if;
  -- longest run of solved days in a row
  select coalesce(max(n), 0) into best from (
    select count(*) n from (select day, day - (row_number() over (order by day))::int as grp
      from secret_pull_plays where user_id = p_uid and solved) s group by grp) t;
  if best >= 3 then return next 'streak-3'; end if;
  if best >= 7 then return next 'streak-7'; end if;
  if best >= 30 then return next 'streak-30'; end if;
  if best >= 100 then return next 'streak-100'; end if;
  select count(*) into perfect from trivia_plays where user_id = p_uid and finished and score = 5;
  if perfect >= 1 then return next 'trivia-1'; end if;
  if perfect >= 10 then return next 'trivia-10'; end if;
  select p.created_at, p.is_public into since, pub from profiles p where p.id = p_uid;
  if since is not null and since <= now() - interval '30 days' then return next 'age-30'; end if;
  if since is not null and since <= now() - interval '180 days' then return next 'age-180'; end if;
  if since is not null and since <= now() - interval '365 days' then return next 'age-365'; end if;
  if coalesce(pub, false) then return next 'public'; end if;
  if exists (select 1 from profile_shares ps where ps.owner = p_uid) then return next 'share-1'; end if;
end $$;
revoke all on function public.badge_check(uuid) from public, anon, authenticated;

-- Hand out badges the signed-in person has newly earned, take back automatic ones they no longer
-- qualify for (for example after removing cards), and say what changed.
drop function if exists public.award_badges();
create or replace function public.award_badges() returns json
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); got json; lost json; ok text[];
begin
  if uid is null then return json_build_object('earned', '[]'::json, 'lost', '[]'::json); end if;
  ok := array(select badge_check(uid));
  with gone as (
    delete from user_badges ub using badge_catalog b
      where ub.user_id = uid and b.id = ub.badge and b.kind = 'auto' and not (ub.badge = any(ok))
      returning ub.badge
  ) select coalesce(json_agg(json_build_object('id', b.id, 'name', b.name, 'icon', b.icon, 'amount', b.sparkles, 'currency', b.currency)), '[]')
    into lost from gone join badge_catalog b on b.id = gone.badge;
  with new as (
    insert into user_badges (user_id, badge, sparkles, currency)
      select uid, b.id, b.sparkles, b.currency from badge_catalog b where b.kind = 'auto' and b.id = any(ok)
      on conflict do nothing returning badge
  ) select coalesce(json_agg(json_build_object('id', b.id, 'name', b.name, 'icon', b.icon, 'amount', b.sparkles, 'currency', b.currency) order by b.sort), '[]')
    into got from new join badge_catalog b on b.id = new.badge;
  return json_build_object('earned', got, 'lost', lost);
end $$;
grant execute on function public.award_badges() to authenticated;

-- Badges on a profile (your own, or anyone's public profile)
create or replace function public.profile_badges(uname text) returns json
language sql stable security definer set search_path = public as $$
  select coalesce(json_agg(json_build_object('id', ub.badge, 'earned_at', ub.earned_at) order by ub.earned_at), '[]')
  from profiles p join user_badges ub on ub.user_id = p.id
  where p.username = lower(uname) and (p.is_public or p.id = auth.uid());
$$;
grant execute on function public.profile_badges(text) to anon, authenticated;

-- Sparkles badges count toward your Sparkles total. The leaderboard counts game Sparkles only.
create or replace function public.tr_total(uid uuid) returns int language sql stable security definer set search_path = public as $$
  select (select coalesce(sum(points),0) from secret_pull_plays where user_id = uid)::int
       + (select coalesce(sum(sparkles),0) from trivia_plays where user_id = uid)::int
       + (select coalesce(sum(sparkles),0) from user_badges where user_id = uid and currency = 'sparkles')::int;
$$;
revoke all on function public.tr_total(uuid) from public, anon, authenticated;
create or replace function public.shimmer_total(uid uuid) returns int language sql stable security definer set search_path = public as $$
  select coalesce(sum(sparkles),0)::int from user_badges where user_id = uid and currency = 'shimmer';
$$;
revoke all on function public.shimmer_total(uuid) from public, anon, authenticated;
create or replace function public.sp_profile_stats(uname text) returns json language sql stable security definer set search_path = public as $$
  select json_build_object('streak', sp_streak(p.id), 'total', tr_total(p.id), 'shimmer', shimmer_total(p.id),
    'solved', (select count(*) from secret_pull_plays where user_id = p.id and solved),
    'trivia_perfect', (select count(*) from trivia_plays where user_id = p.id and finished and score = 5))
  from profiles p where p.username = lower(uname) and (p.is_public or p.id = auth.uid());
$$;

create or replace function public.sp_leaderboard(period text) returns json
language plpgsql stable security definer set search_path = public as $$
declare d date := sp_today(); since date; uid uuid := auth.uid(); out json;
begin
  since := case period when 'today' then d when 'week' then date_trunc('week', d)::date when 'all' then date '2000-01-01' end;
  if since is null then raise exception 'Unknown period'; end if;
  with plays as (
    select user_id, points as pts, solved::int as solved, finished_at from secret_pull_plays where finished and day between since and d
    union all
    select user_id, sparkles, 0, finished_at from trivia_plays where finished and day between since and d
  ), board as (
    select p.id, p.username, p.display_name, p.avatar_card, p.avatar_x, p.avatar_y, p.avatar_zoom, p.is_public,
           sum(s.pts)::int as sparkles, sum(s.solved)::int as solved, min(s.finished_at) as first_done
    from plays s join profiles p on p.id = s.user_id
    where p.is_public or p.id = uid
    group by p.id
    having sum(s.pts) > 0
  ), ranked as (
    select *, (rank() over (order by sparkles desc))::int as rnk from board
  )
  select json_build_object(
    'period', period, 'since', since, 'today', d,
    'players', (select count(*) from ranked),
    'has_profile', uid is not null and exists (select 1 from profiles where id = uid),
    'top', coalesce((select json_agg(json_build_object(
        'rank', rnk, 'username', username, 'display_name', display_name, 'avatar_card', avatar_card,
        'avatar_x', avatar_x, 'avatar_y', avatar_y, 'avatar_zoom', avatar_zoom, 'sparkles', sparkles,
        'solved', solved, 'streak', sp_streak(id), 'me', id = uid, 'is_public', is_public)
        order by rnk, first_done, username) from ranked where rnk <= 50), '[]'::json),
    'me', (select json_build_object('rank', rnk, 'sparkles', sparkles, 'solved', solved, 'is_public', is_public)
           from ranked where id = uid))
  into out;
  return out;
end $$;

-- Deleting an account also removes its badges
create or replace function public.delete_my_account() returns json
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid();
begin
  if uid is null then return json_build_object('error', 'signed_out'); end if;
  update feedback set user_id = null, username = null where user_id = uid;
  delete from user_badges where user_id = uid;
  delete from profile_shares where owner = uid;
  delete from trivia_plays where user_id = uid;
  delete from secret_pull_plays where user_id = uid;
  delete from collection_items where user_id = uid;
  delete from profiles where id = uid;
  delete from auth.users where id = uid;
  return json_build_object('ok', true);
end $$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- New contact topic for claiming the Content Creator badge (only if the contact form from "Site setup" exists yet)
do $$ begin
  if to_regclass('public.feedback') is not null then
    alter table public.feedback drop constraint if exists feedback_topic_check;
    alter table public.feedback add constraint feedback_topic_check
      check (topic in ('Suggestion','Add a card collection','Problem or bug','Complaint','Report a profile','Claim a badge','Other'));
  end if;
end $$;
