# FCBaz

FCBaz is a Persian-first EA SPORTS FC 27 Ultimate Team companion for Android, built with Flutter.

## Product principles

- No registration or login.
- Personal data such as Watchlist, My Club, saved squads and saved Evolutions stays local on the device.
- Public FC27 data only; no fake/demo/wrong-season fallback.
- Missing market or content data is shown as unavailable instead of being fabricated.
- Persian RTL application chrome; player names remain original.

## Current data strategy

- Base FC27 player snapshot: the owner's public FC27 Hub (`sahandse.github.io/FC27`), scraped from EA SPORTS FC 27's official public ratings page (`ea.com/games/ea-sports-fc/ratings`, 19,789 rated players).
- Player cards: EA's official FC27 item-card artwork (`ratings-images-prod.pulse.ea.com/FC27/components/items/<playerId>_en-GB.webp`), used as the complete card face instead of re-drawn approximations.
- Prices: FC27 Hub's verified FUT.GG PlayStation/PC quotes, matched to EA player IDs through FUT.GG's FC27 sitemap; unmatched or ambiguous cards stay unavailable rather than borrowing another version's price.
- Special cards, SBC, Evolutions, Objectives and discovery: verified public FUT.GG sources, mirrored by FC27 Hub.
- Optional production backend can override public sources for richer verified market/history data.
- Last known valid live catalog is cached locally for offline resilience.

## UI direction — 1.5

FCBaz 1.5 uses an original FC27-inspired visual system: dark club/stadium surfaces, acid-lime accents, compact floating navigation and rarity-driven FUT-style player item cards. Gold, Silver, Bronze, ICON, Hero, TOTW, Hall of FUT and Holographic families receive distinct visual treatments without copying EA assets pixel-for-pixel.

## Main features

- FC27 player collection and advanced filters
- Player details and comparison
- Console / PC market prices where a real public source is available
- Watchlist and Android local price alerts
- My Club local inventory
- Squad Builder, chemistry, formations and tactics
- Console squad screenshot import using on-device OCR, player-name matching, formation-slot estimation, and a confirmation step before replacing the current XI
- SBC Center and rating combinations
- Evolutions and eligibility tools
- Objectives
- Meta/Trending discovery
- Android local notifications and background price checks
- Data Health screen and live-catalog status

See `docs/FUTBIN_PARITY.md`, `docs/DATA_SOURCE_AUDIT.md` and `docs/UI_REDESIGN_15.md` for implementation policy and coverage.
