# FCBaz data-source audit

## Principles
- FC27-only data.
- No demo/fake/wrong-season fallback.
- Missing data stays unavailable.
- Personal data remains local.

## Players
Primary base-card source: the public FC27 Hub snapshot (`sahandse.github.io/FC27/data/fc27-players.json`), scraped from the EA SPORTS FC 27 official public ratings page (`https://www.ea.com/games/ea-sports-fc/ratings`). Every player links back to that page via `source_url`.
Card artwork: the Hub emits EA's official FC27 Ultimate Team item card for each rated player (`https://ratings-images-prod.pulse.ea.com/FC27/components/items/<playerId>_en-GB.webp`). The app renders that image as the whole card face, so rating, position, stats, name, nation, league and club come straight from EA. Promotional/special versions are not in EA's public item set and keep their own verified artwork.
Special cards/discovery: verified public FUT.GG pages and previously verified catalog entries; entries the hub does not publish are preserved instead of dropped.
The last valid catalog is persisted on-device for offline resilience.

## Prices
Source priority:
1. Configured FCBaz production backend when it returns a positive verified value.
2. FC27 Hub verified FUT.GG PlayStation/PC quotes (`fc27-prices.json`, status `verified`).
3. Public FUTBIN endpoints when available.
4. For official EA catalog IDs (`ea-<resourceId>`), try FUTBIN `fetchPriceInformation` using `playerresource` and platform PS/PC.
5. No value => unavailable (`—`).

A zero value is never treated as a real market price. 24h change and price history remain null/unavailable unless a real provider supplies them.

## FC27 Hub
`LiveFc27Catalog` now reads the published feeds directly from `https://sahandse.github.io/FC27/data/` and merges them into the app's validated in-memory catalog. It fetches the player, price, challenge/objective, evolution, news, card-art and portrait-index feeds independently, so an unavailable optional feed does not block player data. The live catalog is refreshed in-app, cached on-device, and falls back to the last valid cache/bundled catalog when offline. Player parsing accepts common portrait/card-image field variants; when no image URL is supplied, the existing player-image fallback remains in place.

The Hub publishes these FC27-only snapshots used as the primary feed:
`fc27-players.json` (official EA ratings page + official item-card artwork), `fc27-prices.json` (verified FUT.GG quotes), `fc27-challenges.json` (SBC + objectives), `fc27-evolutions.json`, `fc27-news.json`, `fc27-card-art.json` (fallback card-art hashes for versions EA does not publish) and `available-portraits.json`.
Cards with an FC26 label in the hub evolution feed are rejected.

## FUT.GG
Used as a public reference for FC27 player/card discovery, rarity pages, SBC, Evolutions, Objectives, What's Hot/What's New and public market/price-range references. The app does not invent current prices from price ranges.

## SBC / Evolution / Objectives
Public FUT.GG listing pages are snapshotted. Detail pages are enriched when accessible. Previous verified snapshot entries are preserved when scraping temporarily fails.

## Market integrity
- Popular players are not labelled market movers without movement data.
- Market feed rows require a positive real price.
- Cheapest-by-rating requires positive real prices.
- Price history requires a real history provider.

## Release quality gate
Live sync validates FC27 season, non-empty content sections, minimum player catalog size, valid IDs/source URLs and sufficient players with real core stats.
