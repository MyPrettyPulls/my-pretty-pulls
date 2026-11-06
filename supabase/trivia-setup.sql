-- My Pretty Pulls: Daily Trivia
-- Run once in Supabase: SQL Editor > New query > paste > Run. Needs "Secret Pull setup" and "Leaderboard setup" first.
-- Then run trivia-questions.sql to load the questions.

-- Question bank (answers stay on the server)
create table if not exists public.trivia_questions (
  id serial primary key,
  question text not null unique,
  answer text not null,
  wrong text[] not null check (cardinality(wrong) = 3),
  difficulty text not null check (difficulty in ('Easy','Medium','Hard','Expert')),
  fact text,
  active boolean not null default true
);
-- Which transformation each card shows (filled in by card-transformations.sql)
alter table public.game_cards add column if not exists transformation text;
-- Each signed-in player's trivia for each day
create table if not exists public.trivia_plays (
  user_id uuid references auth.users(id) on delete cascade,
  day date not null,
  answers jsonb not null default '[]',
  served_i smallint,
  served_at timestamptz,
  score smallint not null default 0,
  sparkles smallint not null default 0,
  finished boolean not null default false,
  finished_at timestamptz,
  primary key (user_id, day)
);
alter table public.trivia_questions enable row level security;
alter table public.trivia_plays enable row level security;
revoke all on public.trivia_questions, public.trivia_plays from anon, authenticated;

-- The 5 questions for a day: 2 written questions and 3 card questions, in a mixed order.
-- Written questions go through the whole bank (any difficulty) before repeating.
create or replace function public.tr_build(d date, i int) returns json
language plpgsql stable security definer set search_path = public as $$
declare n int := d - date '2026-11-05'; seed text := (select seed from game_config); pool text[]; qn trivia_questions;
  c game_cards; kind text; opts text[]; ans text; prompt text; fact text; diff text; k int; h1 int; h2 int; extra json;
  hs int := ('x' || substr(md5(seed || d::text || 'slots'), 1, 6))::bit(24)::int; w1 int; w2 int;
