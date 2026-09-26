# FCBaz

FCBaz یک اپلیکیشن Android مبتنی بر Flutter برای کاربران فارسی‌زبان EA SPORTS FC Ultimate Team است. هدف پروژه ارائه تجربه‌ای سریع، مینیمال و مستقل برای مشاهده بازیکنان، قیمت‌ها، تیم‌ساز، SBC، Evolutions و ابزارهای مرتبط است.

## اصول نسخه Production

- بدون ثبت‌نام، ورود یا حساب اجباری
- رابط کاربری کاملاً فارسی و RTL
- نام بازیکنان به زبان اصلی باقی می‌ماند
- نام Challengeها/SBCها به‌صورت انگلیسی + فارسی نمایش داده می‌شود هر زمان ترجمه معتبر در داده موجود باشد
- هیچ داده Demo، Fake یا Dataset نامرتبط به FC27 نمایش داده نمی‌شود
- اگر منبع واقعی در دسترس نباشد، Empty/Error State واقعی نمایش داده می‌شود
- Dark / Light / System Theme
- داده‌های محلی مثل Watchlist، My Club و تنظیمات روی خود دستگاه ذخیره می‌شوند

## وضعیت فعلی

- Flutter + Material 3
- فارسی و RTL به‌صورت پیش‌فرض
- Players + Search + Advanced Filters + Player Details
- Market + Prices + Watchlist
- Squad Builder + Chemistry
- SBC Center
- Evolutions
- Objectives
- My Club
- Meta
- Android CI + APK artifact
- Backend-ready via `FCBAZ_API_BASE_URL`

## سیاست داده واقعی

منبع اصلی Production باید Backend خود FCBaz باشد. Backend می‌تواند از Provider واقعی FC27 استفاده کند و در نبود Provider اختصاصی فقط از منبع عمومی زنده استفاده کند. هیچ Fallback مربوط به FIFA World Cup، فصل‌های قبلی یا داده ساختگی مجاز نیست.

اگر منبع یک قابلیت واقعی در دسترس نباشد، آن بخش باید خالی/غیرفعال بماند و نباید با داده فرضی پر شود.

## هم‌ترازی با FUTBIN / FUT.GG

FCBaz قرار نیست کپی ظاهری باشد؛ هدف، پوشش ابزارهای مهم این دسته با طراحی اختصاصی فارسی است. موارد هدف شامل این بخش‌هاست:

- Popular / New Players
- Trackers و Upgrades/Downgrades
- Roles و PlayStyles
- Player Game Performance
- Perfect Chemistry
- Squad Builder و Tactics
- Promo Squads
- Active SBCs
- Cheapest Players by Rating
- SBC Rating Combinations
- Best Value SBCs
- Evolutions / Evolution Players / Popular Evolutions / Evo Builder
- Objectives
- Market Movers و Price Tools
- News / Meta Guides

هر مورد فقط پس از اتصال به منبع واقعی وارد UI عمومی می‌شود.

## Build

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define=FCBAZ_API_BASE_URL=https://api.example.com
```

## Android package

`ir.fcbaz.app`

FCBaz پروژه‌ای مستقل است و وابستگی رسمی به EA SPORTS، FUTBIN یا FUT.GG ندارد.

## Production release

قبل از انتشار، `RELEASE_CHECKLIST.md` باید کامل اجرا شود. نسخه عمومی نباید شامل Debug build، داده Demo، داده فصل اشتباه یا Endpoint بدون منبع معتبر باشد.
