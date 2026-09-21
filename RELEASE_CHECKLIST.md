# FCBaz Production Release Checklist

نسخهٔ عمومی فعلی: FUTBIN-style فارسی با دیتای رایگان واقعی و بدون حساب ابری.

## 1. Production data

- کاتالوگ `assets/data/players_fc26.json.gz` در بیلد هست و ریتینگ/اَتربیوت واقعی دارد.
- روی دستگاه واقعی smoke-test کنید: Home، Players، Search، Player Details، Market، Squad.
- تأیید کنید وقتی API عمومی قیمت در دسترس نیست، قیمت جعلی نشان داده نمی‌شود.
- اگر `FCBAZ_API_BASE_URL` ست می‌کنید، endpointها دادهٔ واقعی برگردانند (نه mock).

## 2. Optional live market

اگر می‌خواهید قیمت زنده پایدارتر باشد:

- یک backend با منبع واقعی بالا بیاورید و `FCBAZ_API_BASE_URL` را ست کنید.
- Secretهای provider فقط روی سرور بمانند.

حساب کاربری / Supabase / FCM برای نسخهٔ عمومی فعلی لازم نیست.

## 3. Android signing

Required GitHub Actions secrets (ترجیحاً یک keystore ثابت برای همهٔ آپدیت‌ها):

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

keystore را آفلاین بکاپ بگیرید. آپدیت‌های بعدی باید همان هویت امضا را داشته باشند.

> هشدار: تولید keystore تصادفی در هر run باعث می‌شود آپدیت روی نصب قبلی نصب نشود.

## 4. Privacy and local data

- فقط دادهٔ محلی FCBaz (Favorites، Watchlist، Squads، My Club، Backup) روی دستگاه است.
- Backup فقط preferenceهای متعلق به FCBaz را export کند.
- سیاست حریم خصوصی استور با نسخهٔ بدون حساب هم‌خوان باشد.

## 5. UI and data integrity

- RTL فارسی روی صفحه کوچک و بزرگ
- Dark / Light / System
- empty / loading / network-error
- fallback تصویر بازیکن
- هیچ placeholder جعلی برای بازیکن یا قیمت

## 6. Final release gate

فقط وقتی Sahand صریحاً ریلیز جدید بخواهد:

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. رفع خطاهای blocking
5. Build signed release APK
6. Build signed release AAB
7. ثبت SHA256
8. نصب روی دستگاه واقعی
9. Smoke-test: Home، Search، Players، Details، Market، Squad، My Club، Backup
10. Publish GitHub Release بعد از smoke test

APK دیباگ/پیش‌نمایش را به‌عنوان ریلیز عمومی منتشر نکنید.
