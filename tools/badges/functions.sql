
-- Shimmer for the favorite-character badges grows with how many cards that character has
create or replace function public.badge_fans(p_uid uuid)
returns table (fr text, nm text, sz int, have int)
language sql stable security definer set search_path = public as $$
  with favs as (
    select distinct e.key as fr, e.value as nm
      from profiles p, jsonb_each_text(coalesce(p.fav_chars, '{}'::jsonb)) e
      where p.id = p_uid and e.value <> ''
    union
    select distinct bc.fr, p.fav_char
      from profiles p join badge_cards bc on p.fav_char = any(bc.ap)
      where p.id = p_uid and coalesce(p.fav_char, '') <> '' and coalesce(p.fav_chars, '{}'::jsonb) = '{}'::jsonb
  )
  select f.fr, f.nm, count(*)::int, count(ci.card_uid)::int
    from favs f
    join badge_cards bc on bc.kind = 'card' and bc.fr = f.fr and f.nm = any(bc.ap)
    left join collection_items ci on ci.user_id = p_uid and ci.card_uid = bc.uid and ci.qty > 0
    group by f.fr, f.nm;
$$;
revoke all on function public.badge_fans(uuid) from public, anon, authenticated;

create or replace function public.badge_amount(p_uid uuid, p_badge text) returns int
language sql stable security definer set search_path = public as $$
  select case p_badge
    when 'fan-half' then (select max(least(150, greatest(25, 5 * round(sz * 1.5 / 5))))::int from badge_fans(p_uid) where have * 2 >= sz)
    when 'fan-all'  then (select max(least(300, greatest(50, 5 * round(sz * 3.0 / 5))))::int from badge_fans(p_uid) where have >= sz)
  end;
$$;
revoke all on function public.badge_amount(uuid, text) from public, anon, authenticated;

