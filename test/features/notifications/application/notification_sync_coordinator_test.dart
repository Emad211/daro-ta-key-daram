import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/in_memory_medication_repository.dart';
import 'package:daro_ta_key_daram/features/notifications/application/local_notification_service.dart';
import 'package:daro_ta_key_daram/features/notifications/application/notification_sync_coordinator.dart';
import 'package:daro_ta_key_daram/features/notifications/domain/notification_id.dart';
import 'package:daro_ta_key_daram/features/notifications/domain/notification_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2026, 7, 18, 8);

  test('reschedules an active medication with its stable id', () async {
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(seed: <Medication>[_medication(now)]);
    final _RecordingNotificationService notifications =
        _RecordingNotificationService();
    final NotificationSyncCoordinator coordinator = NotificationSyncCoordinator(
      medicationRepository: repository,
      notificationService: notifications,
      clock: () => now,
    );

    expect(await coordinator.rescheduleMedication('medication-1'), isTrue);
    expect(notifications.scheduled, hasLength(1));
    expect(
      notifications.scheduled.single.id,
      NotificationId.forMedication('medication-1'),
    );
  });

  test('cancels archived or missing medication schedules', () async {
    final Medication archived = _medication(now).copyWith(isArchived: true);
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(seed: <Medication>[archived]);
    final _RecordingNotificationService notifications =
        _RecordingNotificationService();
    final NotificationSyncCoordinator coordinator = NotificationSyncCoordinator(
      medicationRepository: repository,
      notificationService: notifications,
      clock: () => now,
    );

    expect(await coordinator.rescheduleMedication(archived.id), isTrue);
    expect(await coordinator.rescheduleMedication('missing'), isTrue);
    expect(notifications.cancelled, <int>[
      NotificationId.forMedication(archived.id),
      NotificationId.forMedication('missing'),
    ]);
  });

  test('schedule failures are non-blocking and reported as false', () async {
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(seed: <Medication>[_medication(now)]);
    final NotificationSyncCoordinator coordinator = NotificationSyncCoordinator(
      medicationRepository: repository,
      notificationService: _ThrowingNotificationService(),
      clock: () => now,
    );

    expect(await coordinator.rescheduleMedication('medication-1'), isFalse);
  });

  test('cancel failures are non-blocking and reported as false', () async {
    final Medication archived = _medication(now).copyWith(isArchived: true);
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(seed: <Medication>[archived]);
    final NotificationSyncCoordinator coordinator = NotificationSyncCoordinator(
      medicationRepository: repository,
      notificationService: _ThrowingNotificationService(),
      clock: () => now,
    );

    expect(await coordinator.rescheduleMedication(archived.id), isFalse);
  });
}

Medication _medication(DateTime now) {
  return Medication(
    id: 'medication-1',
    name: 'متفورمین',
    unit: MedicationUnit.tablet,
    stockAtRecord: 30,
    unitsPerDay: 2,
    inventoryRecordedAt: now,
    alertLeadDays: 5,
  );
}

final class _RecordingNotificationService implements LocalNotificationService {
  final List<NotificationPlan> scheduled = <NotificationPlan>[];
  final List<int> cancelled = <int>[];

  @override
  Future<void> cancel(int notificationId) async {
    cancelled.add(notificationId);
  }

  @override
  Future<void> cancelAll() async {}

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
}

final class _ThrowingNotificationService implements LocalNotificationService {
  @override
  Future<void> cancel(int notificationId) async {
    throw StateError('cancel failed');
  }

  @override
  Future<void> cancelAll() async {
    throw StateError('cancel all failed');
  }

  @override
  Future<void> initialize({required NotificationTapHandler onTap}) async {
    throw StateError('initialize failed');
  }

  @override
  Future<NotificationPermissionState> permissionState() async {
    throw StateError('permission failed');
  }

  @override
  Future<NotificationPermissionState> requestPermission() async {
    throw StateError('permission failed');
  }

  @override
  Future<void> schedule(NotificationPlan plan) async {
    throw StateError('schedule failed');
  }
}
