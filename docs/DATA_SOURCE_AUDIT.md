# FCBaz data-source audit

## Principles
- FC27-only data.
- No demo/fake/wrong-season fallback.
- Missing data stays unavailable.
- Personal data remains local.

## Players
Primary base-card source: official EA ratings endpoint (`drop-api.ea.com/rating/ea-sports-fc`).
Special cards/discovery: verified public FUT.GG pages and the project live catalog.
The last valid catalog is persisted on-device for offline resilience.

## Prices
Source priority:
1. Configured FCBaz production backend when it returns a positive verified value.
2. Public FUTBIN endpoints when available.
3. For official EA catalog IDs (`ea-<resourceId>`), try FUTBIN `fetchPriceInformation` using `playerresource` and platform PS/PC.
4. No value => unavailable (`—`).

A zero value is never treated as a real market price. 24h change and price history remain null/unavailable unless a real provider supplies them.

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
