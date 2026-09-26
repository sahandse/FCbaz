# FCBaz Production Release Checklist

این چک‌لیست برای انتشار عمومی FCBaz اجباری است.

## 1. داده واقعی FC27

- `FCBAZ_API_BASE_URL` روی Backend واقعی Production تنظیم شده باشد.
- Provider واقعی FC27 فعال و تست شده باشد.
- Players، Prices، SBC، Evolutions، Objectives، Market، Promo Squads و News فقط از منبع واقعی پر شوند.
- هیچ Demo/Fake/Placeholder یا Dataset مربوط به فصل دیگر نمایش داده نشود.
- قیمت Console و PC جداگانه و درست نگاشت شوند.
- در صورت قطع منبع، Empty/Error State واقعی نمایش داده شود؛ نه داده جایگزین نامرتبط.

## 2. بدون ثبت‌نام

- اپ هیچ Login/Register اجباری نداشته باشد.
- Watchlist، My Club، Saved Squads، Saved Evolutions و تنظیمات به‌صورت Local روی دستگاه کار کنند.
- هیچ Token حساب کاربری یا Credential غیرضروری ذخیره نشود.
- حذف داده‌های محلی از تنظیمات قابل انجام باشد.

## 3. زبان و RTL

- کل رابط کاربری فارسی و RTL باشد.
- نام بازیکنان به زبان اصلی باقی بماند.
- نام Challengeها/SBCها در صورت وجود ترجمه معتبر، انگلیسی و فارسی کنار هم نمایش داده شود.
- اصطلاحات عمومی UI مانند Market، Meta، Objectives، Consumables و Watchlist به فارسی نمایش داده شوند.
- Overflow روی گوشی‌های کوچک و بزرگ تست شود.

## 4. Android signing

GitHub Actions secrets موردنیاز:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Keystore اصلی باید خارج از GitHub بکاپ امن داشته باشد و همه آپدیت‌های بعدی با همان کلید Sign شوند.

## 5. پایداری و شبکه

- Timeout و خطاهای شبکه مدیریت شوند.
- Retry دستی در Empty/Error State وجود داشته باشد.
- درخواست‌های عمومی Cache محدود و قابل Refresh داشته باشند.
- هیچ Credential یا Secret در اپ Flutter قرار نگیرد.
- Backend فقط Secretهای Provider را نگه دارد.

## 6. UI و کیفیت

- Dark، Light و System Theme تست شوند.
- Home، Players، Search، Player Details، Market، Squad Builder، SBC، Evolutions، Objectives، My Club و More روی دستگاه واقعی تست شوند.
- Loading، Empty و Error State برای همه صفحات وجود داشته باشد.
- تمام تصاویر Player/Card fallback مناسب داشته باشند.
- هیچ متن انگلیسی در UI باقی نماند مگر نام بازیکن، نام Challenge یا اصطلاحی که عمداً دو‌زبانه نمایش داده می‌شود.

## 7. تست

1. `flutter pub get`
2. `flutter analyze`
3. اجرای کامل `flutter test`
4. رفع همه خطاهای Release-blocking
5. Build امضاشده APK
6. Build امضاشده AAB
7. ثبت SHA256 فایل‌ها
8. نصب APK Release روی گوشی واقعی
9. Smoke Test کامل صفحات اصلی و جریان‌های ذخیره محلی
10. تست با Backend قطع و وصل برای اطمینان از عدم نمایش داده Fake

## 8. Release gate

فقط زمانی Release عمومی ساخته شود که Sahand صراحتاً درخواست انتشار نسخه جدید بدهد و همه مراحل بالا پاس شده باشند.

هیچ Debug/Preview APK و هیچ نسخه دارای داده Demo نباید به‌عنوان Release عمومی منتشر شود.
