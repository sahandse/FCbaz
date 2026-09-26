# FCBaz Backend

Backend production proxy for real FC27 data.

## Architecture policy

FCBaz has **no registration, login or online account system**.

- No Supabase Auth.
- No Firebase user/device registration.
- No bearer-token API routes.
- No cloud account sync.
- Watchlist, My Club, Squads, local profile and Objective progress stay on the Android device.
- Backend endpoints are read-only public data endpoints for FC27 content and prices.

## Data policy

- Never fabricates player, price, SBC, Evolution or Objective data.
- Uses the configured real-data provider where available.
- Falls back only to supported public FUTBIN data for player/market information.
- Unsupported datasets return empty/unavailable data rather than demo content.
- Provider keys remain server-side; the Android APK only receives the FCBaz API base URL.

## Environment

- `PARSE_API_KEY` — optional server-only real-data provider key.
- `PARSE_SCRAPER_ID` — provider scraper id.
- `PORT` — defaults to 8787.
- `CACHE_TTL_SECONDS` — defaults to 60.
- `GITHUB_RELEASE_REPO` — optional release lookup repository.

## Run

Node.js 20+:

```bash
cd backend
npm start
```

Flutter release should point to this backend:

```bash
flutter build appbundle --release --dart-define=FCBAZ_API_BASE_URL=https://api.example.com
```

Do not place `PARSE_API_KEY` in Flutter, GitHub source, or a public APK.
