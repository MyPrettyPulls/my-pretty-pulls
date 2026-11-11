# Builds supabase/badges-v2.sql from the site's card data (/tmp/carddata.json, made by dump_cards.py).
import json, math
d = json.load(open('/tmp/carddata.json'))
RN = d['rinfo']
q = lambda s: "$q$" + s + "$q$"
arr = lambda xs: "array[" + ",".join(q(x) for x in xs) + "]::text[]" if xs is not None else "null"
OLD = {'winx-rar-r':10,'winx-rar-qr':15,'winx-rar-sr':15,'winx-rar-srp':20,'winx-rar-fr':20,'winx-rar-ssr':20,'winx-rar-hr':25,'winx-rar-tr':25,
       'winx-rar-ur':30,'winx-rar-ugr':30,'winx-rar-ar':30,'winx-rar-zr':30,'winx-rar-cr':30,'winx-rar-bp':30,'winx-rar-se':20,'winx-rar-pr':25}
r5 = lambda x: int(5 * round(x / 5))

W = {**{k: 2 for k in ['R', 'SR', 'QR', 'HR']}, **{k: 4 for k in ['SSR', 'FR', 'SRP', 'UR']},
     **{k: 8 for k in ['TR', 'UGR', 'GP', 'AR']}, **{k: 15 for k in ['ZR', 'LR', 'SP', 'CR', 'CRP', 'BP', 'SE']}, 'PR': 10}
SERIAL = {('KPDH01', 'SE'), ('KPDH01', 'BP'), ('KPDH02', 'SE'), ('KPDH02', 'BP'), ('KPDH02', 'CRP')}
def rar_value(sets, rar):
    n = sum(1 for c in d['cards'] if c['set'] in sets and c['rar'] == rar)
    w = 60 if any((s, rar) in SERIAL for s in sets) else W[rar]
    return max(25, r5(n * w)), n

badges = []   # (id, category, name, desc, amount, icon, currency)
rules = []    # dict(badge, kind, fr, csets, rar, ed, chars, anychar, secret, need_frac, need_count, groups_needed, by_fr)
sort = [0]
def B(id, cat, name, desc, amt, icon, cur='shimmer', **rule):
    sort[0] += 10; badges.append((id, cat, name, desc, amt, icon, cur, sort[0]))
    if rule: rules.append(dict(badge=id, **rule))

# ---- General collecting (every collection counts) ----
C = 'Collecting'
B('first-card', C, 'First Pull', 'Add your first card to your collection.', 10, '🌱', kind='card', need_count=1)
B('cards-50', C, 'Binder Builder', 'Own 50 different cards.', 25, '📒', kind='card', need_count=50)
B('cards-100', C, 'Card Keeper', 'Own 100 different cards.', 50, '📚', kind='card', need_count=100)
B('cards-250', C, 'Card Vault', 'Own 250 different cards.', 100, '🗄️', kind='card', need_count=250)
B('cards-500', C, 'Treasure Trove', 'Own 500 different cards.', 200, '💎', kind='card', need_count=500)
B('multi-2', C, 'Double Feature', 'Collect cards from 2 different collections.', 50, '🎞️', kind='card', need_count=1, by_fr=True, groups_needed=2)
B('merch-1', C, 'First Merch', 'Add your first merch item, like an album or card holder.', 10, '🎁', kind='merch', need_count=1)
B('merch-5', C, 'On Display', 'Own 5 merch items.', 40, '🖼️', kind='merch', need_count=5)
B('secret-style', C, 'Secret Style', 'Own any secret style from a blind-box merch item.', 75, '🤫', kind='merch', secret=True, need_count=1)
B('fan-half', C, 'Biggest Fan', 'Own half the cards of one of your favorite characters. More Shimmer for characters with more cards.', 25, '💗', kind='fan')
B('fan-all', C, 'Superfan', 'Own every card of one of your favorite characters. More Shimmer for characters with more cards.', 50, '💖', kind='fan')

# ---- Profile and milestones ----
M = 'Collector milestones'
B('public', M, 'Show and Tell', 'Make your profile public so others can see your collection.', 10, '🪪')
B('about-me', M, 'All About Me', 'Add a profile picture, an about me and a favorite character.', 15, '📝')
B('curator', M, 'Curator', 'Fill a showcase row with 5 cards from one collection.', 15, '🏛️')
B('age-30', M, 'One Month In', 'Collect on My Pretty Pulls for 1 month.', 25, '🎂')
B('age-180', M, 'Half-Year Collector', 'Collect on My Pretty Pulls for 6 months.', 75, '🎂')
B('age-365', M, 'One Year of Pulls', 'Collect on My Pretty Pulls for 1 year.', 200, '🎂')

