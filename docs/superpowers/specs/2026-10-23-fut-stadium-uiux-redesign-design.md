# FCBaz — FUT Stadium full UI/UX redesign

Date: 2026-10-23
Status: approved in chat (direction + new navigation), spec ready for review

## Goal

Redesign the whole FCBaz app around one coherent visual and interaction system that matches
the FUT-style player cards already shipped in v2.2.0. This is a presentation-layer redesign:
catalog data, repositories, chemistry/squad engines, pricing sources and API contracts stay
unchanged.

## Non-goals

- No new data sources, no fabricated data, no backend changes.
- No changes to squad, chemistry, evolution projection or price logic.
- No new product features beyond navigation/search consolidation and UI-level actions
  (compare selection, list/grid density, saved filters, bulk club selection).
- No iOS-only work.

## Design principles

1. **Cards are the hero.** Only one stadium-lit hero per screen; everything else is calm,
   flat and data-first so player cards stay the brightest element.
2. **Game language, human copy.** FUT energy in shape, type and color; Persian-first copy
   for everything except in-game terms (OVR, PAC, SBC, Evolution, PlayStyle).
3. **One system.** A single set of tokens and components replaces the current mix of
   one-off gradients, hardcoded dark colors and radii between 7 and 18.
4. **Truthful data.** Loading, empty, offline and error states are explicit; every data
   surface can show its source and last update.
5. **Built for thumbs.** 44×44 minimum targets, 12px minimum Persian text, AA contrast,
   RTL-safe icons and motion that can be skipped.

## Visual language — "FUT Stadium"

### Dark palette (default)

| Token | Value | Use |
| --- | --- | --- |
| canvas | `#050706` | app background |
| surface | `#0B100C` | cards, sheets |
| surfaceRaised | `#121A13` | inputs, chips, hover |
| line | `#26352A` | hairline borders |
| lineStrong | `#354839` | focused/dividers |
| text | `#F2F6EF` | primary text |
| textMuted | `#A7B4A9` | secondary text |
| primary | `#C8FF42` | actions, active tab, OVR |
| onPrimary | `#10140C` | text on lime |
| secondary | `#7DEBFF` | market/data accents |
| warning | `#FFD76A` | deadlines, warnings |
| danger | `#FF5F72` | live, negative deltas |
| success | `#6EE7A0` | positive deltas |

Rarity gradients remain owned by `PlayerCardTheme`; UI tokens never duplicate them.

### Light palette

| Token | Value |
| --- | --- |
| canvas | `#F2F5EE` |
| surface | `#FFFFFF` |
| surfaceRaised | `#E8EEE2` |
| line | `#D3DBC9` |
| lineStrong | `#B9C6B0` |
| text | `#121711` |
| textMuted | `#5C6B5A` |
| primary | `#486900` |
| onPrimary | `#FFFFFF` |
| secondary | `#006879` |
| warning | `#8A5B00` |
| danger | `#B3263A` |
| success | `#1F6B3A` |

Rule: feature screens may not use raw `Color(0x...)` for surfaces, text or borders. All
colors come from the theme extension; only shadows and image overlays may be raw black/white
with alpha.

### Typography

- **Vazirmatn** (SIL OFL, weights 400/500/700/800) for all Persian UI text.
- **Barlow Condensed** (already bundled, 600/800 italic) for Latin kickers, OVR/stat
  numerals and Latin labels.
- Persian line height 1.7 for body, 1.35 for titles; Latin condensed line height .95.
- Scale: display 32, h1 26, h2 20, h3 16, body 14, bodySmall 12.5, caption 11.
  Persian text never renders below 11px; no 8–9px Persian labels remain.
- Latin uppercase is only a kicker (10px, tracking 1.2), never the primary heading.
- Tabular figures for prices and stats.

### Geometry, elevation, motion

- 4pt spacing scale: 4, 8, 12, 16, 20, 24, 32; page padding 16; section gap 24.
- Radii: 8 (small), 12 (card/input), 18 (hero/sheet), 999 (pills).
- Elevation is a 1px hairline plus at most one soft shadow; heroes may use
  `0 18 40 -24` shadow and a stadium-light gradient. Content cards stay flat.
- Motion: standard 200ms `easeOutCubic`; fast 140ms; shared card→details 320ms.
  No looping glow or shimmer except skeletons.
- Haptics: favorite, filter apply, compare select, tab change (light impact).

## Information architecture

### New bottom navigation (5 tabs)

| Index | Tab | Content |
| --- | --- | --- |
| 0 | خانه | `HomeDashboardScreen` (rewritten) |
| 1 | کارت‌ها | merged Players + Search + saved filters + compare |
| 2 | باشگاه | My Club inventory/value/duplicates (body extracted) |
| 3 | تیم | `SquadScreenPro` (re-skinned) |
| 4 | بیشتر | all tools + profile + settings |

Search is no longer a tab. A search action in the top app bar is available on every tab and
selects tab 1 with the search field focused.

### Persisted tab migration

`AppNavigationRepository` stores an integer 0–4. On load:

