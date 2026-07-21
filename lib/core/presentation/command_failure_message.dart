import '../../features/medication_inventory/application/medication_lifecycle.dart';

abstract final class CommandFailureMessage {
  static String resolve(Object error, {required String fallback}) {
    if (error is MedicationNotFoundException) {
      return 'این مورد دیگر در دسترس نیست. صفحه را تازه‌سازی کنید.';
    }
    if (error is MedicationLifecycleViolation) {
      return switch (error.state) {
        MedicationLifecycleState.archived =>
          'این مورد آرشیو شده است. ابتدا آن را بازیابی کنید.',
        MedicationLifecycleState.active =>
          'این عملیات در وضعیت فعلی قابل انجام نیست.',
        MedicationLifecycleState.missing =>
          'این مورد دیگر در دسترس نیست. صفحه را تازه‌سازی کنید.',
      };
    }
    if (error is ArgumentError || error is FormatException) {
      return 'اطلاعات واردشده معتبر نیست. موارد فرم را دوباره بررسی کنید.';
    }
    if (error is StateError) {
      return 'اطلاعات در این فاصله تغییر کرده است. صفحه را تازه‌سازی کنید.';
    }
    return fallback;
  }
}
