-- ================= Game functions that work for both Winx Club and KPop Demon Hunters =================
-- fr = 'winx' or 'kpdh'. The old function names keep working (as the Winx version) so nothing breaks
-- for anyone on the current site while the new one rolls out.

-- Today's card for a game. Winx picks exactly as before; KPop only picks cards that have a picture.
create or replace function public.sp_card_for(d date, f text) returns text language sql stable security definer set search_path = public as $$
  select uid from game_cards g where g.fr = f and (f = 'winx' or exists (select 1 from game_mosaics m where m.uid = g.uid))
  order by md5(uid || (select seed from game_config) || d::text) limit 1;
$$;
revoke all on function public.sp_card_for(date, text) from public, anon, authenticated;
create or replace function public.sp_card_for(d date) returns text language sql stable security definer set search_path = public as $$
  select sp_card_for(d, 'winx');
$$;
revoke all on function public.sp_card_for(date) from public, anon, authenticated;

-- Does this card match the question?
create or replace function public.sp_check(card text, q text) returns boolean language plpgsql stable security definer set search_path = public as $$
declare c game_cards; parts text[] := string_to_array(q, ':');
begin
  select * into c from game_cards where uid = card;
  case parts[1]
    when 'ed'   then return parts[2] = any(c.editions);
    when 'rar'  then return c.rar = parts[2];
    when 'hit'  then return c.rar not in ('R','QR','SR','PR');
    when 'solo' then return c.main is not null and cardinality(c.appears) = 1;
    when 'char' then return parts[2] = any(c.appears);
    when 'grp'  then
      if c.fr = 'kpdh' then
        return c.appears && (case parts[2]
          when 'HUNTR/X' then array['Rumi','Mira','Zoey']
          when 'Saja Boys' then array['Jinu','Abby','Baby','Mystery','Romance']
          when 'Friends & family' then array['Celine','Bobby','Healer Han']
          when 'Pets' then array['Derpy','Sussie']
          else array[]::text[] end);
      end if;
      return c.appears && (case parts[2]
        when 'Winx' then array['Bloom','Stella','Flora','Musa','Tecna','Aisha']
        when 'Specialists' then array['Sky','Brandon','Helia','Riven','Timmy','Nabu']
        when 'Trix' then array['Icy','Darcy','Stormy']
        when 'Pets' then array['Kiko','Milly','Belle','Coco','Pepe','Ginger','Chicko']
        when 'Special guests' then array['Zara Larsson']
        else array[]::text[] end);
    when 'gt'   then return c.n > parts[2]::int;
    else raise exception 'Unknown question';
  end case;
end $$;
revoke all on function public.sp_check(text, text) from public, anon, authenticated;

-- Streak for one game: days in a row with that game solved
create or replace function public.sp_streak(uid uuid, f text) returns int language plpgsql stable security definer set search_path = public as $$
declare d date := sp_today(); n int := 0;
begin
  if not exists (select 1 from secret_pull_plays where user_id = uid and day = d and fr = f and solved) then d := d - 1; end if;
  while exists (select 1 from secret_pull_plays where user_id = uid and day = d and fr = f and solved) loop
    n := n + 1; d := d - 1;
  end loop;
  return n;
end $$;
revoke all on function public.sp_streak(uuid, text) from public, anon, authenticated;
-- Overall streak (profiles, leaderboard): a day counts if either game was solved
create or replace function public.sp_streak(uid uuid) returns int language plpgsql stable security definer set search_path = public as $$
declare d date := sp_today(); n int := 0;
begin
  if not exists (select 1 from secret_pull_plays where user_id = uid and day = d and solved) then d := d - 1; end if;
  while exists (select 1 from secret_pull_plays where user_id = uid and day = d and solved) loop
    n := n + 1; d := d - 1;
  end loop;
  return n;
end $$;
revoke all on function public.sp_streak(uuid) from public, anon, authenticated;

create or replace function public.sp_number(d date, f text) returns int language sql immutable as $$
  select d - case when f = 'kpdh' then date '2026-11-09' else date '2026-11-05' end;
$$;