begin
  if i not between 0 and 4 then raise exception 'Bad question'; end if;
  -- which 2 of the 5 spots are written questions today
  w1 := hs % 5; w2 := (w1 + 1 + (hs / 5) % 4) % 5;
  if i in (w1, w2) then
    select count(*) into k from trivia_questions where active;
    if k = 0 then raise exception 'No questions loaded'; end if;
    select * into qn from trivia_questions where active
      order by md5(id::text || seed || 'tq') offset ((2 * n + case when i = least(w1, w2) then 0 else 1 end) % k) limit 1;
    prompt := qn.question; ans := qn.answer; fact := qn.fact; diff := qn.difficulty; kind := 'q';
    opts := array_append(qn.wrong, qn.answer);
  else
    select g.* into c from game_cards g
      where exists (select 1 from game_mosaics m where m.uid = g.uid) and g.uid <> sp_card_for(d)
      order by md5(g.uid || seed || d::text || 'tc')
      offset ((select count(*) from generate_series(0, i - 1) x where x not in (w1, w2))) limit 1;
    h1 := ('x' || substr(md5(c.uid || seed || d::text || 'h1'), 1, 6))::bit(24)::int;
    h2 := ('x' || substr(md5(c.uid || seed || d::text || 'h2'), 1, 6))::bit(24)::int;
    k := ('x' || substr(md5(c.uid || seed || d::text || 'kind'), 1, 6))::bit(24)::int % 6;
    kind := (array['rar','char','box','zoom','odd','trans'])[k + 1];
    -- only ask about transformations on cards where a Winx fairy is transformed (not everyday clothes, pets, witches or Specialists)
    if kind = 'trans' and (c.transformation is null or c.transformation like 'No transformation%'
        or not c.appears && array['Bloom','Stella','Flora','Musa','Tecna','Aisha']) then kind := 'box'; end if;
    if kind = 'char' and not (c.main is not null and cardinality(c.appears) = 1) then kind := 'rar'; end if;
    diff := 'Card'; fact := c.num;
    if kind = 'rar' then
      prompt := 'What rarity is this card?'; ans := c.rar;
      opts := array_append(array(select r from (select distinct rar r from game_cards where rar <> c.rar) x
                order by md5(r || seed || d::text || i::text) limit 3), c.rar);
    elsif kind = 'char' then
      prompt := 'Who''s on this blurry card?'; ans := c.main;
      opts := array_append(array(select m from (select distinct main m from game_cards where main is not null and main <> c.main and cardinality(appears) = 1) x
                order by md5(m || seed || d::text || i::text) limit 3), c.main);
    elsif kind = 'trans' then
      prompt := 'What transformation is shown on this card?'; ans := c.transformation;
      opts := array_append(array(select t from (
                select distinct transformation t from game_cards where transformation is not null and transformation not like 'No transformation%'
                union select unnest(array['Charmix','Harmonix','Bloomix','Mythix','Butterflix'])) x
                where t <> c.transformation order by md5(t || seed || d::text || i::text) limit 3), c.transformation);
    elsif kind = 'zoom' then
      -- a close-up of one spot on the card; the choices are 4 cards, mostly of the same rarity so they look alike
      prompt := 'Which card is this close-up from?'; ans := c.uid;
      opts := array_append(array(select g2.uid from game_cards g2
                where g2.uid <> c.uid and exists (select 1 from game_mosaics m where m.uid = g2.uid)
                order by (g2.rar <> c.rar), md5(g2.uid || seed || d::text || i::text) limit 3), c.uid);
      extra := json_build_object('zx', 25 + h1 % 51, 'zy', 22 + h2 % 50);
    elsif kind = 'odd' then
      -- the card is shown with one thing changed (or nothing)
      prompt := 'What''s wrong with this card?';
      k := h1 % 4;
      ans := (array['It''s mirrored','The colors are wrong','Two pieces are swapped','Nothing, it''s right'])[k + 1];
      opts := array['It''s mirrored','The colors are wrong','Two pieces are swapped','Nothing, it''s right'];
      extra := json_build_object('fx', (array['m','h','s','n'])[k + 1], 'a', h2 % 9, 'b', (h2 % 9 + 1 + (h1 / 4) % 8) % 9, 'hue', 110 + h2 % 140);
    else
      prompt := 'Which box can you pull this card from?';
      ans := case when 'promo' = any(c.editions) then 'Promo card'
                  when 'daily' = any(c.editions) and 'magic' = any(c.editions) then 'Both Daily and Magic'
                  when 'daily' = any(c.editions) then 'Daily Edition only' else 'Magic Edition only' end;
      opts := array['Daily Edition only','Magic Edition only','Both Daily and Magic','Promo card'];
    end if;
  end if;
  -- shuffle so the right answer lands in a different spot from question to question
  opts := array(select o from unnest(opts) o order by md5(o || seed || d::text || i::text || 'shuffle'));
  return json_build_object('i', i, 'kind', kind, 'difficulty', diff, 'question', prompt, 'options', opts,
    'card', case when kind <> 'q' then c.uid end, 'answer', ans, 'fact', fact, 'extra', extra);
end $$;
revoke all on function public.tr_build(date, int) from public, anon, authenticated;

create or replace function public.tr_total(uid uuid) returns int language sql stable security definer set search_path = public as $$
  select (select coalesce(sum(points),0) from secret_pull_plays where user_id = uid)::int
       + (select coalesce(sum(sparkles),0) from trivia_plays where user_id = uid)::int;
$$;
revoke all on function public.tr_total(uuid) from public, anon, authenticated;

-- Where the player stands today
create or replace function public.tr_state() returns json language plpgsql security definer set search_path = public as $$
declare d date := sp_today(); p trivia_plays; uid uuid := auth.uid();
begin
  if uid is not null then select * into p from trivia_plays where user_id = uid and day = d; end if;
  return json_build_object('day', d, 'number', d - date '2026-11-05',
    'answers', coalesce(p.answers, '[]'::jsonb), 'finished', coalesce(p.finished, false),
    'score', coalesce(p.score, 0), 'sparkles', coalesce(p.sparkles, 0),
    'total', case when uid is null then 0 else tr_total(uid) end);
end $$;

