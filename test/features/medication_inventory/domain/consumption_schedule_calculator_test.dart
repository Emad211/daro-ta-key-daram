import 'package:daro_ta_key_daram/features/medication_inventory/domain/consumption_schedule.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/consumption_schedule_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime baseline = DateTime.utc(2026, 7, 1, 8);

  group('daily schedule', () {
    final DailyConsumptionSchedule schedule = DailyConsumptionSchedule(
      amountPerOccurrence: 0.5,
      occurrencesPerDay: 2,
    );

    test('places multiple daily occurrences evenly after the baseline', () {
      expect(
        ConsumptionScheduleCalculator.occurrenceAt(
          schedule: schedule,
          baseline: baseline,
          occurrenceNumber: 1,
        ),
        baseline.add(const Duration(hours: 12)),
      );
      expect(
        ConsumptionScheduleCalculator.occurrenceAt(
          schedule: schedule,
          baseline: baseline,
          occurrenceNumber: 2,
        ),
        baseline.add(const Duration(days: 1)),
      );
    });

    test('supports fractional amounts and exact occurrence boundaries', () {
      final ConsumptionScheduleProjection before =
          ConsumptionScheduleCalculator.project(
            schedule: schedule,
            baseline: baseline,
            stockAtBaseline: 2,
            now: baseline.add(const Duration(hours: 12, microseconds: -1)),
          );
      final ConsumptionScheduleProjection atFirst =
          ConsumptionScheduleCalculator.project(
            schedule: schedule,
            baseline: baseline,
            stockAtBaseline: 2,
            now: baseline.add(const Duration(hours: 12)),
          );

      expect(before.estimatedRemainingUnits, 2);
      expect(before.completedOccurrences, 0);
      expect(atFirst.estimatedRemainingUnits, 1.5);
      expect(atFirst.completedOccurrences, 1);
      expect(atFirst.depletionAt, baseline.add(const Duration(days: 2)));
    });
  });

  group('every-N-days schedule', () {
    final EveryNDaysConsumptionSchedule schedule =
        EveryNDaysConsumptionSchedule(amountPerOccurrence: 1, intervalDays: 2);

    test('keeps stock unchanged between discrete occurrences', () {
      final ConsumptionScheduleProjection dayOne =
          ConsumptionScheduleCalculator.project(
            schedule: schedule,
            baseline: baseline,
            stockAtBaseline: 3,
            now: baseline.add(const Duration(days: 1)),
          );
      final ConsumptionScheduleProjection dayTwo =
          ConsumptionScheduleCalculator.project(
            schedule: schedule,
            baseline: baseline,
            stockAtBaseline: 3,
            now: baseline.add(const Duration(days: 2)),
          );
      final ConsumptionScheduleProjection dayThree =
          ConsumptionScheduleCalculator.project(
            schedule: schedule,
            baseline: baseline,
            stockAtBaseline: 3,
            now: baseline.add(const Duration(days: 3)),
          );

      expect(dayOne.estimatedRemainingUnits, 3);
      expect(dayTwo.estimatedRemainingUnits, 2);
      expect(dayThree.estimatedRemainingUnits, 2);
      expect(dayThree.depletionAt, baseline.add(const Duration(days: 6)));
    });

    test(
      'marks partial stock depleted at the first unsatisfied occurrence',
      () {
        final ConsumptionScheduleProjection before =
            ConsumptionScheduleCalculator.project(
              schedule: schedule,
              baseline: baseline,
              stockAtBaseline: 0.5,
              now: baseline.add(const Duration(days: 1)),
            );
        final ConsumptionScheduleProjection atOccurrence =
            ConsumptionScheduleCalculator.project(
              schedule: schedule,
              baseline: baseline,
              stockAtBaseline: 0.5,
              now: baseline.add(const Duration(days: 2)),
            );

        expect(before.estimatedRemainingUnits, 0.5);
        expect(atOccurrence.estimatedRemainingUnits, 0);
        expect(atOccurrence.depletionAt, baseline.add(const Duration(days: 2)));
      },
    );
  });

  group('selected weekdays schedule', () {
    final WeeklyConsumptionSchedule schedule = WeeklyConsumptionSchedule(
      amountPerOccurrence: 1,
      weekdays: <int>{DateTime.monday, DateTime.friday},
    );

    test('orders multiple weekdays across week boundaries', () {
      expect(baseline.weekday, DateTime.wednesday);
      expect(
        ConsumptionScheduleCalculator.occurrenceAt(
          schedule: schedule,
          baseline: baseline,
          occurrenceNumber: 1,
        ),
        DateTime.utc(2026, 7, 3, 8),
      );
      expect(
        ConsumptionScheduleCalculator.occurrenceAt(
          schedule: schedule,
          baseline: baseline,
          occurrenceNumber: 2,
        ),
        DateTime.utc(2026, 7, 6, 8),
      );
      expect(
        ConsumptionScheduleCalculator.occurrenceAt(
          schedule: schedule,
          baseline: baseline,
          occurrenceNumber: 3,
        ),
        DateTime.utc(2026, 7, 10, 8),
      );
    });

    test('does not count the baseline weekday itself as an occurrence', () {
      final DateTime fridayBaseline = DateTime.utc(2026, 7, 3, 8);
      final WeeklyConsumptionSchedule fridayOnly = WeeklyConsumptionSchedule(
        amountPerOccurrence: 1,
        weekdays: <int>{DateTime.friday},
      );

      expect(
        ConsumptionScheduleCalculator.occurrenceAt(
          schedule: fridayOnly,
          baseline: fridayBaseline,
          occurrenceNumber: 1,
        ),
        DateTime.utc(2026, 7, 10, 8),
      );
    });
  });

  test('never consumes before the inventory baseline', () {
    final ConsumptionScheduleProjection projection =
        ConsumptionScheduleCalculator.project(
          schedule: EveryNDaysConsumptionSchedule(
            amountPerOccurrence: 1,
            intervalDays: 2,
          ),
          baseline: baseline,
          stockAtBaseline: 4,
          now: baseline.subtract(const Duration(days: 20)),
        );

    expect(projection.estimatedRemainingUnits, 4);
    expect(projection.completedOccurrences, 0);
  });

  test('rejects invalid stock and occurrence numbers', () {
    final ConsumptionSchedule schedule = DailyConsumptionSchedule(
      amountPerOccurrence: 1,
      occurrencesPerDay: 1,
    );

    expect(
      () => ConsumptionScheduleCalculator.project(
        schedule: schedule,
        baseline: baseline,
        stockAtBaseline: -1,
        now: baseline,
      ),
      throwsArgumentError,
    );
    expect(
      () => ConsumptionScheduleCalculator.occurrenceAt(
        schedule: schedule,
        baseline: baseline,
        occurrenceNumber: 0,
      ),
      throwsRangeError,
    );
  });
}
