# FCBaz 1.5 price sources

Priority for a player price request:

1. FCBaz production backend, when configured and returning a positive verified price.
2. FUTBIN public player-price endpoint for compatible FUTBIN card IDs.
3. FUTBIN public `fetchPriceInformation` with EA `playerresource` for catalog IDs in `ea-<resourceId>` form.
4. Public snapshot price already attached to a verified catalog item.
5. Unavailable (`—`).

Rules:
- `0` is not a price.
- Price history is never synthesized.
- 24h change is never synthesized.
- Console and PC are displayed separately.
- FUT.GG public pages remain a reference for FC27 cards, discovery and public price-range context; price ranges are not converted into a fake current market price.