- 0 → 0 (home)
- 1 → 1 (players/cards)
- 2 (old search) → 1 (cards)
- 3 → 3 (squad)
- 4 → 4 (more)

Out-of-range values → 0. No other state is migrated.

### Removals

- Search tab (content is folded into Cards).
- Duplicate "سبک‌ها و نقش‌ها" entry in More (keep one).
- Duplicate profile hero + "پروفایل محلی" tile in More (keep one profile entry).
- Home "LIVE HUB" six-tile grid (replaced by a focused quick-action grid of four).
- English uppercase section headings as primary headings; they become Latin kickers.

## Component system

New shared widgets live in `lib/src/ui/`:

| Component | Responsibility |
| --- | --- |
| `FcbazTopBar` | brand mark, Persian page title, optional search/notification actions |
| `StadiumHero` | eyebrow, Persian title, metric + delta, max two actions; one per screen |
| `SectionHeader` | Latin kicker + Persian title + optional "همه" action |
| `FilterBar` | search field, filter button with badge, sort menu, grid/list toggle |
| `PlayerTile` | wraps `PlayerCard`; grid and list variants; compare checkbox; long-press actions |
| `CompareBar` | floating bottom bar with selected count and compare CTA |
| `StatPill` / `PriceDelta` | compact stat and signed price movement |
| `DeadlineChip` | relative deadline with warning color |
| `ProgressRing` | objective/SBC/evolution completion |
| `ChallengeCard` | shared SBC / Evolution / Objective card |
| `EmptyState` / `ErrorState` | illustrated-free, actionable states |
| `Skeleton` | layout-matched loading placeholders |
| `OfflineBanner` | retryable connectivity notice |
| `SourceBadge` | data source + last-updated label |
| `SegmentedTabs` | scrollable Persian tabs used in details/club/market |

Existing `PlayerItemVisual`, `PlayerCard`, `PlayerCardTheme` stay the card foundation and are
reused unchanged except for optional list-variant sizing.

## Screen specifications

### Home (خانه)

1. Top bar: brand, search action, notification badge.
2. Greeting row with Jalali date.
3. `StadiumHero`: "باشگاهت، زنده." with club value, weekly delta and two actions
   (کارت‌ها، باشگاه). If local club is empty, show a setup CTA instead of fake metrics.
4. "امروز" rail: deadline items (SBC, Evolution, Objective) sorted by remaining time,
   each with `DeadlineChip`, progress and tap-through.
5. "بازار" list: up to five market movers with price, `PriceDelta` and tap-through.
6. "کارت‌های داغ" rail: existing trending players, 160px cards.
7. Quick actions: SBC, Evolution, اهداف, بازار (2×2).
8. `SourceBadge` footer for catalog freshness; pull-to-refresh keeps current behavior.

### Cards (کارت‌ها)

1. Header strip with title, result count and saved-view entry.
2. Sticky `FilterBar` (search + filter sheet + sort + 2/3-column/list toggle).
3. Rarity chips and active filter chips as today, restyled.
4. Compare mode: select up to four cards, floating `CompareBar`, opens
   `PlayerCompareScreen`.
5. Discovery state when the query is empty: trending players and recent/saved searches
   (reuse existing search discovery data), favorites rail.
6. Results grid/list; lazy sliver grid keeps current catalog performance; debounce search
   250ms.
7. Explicit loading skeleton, empty, error and offline states.
8. Global search requests focus this field via a `ValueNotifier<int>` owned by `MainShell`.

### Player details

1. Sliver header: card rendered at 200px over a rarity-tinted backdrop, back/share/favorite.
2. Name, rating, position, club/league/nation and `SourceBadge`.
3. Sticky `SegmentedTabs`: نمای کلی / آمار / استایل‌ها / بازار / یادداشت.
4. Overview: PS/PC prices, key stats with bars (value/99), chemistry suggestions, roles,
   other versions rail.
5. Market: existing `PlayerMarketPanel` and chart, plus alert CTA.
6. Review: existing local review flow.
7. Bottom action bar: "افزودن به باشگاه" and "مقایسه".
8. Shared-element card transition from the grid where feasible.

### Club (باشگاه)

1. Hero: item count, total value, duplicate count; no fake values.
2. Tabs: همه / دوبل‌ها / علاقه‌مندی‌ها.
3. Filters and grid of `PlayerTile`; bulk select for "افزودن به تیم" and value summary.
4. Preserve `MyClubService` and all current actions; extract the body into an embeddable
   `ClubView` and keep `MyClubScreen` as a route wrapper.

### Squad (تیم)

1. Header: formation pill, chemistry ring, squad rating, budget/value.
2. Pitch-first canvas with the existing drag/tap interactions and engine.
3. Slot tap opens a search bottom sheet; long-press opens swap/remove actions.
4. Bottom bar: ذخیره / تحلیل. Insights panel restyled.
5. No chemistry, formation or persistence logic changes.

### Market (بازار)

