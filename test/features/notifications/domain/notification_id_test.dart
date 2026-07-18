import 'package:daro_ta_key_daram/features/notifications/domain/notification_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationId', () {
    test('is stable for known medication identifiers', () {
      expect(NotificationId.forMedication('medication-1'), 1539718964);
      expect(NotificationId.forMedication('medication-2'), 1590051821);
      expect(NotificationId.forMedication('demo-metformin'), 2027250508);
      expect(NotificationId.forMedication('دارو-۱'), 1777559374);
    });

    test('returns a positive signed 31-bit integer', () {
      final int id = NotificationId.forMedication('medication-1');

      expect(id, greaterThan(0));
      expect(id, lessThanOrEqualTo(0x7FFFFFFF));
    });

    test('rejects an empty identifier', () {
      expect(() => NotificationId.forMedication('  '), throwsArgumentError);
    });
  });
}