create or replace function public.sp_state_for(f text) returns json language plpgsql security definer set search_path = public as $$
declare d date := sp_today(); p secret_pull_plays; uid uuid := auth.uid();
begin
  if f not in ('winx','kpdh') then raise exception 'Unknown game'; end if;
  if uid is not null then select * into p from secret_pull_plays where user_id = uid and day = d and fr = f; end if;
  return json_build_object(
    'day', d, 'number', sp_number(d, f), 'fr', f,
    'log', coalesce(p.log, '[]'::jsonb), 'used', coalesce(p.used, 0),
    'finished', coalesce(p.finished, false), 'solved', coalesce(p.solved, false), 'points', coalesce(p.points, 0),
    'card', case when p.finished then sp_card_for(d, f) end,
    'streak', case when uid is null then 0 else sp_streak(uid, f) end,
    'total', case when uid is null then 0 else tr_total(uid) end);
end $$;

create or replace function public.sp_ask_for(q text, f text) returns json language plpgsql security definer set search_path = public as $$
declare d date := sp_today(); card text; uid uuid := auth.uid(); p secret_pull_plays; ans boolean;
begin
  if f not in ('winx','kpdh') then raise exception 'Unknown game'; end if;
  if q !~ '^(ed:(daily|magic|promo|c1|e1|m1|c2|e2)|rar:[A-Z]{1,4}|hit|solo|char:[A-Za-z .''-]{2,30}|grp:[A-Za-z /&]{2,30}|gt:[0-9]{1,3})$' then raise exception 'Unknown question'; end if;
  card := sp_card_for(d, f);
  ans := sp_check(card, q);
  if uid is not null then
    insert into secret_pull_plays (user_id, day, fr) values (uid, d, f) on conflict do nothing;
    select * into p from secret_pull_plays where user_id = uid and day = d and fr = f for update;
    if p.finished then return json_build_object('error', 'finished'); end if;
    if p.used >= 8 then return json_build_object('error', 'no_tries'); end if;
    update secret_pull_plays set used = used + 1, log = log || jsonb_build_array(jsonb_build_object('q', q, 'a', ans))
      where user_id = uid and day = d and fr = f;
  end if;
  return json_build_object('answer', ans);
end $$;

create or replace function public.sp_guess_for(guess text, f text) returns json language plpgsql security definer set search_path = public as $$
declare d date := sp_today(); card text; uid uuid := auth.uid(); p secret_pull_plays; ok boolean; over boolean;
begin
  if f not in ('winx','kpdh') then raise exception 'Unknown game'; end if;
  card := sp_card_for(d, f); ok := (guess = card);
  if uid is null then
    return json_build_object('correct', ok, 'card', case when ok then card end);
  end if;
  insert into secret_pull_plays (user_id, day, fr) values (uid, d, f) on conflict do nothing;
  select * into p from secret_pull_plays where user_id = uid and day = d and fr = f for update;
  if p.finished then return json_build_object('error', 'finished'); end if;
  over := ok or p.used >= 8;
  update secret_pull_plays set
      used = case when ok or p.used >= 8 then used else used + 1 end,
      log = log || jsonb_build_array(jsonb_build_object('g', guess, 'a', ok)),
      solved = ok, finished = over, points = sp_points(p.used, ok),
      finished_at = case when over then now() end
    where user_id = uid and day = d and fr = f;
  return json_build_object('correct', ok, 'finished', over, 'card', case when over then card end, 'points', sp_points(p.used, ok));
end $$;

create or replace function public.sp_reveal_for(f text) returns text language plpgsql security definer set search_path = public as $$
declare d date := sp_today(); p secret_pull_plays;
begin
  if f not in ('winx','kpdh') then raise exception 'Unknown game'; end if;
  if auth.uid() is null then return sp_card_for(d, f); end if;
  select * into p from secret_pull_plays where user_id = auth.uid() and day = d and fr = f;
  if coalesce(p.finished, false) then return sp_card_for(d, f); end if;
  return null;
end $$;

