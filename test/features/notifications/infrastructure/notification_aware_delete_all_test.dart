import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/in_memory_medication_repository.dart';
import 'package:daro_ta_key_daram/features/notifications/application/local_notification_service.dart';
import 'package:daro_ta_key_daram/features/notifications/application/notification_sync_coordinator.dart';
import 'package:daro_ta_key_daram/features/notifications/domain/notification_plan.dart';
import 'package:daro_ta_key_daram/features/notifications/infrastructure/notification_aware_medication_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'deleteAll clears persisted medication data before notification cleanup',
    () async {
      final DateTime now = DateTime.utc(2026, 7, 21, 12);
      final InMemoryMedicationRepository raw = InMemoryMedicationRepository(
        seed: <Medication>[
          Medication(
            id: 'medication-1',
            name: 'متفورمین',
            unit: MedicationUnit.tablet,
            stockAtRecord: 30,
            unitsPerDay: 2,
            inventoryRecordedAt: now,
          ),
        ],
        clock: () => now,
      );
      late _OrderingNotificationService notifications;
      notifications = _OrderingNotificationService(
        onCancelAll: () async {
          expect(await raw.watchActiveMedications().first, isEmpty);
          expect(await raw.watchArchivedMedications().first, isEmpty);
        },
      );
      final NotificationAwareMedicationRepository repository =
          NotificationAwareMedicationRepository(
            raw,
            NotificationSyncCoordinator(
              medicationRepository: raw,
              notificationService: notifications,
              clock: () => now,
            ),
          );

      await repository.deleteAll();

      expect(notifications.cancelAllCalls, 1);
    },
  );
}

final class _OrderingNotificationService implements LocalNotificationService {
  _OrderingNotificationService({required this.onCancelAll});

  final Future<void> Function() onCancelAll;
  int cancelAllCalls = 0;

  @override
  Future<void> cancelAll() async {
    cancelAllCalls += 1;
    await onCancelAll();
  }

  @override
  Future<void> cancel(int notificationId) async {}

  @override
  Future<void> initialize({required NotificationTapHandler onTap}) async {}

  @override
  Future<NotificationPermissionState> permissionState() async {
    return NotificationPermissionState.granted;
  }

  @override
  Future<NotificationPermissionState> requestPermission() async {
    return NotificationPermissionState.granted;
  }

  @override
  Future<void> schedule(NotificationPlan plan) async {}
}
