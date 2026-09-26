# FCBaz Data Source Audit — FC27

هدف: تمام داده‌های عمومی اپ باید واقعی، قابل ردیابی و متعلق به فصل FC27 باشند.

## منابع فعال

- EA Ratings API: بازیکنان پایه، OVR، پست، PAC/SHO/PAS/DRI/DEF/PHY، باشگاه، لیگ، کشور، تصویر
- FUT.GG Ratings/Rarities: کارت‌های special، Icon، Hero، TOTW، Promoها
- FUT.GG SBC: SBCهای فعال/منقضی و اطلاعات قابل استخراج عمومی
- FUT.GG Evolutions: Evolutionهای فعال، requirements/upgrades عمومی
- FUT.GG Objectives: Objectiveهای فعال
- FUT.GG What's New / What's Hot: feed محتوای جدید و محبوب
- FUTBIN public endpoint: فقط fallback قیمت/بازیکن در صورتی که منبع پاسخ دهد؛ 403 یا failure نباید باعث داده جعلی شود

## سیاست نمایش

- مقدار ناموجود = null/empty state؛ هرگز صفر جعلی یا متن ساختگی
- price history فقط در صورت وجود منبع واقعی
- source_url برای هر snapshot عمومی ضروری است
- فصل غیر FC27 ممنوع
- داده شخصی فقط local: My Club, Watchlist, Squads, Saved Evolutions

## Quality Gate

Release باید این موارد را پاس کند:

- حداقل 200 بازیکن معتبر FC27
- حداقل یک SBC، Evolution و Objective واقعی
- generated_at معتبر و تازه
- source_url معتبر برای تمام محتوای عمومی catalog
- عدم duplicate ID
- Analyze + tests + APK build سبز