# ---- Winx Club ----
WX = 'Winx Club'; FD = ['WFD01']; CP = ['WCP01']
B('winx-col25', WX, 'Quarter Binder', 'Own 25% of the Winx Club Fairy Diary set.', 50, '🌸', kind='card', csets=FD, need_frac=.25)
B('winx-col50', WX, 'Halfway Magic', 'Own 50% of the Winx Club Fairy Diary set.', 100, '🌷', kind='card', csets=FD, need_frac=.5)
B('winx-col75', WX, 'Almost Enchanted', 'Own 75% of the Winx Club Fairy Diary set.', 200, '🌺', kind='card', csets=FD, need_frac=.75)
B('winx-col100', WX, 'Fairy Diary Complete', 'Own every card in the Winx Club Fairy Diary set, promos included.', 500, '👑', kind='card', csets=FD, need_frac=1)
B('winx-ed-daily', WX, 'Daily Edition Complete', 'Own every card you can pull from Daily Edition boxes.', 150, '☀️', kind='card', csets=FD, ed='daily', need_frac=1)
B('winx-ed-magic', WX, 'Magic Edition Complete', 'Own every card you can pull from Magic Edition boxes.', 150, '🌙', kind='card', csets=FD, ed='magic', need_frac=1)
B('winx-ed-promo', WX, 'Promo Collector', 'Own every Winx Club Fairy Diary promo card.', 100, '🎟️', kind='card', csets=FD, ed='promo', need_frac=1)
B('winx-cp-complete', WX, 'Costume Party Complete', 'Own every Winx Club Costume Party card, promos included.', 250, '🎭', kind='card', csets=CP, need_frac=1)
B('winx-six', WX, 'All Six Fairies', 'Own a card of Bloom, Stella, Flora, Musa, Tecna and Aisha.', 50, '🧚', kind='card', fr='winx', chars=['Bloom', 'Stella', 'Flora', 'Musa', 'Tecna', 'Aisha'], need_count=1)

def rarsets(prefix, cat, label, sets, fr, setdesc):
    for k in reversed(list(RN)):   # Rare first, rarest last
        if not any(c['set'] in sets and c['rar'] == k for c in d['cards']): continue
        amt, n = rar_value(sets, k)
        amt = max(amt, OLD.get(f"{prefix}-{k.lower()}", 0))   # never pay less than before
        nm = 'Promo Set' if k == 'PR' else f"{RN[k]} Set"
        B(f"{prefix}-{k.lower()}", cat, f"{label}{nm}", f"Own every {RN[k]} card in {setdesc}.", amt, '💠', kind='card', csets=sets, rar=k, need_frac=1)
rarsets('winx-rar', 'Winx Club · Fairy Diary rarity sets', 'Fairy Diary ', FD, 'winx', 'Winx Club Fairy Diary')
rarsets('winx-cp-rar', 'Winx Club · Costume Party rarity sets', 'Costume Party ', CP, 'winx', 'Winx Club Costume Party')

# ---- KPop Demon Hunters ----
KP = 'KPop Demon Hunters'; ALLK = ['KPDH01', 'KPDHM01', 'KPDH02', 'PROMO']
B('kpdh-col25', KP, 'Opening Act', 'Own 25% of every KPop Demon Hunters card.', 50, '🎤', kind='card', fr='kpdh', need_frac=.25)
B('kpdh-col50', KP, 'Halfway to Golden', 'Own 50% of every KPop Demon Hunters card.', 100, '🌟', kind='card', fr='kpdh', need_frac=.5)
B('kpdh-col75', KP, 'Encore', 'Own 75% of every KPop Demon Hunters card.', 200, '🎶', kind='card', fr='kpdh', need_frac=.75)
B('kpdh-col100', KP, 'World Tour Complete', 'Own every KPop Demon Hunters card: both series, the Special Mini Edition and promos.', 500, '🏆', kind='card', fr='kpdh', need_frac=1)
for e, nm, ic in [('c1', 'Classic Edition Series 1', '🎫'), ('e1', 'Energy Edition Series 1', '⚡'), ('m1', 'Special Mini Edition', '🎀'), ('c2', 'Classic Edition Series 2', '🎫'), ('e2', 'Energy Edition Series 2', '⚡')]:
    B(f'kpdh-ed-{e}', KP, f'{nm} Complete', f'Own every card you can pull from {nm} packs.', 150, ic, kind='card', fr='kpdh', ed=e, need_frac=1)
