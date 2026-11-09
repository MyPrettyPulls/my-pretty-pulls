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
- QR (both series): whole card rainbow holo + sparkles.
- A card effect's mask can now be a named file: ["shine","m2"] uses cards/<key>-m2.webp.
- Still to describe: every other KPop rarity (Kinsey is going through them).
