import 'consumption_schedule_calculator.dart';
import 'medication.dart';
import 'medication_stock_snapshot.dart';

abstract final class StockCalculator {
  static const int criticalThresholdDays = 3;

  static MedicationStockSnapshot calculate({
    required Medication medication,
    required DateTime now,
  }) {
    final DateTime baseline = medication.inventoryRecordedAt;
    final DateTime effectiveNow = now.isBefore(baseline) ? baseline : now;
    final ConsumptionScheduleProjection projection =
        ConsumptionScheduleCalculator.project(
          schedule: medication.consumptionSchedule,
          baseline: baseline,
          stockAtBaseline: medication.stockAtRecord,
          now: effectiveNow,
        );
    final bool isDepleted =
        !projection.depletionAt.isAfter(effectiveNow) ||
        projection.estimatedRemainingUnits <= 0;
    final double exactRemainingDays = isDepleted
        ? 0
        : projection.depletionAt.difference(effectiveNow).inMicroseconds /
              Duration.microsecondsPerDay;
    final DateTime reorderCandidate = projection.depletionAt.subtract(
      Duration(days: medication.alertLeadDays),
    );
    final DateTime reorderAt = reorderCandidate.isBefore(baseline)
        ? baseline
        : reorderCandidate;

    return MedicationStockSnapshot(
      estimatedRemainingUnits: projection.estimatedRemainingUnits,
      exactRemainingDays: exactRemainingDays,
      fullRemainingDays: exactRemainingDays.floor(),
      depletionAt: projection.depletionAt,
      reorderAt: reorderAt,
      urgency: _resolveUrgency(
        isDepleted: isDepleted,
        remainingDays: exactRemainingDays,
        warningThresholdDays: medication.alertLeadDays,
      ),
    );
  }

  static MedicationUrgency _resolveUrgency({
    required bool isDepleted,
    required double remainingDays,
    required int warningThresholdDays,
  }) {
    if (isDepleted) {
      return MedicationUrgency.depleted;
    }
    if (remainingDays <= criticalThresholdDays) {
      return MedicationUrgency.critical;
    }
    if (remainingDays <= warningThresholdDays) {
      return MedicationUrgency.warning;
    }
    return MedicationUrgency.safe;
  }
}