B('kpdh-promo', KP, 'KPop Promo Collector', 'Own every KPop Demon Hunters promo card.', max(25, r5(10 * sum(1 for c in d['cards'] if c['set'] == 'PROMO'))), '🎟️', kind='card', csets=['PROMO'], need_frac=1)
B('kpdh-huntrx', KP, 'HUNTR/X Forever', 'Own a card of Rumi, Mira and Zoey.', 30, '🗡️', kind='card', fr='kpdh', chars=['Rumi', 'Mira', 'Zoey'], need_count=1)
B('kpdh-saja', KP, 'Saja Boys Stan', 'Own a card of Jinu, Abby, Baby, Mystery and Romance.', 50, '😈', kind='card', fr='kpdh', chars=['Jinu', 'Abby', 'Baby', 'Mystery', 'Romance'], need_count=1)
B('kpdh-pets', KP, 'Derpy & Sussie', 'Own every card with Derpy or Sussie on it.', 100, '🐯', kind='card', fr='kpdh', anychar=['Derpy', 'Sussie'], need_frac=1)
B('kpdh-costco', KP, 'Costco Haul', 'Own both Costco Collector Boxes.', 75, '📦', kind='merch', uids=['KPDH-M|costco|1', 'KPDH-M|costco|2'], need_frac=1)
B('serial-1', KP, 'Numbered Pull', 'Save the serial number of a serialized card you own.', 50, '🔢')
rarsets('kpdh-s1-rar', 'KPop Demon Hunters · Series 1 rarity sets', 'Series 1 ', ['KPDH01'], 'kpdh', 'World Tour Series 1 (Classic and Energy)')
rarsets('kpdh-m1-rar', 'KPop Demon Hunters · Special Mini rarity sets', 'Special Mini ', ['KPDHM01'], 'kpdh', 'the Special Mini Edition')
rarsets('kpdh-s2-rar', 'KPop Demon Hunters · Series 2 rarity sets', 'Series 2 ', ['KPDH02'], 'kpdh', 'World Tour Series 2 (Classic and Energy)')

# ---- Games (Sparkles) ----
G = 'Guess the Secret Pull'
B('solve-1', G, 'First Find', 'Solve your first Secret Pull, in either game.', 5, '🃏', 'sparkles')
B('solve-10', G, 'Card Detective', 'Solve 10 Secret Pulls, counting both games.', 20, '🔎', 'sparkles')
B('solve-50', G, 'Secret Keeper', 'Solve 50 Secret Pulls, counting both games.', 50, '🗝️', 'sparkles')
B('solve-kpdh-1', G, "Hunter's Instinct", 'Solve your first KPop Demon Hunters Secret Pull.', 5, '🎯', 'sparkles')
B('solve-both', G, 'Double Duty', 'Solve both Secret Pulls on the same day.', 10, '🃏', 'sparkles')
S = 'Streaks'
for n, nm, amt in [(3, 'On a Roll', 5), (7, 'Week of Wonder', 15), (30, 'Monthly Magic', 50), (100, 'Unstoppable', 150)]:
    B(f'streak-{n}', S, nm, f'Solve a Secret Pull {n} days in a row (either game counts).', amt, '🔥', 'sparkles')
T = 'Daily Trivia'
B('trivia-1', T, 'Perfect Score', 'Get all 5 trivia questions right in one day, in either game.', 10, '💡', 'sparkles')
B('trivia-10', T, 'Trivia Whiz', 'Get a perfect trivia score on 10 different days.', 30, '🧠', 'sparkles')
B('trivia-30', T, 'Trivia Champion', 'Get a perfect trivia score on 30 different days.', 75, '🏅', 'sparkles')
B('trivia-both', T, 'Double Perfect', 'Get a perfect score in both trivia games on the same day.', 15, '✨', 'sparkles')

