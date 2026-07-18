# 02 — معماری نرم‌افزار

## سبک معماری

معماری پروژه **Feature-first + Layered Clean Architecture** است. هدف، جداسازی منطق محاسبه از UI، دیتابیس و SDK تبلیغات است؛ نه ایجاد لایه‌های تشریفاتی غیرضروری.

## لایه‌ها

### Domain

شامل مدل‌ها، value objectها و قواعد خالص کسب‌وکار است.

- بدون وابستگی به Flutter
- بدون دسترسی به دیتابیس یا شبکه
- قابل تست با unit test سریع

### Application

use caseها، قرارداد repository و orchestration را نگهداری می‌کند.

### Infrastructure

پیاده‌سازی storage، notification، analytics و SDK تبلیغات در این لایه قرار می‌گیرد.

### Presentation

صفحه‌ها، widgetها و providerهای UI را شامل می‌شود.

## ساختار پوشه

```text
lib/
  app/
    app.dart
    router.dart
  core/
    theme/
    widgets/
  features/
    ads/
      domain/
      infrastructure/
      presentation/
    medication_inventory/
      domain/
      application/
      infrastructure/
      presentation/
```

## مدل داده MVP

### Medication

| فیلد | نوع | توضیح |
|---|---|---|
| id | String | شناسه داخلی |
| name | String | نامی که کاربر وارد می‌کند |
| unit | MedicationUnit | واحد شمارش |
| stockAtRecord | double | موجودی در زمان ثبت |
| unitsPerDay | double | مصرف روزانه طبق دستور پزشک |
| inventoryRecordedAt | DateTime | زمان مبنای محاسبه |
| alertLeadDays | int | فاصله هشدار |
| notes | String? | توضیح اختیاری |
| isArchived | bool | وضعیت آرشیو |

### MedicationStockSnapshot

خروجی محاسبه در یک زمان مشخص:

- موجودی تخمینی فعلی
- تعداد روز دقیق و کامل باقی‌مانده
- زمان تقریبی پایان
- زمان پیشنهادشده برای هشدار
- وضعیت urgency

## فرمول پایه

```text
elapsedDays = max(0, now - inventoryRecordedAt)
estimatedRemaining = max(0, stockAtRecord - elapsedDays × unitsPerDay)
remainingDays = estimatedRemaining / unitsPerDay
depletionAt = inventoryRecordedAt + (stockAtRecord / unitsPerDay)
```

این فرمول یک **مدل تخمینی با نرخ ثابت** است. برنامه باید این محدودیت را به کاربر توضیح دهد.

## Persistence plan

مرحله بعدی از Drift/SQLite استفاده می‌کند:

- `medications`
- `inventory_events`
- `app_preferences`
- `ad_impression_caps`

تاریخچه موجودی به‌صورت event نگهداری می‌شود تا ویرایش‌ها قابل ردگیری باشند.

## Dependency injection

Riverpod composition root وابستگی‌ها را فراهم می‌کند:

- `MedicationRepository`
- `Clock`
- `AdService`
- در مراحل بعد `NotificationService` و `AnalyticsService`

## خط‌مشی خطا

- خطاهای validation در UI نمایش داده می‌شوند.
- خطای تبلیغ silent و non-blocking است.
- خطای storage باید پیام قابل فهم و امکان retry داشته باشد.
- هیچ crashای به دلیل نبود اینترنت یا نبود تبلیغ مجاز نیست.

## امنیت داده

- دیتابیس محلی منبع حقیقت است.
- هیچ نام دارو یا دوزی در log تولیدی ثبت نمی‌شود.
- placement IDها و کلیدهای تبلیغ از config build دریافت می‌شوند.
- نسخه پشتیبان ابری تا تدوین مدل رضایت و رمزنگاری اضافه نمی‌شود.
