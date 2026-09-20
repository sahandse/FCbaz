# FCBaz

FCBaz یک اپلیکیشن Android مبتنی بر Flutter برای کاربران فارسی‌زبان EA SPORTS FC Ultimate Team است. هدف پروژه ارائه تجربه‌ای سریع، مینیمال و مستقل برای مشاهده بازیکنان، قیمت‌ها، تیم‌ساز، SBC، Evolutions و ابزارهای مرتبط است.

## وضعیت فعلی

- Flutter + Material 3
- فارسی و RTL به‌صورت پیش‌فرض
- Dark / Light Theme
- Players + Search + Filters + Player Details
- Market + Price History + Watchlist
- Backend-ready via `FCBAZ_API_BASE_URL`
- Android CI + APK artifact
- بدون جایگزینی داده ساختگی به‌جای داده واقعی FC27

## نقشه توسعه

1. Players / Search / Filters / Details
2. Market / Prices / History / Watchlist
3. Squad Builder / Chemistry / Squad Price
4. SBC Center
5. Evolutions / Evo Lab
6. SBC Solver / Cheapest Players
7. My Club / Price Alerts / Notifications
8. Meta / Best Players / News

## Build

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define=FCBAZ_API_BASE_URL=https://example.com
```

## Android package

`ir.fcbaz.app`

FCBaz یک پروژه مستقل است و وابستگی رسمی به FUTBIN یا EA SPORTS FC ندارد.


## Production release

FCBaz uses a strict production-only release flow. Debug/preview builds are not
intended for public distribution. Before publishing, follow
`RELEASE_CHECKLIST.md` and configure the real FC27 backend, Supabase account
sync, Firebase Cloud Messaging, and Android signing credentials.
