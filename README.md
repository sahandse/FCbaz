# FCBaz

FCBaz یک اپلیکیشن Android مبتنی بر Flutter است؛ همراه فارسی و RTL برای
بازیکنان EA SPORTS FC Ultimate Team با **دیتای رایگان و واقعی**.

## چه چیزی می‌دهد؟

- دیتابیس بازیکن با ریتینگ و اَتربیوت واقعی
- عکس کارت بازیکن از CDN عمومی
- جستجو، فیلتر پیشرفته، جزئیات بازیکن، مقایسه
- قیمت زنده سکه وقتی منبع بازار در دسترس باشد
- تیم‌ساز / Chemistry، Market، Watchlist، Meta، My Club
- بدون ثبت‌نام اجباری

## سیاست داده

- دادهٔ ساختگی به‌جای کارت/قیمت واقعی نمایش داده نمی‌شود.
- اگر قیمت زنده در دسترس نباشد، قیمت خالی می‌ماند (نه عدد جعلی).
- منبع اصلی دیتابیس: کاتالوگ community (`assets/data/players_fc26.json.gz`).
- Backend اختیاری (`FCBAZ_API_BASE_URL`) فقط اگر خودتان بالا آورده باشید.

## Build

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

پکیج: `ir.fcbaz.app`

FCBaz یک پروژه مستقل است و وابستگی رسمی به EA SPORTS FC ندارد.