-- Which badges this person qualifies for right now
create or replace function public.badge_check(p_uid uuid) returns setof text
language plpgsql stable security definer set search_path = public as $$
declare best int; solves int; perfect int; since timestamptz; pub boolean; ok boolean; r record;
begin
  -- collection badges, from the rules table
  for r in
    with own as (select card_uid from collection_items where user_id = p_uid and qty > 0),
    grp as (
      select ru.badge, coalesce(ch.c, case when ru.by_fr then bc.fr end, '') as g, count(*) as sz, count(o.card_uid) as have
        from badge_rules ru
        left join lateral unnest(ru.chars) ch(c) on true
        join badge_cards bc on bc.kind = ru.kind
          and (ru.fr is null or bc.fr = ru.fr) and (ru.csets is null or bc.cset = any(ru.csets))
          and (ru.rar is null or bc.rar = ru.rar) and (ru.ed is null or ru.ed = any(bc.eds))
          and (ru.uids is null or bc.uid = any(ru.uids)) and (not ru.secret or bc.secret)
          and (ru.anychar is null or bc.ap && ru.anychar) and (ch.c is null or ch.c = any(bc.ap))
        left join own o on o.card_uid = bc.uid
        where ru.kind in ('card', 'merch')
        group by ru.badge, 2
    )
    select g.badge from grp g join badge_rules ru on ru.badge = g.badge
      group by g.badge, ru.groups_needed, ru.need_count, ru.need_frac
      having count(*) filter (where case when ru.need_count is not null then g.have >= ru.need_count
                                         else g.have >= ceil(ru.need_frac * g.sz) end)
             >= coalesce(ru.groups_needed, count(*))
  loop return next r.badge; end loop;

  -- favorite characters
  if exists (select 1 from badge_fans(p_uid) where have * 2 >= sz) then return next 'fan-half'; end if;
  if exists (select 1 from badge_fans(p_uid) where have >= sz) then return next 'fan-all'; end if;

  -- Guess the Secret Pull (both games count)
  select count(*) into solves from secret_pull_plays where user_id = p_uid and solved;
  if solves >= 1 then return next 'solve-1'; end if;
  if solves >= 10 then return next 'solve-10'; end if;
  if solves >= 50 then return next 'solve-50'; end if;
  if exists (select 1 from secret_pull_plays where user_id = p_uid and solved and fr = 'kpdh') then return next 'solve-kpdh-1'; end if;
  if exists (select 1 from secret_pull_plays where user_id = p_uid and solved group by day having count(distinct fr) >= 2) then return next 'solve-both'; end if;
  select coalesce(max(n), 0) into best from (
    select count(*) n from (select day, day - (row_number() over (order by day))::int as grp
      from (select distinct day from secret_pull_plays where user_id = p_uid and solved) dd) s group by grp) t;
  if best >= 3 then return next 'streak-3'; end if;
  if best >= 7 then return next 'streak-7'; end if;
  if best >= 30 then return next 'streak-30'; end if;
  if best >= 100 then return next 'streak-100'; end if;

  -- Daily Trivia (both games count)
  select count(*) into perfect from trivia_plays where user_id = p_uid and finished and score = 5;
  if perfect >= 1 then return next 'trivia-1'; end if;
  if perfect >= 10 then return next 'trivia-10'; end if;
  if perfect >= 30 then return next 'trivia-30'; end if;
  if exists (select 1 from trivia_plays where user_id = p_uid and finished and score = 5 group by day having count(distinct fr) >= 2) then return next 'trivia-both'; end if;

  -- profile and milestones
  select p.created_at, p.is_public into since, pub from profiles p where p.id = p_uid;
  if since is not null and since <= now() - interval '30 days' then return next 'age-30'; end if;
  if since is not null and since <= now() - interval '180 days' then return next 'age-180'; end if;
  if since is not null and since <= now() - interval '365 days' then return next 'age-365'; end if;
  if coalesce(pub, false) then return next 'public'; end if;
  if exists (select 1 from profiles p where p.id = p_uid and p.avatar_card is not null and length(btrim(coalesce(p.about, ''))) > 0
      and (coalesce(p.fav_char, '') <> '' or coalesce(p.fav_chars, '{}'::jsonb) <> '{}'::jsonb)) then return next 'about-me'; end if;
  if exists (select 1 from profiles p cross join lateral unnest(p.showcase) u(uid)
      join badge_cards bc on bc.uid = u.uid
      join collection_items ci on ci.user_id = p_uid and ci.card_uid = u.uid and ci.qty > 0
      where p.id = p_uid group by bc.fr having count(distinct u.uid) >= 5) then return next 'curator'; end if;
  if exists (select 1 from profile_shares ps where ps.owner = p_uid) then return next 'share-1'; end if;

  -- a saved serial number on a serialized card you own (only once card-serials.sql has been run)
  if to_regclass('public.card_serials') is not null then
    execute 'select exists (select 1 from card_serials s join collection_items ci on ci.user_id = s.user_id and ci.card_uid = s.card_uid and ci.qty > 0
      where s.user_id = $1 and exists (select 1 from unnest(s.serials) x where btrim(x) <> ''''))' into ok using p_uid;
    if ok then return next 'serial-1'; end if;
  end if;
end $$;
revoke all on function public.badge_check(uuid) from public, anon, authenticated;

-- Hand out newly earned badges, take back automatic ones you no longer qualify for, and say what changed.
create or replace function public.award_badges() returns json
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); got json; lost json; ok text[];
begin
  if uid is null then return json_build_object('earned', '[]'::json, 'lost', '[]'::json); end if;
  ok := array(select badge_check(uid));
  with gone as (
    delete from user_badges ub using badge_catalog b
      where ub.user_id = uid and b.id = ub.badge and b.kind = 'auto' and not (ub.badge = any(ok))
      returning ub.badge, ub.sparkles
  ) select coalesce(json_agg(json_build_object('id', b.id, 'name', b.name, 'icon', b.icon, 'amount', gone.sparkles, 'currency', b.currency)), '[]')
    into lost from gone join badge_catalog b on b.id = gone.badge;
  with new as (
    insert into user_badges (user_id, badge, sparkles, currency)
      select uid, b.id, coalesce(badge_amount(uid, b.id), b.sparkles), b.currency from badge_catalog b where b.kind = 'auto' and b.id = any(ok)
      on conflict do nothing returning badge, sparkles
  ) select coalesce(json_agg(json_build_object('id', b.id, 'name', b.name, 'icon', b.icon, 'amount', new.sparkles, 'currency', b.currency) order by b.sort), '[]')
    into got from new join badge_catalog b on b.id = new.badge;
  -- a bigger favorite later on earns the bigger fan reward
  update user_badges ub set sparkles = badge_amount(uid, ub.badge)
    where ub.user_id = uid and ub.badge in ('fan-half', 'fan-all') and badge_amount(uid, ub.badge) > ub.sparkles;
  return json_build_object('earned', got, 'lost', lost);
end $$;
grant execute on function public.award_badges() to authenticated;

-- Top up badges people already earned to the new, bigger amounts (never lowers anything)
update public.user_badges ub set sparkles = b.sparkles, currency = b.currency
  from public.badge_catalog b
  where ub.badge = b.id and b.id not in ('fan-half', 'fan-all') and ub.sparkles < b.sparkles;
