# 07 — معماری اعلان موجودی کم

## هدف

ارسال اعلان محلی و قابل‌جایگزینی پیش از اتمام موجودی دارو، بدون backend، بدون انتقال داده سلامت و بدون ایجاد وابستگی میان دامنه دارو و SDK اعلان.

## سیاست محصول

- درخواست مجوز فقط پس از اقدام آگاهانه کاربر انجام می‌شود.
- هنگام startup هیچ permission dialogی نمایش داده نمی‌شود.
- رد مجوز هیچ قابلیت مدیریت دارو را محدود نمی‌کند.
- اعلان‌ها inexact هستند و مجوز Exact Alarm درخواست نمی‌شود.
- هیچ تبلیغی در flow مجوز، اعلان یا deep link نمایش داده نمی‌شود.
- متن اعلان فقط روی دستگاه ساخته می‌شود و وارد analytics یا تبلیغات نمی‌شود.

## لایه‌ها

### Domain

- `NotificationId`: تولید شناسه پایدار FNV-1a برای هر دارو
- `NotificationPayload`: payload نسخه‌دار و قابل اعتبارسنجی
- `LowStockNotificationPlanner`: تولید برنامه اعلان بدون وابستگی Flutter
- `NotificationPlan`: داده immutable برای adapter

### Application

- `LocalNotificationService`: قرارداد plugin-independent
- `NotificationSyncCoordinator`: schedule، replace، cancel و rebuild به‌شکل best-effort

### Infrastructure

- `FlutterLocalNotificationService`: adapter واقعی Android
- `NotificationAwareMedicationRepository`: decorator اجرای sync فقط بعد از commit موفق persistence
- `NoopLocalNotificationService`: تست و پلتفرم‌های پشتیبانی‌نشده

## قواعد زمان‌بندی

1. هر دارو یک notification ID پایدار دارد.
2. موعد اصلی، reorder date در ساعت ۹ محلی است.
3. اگر موعد هشدار گذشته ولی موجودی تمام نشده باشد، اعلان نزدیک‌زمانی جایگزین می‌شود.
4. اگر موجودی تخمینی تمام شده باشد، یک اعلان depleted قابل‌جایگزینی زمان‌بندی می‌شود.
5. restock و correction اعلان قبلی را با همان ID جایگزین می‌کنند.
6. archive و delete اعلان را لغو می‌کنند.
7. restore اعلان را دوباره می‌سازد.
8. reboot و app update توسط receiverهای plugin مدیریت می‌شوند.

## Android

- Application ID: `ir.emadkarimi.darutakey`
- compileSdk / targetSdk: 36
- Java و Kotlin: 17
- Core library desugaring: فعال
- `POST_NOTIFICATIONS`: مجوز runtime برای Android 13+
- `RECEIVE_BOOT_COMPLETED`: حفظ اعلان‌های زمان‌بندی‌شده پس از reboot
- `ScheduledNotificationReceiver`
- `ScheduledNotificationBootReceiver`
- `AndroidScheduleMode.inexactAllowWhileIdle`
- بدون `SCHEDULE_EXACT_ALARM` و `USE_EXACT_ALARM`

## Deep link

payload معتبر به مسیر زیر نگاشت می‌شود:

```text
/medications/:medicationId
```

شناسه حذف‌شده یا نامعتبر به صفحه not-found بازیابی‌پذیر موجود می‌رسد.

## Failure policy

- شکست schedule یا cancel موجب rollback داده دارویی نمی‌شود.
- شکست initialize موجب crash یا جلوگیری از startup نمی‌شود.
- payload خراب نادیده گرفته می‌شود.
- timezone ناشناخته به UTC fallback می‌کند.

## تست دستگاه پیش از انتشار

- [ ] Android 13+: نمایش permission dialog فقط پس از لمس دکمه یادآوری
- [ ] رد مجوز و ادامه کامل CRUD دارو
- [ ] پذیرش مجوز و مشاهده pending notification
- [ ] restock و جایگزینی schedule قبلی
- [ ] archive و حذف pending notification
- [ ] tap اعلان در foreground
- [ ] tap اعلان در background
- [ ] tap اعلان پس از terminate شدن اپ
- [ ] reboot دستگاه و حفظ schedule
- [ ] تغییر timezone و بازسازی پس از بازشدن اپ
- [ ] تست قفل صفحه و private visibility
- [ ] تست Android 12 یا پایین‌تر بدون runtime prompt