create or replace function public.sp_peek_for(used_count int, f text) returns json language plpgsql security definer set search_path = public as $$
declare d date := sp_today(); u int := used_count; lv int; m game_mosaics;
begin
  if f not in ('winx','kpdh') then raise exception 'Unknown game'; end if;
  if auth.uid() is not null then select coalesce(max(used), 0) into u from secret_pull_plays where user_id = auth.uid() and day = d and fr = f; end if;
  lv := case when u >= 6 then 3 when u >= 4 then 2 when u >= 2 then 1 else 0 end;
  if lv = 0 then return null; end if;
  select * into m from game_mosaics where uid = sp_card_for(d, f) and level = lv;
  return json_build_object('level', lv, 'w', m.w, 'h', m.h, 'px', m.px);
end $$;

-- The old names stay as the Winx version
create or replace function public.sp_state() returns json language sql security definer set search_path = public as $$ select sp_state_for('winx'); $$;
create or replace function public.sp_ask(q text) returns json language sql security definer set search_path = public as $$ select sp_ask_for(q, 'winx'); $$;
create or replace function public.sp_guess(guess text) returns json language sql security definer set search_path = public as $$ select sp_guess_for(guess, 'winx'); $$;
create or replace function public.sp_reveal() returns text language sql security definer set search_path = public as $$ select sp_reveal_for('winx'); $$;
create or replace function public.sp_peek(used_count int) returns json language sql security definer set search_path = public as $$ select sp_peek_for(used_count, 'winx'); $$;

-- ================= Daily Trivia =================
-- The 5 questions for a day and game: 2 written questions and 3 card questions of 3 different kinds.
create or replace function public.tr_build(d date, i int, f text) returns json
language plpgsql stable security definer set search_path = public as $$
declare n int := d - date '2026-11-05'; seed text := (select seed from game_config); qn trivia_questions;
  c game_cards; kind text; opts text[]; ans text; prompt text; fact text; diff text; k int; h1 int; h2 int; extra json;
  hs int := ('x' || substr(md5(seed || d::text || 'slots' || case when f = 'kpdh' then 'kpdh' else '' end), 1, 6))::bit(24)::int;
  w1 int; w2 int; j int; kinds text[]; today_card text := sp_card_for(d, f);
