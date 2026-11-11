-- One favourite character per collection (IP) on the profile.
-- Stores e.g. {"winx":"Bloom","kpdh":"Rumi"}. The old fav_char column stays for older code.
alter table public.profiles add column if not exists fav_chars jsonb;

alter table public.profiles drop constraint if exists profiles_fav_chars_small;
alter table public.profiles add constraint profiles_fav_chars_small
  check (fav_chars is null or (jsonb_typeof(fav_chars) = 'object' and length(fav_chars::text) < 400));

-- Copy anyone's existing single favourite into the new column.
update public.profiles set fav_chars = jsonb_build_object('winx', fav_char)
 where fav_chars is null and fav_char is not null and fav_char <> '';
