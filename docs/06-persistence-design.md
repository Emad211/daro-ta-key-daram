# 06 — طراحی Persistence محلی

## هدف

جایگزینی `InMemoryMedicationRepository` با یک repository پایدار، آفلاین و قابل مهاجرت، بدون تغییر در قراردادهای Domain و Application.

## تصمیم فناوری

برای پیاده‌سازی از **Drift روی SQLite** استفاده می‌شود.

دلایل:

- type-safety و code generation
- migrationهای قابل آزمون
- streamهای reactive مناسب Riverpod
- transaction و foreign key
- مناسب‌بودن برای داده محلی ساختاریافته

## مرز داده

دیتابیس فقط داده‌های لازم برای مدیریت موجودی را نگهداری می‌کند. داده‌ای برای تشخیص، بیماری زمینه‌ای یا پیشنهاد درمان اضافه نمی‌شود.

## جدول `medications`

| ستون | نوع | قید | توضیح |
|---|---|---|---|
| id | TEXT | PRIMARY KEY | UUID داخلی |
| name | TEXT | NOT NULL | نام واردشده توسط کاربر |
| unit | TEXT | NOT NULL | مقدار enum پایدار |
| units_per_day | REAL | CHECK > 0 | میانگین مشتق‌شده برای سازگاری migration |
| consumption_schedule_json | TEXT | NULL در schema | JSON نسخه‌دار برنامه مصرف؛ برای داده جدید الزامی در repository |
| alert_lead_days | INTEGER | 0..365 | فاصله هشدار |
| notes | TEXT | NULL | توضیح اختیاری |
| is_archived | INTEGER | NOT NULL DEFAULT 0 | آرشیو منطقی |
| created_at | INTEGER | NOT NULL | UTC epoch milliseconds |
| updated_at | INTEGER | NOT NULL | UTC epoch milliseconds |

## جدول `inventory_events`

موجودی فعلی نباید صرفاً با overwrite یک فیلد ذخیره شود. هر خرید یا اصلاح موجودی یک event جدید ایجاد می‌کند.

| ستون | نوع | قید | توضیح |
|---|---|---|---|
| id | TEXT | PRIMARY KEY | UUID رویداد |
| medication_id | TEXT | FK, NOT NULL | ارجاع به دارو |
| event_type | TEXT | NOT NULL | initial, restock, correction, scheduleChange |
| stock_units | REAL | CHECK >= 0 | موجودی مبنا بعد از رویداد |
| effective_at | INTEGER | NOT NULL | زمان شروع محاسبه |
| created_at | INTEGER | NOT NULL | زمان ثبت رویداد |
| note | TEXT | NULL | توضیح اختیاری |

شاخص لازم:

```sql
CREATE INDEX idx_inventory_events_medication_effective
ON inventory_events(medication_id, effective_at DESC);
```

آخرین event مؤثر در زمان `now` مبنای محاسبه موجودی است.

## جدول `app_preferences`

تنظیمات غیرحساس key/value مانند:

- زمان آخرین نمایش disclaimer
- واحدهای ظاهری
- وضعیت onboarding

شناسه‌های تبلیغاتی داخل دیتابیس ذخیره نمی‌شوند و از build configuration می‌آیند.

## جدول `ad_frequency_caps`

این جدول فقط وضعیت frequency cap را ذخیره می‌کند و هیچ اتصال یا foreign key به دارو ندارد.

| ستون | نوع | توضیح |
|---|---|---|
| placement | TEXT PRIMARY KEY | جایگاه تبلیغ |
| meaningful_actions | INTEGER | اقدامات از آخرین نمایش |
| last_shown_at | INTEGER NULL | آخرین نمایش |
| day_key | TEXT | روز محلی برای reset cap |
| shown_today | INTEGER | تعداد نمایش روزانه |

## Invariantها

1. `consumption_schedule_json` برای تمام writeهای جدید معتبر و نسخه‌دار است.
2. `units_per_day` فقط projection سازگاری و همیشه بزرگ‌تر از صفر است.
3. `stock_units` منفی نیست.
4. حذف دارو در MVP به‌صورت archive انجام می‌شود.
5. حذف دائمی، رویدادهای موجودی وابسته را داخل یک transaction حذف می‌کند.
6. زمان‌ها به UTC ذخیره و برای نمایش به timezone دستگاه تبدیل می‌شوند.
7. تغییر ساعت دستگاه، رویداد قبلی را بازنویسی نمی‌کند.
8. نام دارو یا مقدار مصرف در جدول تبلیغات، analytics یا log قرار نمی‌گیرد.

## Repository API هدف

```dart
abstract interface class MedicationRepository {
  Stream<List<Medication>> watchActiveMedications();
  Future<Medication?> findById(String id);
  Future<void> createMedication(Medication medication);
  Future<void> updateMedication(Medication medication);
  Future<void> recordInventoryEvent(InventoryEvent event);
  Future<void> archive(String medicationId);
  Future<void> restore(String medicationId);
  Future<void> deletePermanently(String medicationId);
}
```

## Transactionها

### ایجاد دارو

در یک transaction:

1. درج `medications`
2. درج رویداد `initial`
3. زمان‌بندی اعلان، پس از commit موفق

### خرید مجدد

1. خواندن موجودی برآوردی فعلی
2. ساخت event جدید با مقدار نهایی مورد تأیید کاربر
3. درج event
4. reschedule اعلان پس از commit

### حذف دائمی

1. حذف inventory events
2. حذف medication
3. لغو notification

## Migration strategy

- `schemaVersion = 2` شامل برنامه مصرف ساختاریافته است.
- migration نسخه ۱ نرخ روزانه قدیمی را به JSON روزانه معادل تبدیل می‌کند.
- هر تغییر schema همراه migration test است.
- migrationها forward-only هستند.
- downgrade پشتیبانی نمی‌شود.
- قبل از انتشار عمومی، export/import مستقل از schema طراحی می‌شود.

## تست‌های اجباری

- ایجاد دارو و دریافت از stream
- persistence پس از بازشدن مجدد دیتابیس
- مرتب‌سازی براساس تاریخ اتمام
- رویداد خرید مجدد
- archive و restore
- cascade حذف دائمی
- rollback transaction در خطا
- migration از هر schema عمومی قبلی
- عدم ثبت داده دارویی در ad frequency table

## ترتیب پیاده‌سازی

1. افزودن Drift و generator
2. تعریف database و tableها
3. mapperهای database ↔ domain
4. `DriftMedicationRepository`
5. repository test با دیتابیس in-memory
6. جایگزینی provider فعلی
7. حذف demo data از build تولیدی
8. ایجاد issue جداگانه برای notification scheduling

## تعریف Done

- برنامه پس از بسته‌شدن و بازشدن، داروها را حفظ کند.
- تمام تست‌های repository و migration سبز باشند.
- UI به Drift وابستگی مستقیم نداشته باشد.
- هیچ داده سلامت از مرز repository به تبلیغات یا analytics عبور نکند.
