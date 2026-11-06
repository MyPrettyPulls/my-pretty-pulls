-- My Pretty Pulls: Sparkles leaderboard
-- Run once in Supabase: SQL Editor > New query > paste > Run. Needs "Secret Pull setup" to have been run first.
-- Only public profiles are listed. A signed-in player with a private profile still sees their own spot.

create or replace function public.sp_leaderboard(period text) returns json
language plpgsql stable security definer set search_path = public as $$
declare d date := sp_today(); since date; uid uuid := auth.uid(); out json;
begin
  since := case period when 'today' then d when 'week' then date_trunc('week', d)::date when 'all' then date '2000-01-01' end;
  if since is null then raise exception 'Unknown period'; end if;
  with board as (
    select p.id, p.username, p.display_name, p.avatar_card, p.avatar_x, p.avatar_y, p.avatar_zoom, p.is_public,
           sum(s.points)::int as sparkles, (count(*) filter (where s.solved))::int as solved, min(s.finished_at) as first_done
    from secret_pull_plays s join profiles p on p.id = s.user_id
    where s.day between since and d and s.finished and (p.is_public or p.id = uid)
    group by p.id
    having sum(s.points) > 0
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
grant execute on function public.sp_leaderboard(text) to anon, authenticated;
