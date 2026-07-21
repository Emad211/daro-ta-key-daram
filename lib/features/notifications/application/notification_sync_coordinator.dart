import '../../medication_inventory/application/medication_repository.dart';
import '../../medication_inventory/domain/medication.dart';
import '../domain/low_stock_notification_planner.dart';
import '../domain/notification_id.dart';
import '../domain/notification_plan.dart';
import 'local_notification_service.dart';

final class NotificationSyncCoordinator {
  NotificationSyncCoordinator({
    required this._medicationRepository,
    required this._notificationService,
    required this._clock,
    LowStockNotificationPlanner? planner,
  }) : _planner = planner ?? LowStockNotificationPlanner();

  final MedicationRepository _medicationRepository;
  final LocalNotificationService _notificationService;
  final DateTime Function() _clock;
  final LowStockNotificationPlanner _planner;

  Future<bool> rescheduleMedication(String medicationId) async {
    try {
      final Medication? medication = await _medicationRepository.findById(
        medicationId,
      );
      if (medication == null || medication.isArchived) {
        return cancelMedication(medicationId);
      }

      final NotificationPlan? plan = _planner.plan(
        medication: medication,
        now: _clock(),
      );
      if (plan == null) {
        return cancelMedication(medicationId);
      }

      await _notificationService.schedule(plan);
      return true;
    } on Object {
      return false;
    }
  }

  Future<bool> cancelMedication(String medicationId) async {
    try {
      await _notificationService.cancel(
        NotificationId.forMedication(medicationId),
      );
      return true;
    } on Object {
      return false;
    }
  }

  Future<bool> cancelAll() async {
    try {
      await _notificationService.cancelAll();
      return true;
    } on Object {
      return false;
    }
  }

  Future<int> rebuildAll() async {
    final List<Medication> medications = await _medicationRepository
        .watchActiveMedications()
        .first;
    int successfulSchedules = 0;

    for (final Medication medication in medications) {
      if (await rescheduleMedication(medication.id)) {
        successfulSchedules += 1;
      }
    }
    return successfulSchedules;
  }
}
