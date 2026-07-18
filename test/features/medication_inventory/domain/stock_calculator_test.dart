import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_stock_snapshot.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/stock_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StockCalculator', () {
    final DateTime recordedAt = DateTime.utc(2026, 7, 18, 8);

    test('calculates 15 full days for 30 tablets at 2 per day', () {
      final Medication medication = _medication(
        id: 'm1',
        stockAtRecord: 30,
        unitsPerDay: 2,
        recordedAt: recordedAt,
      );

      final MedicationStockSnapshot snapshot = medication.stockAt(recordedAt);

      expect(snapshot.estimatedRemainingUnits, 30);
      expect(snapshot.exactRemainingDays, 15);
      expect(snapshot.fullRemainingDays, 15);
      expect(snapshot.depletionAt, DateTime.utc(2026, 8, 2, 8));
      expect(snapshot.reorderAt, DateTime.utc(2026, 7, 28, 8));
      expect(snapshot.urgency, MedicationUrgency.safe);
    });

    test('uses sub-minute precision for partial-day coverage', () {
      final Medication medication = _medication(
        id: 'sub-minute',
        stockAtRecord: 1,
        unitsPerDay: 2880,
        recordedAt: recordedAt,
      );

      final MedicationStockSnapshot initial = medication.stockAt(recordedAt);
      final MedicationStockSnapshot halfway = medication.stockAt(
        recordedAt.add(const Duration(seconds: 15)),
      );

      expect(initial.depletionAt, recordedAt.add(const Duration(seconds: 30)));
      expect(halfway.estimatedRemainingUnits, closeTo(0.5, 1e-12));
      expect(
        halfway.exactRemainingDays,
        closeTo(15 / Duration.secondsPerDay, 1e-12),
      );
    });

    test('does not round exact days across a full-day boundary', () {
      final Medication medication = _medication(
        id: 'rounding-boundary',
        stockAtRecord: 2,
        unitsPerDay: 1,
        recordedAt: recordedAt,
      );
      final DateTime now = recordedAt.add(
        const Duration(days: 1, seconds: 34, milliseconds: 560),
      );

      final MedicationStockSnapshot snapshot = medication.stockAt(now);

      expect(snapshot.exactRemainingDays, closeTo(0.9996, 1e-12));
      expect(snapshot.fullRemainingDays, 0);
    });

    test('never returns negative values at or after depletion', () {
      final Medication medication = _medication(
        id: 'depletion-boundary',
        stockAtRecord: 10,
        unitsPerDay: 2,
        recordedAt: recordedAt,
      );
      final DateTime depletionAt = medication.stockAt(recordedAt).depletionAt;

      final MedicationStockSnapshot justBefore = medication.stockAt(
        depletionAt.subtract(const Duration(microseconds: 1)),
      );
      final MedicationStockSnapshot atDepletion = medication.stockAt(
        depletionAt,
      );
      final MedicationStockSnapshot afterDepletion = medication.stockAt(
        depletionAt.add(const Duration(days: 10)),
      );

      expect(justBefore.estimatedRemainingUnits, greaterThan(0));
      expect(justBefore.urgency, MedicationUrgency.critical);
      for (final MedicationStockSnapshot snapshot in <MedicationStockSnapshot>[
        atDepletion,
        afterDepletion,
      ]) {
        expect(snapshot.estimatedRemainingUnits, 0);
        expect(snapshot.exactRemainingDays, 0);
        expect(snapshot.fullRemainingDays, 0);
        expect(snapshot.urgency, MedicationUrgency.depleted);
      }
    });

    test('supports fractional daily use', () {
      final Medication medication = _medication(
        id: 'weekly',
        stockAtRecord: 4,
        unitsPerDay: 1 / 7,
        recordedAt: recordedAt,
        alertLeadDays: 7,
      );

      final MedicationStockSnapshot snapshot = medication.stockAt(recordedAt);

      expect(snapshot.exactRemainingDays, closeTo(28, 1e-12));
      expect(snapshot.depletionAt, DateTime.utc(2026, 8, 15, 8));
      expect(snapshot.reorderAt, DateTime.utc(2026, 8, 8, 8));
    });

    test('does not consume stock when device time is before record time', () {
      final Medication medication = _medication(
        id: 'clock-test',
        stockAtRecord: 10,
        unitsPerDay: 1,
        recordedAt: recordedAt,
      );

      final MedicationStockSnapshot snapshot = medication.stockAt(
        recordedAt.subtract(const Duration(days: 2)),
      );

      expect(snapshot.estimatedRemainingUnits, 10);
      expect(snapshot.exactRemainingDays, 10);
      expect(snapshot.depletionAt, recordedAt.add(const Duration(days: 10)));
    });

    test('clamps reorder time to the inventory baseline', () {
      final Medication medication = _medication(
        id: 'short-coverage',
        stockAtRecord: 2,
        unitsPerDay: 1,
        recordedAt: recordedAt,
        alertLeadDays: 5,
      );

      final MedicationStockSnapshot snapshot = medication.stockAt(recordedAt);

      expect(snapshot.reorderAt, recordedAt);
      expect(snapshot.reorderAt.isAfter(snapshot.depletionAt), isFalse);
    });

    test('applies warning and critical thresholds at exact boundaries', () {
      final Medication medication = _medication(
        id: 'urgency-thresholds',
        stockAtRecord: 10,
        unitsPerDay: 1,
        recordedAt: recordedAt,
        alertLeadDays: 7,
      );

      expect(medication.stockAt(recordedAt).urgency, MedicationUrgency.safe);
      expect(
        medication.stockAt(recordedAt.add(const Duration(days: 3))).urgency,
        MedicationUrgency.warning,
      );
      expect(
        medication
            .stockAt(
              recordedAt
                  .add(const Duration(days: 7))
                  .subtract(const Duration(microseconds: 1)),
            )
            .urgency,
        MedicationUrgency.warning,
      );
      expect(
        medication.stockAt(recordedAt.add(const Duration(days: 7))).urgency,
        MedicationUrgency.critical,
      );
      expect(StockCalculator.criticalThresholdDays, 3);
    });

    test('zero stock is depleted immediately with a safe reorder bound', () {
      final Medication medication = _medication(
        id: 'zero-stock',
        stockAtRecord: 0,
        unitsPerDay: 1,
        recordedAt: recordedAt,
        alertLeadDays: 30,
      );

      final MedicationStockSnapshot snapshot = medication.stockAt(recordedAt);

      expect(snapshot.estimatedRemainingUnits, 0);
      expect(snapshot.exactRemainingDays, 0);
      expect(snapshot.depletionAt, recordedAt);
      expect(snapshot.reorderAt, recordedAt);
      expect(snapshot.urgency, MedicationUrgency.depleted);
    });

    test('remaining stock is finite, non-negative, and monotonic', () {
      final Medication medication = _medication(
        id: 'monotonic',
        stockAtRecord: 100.5,
        unitsPerDay: 2.75,
        recordedAt: recordedAt,
        alertLeadDays: 9,
      );
      double previousUnits = double.infinity;
      double previousDays = double.infinity;

      for (int hours = -24; hours <= 24 * 50; hours += 3) {
        final MedicationStockSnapshot snapshot = medication.stockAt(
          recordedAt.add(Duration(hours: hours)),
        );

        expect(snapshot.estimatedRemainingUnits.isFinite, isTrue);
        expect(snapshot.exactRemainingDays.isFinite, isTrue);
        expect(snapshot.estimatedRemainingUnits, greaterThanOrEqualTo(0));
        expect(snapshot.exactRemainingDays, greaterThanOrEqualTo(0));
        expect(
          snapshot.estimatedRemainingUnits,
          lessThanOrEqualTo(previousUnits + 1e-10),
        );
        expect(
          snapshot.exactRemainingDays,
          lessThanOrEqualTo(previousDays + 1e-10),
        );
        expect(snapshot.fullRemainingDays, snapshot.exactRemainingDays.floor());
        expect(snapshot.reorderAt.isBefore(recordedAt), isFalse);
        expect(snapshot.reorderAt.isAfter(snapshot.depletionAt), isFalse);

        previousUnits = snapshot.estimatedRemainingUnits;
        previousDays = snapshot.exactRemainingDays;
      }
    });

    test('rejects invalid stock and daily-use inputs', () {
      for (final double invalidStock in <double>[
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _medication(
            id: 'invalid-stock-$invalidStock',
            stockAtRecord: invalidStock,
            unitsPerDay: 1,
            recordedAt: recordedAt,
          ),
          throwsArgumentError,
        );
      }

      for (final double invalidDailyUse in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _medication(
            id: 'invalid-use-$invalidDailyUse',
            stockAtRecord: 10,
            unitsPerDay: invalidDailyUse,
            recordedAt: recordedAt,
          ),
          throwsArgumentError,
        );
      }
    });

    test('rejects coverage that cannot be represented safely', () {
      final Medication medication = _medication(
        id: 'overflow',
        stockAtRecord: 1e300,
        unitsPerDay: 1e-300,
        recordedAt: recordedAt,
      );

      expect(() => medication.stockAt(recordedAt), throwsArgumentError);
    });
  });
}

Medication _medication({
  required String id,
  required double stockAtRecord,
  required double unitsPerDay,
  required DateTime recordedAt,
  int alertLeadDays = 5,
}) {
  return Medication(
    id: id,
    name: 'Test medication',
    unit: MedicationUnit.tablet,
    stockAtRecord: stockAtRecord,
    unitsPerDay: unitsPerDay,
    inventoryRecordedAt: recordedAt,
    alertLeadDays: alertLeadDays,
  );
}
