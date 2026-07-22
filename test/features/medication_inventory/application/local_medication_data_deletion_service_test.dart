import 'dart:async';

import 'package:daro_ta_key_daram/features/medication_inventory/application/local_medication_data_deletion_service.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/in_memory_medication_repository.dart';
import 'package:daro_ta_key_daram/features/notifications/application/local_notification_service.dart';
import 'package:daro_ta_key_daram/features/notifications/application/notification_sync_coordinator.dart';
import 'package:daro_ta_key_daram/features/notifications/domain/notification_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 7, 21, 12);

  test(
    'deletes active, archived, and inventory data then clears notifications',
    () async {
      final InMemoryMedicationRepository repository =
          InMemoryMedicationRepository(
            seed: <Medication>[
              _medication(id: 'active', now: now),
              _medication(id: 'archived', now: now, isArchived: true),
            ],
            clock: () => now,
          );
      final _DeletionNotificationService notifications =
          _DeletionNotificationService();
      final LocalMedicationDataDeletionService service =
          LocalMedicationDataDeletionService(
            repository,
            NotificationSyncCoordinator(
              medicationRepository: repository,
              notificationService: notifications,
              clock: () => now,
            ),
          );

      final LocalMedicationDataDeletionResult result = await service
          .deleteAll();

      expect(result.status, LocalMedicationDataDeletionStatus.completed);
      expect(result.notificationsCleared, isTrue);
      expect(await repository.watchActiveMedications().first, isEmpty);
      expect(await repository.watchArchivedMedications().first, isEmpty);
      expect(await repository.watchInventoryEvents('active').first, isEmpty);
      expect(await repository.watchInventoryEvents('archived').first, isEmpty);
      expect(notifications.cancelAllCalls, 1);
    },
  );

  test('reports notification cleanup separately and supports retry', () async {
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(
          seed: <Medication>[_medication(id: 'active', now: now)],
          clock: () => now,
        );
    final _DeletionNotificationService notifications =
        _DeletionNotificationService()..failCancelAll = true;
    final LocalMedicationDataDeletionService service =
        LocalMedicationDataDeletionService(
          repository,
          NotificationSyncCoordinator(
            medicationRepository: repository,
            notificationService: notifications,
            clock: () => now,
          ),
        );

    final LocalMedicationDataDeletionResult result = await service.deleteAll();

    expect(
      result.status,
      LocalMedicationDataDeletionStatus.notificationCleanupPending,
    );
    expect(result.notificationsCleared, isFalse);
    expect(await repository.watchActiveMedications().first, isEmpty);
    expect(notifications.cancelAllCalls, 1);

    notifications.failCancelAll = false;
    expect(await service.retryNotificationCleanup(), isTrue);
    expect(notifications.cancelAllCalls, 2);
  });

  test(
    'privacy erasure waits for an in-flight rebuild and remains the final operation',
    () async {
      final InMemoryMedicationRepository repository =
          InMemoryMedicationRepository(
            seed: <Medication>[_medication(id: 'active', now: now)],
            clock: () => now,
          );
      final _BlockingNotificationService notifications =
          _BlockingNotificationService();
      final NotificationSyncCoordinator coordinator =
          NotificationSyncCoordinator(
            medicationRepository: repository,
            notificationService: notifications,
            clock: () => now,
          );
      final LocalMedicationDataDeletionService service =
          LocalMedicationDataDeletionService(repository, coordinator);

      final Future<int> rebuild = coordinator.rebuildAll();
      await notifications.scheduleStarted.future;

      final Future<LocalMedicationDataDeletionResult> deletion = service
          .deleteAll();
      await Future<void>.delayed(Duration.zero);
      expect(
        await repository.watchActiveMedications().first,
        isEmpty,
        reason: 'Database erasure is independent from notification cleanup.',
      );

      notifications.allowScheduleToFinish.complete();

      expect(await rebuild, 1);
      final LocalMedicationDataDeletionResult result = await deletion;
      expect(result.status, LocalMedicationDataDeletionStatus.completed);
      expect(notifications.scheduledIds, isEmpty);
      expect(notifications.operations, <String>[
        'schedule-start',
        'schedule-complete',
        'cancel-all',
      ]);
    },
  );
}

Medication _medication({
  required String id,
  required DateTime now,
  bool isArchived = false,
}) {
  return Medication(
    id: id,
    name: 'داروی $id',
    unit: MedicationUnit.tablet,
    stockAtRecord: 20,
    unitsPerDay: 1,
    inventoryRecordedAt: now,
    isArchived: isArchived,
  );
}

final class _DeletionNotificationService implements LocalNotificationService {
  bool failCancelAll = false;
  int cancelAllCalls = 0;

  @override
  Future<void> cancelAll() async {
    cancelAllCalls += 1;
    if (failCancelAll) {
      throw StateError('Notification cleanup failed.');
    }
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

final class _BlockingNotificationService implements LocalNotificationService {
  final Completer<void> scheduleStarted = Completer<void>();
  final Completer<void> allowScheduleToFinish = Completer<void>();
  final Set<int> scheduledIds = <int>{};
  final List<String> operations = <String>[];

  @override
  Future<void> schedule(NotificationPlan plan) async {
    operations.add('schedule-start');
    scheduleStarted.complete();
    await allowScheduleToFinish.future;
    scheduledIds.add(plan.id);
    operations.add('schedule-complete');
  }

  @override
  Future<void> cancelAll() async {
    operations.add('cancel-all');
    scheduledIds.clear();
  }

  @override
  Future<void> cancel(int notificationId) async {
    scheduledIds.remove(notificationId);
  }

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
}