-- Show question i (signed-in players: in order, and the 20-second clock starts now)
create or replace function public.tr_get(i int) returns json language plpgsql security definer set search_path = public as $$
declare d date := sp_today(); uid uuid := auth.uid(); p trivia_plays; q json; left_s numeric := 20;
begin
  q := tr_build(d, i);
  if uid is not null then
    insert into trivia_plays (user_id, day) values (uid, d) on conflict do nothing;
    select * into p from trivia_plays where user_id = uid and day = d for update;
    if p.finished then return json_build_object('error', 'finished'); end if;
    if i <> jsonb_array_length(p.answers) then return json_build_object('error', 'order'); end if;
    if p.served_i is distinct from i then
      update trivia_plays set served_i = i, served_at = now() where user_id = uid and day = d;
    else
      left_s := greatest(0, 20 - extract(epoch from now() - p.served_at));
    end if;
  end if;
  -- the "who's on it" question shows a blurry version, since most cards print the name
  return json_build_object('i', i, 'kind', q->>'kind', 'difficulty', q->>'difficulty', 'question', q->>'question',
    'options', q->'options', 'card', case when q->>'kind' <> 'char' then q->>'card' end, 'extra', q->'extra',
    'peek', case when q->>'kind' = 'char' then (select json_build_object('w', m.w, 'h', m.h, 'px', m.px) from game_mosaics m where m.uid = q->>'card' and m.level = 3) end,
    'seconds', round(left_s, 1));
end $$;

-- Answer question i (an empty choice means time ran out)
create or replace function public.tr_answer(i int, choice text) returns json language plpgsql security definer set search_path = public as $$
declare d date := sp_today(); uid uuid := auth.uid(); p trivia_plays; q json; ok boolean; done boolean := false; sc int; sp int := 0;
begin
  q := tr_build(d, i);
  ok := coalesce(choice, '') = q->>'answer';
  if uid is not null then
    select * into p from trivia_plays where user_id = uid and day = d for update;
    if p.user_id is null or p.finished then return json_build_object('error', 'finished'); end if;
    if i <> jsonb_array_length(p.answers) or p.served_i is distinct from i then return json_build_object('error', 'order'); end if;
    if now() - p.served_at > interval '23 seconds' then ok := false; end if;   -- 20 seconds plus a little grace
    sc := p.score + case when ok then 1 else 0 end;
    done := i = 4;
    if done then sp := sc + case when sc = 5 then 2 else 0 end; end if;
    update trivia_plays set answers = answers || jsonb_build_array(jsonb_build_object('c', coalesce(choice, ''), 'ok', ok)),
      score = sc, served_i = null, finished = done, sparkles = sp, finished_at = case when done then now() end
      where user_id = uid and day = d;
  end if;
  return json_build_object('correct', ok, 'answer', q->>'answer', 'fact', q->>'fact', 'card', q->>'card', 'finished', done,
    'score', sc, 'sparkles', sp, 'total', case when uid is null then 0 else tr_total(uid) end);
end $$;

grant execute on function public.tr_state(), public.tr_get(int), public.tr_answer(int, text) to anon, authenticated;

-- Sparkles from both games now count everywhere
create or replace function public.sp_state() returns json language plpgsql security definer set search_path = public as $$
declare d date := sp_today(); p secret_pull_plays; uid uuid := auth.uid();
begin
  if uid is not null then select * into p from secret_pull_plays where user_id = uid and day = d; end if;
  return json_build_object(
    'day', d, 'number', d - date '2026-11-05',
    'log', coalesce(p.log, '[]'::jsonb), 'used', coalesce(p.used, 0),
    'finished', coalesce(p.finished, false), 'solved', coalesce(p.solved, false), 'points', coalesce(p.points, 0),
    'card', case when p.finished then sp_card_for(d) end,
    'streak', case when uid is null then 0 else sp_streak(uid) end,
    'total', case when uid is null then 0 else tr_total(uid) end);
end $$;

create or replace function public.sp_profile_stats(uname text) returns json language sql stable security definer set search_path = public as $$
  select json_build_object('streak', sp_streak(p.id), 'total', tr_total(p.id),
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
