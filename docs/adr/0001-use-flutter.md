# ADR-0001 — استفاده از Flutter

- Status: Accepted
- Date: 2026-07-18

## Context

محصول در ابتدا Android-first و فارسی است، اما احتمال انتشار نسخه انگلیسی و Google Play وجود دارد. شبکه‌های تبلیغاتی ایرانی موردنظر پلاگین Flutter دارند.

## Decision

Flutter انتخاب می‌شود.

## Consequences

### مثبت

- یک codebase برای بازار، مایکت و Google Play
- RTL و UI سفارشی مناسب
- تست‌پذیری خوب منطق و widgetها
- پلاگین رسمی Adivery و Tapsell Plus

### منفی

- وابستگی به کیفیت پلاگین‌های تبلیغاتی
- نیاز به کنترل دقیق Gradle/Kotlin هنگام ارتقا SDKها
- حجم اپ بیشتر از یک ابزار native بسیار کوچک
