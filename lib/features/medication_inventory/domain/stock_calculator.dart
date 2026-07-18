import 'dart:math' as math;

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
    final double totalCoverageDays = _totalCoverageDays(medication);
    final DateTime depletionAt = _depletionAt(
      baseline: baseline,
      totalCoverageDays: totalCoverageDays,
      stockAtRecord: medication.stockAtRecord,
    );

    final bool depletedByTime = !depletionAt.isAfter(effectiveNow);
    final double remainingUnits;
    final double exactRemainingDays;

    if (depletedByTime || medication.stockAtRecord == 0) {
      remainingUnits = 0;
      exactRemainingDays = 0;
    } else {
      final int elapsedMicroseconds = effectiveNow
          .difference(baseline)
          .inMicroseconds;
      final double elapsedDays =
          elapsedMicroseconds / Duration.microsecondsPerDay;
      final double consumedUnits = elapsedDays * medication.unitsPerDay;
      remainingUnits = math.max(0.0, medication.stockAtRecord - consumedUnits);
      exactRemainingDays = remainingUnits / medication.unitsPerDay;
    }

    final bool isDepleted = depletedByTime || remainingUnits <= 0;
    final DateTime reorderAt = medication.alertLeadDays >= totalCoverageDays
        ? baseline
        : depletionAt.subtract(Duration(days: medication.alertLeadDays));

    return MedicationStockSnapshot(
      estimatedRemainingUnits: remainingUnits,
      exactRemainingDays: exactRemainingDays,
      fullRemainingDays: exactRemainingDays.floor(),
      depletionAt: depletionAt,
      reorderAt: reorderAt,
      urgency: _resolveUrgency(
        isDepleted: isDepleted,
        remainingDays: exactRemainingDays,
        warningThresholdDays: medication.alertLeadDays,
      ),
    );
  }

  static double _totalCoverageDays(Medication medication) {
    final double coverageDays =
        medication.stockAtRecord / medication.unitsPerDay;
    final double coverageMicroseconds =
        coverageDays * Duration.microsecondsPerDay;

    if (!coverageDays.isFinite || !coverageMicroseconds.isFinite) {
      throw ArgumentError.value(
        coverageDays,
        'coverageDays',
        'The medication coverage cannot be represented safely.',
      );
    }

    return coverageDays;
  }

  static DateTime _depletionAt({
    required DateTime baseline,
    required double totalCoverageDays,
    required double stockAtRecord,
  }) {
    final double coverageMicroseconds =
        totalCoverageDays * Duration.microsecondsPerDay;
    final int roundedCoverageMicroseconds = coverageMicroseconds.round();

    try {
      return baseline.add(Duration(microseconds: roundedCoverageMicroseconds));
    } on ArgumentError {
      throw ArgumentError.value(
        stockAtRecord,
        'stockAtRecord',
        'The resulting depletion date is outside the supported range.',
      );
    }
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
