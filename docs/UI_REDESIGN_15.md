# FCBaz 1.5 — FC27-inspired UI system

This release moves the app from a generic Material companion look to a distinct FC27-inspired football item experience while keeping FCBaz original.

## Visual language
- Near-black club/stadium surfaces with acid-lime primary accent.
- Reduced rounded-corner usage; more angular item silhouettes and compact controls.
- Player items are the primary visual object, not generic list cards.
- Persian RTL chrome; player names and game terminology remain original where appropriate.

## Player items
- Large portrait area.
- OVR + position at the top.
- Club/nation line.
- PAC / SHO / PAS / DRI / DEF / PHY.
- Separate Console and PC prices; zero/missing value renders as `—`.
- Rarity-driven themes: Gold, Silver, Bronze, ICON, Hero, TOTW, Hall of FUT, Holographic/Pristine and generic Promo fallback.

## Collection
- Two-column FUT Collection grid.
- Fast rarity filters for Gold / ICON / Hero / TOTW / Hall / Holo / Silver / Bronze.
- Advanced filters remain available.
- Verified FC27 catalog status is visible without pretending unavailable price data exists.

## Market data
- Backend provider first when configured.
- Public FUTBIN price endpoint next.
- EA resource-ID lookup uses the public `fetchPriceInformation` route where available.
- No generated prices and no `0` presented as a real market value.
- FUT.GG is used as a public FC27 player/rarity/discovery reference and for live snapshot enrichment.

This is an inspired product language, not a pixel-for-pixel copy of EA assets or screens.
