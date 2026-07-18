import 'package:daro_ta_key_daram/features/medication_inventory/domain/inventory_event.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/in_memory_medication_repository.dart';
import 'package:daro_ta_key_daram/features/notifications/application/local_notification_service.dart';
import 'package:daro_ta_key_daram/features/notifications/application/notification_sync_coordinator.dart';
import 'package:daro_ta_key_daram/features/notifications/domain/notification_plan.dart';
import 'package:daro_ta_key_daram/features/notifications/infrastructure/notification_aware_medication_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2026, 7, 18, 8);

  test('synchronizes notifications only after successful writes', () async {
    final InMemoryMedicationRepository raw = InMemoryMedicationRepository();
    final _RecordingNotificationService notifications =
        _RecordingNotificationService();
    final NotificationSyncCoordinator coordinator = NotificationSyncCoordinator(
      medicationRepository: raw,
      notificationService: notifications,
      clock: () => now,
    );
    final NotificationAwareMedicationRepository repository =
        NotificationAwareMedicationRepository(raw, coordinator);
    final Medication medication = Medication(
      id: 'medication-1',
      name: 'متفورمین',
      unit: MedicationUnit.tablet,
      stockAtRecord: 30,
      unitsPerDay: 2,
      inventoryRecordedAt: now,
    );

    await repository.upsert(medication);
    expect(notifications.scheduled, hasLength(1));

    await repository.recordInventoryEvent(
      InventoryEvent(
        id: 'event-1',
        medicationId: medication.id,
        type: InventoryEventType.restock,
        stockUnits: 60,
        effectiveAt: now,
        createdAt: now,
      ),
    );
    expect(notifications.scheduled, hasLength(2));

    await repository.archive(medication.id);
    expect(notifications.cancelled, hasLength(1));
  });

  test('does not schedule when persistence fails', () async {
    final InMemoryMedicationRepository raw = InMemoryMedicationRepository();
    final _RecordingNotificationService notifications =
        _RecordingNotificationService();
    final NotificationAwareMedicationRepository repository =
        NotificationAwareMedicationRepository(
          raw,
          NotificationSyncCoordinator(
            medicationRepository: raw,
            notificationService: notifications,
            clock: () => now,
          ),
        );

    final Future<void> operation = repository.recordInventoryEvent(
      InventoryEvent(
        id: 'orphan',
        medicationId: 'missing',
        type: InventoryEventType.correction,
        stockUnits: 3,
        effectiveAt: now,
        createdAt: now,
      ),
    );

    await expectLater(operation, throwsStateError);
    expect(notifications.scheduled, isEmpty);
    expect(notifications.cancelled, isEmpty);
  });
}

final class _RecordingNotificationService implements LocalNotificationService {
  final List<NotificationPlan> scheduled = <NotificationPlan>[];
  final List<int> cancelled = <int>[];

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
  Future<void> schedule(NotificationPlan plan) async {
    scheduled.add(plan);
  }

  @override
  Future<void> cancel(int notificationId) async {
    cancelled.add(notificationId);
  }

  @override
  Future<void> cancelAll() async {}
}
