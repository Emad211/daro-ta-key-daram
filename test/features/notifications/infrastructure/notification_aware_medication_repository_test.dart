import 'package:daro_ta_key_daram/features/medication_inventory/application/medication_details_update.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/application/medication_lifecycle.dart';
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

  test('synchronizes only after successful persisted commands', () async {
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

    await repository.create(medication);
    expect(notifications.scheduled, hasLength(1));

    await repository.updateDetails(
      MedicationDetailsUpdate(
        medicationId: medication.id,
        name: 'متفورمین ۵۰۰',
        unit: medication.unit,
        consumptionSchedule: medication.consumptionSchedule,
        alertLeadDays: 7,
      ),
    );
    expect(notifications.scheduled, hasLength(2));

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
    expect(notifications.scheduled, hasLength(3));

    await repository.archive(medication.id);
    expect(notifications.cancelled, hasLength(1));

    await repository.restore(medication.id);
    expect(notifications.scheduled, hasLength(4));

    await repository.deletePermanently(medication.id);
    expect(notifications.cancelled, hasLength(2));
  });

  test('does not synchronize after rejected lifecycle commands', () async {
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
    final Medication medication = Medication(
      id: 'medication-1',
      name: 'Test',
      unit: MedicationUnit.tablet,
      stockAtRecord: 30,
      unitsPerDay: 2,
      inventoryRecordedAt: now,
    );

    await repository.create(medication);
    await repository.archive(medication.id);
    final int scheduledBefore = notifications.scheduled.length;
    final int cancelledBefore = notifications.cancelled.length;

    await expectLater(
      repository.updateDetails(
        MedicationDetailsUpdate(
          medicationId: medication.id,
          name: 'Rejected',
          unit: medication.unit,
          consumptionSchedule: medication.consumptionSchedule,
          alertLeadDays: 5,
        ),
      ),
      throwsA(isA<MedicationLifecycleViolation>()),
    );
    await expectLater(
      repository.archive(medication.id),
      throwsA(isA<MedicationLifecycleViolation>()),
    );
    await expectLater(
      repository.recordInventoryEvent(
        InventoryEvent(
          id: 'rejected',
          medicationId: medication.id,
          type: InventoryEventType.correction,
          stockUnits: 3,
          effectiveAt: now,
          createdAt: now,
        ),
      ),
      throwsA(isA<MedicationLifecycleViolation>()),
    );

    expect(notifications.scheduled, hasLength(scheduledBefore));
    expect(notifications.cancelled, hasLength(cancelledBefore));
  });

  test('does not synchronize when the aggregate is missing', () async {
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

    await expectLater(operation, throwsA(isA<MedicationNotFoundException>()));
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
