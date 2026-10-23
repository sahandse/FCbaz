# FCBaz — FIFA-style player cards

Date: 2026-10-23
Status: approved (design presented and approved by the user in chat)

## Goal

Make every player card in FCBaz look like an EA FC / FUT Ultimate Team card instead of the
current custom "stats panel" card, for all 19,831 catalog players, without downloading
official card art.

## Approach

Redraw the card in Flutter (vector shapes + gradients + typography). No external card
images, no data-model changes.

- `PlayerItemVisual` stays the single card surface, so players list, search, home, market,
  club, draft, details and "other versions" all get the new look at once.
- The real FUT.GG card render (`cardImageUrl`) is not used as the card face because it only
  exists for 45% of players and would make the lists visually inconsistent.

## Anatomy

1. Card body: clipped FUT-like silhouette (chamfered top corners, rounded bottom), thin
   inner frame, soft outer shadow.
2. Background: rarity gradient, diagonal shine sweep, low-alpha dot/stripe pattern and a
   large faint rarity watermark.
3. Top-left: rating (large, italic, heavy) with position underneath and a compact
   PlayStyle+ badge when the player has one.
4. Top-right: three stacked badges — nation flag, league crest, club crest.
5. Center-right: player cutout from `imageUrl`, bottom aligned, with a contact shadow;
   silhouette icon when the portrait is missing (87% of players).
6. Lower third: uppercase italic name, thin divider, six stats in two rows of three
   (GK: DIV/HAN/KIC/REF/SPD/POS), and the version/rarity label.
7. Bottom: PS/PC price pills, kept because the app and existing tests depend on them.
8. Favorite button stays as the overlay in `PlayerCard`, top-right, above the badges column.

## Themes

| Rarity | Look |
| --- | --- |
| Gold | warm gold gradient, dark ink |
| Silver | cool silver gradient, dark ink |
| Bronze | copper-brown gradient, dark ink |
| ICON | cream/gold, dark ink |
| Hero | purple-red, light ink |
| TOTW | black-gold, light ink |
| Hall of FUT | teal, light ink |
| Holo | blue-purple-teal, light ink |
| default | dark green (current brand), light ink |

## Typography

Bundle Barlow Condensed (OFL) ExtraBold Italic + SemiBold Italic in `assets/fonts/` and use
it only inside the card (rating, position, name, stats, prices). Persian UI text keeps the
app font. Add the OFL license file next to the fonts.

## Data limitations

- Club and league logos are not in the catalog: render monogram crests (initials on a themed
  disc) instead of official crests.
- Nation flags come from a name → ISO-3166 map; unknown nations fall back to a globe icon.
- Portraits exist for 2,576 players; everyone else gets a silhouette.

## Code layout

- `lib/features/players/presentation/player_item_visual.dart` — layout, prices, portrait.
- `lib/features/players/presentation/card/player_card_theme.dart` — rarity themes.
- `lib/features/players/presentation/card/player_card_painters.dart` — clipper, pattern,
  shine, frame painters.
- `lib/features/players/presentation/card/player_card_badges.dart` — flag/crest/league
  badges.
- `lib/features/players/presentation/card/nation_flags.dart` — nation name → flag map.

Public widget API (`PlayerItemVisual(player, showPrices, compact)`) is unchanged.

## Existing constraints that must keep passing

- `test/ui_redesign_15_test.dart` scans `player_item_visual.dart` for `label: 'PS'`,
  `label: 'PC'`, `if (value <= 0) return '—'` and `BoxFit.contain`.
- `test/core_surfaces_18_test.dart` and `test/phase14_persian_ui_test.dart` scan the details
  and club screens for `PlayerItemVisual` and section labels — those screens are untouched.
- `players_screen.dart` rarity chip tokens stay as-is.

## Testing

- New widget tests: gold outfield card, GK stat labels, missing portrait, long name, and
  compact/non-compact sizes at widths 145–220 with no overflow.
- Theme mapping test (gold/silver/bronze/ICON choose different gradients).
- `flutter analyze` + full `flutter test`, then the GitHub `Android release` workflow on the
  feature branch, then merge to `main`.
