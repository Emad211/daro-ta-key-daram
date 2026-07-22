import 'dart:async';

import '../../medication_inventory/application/medication_repository.dart';
import '../../medication_inventory/domain/medication.dart';
import '../domain/low_stock_notification_planner.dart';
import '../domain/notification_id.dart';
import '../domain/notification_plan.dart';
import 'local_notification_service.dart';

final class NotificationSyncCoordinator {
  factory NotificationSyncCoordinator({
    required MedicationRepository medicationRepository,
    required LocalNotificationService notificationService,
    required DateTime Function() clock,
    LowStockNotificationPlanner? planner,
  }) {
    return NotificationSyncCoordinator._(
      medicationRepository,
      notificationService,
      clock,
      planner ?? LowStockNotificationPlanner(),
    );
  }

  NotificationSyncCoordinator._(
    this._medicationRepository,
    this._notificationService,
    this._clock,
    this._planner,
  );

  final MedicationRepository _medicationRepository;
  final LocalNotificationService _notificationService;
  final DateTime Function() _clock;
  final LowStockNotificationPlanner _planner;
  Future<void> _operationTail = Future<void>.value();

  Future<bool> rescheduleMedication(String medicationId) {
    return _runSerialized<bool>(
      () => _rescheduleMedicationUnlocked(medicationId),
    );
  }

  Future<bool> cancelMedication(String medicationId) {
    return _runSerialized<bool>(() => _cancelMedicationUnlocked(medicationId));
  }

  Future<bool> cancelAll() {
    return _runSerialized<bool>(() async {
      try {
        await _notificationService.cancelAll();
        return true;
      } on Object {
        return false;
      }
    });
  }

  Future<int> rebuildAll() {
    return _runSerialized<int>(() async {
      final List<Medication> medications = await _medicationRepository
          .watchActiveMedications()
          .first;
      int successfulSchedules = 0;

      for (final Medication medication in medications) {
        if (await _rescheduleMedicationUnlocked(medication.id)) {
          successfulSchedules += 1;
        }
      }
      return successfulSchedules;
    });
  }

  Future<bool> _rescheduleMedicationUnlocked(String medicationId) async {
    try {
      final Medication? medication = await _medicationRepository.findById(
        medicationId,
      );
      if (medication == null || medication.isArchived) {
        return _cancelMedicationUnlocked(medicationId);
      }

      final NotificationPlan? plan = _planner.plan(
        medication: medication,
        now: _clock(),
      );
      if (plan == null) {
        return _cancelMedicationUnlocked(medicationId);
      }

      await _notificationService.schedule(plan);
      return true;
    } on Object {
      return false;
    }
  }

  Future<bool> _cancelMedicationUnlocked(String medicationId) async {
    try {
      await _notificationService.cancel(
        NotificationId.forMedication(medicationId),
      );
      return true;
    } on Object {
      return false;
    }
  }

  Future<T> _runSerialized<T>(Future<T> Function() operation) {
    final Completer<T> result = Completer<T>();
    _operationTail = _operationTail.then<void>((void _) async {
      try {
        result.complete(await operation());
      } on Object catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }
}
