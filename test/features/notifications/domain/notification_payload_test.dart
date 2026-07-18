import 'package:daro_ta_key_daram/features/notifications/domain/notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPayload', () {
    test('round-trips a medication payload', () {
      const NotificationPayload original = NotificationPayload(
        medicationId: 'medication/with spaces',
      );

      final NotificationPayload? decoded = NotificationPayload.tryDecode(
        original.encode(),
      );

      expect(decoded?.medicationId, original.medicationId);
      expect(decoded?.route, '/medications/medication%2Fwith%20spaces');
    });

    test('rejects malformed, unsupported, and unrelated payloads', () {
      expect(NotificationPayload.tryDecode(null), isNull);
      expect(NotificationPayload.tryDecode('not-json'), isNull);
      expect(
        NotificationPayload.tryDecode(
          '{"v":2,"type":"medication","medicationId":"m1"}',
        ),
        isNull,
      );
      expect(
        NotificationPayload.tryDecode(
          '{"v":1,"type":"ad","medicationId":"m1"}',
        ),
        isNull,
      );
    });
  });
}
