# FCBaz Backend

Backend production proxy for real FC27 data.

## Data policy

- Never fabricates player, price, SBC or Evolution data.
- Returns HTTP 503 when the provider is not configured.
- Keeps the provider key server-side; the Android APK only receives the FCBaz API base URL.
- Responses include the source where applicable.

## Environment

Copy `.env.example` values into your hosting environment:

- `PARSE_API_KEY` — server-only API key.
- `PARSE_SCRAPER_ID` — current FC data API scraper id.
- `PORT` — defaults to 8787.
- `CACHE_TTL_SECONDS` — defaults to 60.

## Run

Node.js 20+:

```bash
cd backend
PARSE_API_KEY=your_key npm start
```

Flutter release should point to this backend:

```bash
flutter build appbundle --release --dart-define=FCBAZ_API_BASE_URL=https://api.example.com
```

Do not place `PARSE_API_KEY` in Flutter, GitHub source, or a public APK.
