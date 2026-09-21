# FCBaz

FCBaz یک اپلیکیشن Android مبتنی بر Flutter است؛ تجربهٔ فارسی و RTL شبیه
[FUTBIN](https://www.futbin.com)، با **دیتای رایگان و واقعی** برای کاربران
EA SPORTS FC Ultimate Team.

## چه چیزی می‌دهد؟

- دیتابیس بازیکن با ریتینگ و اَتربیوت واقعی (کاتالوگ رایگان FC26 داخل اپ)
- جستجو، فیلتر پیشرفته، جزئیات بازیکن، مقایسه
- قیمت زنده سکه وقتی endpoint عمومی بازار در دسترس باشد
- تیم‌ساز / Chemistry، Market، Watchlist، Meta، My Club
- بدون ثبت‌نام اجباری، بدون حساب ابری در نسخهٔ عمومی

## سیاست داده

- دادهٔ ساختگی به‌جای کارت/قیمت واقعی نمایش داده نمی‌شود.
- اگر قیمت زنده در دسترس نباشد، قیمت خالی می‌ماند (نه عدد جعلی).
- منبع اصلی دیتابیس رایگان: کاتالوگ community مبتنی بر دادهٔ Sofifa/FC26
  (`assets/data/players_fc26.json.gz`).
- منبع اختیاری قیمت/ترند زنده: API عمومی FUTBIN وقتی از دستگاه قابل دسترس باشد.
- Backend اختیاری (`FCBAZ_API_BASE_URL`) فقط اگر خودتان بالا آورده باشید.

## وضعیت فنی

- Flutter + Material 3
- فارسی و RTL به‌صورت پیش‌فرض
- Dark / Light Theme
- Android CI + APK artifact
- پکیج: `ir.fcbaz.app`

## Build

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

اختیاری با backend خودتان:

```bash
flutter build apk --release \
  --dart-define=FCBAZ_API_BASE_URL=https://your-api.example.com
```

## Production release

قبل از انتشار عمومی، `RELEASE_CHECKLIST.md` را دنبال کنید.
نسخهٔ عمومی فعلی روی دادهٔ رایگان واقعی و بدون حساب کاربری طراحی شده است.

FCBaz یک پروژه مستقل است و وابستگی رسمی به FUTBIN یا EA SPORTS FC ندارد.