1. Tabs: واچ‌لیست / حرکت‌کنندگان / هشدارها.
2. Watchlist rows with delta and target price; movers with chart preview.
3. Alert creation sheet; links to market tools.
4. All repositories and alert services unchanged.

### SBC / Evolutions / Objectives

- Shared `ChallengeCard` with type chip, deadline, `ProgressRing`, reward and requirement
  count; detail screens keep existing requirement/eligibility logic.
- Filters become scrollable Persian chips; empty/expired states are explicit.

### More & Settings (بیشتر)

- Searchable grouped list: ابزارها، داده‌های من، راهنما، تنظیمات.
- One profile entry, one reference entry, no duplicated cards.
- Settings keeps theme mode, accent color, market refresh, alerts and backup; restyled with
  the new tokens. Light theme must be fully usable.

### News (اخبار)

- Article cards with cover, source, date and reading time; detail uses the same top bar.

## States, accessibility and RTL

- Every data screen implements: skeleton → content / empty / error / offline, with a Persian
  message and one retry action. Technical errors are hidden behind "جزئیات".
- Minimum touch target 44×44; icon buttons get at least 8px padding when visually smaller.
- Persian text ≥11px; muted text pairs with AA contrast in both themes.
- Directional icons (chevrons, arrows) mirror in RTL; numbers, prices and Latin names stay
  LTR via `textDirection: TextDirection.ltr`.
- Semantics labels for cards (`name rating position price`), favorite and compare actions.
- Motion respects `MediaQuery.disableAnimations`.

## Technical plan

- Add `FcbazPalette` as a `ThemeExtension` in `lib/src/theme/fcbaz_theme.dart`; keep
  `FCBazTheme.dark()/light()` signatures for settings and tests.
- Add Vazirmatn assets and declare them in `pubspec.yaml` with their OFL license.
- Build `lib/src/ui/` components; migrate screens feature by feature.
- `MainShell`: new destinations, brand top bar, search controller, tab migration, new
  `ClubView`; keep IndexedStack and PopScope behavior.
- `CardsScreen`: new screen composing search discovery + advanced filters + player grid;
  reuse `PlayerRepository.advanced` and existing search history/saved filters.
- `HomeDashboardScreen`, `PlayerDetailsScreen`, `MoreScreen`, `MyClubScreen`,
  `MarketScreen`, `SbcScreen`, `EvolutionsScreen`, `ObjectivesScreen`, `NewsScreen`,
  `SettingsScreen` are restyled without changing their repositories.
- No catalog, API, squad or notification service changes.

## Testing strategy

- Keep the existing suite green (94 tests at v2.2.0); update source-token tests when paths
  intentionally change.
- New widget tests: 5-tab shell + labels, tab migration 2→1, global search focuses Cards,
  saved filters, grid/list toggle, compare selection limit, details tabs, club tabs,
  deadline ordering, light/dark theme tokens.
- Layout tests at 320/360/412 logical px for Home, Cards, Details, Club, Squad header: no
  overflow, 44px targets, no Persian text below 11px.
- Render preview tests to `build/previews/*.png` for Home, Cards and Details in both themes
  for visual review (not committed).
- `flutter analyze` clean (errors/warnings), `flutter test` green, PR CI and
  `android-release.yml` on the branch, then production release 2.3.0.

## Rollout

| Phase | Scope | PR |
| --- | --- | --- |
| 0 | this spec | branch `feat/uiux-fut-stadium` |
| 1 | tokens, Vazirmatn, top bar, navigation + migration, shared components, light-mode cleanup | PR A |
| 2 | Home, Cards (merged search), Player details | PR B |
| 3 | Club, Squad, Market | PR C |
| 4 | SBC, Evolutions, Objectives, News, More, Settings + accessibility/QA | PR D |
| release | version 2.3.0, signed APK/AAB via production workflow | after PR D |

Each phase ships independently, keeps the app usable, and is verified on GitHub Actions.

## Risks and mitigations

- **Auto-refresh commits** (`data: refresh verified FC27 live catalog`) land on main every
  few hours; rebase before push and never touch `assets/data/` or `data/live/`.
- **Old tests assert copy/layout**; update assertions with each phase instead of weakening
  them.
- **Search tab removal** could break deep links or saved tab state; the repository migration
  and global search action cover both, and tests pin the behavior.
- **Light mode has hardcoded dark colors today**; phase 1 sweeps surfaces before flagship
  screens so later screens inherit correct themes.
- **Squad screen is the most complex**; phase 3 only restyles chrome and keeps engine code
  untouched.
- **Font size** adds roughly 1–2 MB; acceptable for the readability gain.

## Acceptance criteria

- Five tabs exactly: خانه، کارت‌ها، باشگاه، تیم، بیشتر; no standalone search tab.
- Global search from any tab opens Cards with a focused query field.
- Every screen uses the new tokens and typography; no Persian text below 11px; 44px targets.
- Light and dark themes both usable; no hardcoded dark surface colors in migrated screens.
- No duplicated More entries.
- Existing functionality and data behavior preserved; all tests green; analyze clean.
- Signed APK and AAB build on GitHub; release 2.3.0 published.
