import 'dart:math' as math;

import 'medication.dart';
import 'medication_stock_snapshot.dart';

abstract final class StockCalculator {
  static const double _minutesPerDay = 24 * 60.0;

  static MedicationStockSnapshot calculate({
    required Medication medication,
    required DateTime now,
  }) {
    final double elapsedMinutes = math.max(
      0.0,
      now.difference(medication.inventoryRecordedAt).inSeconds / 60,
    );
    final double elapsedDays = elapsedMinutes / _minutesPerDay;

    final double consumedUnits = elapsedDays * medication.unitsPerDay;
    final double remainingUnits = math.max(
      0.0,
      medication.stockAtRecord - consumedUnits,
    );
    final double remainingDays = remainingUnits / medication.unitsPerDay;

    final double totalCoverageMinutes =
        medication.stockAtRecord / medication.unitsPerDay * _minutesPerDay;
    final DateTime depletionAt = medication.inventoryRecordedAt.add(
      Duration(minutes: totalCoverageMinutes.round()),
    );
    final DateTime reorderAt = depletionAt.subtract(
      Duration(days: medication.alertLeadDays),
    );

    final MedicationUrgency urgency = _resolveUrgency(
      remainingUnits: remainingUnits,
      remainingDays: remainingDays,
      warningThresholdDays: medication.alertLeadDays,
    );

    return MedicationStockSnapshot(
      estimatedRemainingUnits: _normalize(remainingUnits),
      exactRemainingDays: _normalize(remainingDays),
      fullRemainingDays: remainingDays.floor(),
      depletionAt: depletionAt,
      reorderAt: reorderAt,
      urgency: urgency,
    );
  }

  static MedicationUrgency _resolveUrgency({
    required double remainingUnits,
    required double remainingDays,
    required int warningThresholdDays,
  }) {
    if (remainingUnits <= 0) {
      return MedicationUrgency.depleted;
    }
    if (remainingDays <= 3) {
      return MedicationUrgency.critical;
    }
    if (remainingDays <= warningThresholdDays) {
      return MedicationUrgency.warning;
    }
    return MedicationUrgency.safe;
  }

  static double _normalize(double value) {
    return double.parse(value.toStringAsFixed(3));
  }
}
