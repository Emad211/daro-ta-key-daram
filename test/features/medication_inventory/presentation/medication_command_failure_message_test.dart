import 'package:daro_ta_key_daram/features/medication_inventory/application/medication_lifecycle.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/presentation/medication_command_failure_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps typed lifecycle failures without exposing technical details', () {
    expect(
      MedicationCommandFailureMessage.resolve(
        const MedicationNotFoundException(
          'missing',
          MedicationLifecycleOperation.updateDetails,
        ),
        fallback: 'fallback',
      ),
      'این دارو دیگر در دسترس نیست. صفحه را تازه‌سازی کنید.',
    );
    expect(
      MedicationCommandFailureMessage.resolve(
        const MedicationLifecycleViolation(
          medicationId: 'archived',
          state: MedicationLifecycleState.archived,
          operation: MedicationLifecycleOperation.recordInventoryEvent,
        ),
        fallback: 'fallback',
      ),
      'این دارو آرشیو شده است. ابتدا آن را بازیابی کنید.',
    );
    expect(
      MedicationCommandFailureMessage.resolve(
        const MedicationLifecycleViolation(
          medicationId: 'active',
          state: MedicationLifecycleState.active,
          operation: MedicationLifecycleOperation.restore,
        ),
        fallback: 'fallback',
      ),
      'این عملیات در وضعیت فعلی دارو قابل انجام نیست.',
    );
  });

  test('maps validation, stale-state, and unknown failures', () {
    expect(
      MedicationCommandFailureMessage.resolve(
        ArgumentError('bad'),
        fallback: 'fallback',
      ),
      'اطلاعات واردشده معتبر نیست. موارد فرم را دوباره بررسی کنید.',
    );
    expect(
      MedicationCommandFailureMessage.resolve(
        StateError('stale'),
        fallback: 'fallback',
      ),
      'اطلاعات در این فاصله تغییر کرده است. صفحه را تازه‌سازی کنید.',
    );
    expect(
      MedicationCommandFailureMessage.resolve(
        Exception('unknown'),
        fallback: 'fallback',
      ),
      'fallback',
    );
  });
}
