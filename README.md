# دارو تا کی دارم؟

یک اپلیکیشن اندرویدی فارسی، آفلاین‌محور و رایگان برای تخمین زمان پایان موجودی دارو و یادآوری خرید مجدد.

> این برنامه ابزار ثبت و یادآوری است و تشخیص پزشکی، تجویز دارو یا تعیین دوز انجام نمی‌دهد.

## وضعیت پروژه

**مرحله فعلی: Phase 3 — اعلان محلی Android و آماده‌سازی تست دستگاه**

موارد اصلی پیاده‌سازی‌شده:

- موتور محاسبه موجودی و تاریخ تقریبی اتمام
- داشبورد و فرم‌های فارسی RTL
- Drift/SQLite با transaction و schema snapshot
- جزئیات دارو، خرید مجدد، اصلاح موجودی، timeline و آرشیو
- parser اعداد فارسی و عربی
- stable notification ID و payload نسخه‌دار
- اعلان low-stock/depleted با زمان‌بندی inexact
- permission flow آگاهانه Android 13+
- deep link اعلان به جزئیات دارو
- حفظ schedule پس از reboot و app update
- fallback timezone و failure isolation
- Android project متعهدشده با application ID `ir.emadkarimi.darutakey`
- CI شامل code generation، schema parity، format، analyze، test و build APK

## مدل کسب‌وکار

تمام قابلیت‌های اصلی رایگان می‌مانند و درآمد محصول فقط از تبلیغات داخل اپ تأمین می‌شود. تبلیغ نباید مانع دسترسی به اطلاعات ضروری دارویی شود. سیاست دقیق در [`docs/03-monetization.md`](docs/03-monetization.md) ثبت شده است.

## پشته فنی

- Flutter 3.44.x / Dart 3.12.x
- Riverpod و go_router
- Drift/SQLite
- flutter_local_notifications 22.0.1
- flutter_timezone 5.1.0 و timezone 0.11.1
- Android compile/target SDK 36 و Java/Kotlin 17
- معماری Offline-first و Android-first

## اجرای پروژه

Android project داخل repository ثبت شده است:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

اعتبارسنجی کامل و ساخت APK Debug:

```bash
bash tool/bootstrap.sh
```

خروجی APK محلی:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

CI نیز همین APK را با نام `daro-ta-key-debug-apk` برای هفت روز نگه می‌دارد.

## اعلان‌ها

- درخواست permission فقط با لمس دکمه یادآوری انجام می‌شود.
- رد permission مانع استفاده از اپ نیست.
- exact-alarm permission استفاده نمی‌شود.
- اعلان‌ها با ID ثابت جایگزین می‌شوند و روی هم انباشته نمی‌شوند.
- restock/correction اعلان را reschedule می‌کند.
- archive/delete اعلان را cancel می‌کند.
- notification tap داروی مربوط را باز می‌کند.

طراحی و چک‌لیست تست دستگاه: [`docs/07-notifications.md`](docs/07-notifications.md)

## مدیریت schema دیتابیس

نسخه فعلی schema در `drift_schemas/drift_schema_v1.json` نگهداری می‌شود. پس از هر تغییر عمدی schema و افزایش `schemaVersion`:

```bash
bash tool/export_drift_schema.sh
```

CI اختلاف میان schema کد و snapshot ثبت‌شده را رد می‌کند.

## ساختار اصلی

```text
lib/
  app/
  core/
    database/
    input/
    theme/
    widgets/
  features/
    ads/
    medication_inventory/
    notifications/
android/
drift_schemas/
test/
```

## قواعد محصول

1. هیچ داده دارویی در MVP به سرور ارسال نمی‌شود.
2. هیچ تبلیغی روی فرم، lifecycle، permission یا notification flow نمایش داده نمی‌شود.
3. اپ دوز مصرف را پیشنهاد یا تغییر نمی‌دهد.
4. قابلیت‌های اصلی پشت تبلیغ قفل نمی‌شوند.
5. notification failure موجب rollback داده دارویی نمی‌شود.
6. تغییر schema بدون snapshot و migration معتبر وارد `main` نمی‌شود.
7. خرید مجدد به‌عنوان موجودی کل جدید ثبت می‌شود.

## اسناد مهندسی

- [چشم‌انداز محصول](docs/00-product-vision.md)
- [نیازمندی‌ها](docs/01-requirements.md)
- [معماری نرم‌افزار](docs/02-architecture.md)
- [مدل درآمد و تبلیغات](docs/03-monetization.md)
- [حریم خصوصی و ایمنی](docs/04-privacy-safety.md)
- [نقشه راه](docs/05-roadmap.md)
- [طراحی persistence](docs/06-persistence-design.md)
- [معماری اعلان‌ها](docs/07-notifications.md)
- [تصمیم‌های معماری](docs/adr/)

## نام و شناسه

- نام نمایشی: **دارو تا کی دارم؟**
- نام پروژه: `daro_ta_key_daram`
- Application ID: `ir.emadkarimi.darutakey`
- مخزن: `Emad211/daro-ta-key-daram`

## مجوز

Copyright © 2026. All rights reserved. این پروژه در حال حاضر محصول تجاری خصوصی است.
