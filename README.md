# دارو تا کی دارم؟

یک اپلیکیشن اندرویدی فارسی، آفلاین‌محور و رایگان برای تخمین زمان پایان موجودی دارو و یادآوری خرید مجدد.

> این برنامه ابزار ثبت و یادآوری است و تشخیص پزشکی، تجویز دارو یا تعیین دوز انجام نمی‌دهد.

## وضعیت پروژه

**مرحله فعلی: Phase 2 — زیرساخت persistence محلی**

موارد پیاده‌سازی‌شده:

- تعریف مسئله، دامنه و الزامات MVP
- معماری Feature-first با تفکیک Domain / Application / Infrastructure / Presentation
- موتور محاسبه موجودی و تاریخ تقریبی اتمام دارو
- داشبورد اولیه فارسی و راست‌به‌چپ
- فرم افزودن دارو با اعتبارسنجی
- دیتابیس محلی Drift/SQLite با schema نسخه ۱
- تاریخچه رویدادهای موجودی برای initial، restock و correction
- repository واقعی با transaction، archive/restore و حذف cascade
- snapshot نسخه‌بندی‌شده schema برای migrationهای آینده
- لایه انتزاعی تبلیغات و سیاست نمایش تبلیغ
- CI برای تولید کد، تطبیق schema، format، analyze و test
- تست‌های دامنه، تبلیغات، UI و lifecycle دیتابیس فایل واقعی

قابلیت‌های UI برای ویرایش دارو، ثبت خرید مجدد و مدیریت آرشیو هنوز در مرحله بعدی هستند.

## مدل کسب‌وکار

تمام قابلیت‌های اصلی رایگان می‌مانند و درآمد محصول فقط از تبلیغات داخل اپ تأمین می‌شود. تبلیغ نباید مانع دسترسی به اطلاعات ضروری دارویی شود. سیاست دقیق در [`docs/03-monetization.md`](docs/03-monetization.md) ثبت شده است.

## پشته فنی

- Flutter 3.44.x / Dart 3.12.x
- Riverpod برای مدیریت state و dependency injection
- go_router برای مسیریابی
- Drift/SQLite برای persistence آفلاین و migrationپذیر
- معماری Offline-first
- Adivery به‌عنوان گزینه اول تبلیغات و Tapsell Plus به‌عنوان گزینه جایگزین/mediation

## اجرای پروژه

اگر پوشه `android/` هنوز وجود ندارد، یک بار دستور زیر را اجرا کنید:

```bash
flutter create \
  --no-pub \
  --platforms=android \
  --org ir.emadkarimi \
  --project-name daro_ta_key_daram \
  .
```

سپس:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

یا از اسکریپت آماده استفاده کنید:

```bash
bash tool/bootstrap.sh
```

## مدیریت schema دیتابیس

نسخه فعلی schema در `drift_schemas/drift_schema_v1.json` نگهداری می‌شود. پس از هر تغییر عمدی schema و افزایش `schemaVersion`:

```bash
bash tool/export_drift_schema.sh
```

CI اختلاف میان schema کد و snapshot ثبت‌شده را رد می‌کند.

## ساختار اصلی

```text
lib/
  app/                       # composition root، theme و router
  core/
    database/                # Drift database و schema
    theme/
    widgets/
  features/
    ads/                     # قرارداد و سیاست تبلیغات
    medication_inventory/
      domain/
      application/
      infrastructure/        # Drift repository
      presentation/
drift_schemas/               # snapshotهای versioned دیتابیس
```

## قواعد محصول

1. هیچ داده دارویی در MVP به سرور ارسال نمی‌شود.
2. هیچ تبلیغی روی فرم ورود اطلاعات، هشدار بحرانی یا onboarding نمایش داده نمی‌شود.
3. اپ فقط تخمین موجودی انجام می‌دهد؛ دوز مصرف را پیشنهاد یا تغییر نمی‌دهد.
4. قابلیت‌های اصلی پشت تبلیغ جایزه‌ای قفل نمی‌شوند.
5. محاسبات دامنه و transactionهای persistence باید تست خودکار داشته باشند.
6. تغییر schema بدون snapshot و migration معتبر وارد `main` نمی‌شود.

## اسناد مهندسی

- [چشم‌انداز محصول](docs/00-product-vision.md)
- [نیازمندی‌ها و معیارهای پذیرش](docs/01-requirements.md)
- [معماری نرم‌افزار](docs/02-architecture.md)
- [مدل درآمد و سیاست تبلیغات](docs/03-monetization.md)
- [حریم خصوصی و ایمنی](docs/04-privacy-safety.md)
- [نقشه راه](docs/05-roadmap.md)
- [طراحی persistence](docs/06-persistence-design.md)
- [تصمیم‌های معماری](docs/adr/)

## نام و شناسه

- نام نمایشی: **دارو تا کی دارم؟**
- نام پروژه: `daro_ta_key_daram`
- Application ID پیشنهادی: `ir.emadkarimi.darutakey`
- مخزن: `Emad211/daro-ta-key-daram`

## مجوز

Copyright © 2026. All rights reserved. این پروژه در حال حاضر محصول تجاری خصوصی است.
