-- Daily Trivia: the 3 card questions in a day are always 3 different kinds
-- (no more three "What rarity is this card?" in one day).
-- Starts with the Nov 10, 2026 quiz; days before that keep their original questions.
-- Run this whole file once in the Supabase SQL editor.

-- the old rules, kept for past days
create or replace function public.tr_build_v1(d date, i int) returns json
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
revoke all on function public.tr_build_v1(date, int) from public, anon, authenticated;

-- the new rules
create or replace function public.tr_build(d date, i int) returns json
language plpgsql stable security definer set search_path = public as $$
declare n int := d - date '2026-11-05'; seed text := (select seed from game_config); pool text[]; qn trivia_questions;
  c game_cards; kind text; opts text[]; ans text; prompt text; fact text; diff text; k int; h1 int; h2 int; extra json;
  hs int := ('x' || substr(md5(seed || d::text || 'slots'), 1, 6))::bit(24)::int; w1 int; w2 int; j int;
begin
  if i not between 0 and 4 then raise exception 'Bad question'; end if;
  if d < date '2026-11-10' then return tr_build_v1(d, i); end if;
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
    -- which card question this is today (0, 1 or 2)
    j := (select count(*) from generate_series(0, i - 1) x where x not in (w1, w2));
    -- the 3 card questions each get a different kind: shuffle the 6 kinds for the day and take the first 3
    kind := (select kk from unnest(array['rar','char','box','zoom','odd','trans']) kk
              order by md5(kk || seed || d::text || 'kinds') offset j limit 1);
    -- then pick a card that suits that kind (who's-on-it needs a solo card; transformations need a transformed Winx fairy)
    select g.* into c from game_cards g
      where exists (select 1 from game_mosaics m where m.uid = g.uid) and g.uid <> sp_card_for(d)
        and (kind <> 'char' or (g.main is not null and cardinality(g.appears) = 1))
        and (kind <> 'trans' or (g.transformation is not null and g.transformation not like 'No transformation%'
             and g.appears && array['Bloom','Stella','Flora','Musa','Tecna','Aisha']))
      order by md5(g.uid || seed || d::text || 'tc' || j::text) limit 1;
    -- just in case nothing fits (should not happen), fall back to a box question on any card
    if c.uid is null then
      kind := 'box';
      select g.* into c from game_cards g where exists (select 1 from game_mosaics m where m.uid = g.uid) and g.uid <> sp_card_for(d)
        order by md5(g.uid || seed || d::text || 'tc' || j::text) limit 1;
    end if;
    h1 := ('x' || substr(md5(c.uid || seed || d::text || 'h1'), 1, 6))::bit(24)::int;
    h2 := ('x' || substr(md5(c.uid || seed || d::text || 'h2'), 1, 6))::bit(24)::int;
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
