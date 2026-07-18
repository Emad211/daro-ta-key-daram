# 05 — نقشه راه مهندسی

## Phase 0 — تعریف محصول

- [x] مسئله و کاربران
- [x] دامنه و non-goals
- [x] الزامات MVP
- [x] سیاست تبلیغات
- [x] مرز ایمنی پزشکی

## Phase 1 — Foundation + Vertical Slice

- [x] ساختار Flutter
- [x] معماری و DI
- [x] مدل دامنه دارو
- [x] موتور محاسبه زمان اتمام
- [x] داشبورد اولیه
- [x] افزودن دارو
- [x] repository موقت در حافظه برای تست
- [x] تست واحد
- [x] AdService abstraction

## Phase 2 — Local persistence and lifecycle

- [x] Drift/SQLite schema نسخه ۱
- [x] schema snapshot و migration strategy
- [x] repository واقعی و transactionها
- [x] restock/correction event history در لایه داده
- [x] archive/restore و cascade delete در repository
- [x] تست repository با دیتابیس memory و فایل واقعی
- [x] صفحه جزئیات دارو
- [x] جریان UI خرید مجدد و اصلاح موجودی
- [x] timeline تاریخچه موجودی
- [x] عملیات آرشیو با حفظ تاریخچه
- [ ] صفحه ویرایش مشخصات دارو
- [ ] صفحه مدیریت داروهای آرشیوشده و restore

## Phase 3 — Notifications

- [x] notification planning خالص و stable IDs
- [x] permission flow آگاهانه Android 13+
- [x] schedule / reschedule / cancel پس از persistence موفق
- [x] boot و app-update persistence
- [x] timezone initialization و fallback
- [x] notification deep links
- [x] committed Android project و debug APK build
- [ ] تست روی دستگاه فیزیکی Android

## Phase 4 — Monetization integration

- [ ] ساخت حساب و app در Adivery
- [ ] دریافت placement ID تست
- [ ] پیاده‌سازی AdiveryAdService
- [ ] banner placement
- [ ] interstitial frequency cap persistence
- [ ] failure handling
- [ ] no-health-data analytics validation

## Phase 5 — Quality and release

- [ ] accessibility audit
- [ ] RTL and large-font tests
- [ ] integration tests روی دستگاه
- [ ] signing config امن و APK/AAB داخلی
- [ ] closed beta با ۱۰ تا ۲۰ کاربر
- [ ] privacy policy و store listing
- [ ] انتشار در کافه‌بازار و مایکت

## Phase 6 — Growth

- [ ] ASO فارسی
- [ ] caregiver profiles
- [ ] export/share report
- [ ] optional cloud backup with explicit consent
- [ ] Google Play English version
- [ ] Tapsell Plus mediation experiment