# ---------------- SQL ----------------
cards = [c for c in d['cards']]
merch = d['merch']
out = []
w = out.append
w("""-- My Pretty Pulls: badges for every collection (Winx Club, Costume Party, KPop Demon Hunters), bigger Shimmer rewards.
-- Run in Supabase: SQL Editor > New query > paste > Run. Needs badges-setup.sql (and the KPop games parts) first. Safe to run again.
-- Made by tools/badges/make_badges.py from the site's card list: rerun that script when cards are added.

alter table public.profiles add column if not exists fav_chars jsonb;

-- Every card and merch item the badges know about
create table if not exists public.badge_cards (
  uid text primary key, fr text not null, kind text not null, cset text, rar text,
  eds text[] not null default '{}', ap text[] not null default '{}', secret boolean not null default false
);
alter table public.badge_cards enable row level security;
revoke all on public.badge_cards from anon, authenticated;
truncate public.badge_cards;
insert into public.badge_cards (uid, fr, kind, cset, rar, eds, ap, secret) values""")
rows = [f"({q(c['uid'])},'{c['fr']}','card','{c['set']}','{c['rar']}',{arr(c['eds'])},{arr(c['ap'])},false)" for c in cards]
rows += [f"({q(m['uid'])},'{m['fr']}','merch',null,null,'{{}}',{arr([])},{str(m['secret']).lower()})" for m in merch]
w(",\n".join(rows) + ";")
w("""
-- What each collection badge needs. The site reads this too, to show your progress.
--   kind: card / merch / fan. Filters: fr, csets (card sets), rar, ed (edition), uids, secret, anychar (cards with any of these characters).
--   chars: one group per character; by_fr: one group per collection. need_frac / need_count apply to each group;
--   groups_needed: how many groups must pass (empty = all of them).
create table if not exists public.badge_rules (
  badge text primary key references public.badge_catalog(id) on delete cascade,
  kind text not null, fr text, csets text[], rar text, ed text, uids text[], secret boolean not null default false,
  anychar text[], chars text[], by_fr boolean not null default false,
  need_frac numeric, need_count int, groups_needed int
);
alter table public.badge_rules enable row level security;
drop policy if exists "Anyone can read badge rules" on public.badge_rules;
create policy "Anyone can read badge rules" on public.badge_rules for select to anon, authenticated using (true);
grant select on public.badge_rules to anon, authenticated;
""")
w("insert into public.badge_catalog (id, category, name, description, sparkles, icon, sort, currency, kind) values")
w(",\n".join(f"({q(i)},{q(c)},{q(n)},{q(ds)},{a},{q(ic)},{s},'{cur}','auto')" for i, c, n, ds, a, ic, cur, s in badges))
w("""on conflict (id) do update set category = excluded.category, name = excluded.name, description = excluded.description,
  sparkles = excluded.sparkles, icon = excluded.icon, sort = excluded.sort, currency = excluded.currency;
-- social badges go last
update public.badge_catalog set sort = 5000 + sort where category = 'Social' and sort < 5000;
-- tidy up old rarity-set badges that no longer exist (none expected, but keeps the list clean)
delete from public.badge_catalog where id like 'winx-rar-%' and id not in (""" + ",".join(q(b[0]) for b in badges if b[0].startswith('winx-rar-')) + """);
""")
w("delete from public.badge_rules;")
w("insert into public.badge_rules (badge, kind, fr, csets, rar, ed, uids, secret, anychar, chars, by_fr, need_frac, need_count, groups_needed) values")
def v(x): return "null" if x is None else (q(x) if isinstance(x, str) else str(x))
w(",\n".join("(" + ",".join([q(r['badge']), q(r['kind']), v(r.get('fr')), arr(r.get('csets')), v(r.get('rar')), v(r.get('ed')), arr(r.get('uids')),
    str(r.get('secret', False)).lower(), arr(r.get('anychar')), arr(r.get('chars')), str(r.get('by_fr', False)).lower(),
    v(r.get('need_frac')), v(r.get('need_count')), v(r.get('groups_needed'))]) + ")" for r in rules) + ";")
w(open('/home/claude/my-pretty-pulls/tools/badges/functions.sql').read())
open('/home/claude/my-pretty-pulls/supabase/badges-v2.sql', 'w').write("\n".join(out) + "\n")
json.dump([b[:8] for b in badges], open('/tmp/badges.json', 'w'))
sh = sum(b[4] for b in badges if b[6] == 'shimmer')
print(len(badges), 'badges,', len(rules), 'rules; shimmer catalogue total', sh)
