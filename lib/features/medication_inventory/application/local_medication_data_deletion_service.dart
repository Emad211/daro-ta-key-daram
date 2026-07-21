import '../../notifications/application/notification_sync_coordinator.dart';
import 'medication_repository.dart';

enum LocalMedicationDataDeletionStatus { completed, notificationCleanupPending }

final class LocalMedicationDataDeletionResult {
  const LocalMedicationDataDeletionResult(this.status);

  final LocalMedicationDataDeletionStatus status;

  bool get notificationsCleared =>
      status == LocalMedicationDataDeletionStatus.completed;
}

final class LocalMedicationDataDeletionService {
  const LocalMedicationDataDeletionService(
    this._repository,
    this._notifications,
  );

  final MedicationRepository _repository;
  final NotificationSyncCoordinator _notifications;

  Future<LocalMedicationDataDeletionResult> deleteAll() async {
    await _repository.deleteAll();
    final bool notificationsCleared = await _notifications.cancelAll();
    return LocalMedicationDataDeletionResult(
      notificationsCleared
          ? LocalMedicationDataDeletionStatus.completed
          : LocalMedicationDataDeletionStatus.notificationCleanupPending,
    );
  }

  Future<bool> retryNotificationCleanup() {
    return _notifications.cancelAll();
  }
}
