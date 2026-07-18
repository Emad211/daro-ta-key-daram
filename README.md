# دارو تا کی دارم؟

یک اپلیکیشن اندرویدی فارسی، آفلاین‌محور و رایگان برای تخمین زمان پایان موجودی دارو و یادآوری خرید مجدد.

> این برنامه ابزار ثبت و یادآوری است و تشخیص پزشکی، تجویز دارو یا تعیین دوز انجام نمی‌دهد.

## وضعیت پروژه

**مرحله فعلی: Phase 1 — مهندسی محصول و اولین Vertical Slice**

در این مرحله موارد زیر پیاده‌سازی شده‌اند:

- تعریف مسئله، دامنه و الزامات MVP
- معماری Feature-first با تفکیک Domain / Application / Infrastructure / Presentation
- موتور محاسبه موجودی و تاریخ تقریبی اتمام دارو
- داشبورد اولیه فارسی و راست‌به‌چپ
- فرم افزودن دارو با اعتبارسنجی
- Repository آفلاین موقت در حافظه برای اولین Vertical Slice
- تست‌های واحد موتور محاسبه
- لایه انتزاعی تبلیغات و سیاست نمایش تبلیغ
- CI پایه برای format، analyze و test

## مدل کسب‌وکار

تمام قابلیت‌های اصلی رایگان می‌مانند و درآمد محصول فقط از تبلیغات داخل اپ تأمین می‌شود. تبلیغ نباید مانع دسترسی به اطلاعات ضروری دارویی شود. سیاست دقیق در [`docs/03-monetization.md`](docs/03-monetization.md) ثبت شده است.

## پشته فنی

- Flutter 3.44.x / Dart 3.12.x
- Riverpod برای مدیریت state و dependency injection
- go_router برای مسیریابی
- معماری Offline-first
- Adivery به‌عنوان گزینه اول تبلیغات و Tapsell Plus به‌عنوان گزینه جایگزین/mediation

## اجرای پروژه

این مخزن در مرحله اولیه شامل کد اپ و تست‌هاست. اگر پوشه `android/` هنوز وجود ندارد، یک بار دستور زیر را اجرا کنید:

```bash
flutter create \
  --platforms=android \
  --org ir.emadkarimi \
  --project-name daro_ta_key_daram \
  .
```

سپس:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

یا از اسکریپت آماده استفاده کنید:

```bash
bash tool/bootstrap.sh
```

## ساختار اصلی

```text
lib/
  app/                       # composition root، theme و router
  core/                      # ابزارهای مشترک و قواعد عمومی
  features/
    ads/                     # قرارداد و سیاست تبلیغات
    medication_inventory/    # دامنه اصلی محصول
      domain/
      application/
      infrastructure/
      presentation/
```

## قواعد محصول

1. هیچ داده دارویی در MVP به سرور ارسال نمی‌شود.
2. هیچ تبلیغی روی فرم ورود اطلاعات، هشدار بحرانی یا onboarding نمایش داده نمی‌شود.
3. اپ فقط تخمین موجودی انجام می‌دهد؛ دوز مصرف را پیشنهاد یا تغییر نمی‌دهد.
4. قابلیت‌های اصلی پشت تبلیغ جایزه‌ای قفل نمی‌شوند.
5. محاسبات دامنه باید تست واحد داشته باشند.

## اسناد مهندسی

- [چشم‌انداز محصول](docs/00-product-vision.md)
- [نیازمندی‌ها و معیارهای پذیرش](docs/01-requirements.md)
- [معماری نرم‌افزار](docs/02-architecture.md)
- [مدل درآمد و سیاست تبلیغات](docs/03-monetization.md)
- [حریم خصوصی و ایمنی](docs/04-privacy-safety.md)
- [نقشه راه](docs/05-roadmap.md)
- [تصمیم‌های معماری](docs/adr/)

## نام و شناسه

- نام نمایشی: **دارو تا کی دارم؟**
- نام پروژه: `daro_ta_key_daram`
- Application ID پیشنهادی: `ir.emadkarimi.darutakey`
- مخزن پیشنهادی: `Emad211/daro-ta-key-daram`

## مجوز

Copyright © 2026. All rights reserved. این پروژه در حال حاضر محصول تجاری خصوصی است.
