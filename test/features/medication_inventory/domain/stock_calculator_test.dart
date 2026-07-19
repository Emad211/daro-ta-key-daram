import 'package:daro_ta_key_daram/features/medication_inventory/domain/consumption_schedule.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_stock_snapshot.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/stock_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StockCalculator with structured schedules', () {
    final DateTime baseline = DateTime.utc(2026, 7, 1, 8);

    test('daily multiple occurrences keep stock and time consistent', () {
      final Medication medication = _medication(
        baseline: baseline,
        stock: 4,
        schedule: DailyConsumptionSchedule(
          amountPerOccurrence: 1,
          occurrencesPerDay: 2,
        ),
      );

      final MedicationStockSnapshot initial = medication.stockAt(baseline);
      final MedicationStockSnapshot afterFirst = medication.stockAt(
        baseline.add(const Duration(hours: 12)),
      );

      expect(initial.estimatedRemainingUnits, 4);
      expect(initial.exactRemainingDays, 2);
      expect(initial.fullRemainingDays, 2);
      expect(initial.depletionAt, baseline.add(const Duration(days: 2)));
      expect(afterFirst.estimatedRemainingUnits, 3);
      expect(afterFirst.exactRemainingDays, 1.5);
      expect(afterFirst.fullRemainingDays, 1);
    });

    test('every-other-day stock remains discrete between occurrences', () {
      final Medication medication = _medication(
        baseline: baseline,
        stock: 3,
        schedule: EveryNDaysConsumptionSchedule(
          amountPerOccurrence: 1,
          intervalDays: 2,
        ),
      );

      final MedicationStockSnapshot dayOne = medication.stockAt(
        baseline.add(const Duration(days: 1)),
      );
      final MedicationStockSnapshot dayTwo = medication.stockAt(
        baseline.add(const Duration(days: 2)),
      );
      final MedicationStockSnapshot dayThree = medication.stockAt(
        baseline.add(const Duration(days: 3)),
      );

      expect(dayOne.estimatedRemainingUnits, 3);
      expect(dayTwo.estimatedRemainingUnits, 2);
      expect(dayThree.estimatedRemainingUnits, 2);
      expect(dayThree.exactRemainingDays, 3);
      expect(dayThree.depletionAt, baseline.add(const Duration(days: 6)));
    });

    test('weekly schedule uses selected weekdays rather than a daily average', () {
      final Medication medication = _medication(
        baseline: baseline,
        stock: 3,
        schedule: WeeklyConsumptionSchedule(
          amountPerOccurrence: 1,
          weekdays: <int>{DateTime.monday, DateTime.friday},
        ),
      );

      final MedicationStockSnapshot thursday = medication.stockAt(
        DateTime.utc(2026, 7, 2, 8),
      );
      final MedicationStockSnapshot friday = medication.stockAt(
        DateTime.utc(2026, 7, 3, 8),
      );

      expect(thursday.estimatedRemainingUnits, 3);
      expect(friday.estimatedRemainingUnits, 2);
      expect(friday.depletionAt, DateTime.utc(2026, 7, 10, 8));
    });

    test('partial stock becomes depleted at an unsatisfied occurrence', () {
      final Medication medication = _medication(
        baseline: baseline,
        stock: 0.5,
        schedule: EveryNDaysConsumptionSchedule(
          amountPerOccurrence: 1,
          intervalDays: 2,
        ),
      );

      final MedicationStockSnapshot before = medication.stockAt(
        baseline.add(const Duration(days: 1)),
      );
      final MedicationStockSnapshot atOccurrence = medication.stockAt(
        baseline.add(const Duration(days: 2)),
      );

      expect(before.estimatedRemainingUnits, 0.5);
      expect(before.urgency, MedicationUrgency.critical);
      expect(atOccurrence.estimatedRemainingUnits, 0);
      expect(atOccurrence.exactRemainingDays, 0);
      expect(atOccurrence.urgency, MedicationUrgency.depleted);
    });

    test('warning and critical boundaries use time until depletion', () {
      final Medication medication = _medication(
        baseline: baseline,
        stock: 10,
        alertLeadDays: 7,
        schedule: DailyConsumptionSchedule(
          amountPerOccurrence: 1,
          occurrencesPerDay: 1,
        ),
      );

      expect(medication.stockAt(baseline).urgency, MedicationUrgency.safe);
      expect(
        medication.stockAt(baseline.add(const Duration(days: 3))).urgency,
        MedicationUrgency.warning,
      );
      expect(
        medication.stockAt(baseline.add(const Duration(days: 7))).urgency,
        MedicationUrgency.critical,
      );
      expect(StockCalculator.criticalThresholdDays, 3);
    });

    test('reorder time is clamped to the inventory baseline', () {
      final Medication medication = _medication(
        baseline: baseline,
        stock: 1,
        alertLeadDays: 30,
        schedule: WeeklyConsumptionSchedule(
          amountPerOccurrence: 1,
          weekdays: <int>{DateTime.friday},
        ),
      );

      final MedicationStockSnapshot snapshot = medication.stockAt(baseline);

      expect(snapshot.reorderAt, baseline);
      expect(snapshot.reorderAt.isAfter(snapshot.depletionAt), isFalse);
    });

    test('zero stock is depleted immediately', () {
      final Medication medication = _medication(
        baseline: baseline,
        stock: 0,
        schedule: DailyConsumptionSchedule(
          amountPerOccurrence: 1,
          occurrencesPerDay: 1,
        ),
      );

      final MedicationStockSnapshot snapshot = medication.stockAt(baseline);

      expect(snapshot.estimatedRemainingUnits, 0);
      expect(snapshot.exactRemainingDays, 0);
      expect(snapshot.depletionAt, baseline);
      expect(snapshot.reorderAt, baseline);
      expect(snapshot.urgency, MedicationUrgency.depleted);
    });

    test('time before the baseline does not consume stock', () {
      final Medication medication = _medication(
        baseline: baseline,
        stock: 4,
        schedule: EveryNDaysConsumptionSchedule(
          amountPerOccurrence: 1,
          intervalDays: 2,
        ),
      );

      final MedicationStockSnapshot snapshot = medication.stockAt(
        baseline.subtract(const Duration(days: 50)),
      );

      expect(snapshot.estimatedRemainingUnits, 4);
      expect(snapshot.depletionAt, baseline.add(const Duration(days: 8)));
    });

    test('remaining stock is finite, non-negative and monotonic', () {
      final Medication medication = _medication(
        baseline: baseline,
        stock: 12.5,
        schedule: WeeklyConsumptionSchedule(
          amountPerOccurrence: 0.5,
          weekdays: <int>{
            DateTime.monday,
            DateTime.wednesday,
            DateTime.friday,
          },
        ),
      );
      double previous = double.infinity;

      for (int hours = -24; hours <= 24 * 90; hours += 3) {
        final MedicationStockSnapshot snapshot = medication.stockAt(
          baseline.add(Duration(hours: hours)),
        );
        expect(snapshot.estimatedRemainingUnits.isFinite, isTrue);
        expect(snapshot.exactRemainingDays.isFinite, isTrue);
        expect(snapshot.estimatedRemainingUnits, greaterThanOrEqualTo(0));
        expect(snapshot.exactRemainingDays, greaterThanOrEqualTo(0));
        expect(
          snapshot.estimatedRemainingUnits,
          lessThanOrEqualTo(previous + 1e-12),
        );
        expect(snapshot.fullRemainingDays, snapshot.exactRemainingDays.floor());
        expect(snapshot.reorderAt.isBefore(baseline), isFalse);
        expect(snapshot.reorderAt.isAfter(snapshot.depletionAt), isFalse);
        previous = snapshot.estimatedRemainingUnits;
      }
    });
  });
}

Medication _medication({
  required DateTime baseline,
  required double stock,
  required ConsumptionSchedule schedule,
  int alertLeadDays = 5,
}) {
  return Medication(
    id: 'medication-1',
    name: 'Test medication',
    unit: MedicationUnit.tablet,
    stockAtRecord: stock,
    consumptionSchedule: schedule,
    inventoryRecordedAt: baseline,
    alertLeadDays: alertLeadDays,
  );
}