begin
  if i not between 0 and 4 then raise exception 'Bad question'; end if;
  if f = 'winx' and d < date '2026-11-10' then return tr_build_v1(d, i); end if;
  if f = 'kpdh' then kinds := array['rar','char','box','zoom','odd']; n := d - date '2026-11-09';
  else kinds := array['rar','char','box','zoom','odd','trans']; end if;
  w1 := hs % 5; w2 := (w1 + 1 + (hs / 5) % 4) % 5;
  if i in (w1, w2) then
    select count(*) into k from trivia_questions where active and fr = f;
    if k = 0 then raise exception 'No questions loaded'; end if;
    select * into qn from trivia_questions where active and fr = f
      order by md5(id::text || seed || 'tq') offset ((2 * n + case when i = least(w1, w2) then 0 else 1 end) % k) limit 1;
    prompt := qn.question; ans := qn.answer; fact := qn.fact; diff := qn.difficulty; kind := 'q';
    opts := array_append(qn.wrong, qn.answer);
  else
    j := (select count(*) from generate_series(0, i - 1) x where x not in (w1, w2));
    kind := (select kk from unnest(kinds) kk order by md5(kk || seed || d::text || 'kinds' || case when f = 'kpdh' then 'kpdh' else '' end) offset j limit 1);
    select g.* into c from game_cards g
      where g.fr = f and exists (select 1 from game_mosaics m where m.uid = g.uid) and g.uid <> today_card
        and (kind <> 'char' or (g.main is not null and cardinality(g.appears) = 1))
        and (kind <> 'trans' or (g.transformation is not null and g.transformation not like 'No transformation%'
             and g.appears && array['Bloom','Stella','Flora','Musa','Tecna','Aisha']))
      order by md5(g.uid || seed || d::text || 'tc' || j::text) limit 1;
    if c.uid is null then
      kind := 'box';
      select g.* into c from game_cards g where g.fr = f and exists (select 1 from game_mosaics m where m.uid = g.uid) and g.uid <> today_card
        order by md5(g.uid || seed || d::text || 'tc' || j::text) limit 1;
    end if;
    h1 := ('x' || substr(md5(c.uid || seed || d::text || 'h1'), 1, 6))::bit(24)::int;
    h2 := ('x' || substr(md5(c.uid || seed || d::text || 'h2'), 1, 6))::bit(24)::int;
    diff := 'Card'; fact := c.num;
    if kind = 'rar' then
      prompt := 'What rarity is this card?'; ans := c.rar;
      opts := array_append(array(select r from (select distinct rar r from game_cards where fr = f and rar <> c.rar and (f = 'winx' or rar <> 'PR')) x
                order by md5(r || seed || d::text || i::text) limit 3), c.rar);
    elsif kind = 'char' then
      prompt := 'Who''s on this blurry card?'; ans := c.main;
      opts := array_append(array(select m from (select distinct main m from game_cards where fr = f and main is not null and main <> c.main and cardinality(appears) = 1) x
                order by md5(m || seed || d::text || i::text) limit 3), c.main);
    elsif kind = 'trans' then
      prompt := 'What transformation is shown on this card?'; ans := c.transformation;
      opts := array_append(array(select t from (
                select distinct transformation t from game_cards where fr = 'winx' and transformation is not null and transformation not like 'No transformation%'
                union select unnest(array['Charmix','Harmonix','Bloomix','Mythix','Butterflix'])) x
                where t <> c.transformation order by md5(t || seed || d::text || i::text) limit 3), c.transformation);
    elsif kind = 'zoom' then
      prompt := 'Which card is this close-up from?'; ans := c.uid;
      opts := array_append(array(select g2.uid from game_cards g2
                where g2.fr = f and g2.uid <> c.uid and exists (select 1 from game_mosaics m where m.uid = g2.uid)
                order by (g2.rar <> c.rar), md5(g2.uid || seed || d::text || i::text) limit 3), c.uid);
      extra := json_build_object('zx', 25 + h1 % 51, 'zy', 22 + h2 % 50);
    elsif kind = 'odd' then
      prompt := 'What''s wrong with this card?';
      k := h1 % 4;
      ans := (array['It''s mirrored','The colors are wrong','Two pieces are swapped','Nothing, it''s right'])[k + 1];
      opts := array['It''s mirrored','The colors are wrong','Two pieces are swapped','Nothing, it''s right'];
      extra := json_build_object('fx', (array['m','h','s','n'])[k + 1], 'a', h2 % 9, 'b', (h2 % 9 + 1 + (h1 / 4) % 8) % 9, 'hue', 110 + h2 % 140);
    elsif f = 'kpdh' then
      prompt := 'Which box can you pull this card from?';
      ans := case when 'm1' = any(c.editions) then 'Special Mini Edition'
                  when c.editions && array['c1','c2'] and c.editions && array['e1','e2'] then 'Both Classic and Energy'
                  when c.editions && array['c1','c2'] then 'Classic Edition only'
                  when c.editions && array['e1','e2'] then 'Energy Edition only' else 'Promo card' end;
      opts := array['Classic Edition only','Energy Edition only','Both Classic and Energy','Special Mini Edition'];
    else
      prompt := 'Which box can you pull this card from?';
      ans := case when 'promo' = any(c.editions) then 'Promo card'
                  when 'daily' = any(c.editions) and 'magic' = any(c.editions) then 'Both Daily and Magic'
                  when 'daily' = any(c.editions) then 'Daily Edition only' else 'Magic Edition only' end;
      opts := array['Daily Edition only','Magic Edition only','Both Daily and Magic','Promo card'];
    end if;
  end if;
  opts := array(select o from unnest(opts) o order by md5(o || seed || d::text || i::text || 'shuffle'));
  return json_build_object('i', i, 'kind', kind, 'difficulty', diff, 'question', prompt, 'options', opts,
    'card', case when kind <> 'q' then c.uid end, 'answer', ans, 'fact', fact, 'extra', extra);
