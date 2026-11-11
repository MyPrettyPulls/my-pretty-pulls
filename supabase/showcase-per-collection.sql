-- A showcase for each collection: up to 5 cards per collection (Winx Club, KPop Demon Hunters, and room for more later).
-- The site keeps each collection to 5; the database just stops anything silly.
alter table public.profiles drop constraint if exists profiles_showcase_check;
alter table public.profiles drop constraint if exists profiles_showcase_max;
alter table public.profiles add constraint profiles_showcase_max check (cardinality(showcase) <= 25);
