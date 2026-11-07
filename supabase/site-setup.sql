-- My Pretty Pulls: contact form, account deletion and the word filter for profiles
-- Run once in Supabase: SQL Editor > New query > paste > Run. Safe to run again.

-- ---------- Word filter ----------
-- Blocks rude words in usernames, display names and About me. Some words are blocked anywhere they appear,
-- shorter ones only as a whole word (so "grape", "skill" and "Sussex" are fine).
create or replace function public.mpp_text_ok(t text) returns boolean language plpgsql immutable as $$
declare
  s text; joined text; w text;
  anywhere text[] := array['fuck','shit','cunt','nigger','nigga','faggot','whore','slut','porn','bitch','pussy','asshole',
    'motherf','dickhead','blowjob','handjob','jizz','cocksuck','retard','hitler','nazi','rapist','molest','pedophil',
    'incest','hentai','onlyfans','xxx','dildo','masturbat','orgasm','erotic'];
  whole text[] := array['sex','sexy','sexting','rape','raped','raping','kys','kms','dick','dicks','cock','cocks','fag','fags',
    'ass','tits','titty','titties','boob','boobs','cum','penis','vagina','nude','nudes','naked','horny','hoe','hoes','thot',
    'milf','anal','pedo','pedos','nsfw','kkk'];
begin
  if t is null or t = '' then return true; end if;
  s := translate(lower(t), '013457@$!|', 'oieastasii');
  joined := regexp_replace(s, '[^a-z]', '', 'g');
  foreach w in array anywhere loop
    if position(w in joined) > 0 then return false; end if;
  end loop;
  s := ' ' || regexp_replace(s, '[^a-z]+', ' ', 'g') || ' ';
  foreach w in array whole loop
    if position(' ' || w || ' ' in s) > 0 then return false; end if;
  end loop;
  return true;
end $$;

create or replace function public.profiles_clean() returns trigger language plpgsql as $$
begin
  if not (mpp_text_ok(new.username) and mpp_text_ok(new.display_name) and mpp_text_ok(new.about)) then
    raise exception 'inappropriate_words' using errcode = 'P0001';
  end if;
  return new;
end $$;
drop trigger if exists profiles_clean on public.profiles;
create trigger profiles_clean before insert or update of username, display_name, about on public.profiles
  for each row execute function public.profiles_clean();

-- ---------- Contact form ----------
-- Messages show up in Table Editor > feedback. Nobody can read them through the website.
create table if not exists public.feedback (
  id bigserial primary key,
  created_at timestamptz not null default now(),
  topic text not null check (topic in ('Suggestion','Add a card collection','Problem or bug','Complaint','Report a profile','Claim a badge','Other')),
  message text not null check (char_length(message) between 5 and 2000),
  email text check (char_length(email) <= 200),
  username text,
  user_id uuid,
  ip text,
  status text not null default 'new'
);
alter table public.feedback enable row level security;
revoke all on public.feedback from anon, authenticated;

create or replace function public.submit_feedback(topic text, message text, email text default null)
returns json language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); addr text; uname text; recent int;
begin
  begin
    addr := split_part(current_setting('request.headers', true)::json->>'x-forwarded-for', ',', 1);
  exception when others then addr := null;
  end;
  select count(*) into recent from feedback f
    where f.created_at > now() - interval '1 day'
      and ((uid is not null and f.user_id = uid) or (addr is not null and addr <> '' and f.ip = addr));
  if recent >= 10 then return json_build_object('error', 'too_many'); end if;
  if uid is not null then select p.username into uname from profiles p where p.id = uid; end if;
  insert into feedback (topic, message, email, username, user_id, ip)
    values (submit_feedback.topic, trim(submit_feedback.message), nullif(trim(submit_feedback.email), ''), uname, uid, nullif(addr, ''));
  return json_build_object('ok', true);
end $$;
grant execute on function public.submit_feedback(text, text, text) to anon, authenticated;

-- ---------- Delete my account ----------
-- Removes the account and everything tied to it: profile, collection, game scores.
create or replace function public.delete_my_account() returns json
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid();
begin
  if uid is null then return json_build_object('error', 'signed_out'); end if;
  update feedback set user_id = null, username = null where user_id = uid;
  delete from trivia_plays where user_id = uid;
  delete from secret_pull_plays where user_id = uid;
  delete from collection_items where user_id = uid;
  delete from profiles where id = uid;
  delete from auth.users where id = uid;
  return json_build_object('ok', true);
end $$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