end $$;
revoke all on function public.tr_build(date, int, text) from public, anon, authenticated;
create or replace function public.tr_build(d date, i int) returns json language sql stable security definer set search_path = public as $$
  select tr_build(d, i, 'winx');
$$;
revoke all on function public.tr_build(date, int) from public, anon, authenticated;

create or replace function public.tr_state_for(f text) returns json language plpgsql security definer set search_path = public as $$
declare d date := sp_today(); p trivia_plays; uid uuid := auth.uid();
begin
  if f not in ('winx','kpdh') then raise exception 'Unknown game'; end if;
  if uid is not null then select * into p from trivia_plays where user_id = uid and day = d and fr = f; end if;
  return json_build_object('day', d, 'number', sp_number(d, f), 'fr', f,
    'answers', coalesce(p.answers, '[]'::jsonb), 'finished', coalesce(p.finished, false),
    'score', coalesce(p.score, 0), 'sparkles', coalesce(p.sparkles, 0),
    'total', case when uid is null then 0 else tr_total(uid) end);
end $$;

create or replace function public.tr_get_for(i int, f text) returns json language plpgsql security definer set search_path = public as $$
declare d date := sp_today(); uid uuid := auth.uid(); p trivia_plays; q json; left_s numeric := 20;
begin
  if f not in ('winx','kpdh') then raise exception 'Unknown game'; end if;
  q := tr_build(d, i, f);
  if uid is not null then
    insert into trivia_plays (user_id, day, fr) values (uid, d, f) on conflict do nothing;
    select * into p from trivia_plays where user_id = uid and day = d and fr = f for update;
    if p.finished then return json_build_object('error', 'finished'); end if;
    if i <> jsonb_array_length(p.answers) then return json_build_object('error', 'order'); end if;
    if p.served_i is distinct from i then
      update trivia_plays set served_i = i, served_at = now() where user_id = uid and day = d and fr = f;
    else
      left_s := greatest(0, 20 - extract(epoch from now() - p.served_at));
    end if;
  end if;
  return json_build_object('i', i, 'kind', q->>'kind', 'difficulty', q->>'difficulty', 'question', q->>'question',
    'options', q->'options', 'card', case when q->>'kind' <> 'char' then q->>'card' end, 'extra', q->'extra',
    'peek', case when q->>'kind' = 'char' then (select json_build_object('w', m.w, 'h', m.h, 'px', m.px) from game_mosaics m where m.uid = q->>'card' and m.level = 3) end,
    'seconds', round(left_s, 1));
end $$;

create or replace function public.tr_answer_for(i int, choice text, f text) returns json language plpgsql security definer set search_path = public as $$
declare d date := sp_today(); uid uuid := auth.uid(); p trivia_plays; q json; ok boolean; done boolean := false; sc int; sp int := 0;
begin
  if f not in ('winx','kpdh') then raise exception 'Unknown game'; end if;
  q := tr_build(d, i, f);
  ok := coalesce(choice, '') = q->>'answer';
  if uid is not null then
    select * into p from trivia_plays where user_id = uid and day = d and fr = f for update;
    if p.user_id is null or p.finished then return json_build_object('error', 'finished'); end if;
    if i <> jsonb_array_length(p.answers) or p.served_i is distinct from i then return json_build_object('error', 'order'); end if;
    if now() - p.served_at > interval '23 seconds' then ok := false; end if;
    sc := p.score + case when ok then 1 else 0 end;
    done := i = 4;
    if done then sp := sc + case when sc = 5 then 2 else 0 end; end if;
    update trivia_plays set answers = answers || jsonb_build_array(jsonb_build_object('c', coalesce(choice, ''), 'ok', ok)),
      score = sc, served_i = null, finished = done, sparkles = sp, finished_at = case when done then now() end
      where user_id = uid and day = d and fr = f;
  end if;
  return json_build_object('correct', ok, 'answer', q->>'answer', 'fact', q->>'fact', 'card', q->>'card', 'finished', done,
    'score', sc, 'sparkles', sp, 'total', case when uid is null then 0 else tr_total(uid) end);
end $$;

