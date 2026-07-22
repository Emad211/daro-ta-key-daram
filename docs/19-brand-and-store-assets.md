# 19 — هویت بصری و دارایی‌های انتشار

## نشان اصلی

نشان «دارو تا کی دارم؟» از یک کپسول سفید و یک قوس زمان/موجودی فیروزه‌ای روی زمینه سبزآبی تیره تشکیل شده است. مفهوم آن ثبت دارو و پیگیری زمان باقی‌مانده است؛ نشان شامل متن، عدد دوز، صلیب پزشکی یا ادعای درمانی نیست.

منبع اصلی قابل بازتولید در `store/assets/app-icon-source.svg` نگهداری می‌شود. نسخه ۵۱۲ پیکسلی مناسب بارگذاری در پنل‌های فروشگاه در `store/assets/app-icon-512.png` قرار دارد. پنل هر فروشگاه باید هنگام بارگذاری برای اندازه و قالب موردنیاز همان روز دوباره بررسی شود.

## Android launcher icon

- برای Android 8 به بعد foreground و background مستقل adaptive icon ثبت شده‌اند.
- عناصر اصلی داخل safe zone مرکزی نگه داشته شده‌اند تا در ماسک‌های دایره، squircle و rounded-square بریده نشوند.
- برای Android 13 به بعد لایه monochrome وجود دارد تا themed icon کار کند.
- برای دستگاه‌های قدیمی‌تر از adaptive icon، یک vector launcher مستقل وجود دارد.
- `roundIcon` به‌صورت صریح در Manifest ثبت شده است.
- bitmapهای پیش‌فرض Flutter از منابع launcher حذف شده‌اند.

## Splash و اعلان

صفحه شروع Android از همان خانواده بصری استفاده می‌کند و در Android 12+ با SplashScreen سیستم هماهنگ است. آیکن اعلان یک silhouette تک‌رنگ و بدون پس‌زمینه است؛ رنگ و پس‌زمینه launcher در status bar استفاده نمی‌شوند.

## قواعد انتشار

1. فایل source باید بدون متن و بدون font dependency باقی بماند.
2. تغییر نشان باید هم‌زمان launcher، adaptive، monochrome، splash، notification و store asset را بررسی کند.
3. تصاویر فروشگاه نباید حاوی اطلاعات واقعی دارویی یا بیمار باشند.
4. screenshot نهایی فقط از build امضاشده و fixture ساختگیِ مشخص گرفته شود.
5. CI وجود منابع و حذف icon پیش‌فرض Flutter را بررسی می‌کند.
6. تغییر رنگ یا فرم نشان بدون بررسی خوانایی در اندازه ۴۸ پیکسل و themed icon ادغام نشود.

## وضعیت دارایی‌ها

- نشان launcher: آماده و متصل به Android
- adaptive icon: آماده
- themed/monochrome icon: آماده
- round icon: آماده
- notification small icon: آماده
- branded splash: آماده
- store icon 512×512: آماده
- screenshotهای نهایی بازار: نیازمند capture از release build روی دستگاه یا emulator تأییدشده
- feature graphic و تصاویر تبلیغاتی: نیازمند تأیید نهایی ناشر و الزامات روز پنل بازار
