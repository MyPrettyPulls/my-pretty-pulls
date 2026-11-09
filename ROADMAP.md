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
- Winx Costume Party (WXCP01, Nov 11 2026): 45 placeholder cards (CPCARDS) in KAYOU's 8 rarities (ZR, GP, AR, UGR, UR 6 each; SSR 3; FR, SR 6 each).
  When KAYOU posts the cards: replace "Card N" names, real numbers, pictures; GP full name still unknown.
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