create or replace function public.tr_state() returns json language sql security definer set search_path = public as $$ select tr_state_for('winx'); $$;
create or replace function public.tr_get(i int) returns json language sql security definer set search_path = public as $$ select tr_get_for(i, 'winx'); $$;
create or replace function public.tr_answer(i int, choice text) returns json language sql security definer set search_path = public as $$ select tr_answer_for(i, choice, 'winx'); $$;

-- Both games on one page: how today is going in each version
create or replace function public.games_today() returns json language plpgsql security definer set search_path = public as $$
declare d date := sp_today(); uid uuid := auth.uid();
begin
  return json_build_object('day', d,
    'sp', (select coalesce(json_object_agg(fr, json_build_object('finished', finished, 'solved', solved, 'used', used, 'points', points)), '{}'::json)
           from secret_pull_plays where uid is not null and user_id = uid and day = d),
    'tr', (select coalesce(json_object_agg(fr, json_build_object('finished', finished, 'score', score, 'answered', jsonb_array_length(answers), 'sparkles', sparkles)), '{}'::json)
           from trivia_plays where uid is not null and user_id = uid and day = d),
    'streak', case when uid is null then 0 else sp_streak(uid) end,
    'total', case when uid is null then 0 else tr_total(uid) end);
end $$;

grant execute on function public.sp_number(date, text), public.sp_state_for(text), public.sp_ask_for(text, text), public.sp_guess_for(text, text),
  public.sp_reveal_for(text), public.sp_peek_for(int, text), public.sp_state(), public.sp_ask(text), public.sp_guess(text), public.sp_reveal(),
  public.sp_peek(int), public.tr_state_for(text), public.tr_get_for(int, text), public.tr_answer_for(int, text, text),
  public.tr_state(), public.tr_get(int), public.tr_answer(int, text), public.games_today() to anon, authenticated;

-- ================= Badges: collection badges stay about Winx cards; game badges count both games =================
create or replace function public.badge_check(p_uid uuid) returns setof text
language plpgsql stable security definer set search_path = public as $$
declare total int; owned int; best int; solves int; perfect int; since timestamptz; pub boolean; r record;
begin
  select count(*) into total from game_cards where fr = 'winx';
  select count(*) into owned from collection_items ci join game_cards g on g.uid = ci.card_uid where ci.user_id = p_uid and ci.qty > 0 and g.fr = 'winx';
  if owned >= 1 then return next 'first-card'; end if;
  if owned >= 50 then return next 'cards-50'; end if;
  if owned >= 100 then return next 'cards-100'; end if;
  if total > 0 and owned * 4 >= total then return next 'winx-col25'; end if;
  if total > 0 and owned * 2 >= total then return next 'winx-col50'; end if;
  if total > 0 and owned * 4 >= total * 3 then return next 'winx-col75'; end if;
  if total > 0 and owned >= total then return next 'winx-col100'; end if;
  for r in
    select 'winx-ed-' || e as id from unnest(array['daily','magic','promo']) e
      where not exists (select 1 from game_cards g where g.fr = 'winx' and e = any(g.editions)
        and not exists (select 1 from collection_items ci where ci.user_id = p_uid and ci.card_uid = g.uid and ci.qty > 0))
    union all
    select 'winx-rar-' || lower(x.rar) from (select distinct rar from game_cards where fr = 'winx') x
      where not exists (select 1 from game_cards g where g.fr = 'winx' and g.rar = x.rar
        and not exists (select 1 from collection_items ci where ci.user_id = p_uid and ci.card_uid = g.uid and ci.qty > 0))
  loop return next r.id; end loop;
  select count(*) into solves from secret_pull_plays where user_id = p_uid and solved;
  if solves >= 1 then return next 'solve-1'; end if;
  if solves >= 10 then return next 'solve-10'; end if;
  if solves >= 50 then return next 'solve-50'; end if;
  -- longest run of days in a row with a Secret Pull solved (either game)
  select coalesce(max(n), 0) into best from (
    select count(*) n from (select day, day - (row_number() over (order by day))::int as grp
      from (select distinct day from secret_pull_plays where user_id = p_uid and solved) dd) s group by grp) t;
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
