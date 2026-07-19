import 'package:daro_ta_key_daram/features/medication_inventory/domain/consumption_schedule.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/consumption_schedule_codec.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/consumption_schedule_formatter.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsumptionSchedule', () {
    test('daily schedule derives the average without losing structure', () {
      final DailyConsumptionSchedule schedule = DailyConsumptionSchedule(
        amountPerOccurrence: 0.5,
        occurrencesPerDay: 3,
      );

      expect(schedule.averageUnitsPerDay, 1.5);
      expect(schedule.kind, ConsumptionScheduleKind.daily);
      expect(
        ConsumptionScheduleFormatter.describe(
          schedule,
          MedicationUnit.tablet,
        ),
        '0.5 قرص × 3 نوبت در روز',
      );
    });

    test('every-N-days and weekly schedules derive only a compatibility rate', () {
      final EveryNDaysConsumptionSchedule everyOtherDay =
          EveryNDaysConsumptionSchedule(
            amountPerOccurrence: 1,
            intervalDays: 2,
          );
      final WeeklyConsumptionSchedule weekly = WeeklyConsumptionSchedule(
        amountPerOccurrence: 1,
        weekdays: <int>{DateTime.monday, DateTime.friday},
      );

      expect(everyOtherDay.averageUnitsPerDay, 0.5);
      expect(weekly.averageUnitsPerDay, closeTo(2 / 7, 1e-12));
      expect(
        ConsumptionScheduleFormatter.describe(
          everyOtherDay,
          MedicationUnit.capsule,
        ),
        '1 کپسول هر 2 روز یک‌بار',
      );
      expect(
        ConsumptionScheduleFormatter.describe(
          weekly,
          MedicationUnit.capsule,
        ),
        '1 کپسول در دوشنبه، جمعه',
      );
    });

    test('weekly weekdays are normalized and immutable', () {
      final WeeklyConsumptionSchedule schedule = WeeklyConsumptionSchedule(
        amountPerOccurrence: 1,
        weekdays: <int>[
          DateTime.friday,
          DateTime.monday,
          DateTime.friday,
        ],
      );

      expect(schedule.weekdays, <int>[DateTime.monday, DateTime.friday]);
      expect(
        () => schedule.weekdays.add(DateTime.sunday),
        throwsUnsupportedError,
      );
    });

    test('rejects invalid amounts, frequencies, intervals and weekdays', () {
      for (final double amount in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => DailyConsumptionSchedule(
            amountPerOccurrence: amount,
            occurrencesPerDay: 1,
          ),
          throwsArgumentError,
        );
      }

      expect(
        () => DailyConsumptionSchedule(
          amountPerOccurrence: 1,
          occurrencesPerDay: 0,
        ),
        throwsRangeError,
      );
      expect(
        () => EveryNDaysConsumptionSchedule(
          amountPerOccurrence: 1,
          intervalDays: 366,
        ),
        throwsRangeError,
      );
      expect(
        () => WeeklyConsumptionSchedule(
          amountPerOccurrence: 1,
          weekdays: const <int>{},
        ),
        throwsArgumentError,
      );
      expect(
        () => WeeklyConsumptionSchedule(
          amountPerOccurrence: 1,
          weekdays: const <int>{8},
        ),
        throwsRangeError,
      );
    });
  });

  group('ConsumptionScheduleCodec', () {
    final List<ConsumptionSchedule> schedules = <ConsumptionSchedule>[
      DailyConsumptionSchedule(
        amountPerOccurrence: 0.5,
        occurrencesPerDay: 2,
      ),
      EveryNDaysConsumptionSchedule(
        amountPerOccurrence: 1.25,
        intervalDays: 3,
      ),
      WeeklyConsumptionSchedule(
        amountPerOccurrence: 1,
        weekdays: <int>{DateTime.saturday, DateTime.wednesday},
      ),
    ];

    for (final ConsumptionSchedule schedule in schedules) {
      test('round-trips ${schedule.kind.name}', () {
        final String encoded = ConsumptionScheduleCodec.encode(schedule);
        final ConsumptionSchedule decoded = ConsumptionScheduleCodec.decode(
          encoded,
        );

        expect(decoded, schedule);
        expect(ConsumptionScheduleCodec.encode(decoded), encoded);
      });
    }

    test('rejects malformed, unknown and invalid schedule JSON', () {
      for (final String source in <String>[
        'not-json',
        '[]',
        '{"version":2,"kind":"daily","amountPerOccurrence":1,"occurrencesPerDay":1}',
        '{"version":1,"kind":"unknown","amountPerOccurrence":1}',
        '{"version":1,"kind":"weekly","amountPerOccurrence":1,"weekdays":[]}',
        '{"version":1,"kind":"daily","amountPerOccurrence":0,"occurrencesPerDay":1}',
      ]) {
        expect(
          () => ConsumptionScheduleCodec.decode(source),
          throwsFormatException,
        );
      }
    });
  });
}
