# My Pretty Pulls: plans agreed with Kinsey

## Backgrounds
- Each franchise page has its own full background. Winx Club = soft rainbow glitter, fine glitter, twinkling stars, shooting-star shimmers (done).
  KPop Demon Hunters = dusk-stage sky with glowing, patterned light lines that drift and pulse (done, on /kpop-demon-hunters).
- Combined "My collection" page (build when KPop Demon Hunters is added):
  - Starts from a soft neutral shimmer. A brand-new account with no cards sees only that.
  - Each franchise adds its signature layer only once the person owns at least 1 card from it
    (Winx: rainbow glitter + shooting stars; KPDH: glowing patterned light lines, inspired by the show's style,
    not a copy of Rumi's markings; MLP: TBD, e.g. soft clouds / rainbow trails). Layers stack as more franchises are collected.

## Later
- Sparkle Store (button says "Coming soon"; what Sparkles buy is undecided).
- eBay prices, MLP card data, card backs.

## KPop Demon Hunters (added Nov 2026)
- Page: /kpop-demon-hunters. 399 cards: Series 1 Classic + Energy (KPDH01, 170), Special Mini Edition (KPDHM01, 41), Series 2 Classic + Energy (KPDH02, 178), 10 promos.
- KAYOU products on the page: tiles (picture + name) for every card product and the merch line; tap one for details.
  Product photos live in products/<id>.webp (listed in PROD_IMGS); per-style photos are products/<id>-<n>.webp (STYLE_IMGS).
  Still drawn: Costco box, Laser Ticket, promo cards.
- Winx Costume Party (WCP01, Nov 11 2026): real numbers and names in (CPCARDS), plus PR-001..003. Pictures still to add.
- To do: confirm Series 2 card numbers once collectors list them (marked "not confirmed" for now); add card pictures (none yet, cards show colour placeholders);
  KPDH on profiles shows in the card grid, but profile stats and the games are still Winx only.

## Standard for every collection page (Winx, KPDH, and every new IP)
- Products guide: a closed-by-default panel "Every <IP> product from KAYOU". Opens to picture tiles in two groups,
  Cards and Merchandise; each tile opens a details window (headings + bullet lists) with a link to the product's
  KAYOU page and a source credit. Set it up with FRANCH.<id>.products (see W_PRODUCTS / K_PRODUCTS).
- Merchandise is trackable per style (product "items"). Saved like cards, as <IP>-M|<product>|<n>.
- Top counters: Everything collected, Cards, Merchandise, Extras to trade, Binder value.
- Card lists: every collection block and every rarity has Hide/Show, plus Hide all / Show all.
  Works in "Every card" and in a single edition. Remembered on the device.
- Winx merch: none from KAYOU yet ("additional collectibles will follow"); add to W_PRODUCTS when it arrives.
- Merchandise is tracked in the collection list (its own "Merchandise" block and tile), per style, like cards.
  Master list: Google Sheet "Kayou Merchandise List" (one tab per IP). Item IDs (last column) must match the site.
- Trade list ("Make a trade list"): needs + extras (+ merch), follows filters and hidden sections, adds public profile link.

## KPop Demon Hunters background (Nov 2026)
- Day: pastel stage with colour-changing rainbow lines (richer colours, thin lines). No sparkles.
- Every 30–90 s it fades into a dark sparkly night for 10–25 s (sparkles + shooting stars), then back. Lines keep changing colour.
- At night in light mode, text sitting straight on the background turns light; panels, cards and buttons keep their colours.
- Profile pages (/profile, /u/name) follow what the person collects: Winx only = Winx sparkles; KPop only = KPop day/night; both = KPop day/night with sparkles always on. Winx collection page keeps its always-on sparkles.
- Reduced-motion users stay on day. Demon-marking experiments were dropped.

## Profiles with more than one collection (Nov 2026)
- Top counters: "Total collection" across every collection the person has started (cards + merch), total items, editions completed, extras. With only one collection the first counter is named after it.
- One panel per started collection (Everything / Cards / Merchandise / Extras + edition tiles + "Open collection"). Collections they haven't started stay hidden. New IPs show up automatically once added to FRANCH.
- "Your collection" grid gets a tab per collection when there's more than one, plus the favourite-character tab.
- Favourite character, profile picture and showcase can come from any collection. Share image uses the combined numbers.
- Still Winx-only: badges.

## KPop Demon Hunters card pictures (Nov 2026)
- Pictures come from KAYOU's set pages. tools/kpdh-kayou-pages.py lists every picture link in page order; tools/kpdh-image-map.json matches each to a card number.
- Kinsey downloads them (save a page of all pictures as "Webpage, Complete", zip the _files folder); files keep KAYOU's names so they can be matched.
- Converted to cards/<number>-s.webp (560px) and -l.webp (1260px max); ◇CR uses "crp" in the file name. Holo Rare GIFs stay animated (K_ANIM, no extra shine).
- Done: all 389 set cards (Series 1, Mini Edition, Series 2). Promos have no pictures on KAYOU's pages yet.
- Laser Tickets: real styles (8 Regular, 8 Special, 2 Secret Saja Boys, 2 Super Secret HUNTR/X) with pictures cut from KAYOU's page.

## KPop card effects (Nov 2026)
- Series 1 Rare (KPDH01-R): holo on the round "story" pictures and LIVE badges; purple (HUNTR/X) frames also holo on the top/bottom bands; pink (Saja Boys) frames' bands are shine only. Masks: cards/<key>-m.webp (holo) and -m2.webp (pink shine), made by tools/kpdh-rare-masks.py.
- A card effect's mask can now be a named file: ["shine","m2"] uses cards/<key>-m2.webp.
- Classic Edition Series 1 (only cards in C1; Kinsey does each collection separately), masks made by tools/kpdh-c1-masks.py:
  QR foil in the card's colours + holographic glitter; SR shiny pop-outs (-m), silver foil top-right square (-m2), shiny black edges (-m3);
  SSR fine holo shimmer over the whole card; HR as is (animated); UR shattered background, gold signature (-m2), silver+holo white outlines (-m3);
  ZR holo on background lines (-m) + demon markings (-m2, ZR-006/008); CR shifting silver shine over the whole card.
- Energy Edition Series 1: QR, SR, SSR, UR, ◇CR, HR same as Classic. New (tools/kpdh-e1-masks.py): SE raised gold shine on frame/lettering (-m) + sparkle in the glow behind the girls (-m2);
  BP shiny shimmer all over; SP rich, saturated colourful foil (shine kept low) on every colour except black/white and dark flat purples (-m); LR sparkly patterned black background (-m) + holo silver details (-m2) + shiny red chains (-m3); TR plain shine.
- Series 2 (Classic + Energy), masks by tools/kpdh-s2-masks.py: SE silver version of GOLDEN (chrome frame -m, sparkle in blue glow -m2); BP silver holo + shine + tiny holo glitter;
  ◇CR holo + fine coloured shine; SP vivid colours + holo (-m); LR holo letters (-m) + sparkles; UR holo/silver on letters, background lines and silver (-m); QR/TR same as Series 1;
  SSR vivid + soft bright foil; SR holo lines + fine sparkles; R holo on the black/silver clapperboard only (-m); ZR fine shimmer + holo silver HUNTR/X lettering (-m); CR fine shimmer + very fine glitter.
  HR (Series 2) not described yet.
- Still to describe: Special Mini Edition. Until then those cards get a plain shine.

## Serial numbers (Nov 2026)
- Serialized cards get a "Serial number" box per copy owned in the card window: KPDH01 SE (/366, birthday numbering), KPDH01 BP (/999), KPDH02 SE, BP, ◇CR (print run not announced, so no "/ out of").
- Saved on the device (localStorage mpp.serials) and, once supabase/card-serials.sql has been run, to the account (table card_serials, private to each person).

## KPop Demon Hunters games (Nov 2026)
- /play and /trivia open a page to pick the Winx Club or KPop Demon Hunters version; /play/winx, /play/kpop-demon-hunters, /trivia/winx, /trivia/kpop-demon-hunters are the games (Winx/KPop switch at the top of each).
- Database: supabase/kpop-games/kpop-games-part1..6.sql, run in order after trivia-no-repeat-kinds.sql (split because the Supabase editor rejects one big file). Adds fr ('winx'/'kpdh') to game_cards, trivia_questions, secret_pull_plays, trivia_plays; KPop cards + blurry previews; *_for(f) functions; old function names stay as the Winx version so the live site keeps working. Winx puzzles are unchanged (checked).
- Sparkles and the leaderboard are shared across all games. Streaks: per game on the game page; overall (either game) on profiles/leaderboard.
- KPop Secret Pull only uses cards with pictures. KPop card trivia kinds: rarity, who's on it, box, close-up, what's wrong (no transformations).
- Trivia questions come from the "Winx Trivia" and "Kpop Trivia" tabs of the card sheet (no fun facts). To update: regenerate with tools/games (trivia_qs.py) and rerun the trivia part (part 6).
- KPop puzzle numbers start at #1 on Nov 10, 2026.

## Profile: favourites per collection, tidier edit window (preview)
- One favourite character per IP (Winx Club, KPop Demon Hunters…). Header shows a chip for each; the favourites panel shows each one's name, have/total bar in their colour, up to 6 owned cards, and "See all" (opens a tab of just that character).
- Edit profile window: About you / Favorites / Avatar / Showcase are fold-up sections; the open ones are remembered. Avatar and showcase pickers can filter by IP.
- Showcase tray at the top of the picker: the 5 chosen cards in order, drag (or arrows) to rearrange, ✕ to remove.
- Needs supabase/profile-favorites.sql (adds profiles.fav_chars). Until it's run, saving still works with one favourite and shows a note.
- Night mode: panels, docs (badges/about/legal), store buttons, chips and footer pills keep dark text; text sitting on the background turns light with a soft dark glow so it stays readable while the background fades.

## Showcase for each collection (preview)
- Profile showcase has a row for each collection (up to 5 cards each), stacked like the favourites panel, so the two columns line up. Single-IP collectors see one row with no label.
- Empty slots say "Pick a favorite pull" and open the showcase section of Edit profile.
- Edit profile: one box per collection with drag / arrows / ✕; the picker numbers cards within their own collection and stops at 5 per collection.
- Arrange mode on the profile works per row (cards can't be dragged between collections).
- Share image mixes cards from each collection (5 total).
- Stored in the same profiles.showcase list. Needs supabase/showcase-per-collection.sql (raises the 5-card limit). Until it's run, saving keeps the first 5 and shows a note.
- KPop Series 2 card numbers checked against printed cards: "not confirmed" notes removed.

## Badges v2: every collection, bigger Shimmer (preview)
- 112 automatic badges (+6 social). Run supabase/badges-v2.sql after the KPop games parts. If badges-setup.sql is ever rerun, rerun badges-v2.sql after it.
- Built by tools/badges/make_badges.py from the site's card list (dump_cards.py → /tmp/carddata.json). Rerun both when cards/merch are added, then rerun the SQL.
- badge_cards = every card + merch item; badge_rules = what each collection badge needs (filters + need_frac/need_count, groups per character or collection). Database awards from it; the Badges page reads it for "You have X / Y".
- Rarity sets per series: Winx Fairy Diary, Costume Party, KPop S1, Special Mini, S2. Shimmer = cards × rarity weight (R/SR/QR/HR 2, SSR/FR/SRP/UR 4, TR/UGR/GP/AR 8, ZR/LR/SP/CR/CRP 15, serialized KPop SE/BP + S2 CRP 60, PR 10), rounded to 5, min 25; old Winx values never lowered.
- Collection %: 50/100/200/500. Editions 150. Costume Party Complete 250.
- General: cards 50/100/250/500, Double Feature, First Merch, On Display, Secret Style (any secret merch), Biggest Fan / Superfan (scaled by the character's card count: 1.5×, 25–150 / 3×, 50–300), Curator, All About Me, time milestones 25/75/200.
- KPop fun: HUNTR/X Forever, Saja Boys Stan, Derpy & Sussie, Costco Haul, Numbered Pull (needs card-serials.sql). Winx: All Six Fairies.
- Games (Sparkles) count either game; new: Hunter's Instinct, Double Duty, Double Perfect, Trivia Champion.
- Existing earners are topped up to the new amounts when the file runs.
- Badges page: each category folds up (Show/Hide, remembered per device in localStorage "mpp.badgeCatsClosed"); a sticky bar of category chips (with earned counts) jumps to a section and opens it; Show all / Hide all. Chips scroll sideways on phones.

## News and Pretty Pull Updates (preview)
- /news (+ /news/<slug>) and /updates (+ /updates/<slug>); menu section "What's new" and footer links. _redirects updated.
- Posts live in content/news.json and content/updates.json (Kinsey sends posts; Claude adds them). Newest first automatically.
- "draft": true posts only show on the preview site (preview.*, localhost) with a Draft label. Remove it to publish.
- News tags: winx, kpdh (one filter per collection, always shown), tcg (Trading card world), potw (Pretty Pull of the Week). The newest potw post is featured at the top; with none, an invite to tag @myprettypulls shows instead.
  potw fields: {handle, platform (tiktok/instagram/youtube), url, photo (content/news/<file>.webp), card}. Get the fan's OK before using their photo.
- Body text: ## heading, - list, **bold**, *italic*, [link](/path or https://), ![caption](image), !![caption](image) for a long sheet (shows the top, tap for full size). "thumb" = news-card picture only; "cover" = top of the post. In updates, "## You asked, we built" and "## Behind the scenes" become callouts; the number of "You asked" items shows as "💬 N ideas from you".
- Drafted history (needs Kinsey's review): Hello (Nov 5, when the site was started), Daily games + Badges (Nov 7), KPop arrives (Nov 9), KPop games + card shine (Nov 10), Profiles + 100 badges (Nov 11). Two draft news posts: Costume Party, KPop Series 2.
- KAYOU product sheets in posts are cut into one picture per section (info, promo, each rarity) in content/news/<post>-<part>.webp, stacked in the post, instead of one long image. Plain ![alt](src) images have no caption.
