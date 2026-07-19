import 'dart:math' as math;

import 'consumption_schedule.dart';

final class ConsumptionScheduleProjection {
  const ConsumptionScheduleProjection({
    required this.estimatedRemainingUnits,
    required this.depletionAt,
    required this.completedOccurrences,
  });

  final double estimatedRemainingUnits;
  final DateTime depletionAt;
  final int completedOccurrences;
}

abstract final class ConsumptionScheduleCalculator {
  static ConsumptionScheduleProjection project({
    required ConsumptionSchedule schedule,
    required DateTime baseline,
    required double stockAtBaseline,
    required DateTime now,
  }) {
    if (!stockAtBaseline.isFinite || stockAtBaseline < 0) {
      throw ArgumentError.value(
        stockAtBaseline,
        'stockAtBaseline',
        'Inventory must be finite and non-negative.',
      );
    }

    if (stockAtBaseline == 0) {
      return ConsumptionScheduleProjection(
        estimatedRemainingUnits: 0,
        depletionAt: baseline,
        completedOccurrences: 0,
      );
    }

    final int depletionOccurrence = _requiredOccurrenceCount(
      stockAtBaseline,
      schedule.amountPerOccurrence,
    );
    final DateTime depletionAt = occurrenceAt(
      schedule: schedule,
      baseline: baseline,
      occurrenceNumber: depletionOccurrence,
    );
    final DateTime effectiveNow = now.isBefore(baseline) ? baseline : now;

    if (!depletionAt.isAfter(effectiveNow)) {
      return ConsumptionScheduleProjection(
        estimatedRemainingUnits: 0,
        depletionAt: depletionAt,
        completedOccurrences: depletionOccurrence,
      );
    }

    final int completed = occurrencesDue(
      schedule: schedule,
      baseline: baseline,
      at: effectiveNow,
    );
    final double consumed = completed * schedule.amountPerOccurrence;
    final double remaining = math.max(0, stockAtBaseline - consumed);

    return ConsumptionScheduleProjection(
      estimatedRemainingUnits: remaining,
      depletionAt: depletionAt,
      completedOccurrences: completed,
    );
  }

  static int occurrencesDue({
    required ConsumptionSchedule schedule,
    required DateTime baseline,
    required DateTime at,
  }) {
    if (!at.isAfter(baseline)) {
      return 0;
    }

    int low = 0;
    int high = _initialUpperBound(schedule, baseline, at);
    while (!occurrenceAt(
      schedule: schedule,
      baseline: baseline,
      occurrenceNumber: high,
    ).isAfter(at)) {
      if (high > 1 << 52) {
        throw StateError(
          'Consumption occurrence count is outside safe bounds.',
        );
      }
      high *= 2;
    }

    while (low + 1 < high) {
      final int middle = low + ((high - low) ~/ 2);
      final DateTime occurrence = occurrenceAt(
        schedule: schedule,
        baseline: baseline,
        occurrenceNumber: middle,
      );
      if (occurrence.isAfter(at)) {
        high = middle;
      } else {
        low = middle;
      }
    }
    return low;
  }

  static DateTime occurrenceAt({
    required ConsumptionSchedule schedule,
    required DateTime baseline,
    required int occurrenceNumber,
  }) {
    if (occurrenceNumber < 1) {
      throw RangeError.range(occurrenceNumber, 1, null, 'occurrenceNumber');
    }

    return switch (schedule) {
      DailyConsumptionSchedule(:final occurrencesPerDay) => _addMicroseconds(
        baseline,
        occurrenceNumber * Duration.microsecondsPerDay / occurrencesPerDay,
      ),
      EveryNDaysConsumptionSchedule(:final intervalDays) => _addMicroseconds(
        baseline,
        occurrenceNumber *
            intervalDays *
            Duration.microsecondsPerDay.toDouble(),
      ),
      WeeklyConsumptionSchedule(:final weekdays) => _weeklyOccurrenceAt(
        baseline: baseline,
        weekdays: weekdays,
        occurrenceNumber: occurrenceNumber,
      ),
    };
  }

  static int _requiredOccurrenceCount(double stock, double amount) {
    final double ratio = stock / amount;
    if (!ratio.isFinite || ratio <= 0) {
      throw ArgumentError.value(
        ratio,
        'stockToOccurrenceRatio',
        'Coverage cannot be represented safely.',
      );
    }

    final double nearestInteger = ratio.roundToDouble();
    final double tolerance = 1e-10 * math.max(1, ratio.abs());
    if ((ratio - nearestInteger).abs() <= tolerance) {
      return nearestInteger.toInt();
    }
    return ratio.ceil();
  }

  static int _initialUpperBound(
    ConsumptionSchedule schedule,
    DateTime baseline,
    DateTime at,
  ) {
    final int elapsedMicroseconds = at.difference(baseline).inMicroseconds;
    final int estimate = switch (schedule) {
      DailyConsumptionSchedule(:final occurrencesPerDay) =>
        (elapsedMicroseconds * occurrencesPerDay) ~/
                Duration.microsecondsPerDay +
            2,
      EveryNDaysConsumptionSchedule(:final intervalDays) =>
        elapsedMicroseconds ~/ (Duration.microsecondsPerDay * intervalDays) + 2,
      WeeklyConsumptionSchedule(:final weekdays) =>
        (at.difference(baseline).inDays ~/ 7 + 2) * weekdays.length + 1,
    };
    return math.max(1, estimate);
  }

  static DateTime _addMicroseconds(DateTime baseline, double microseconds) {
    if (!microseconds.isFinite || microseconds < 0) {
      throw ArgumentError.value(
        microseconds,
        'microseconds',
        'Occurrence time cannot be represented safely.',
      );
    }
    final int rounded = microseconds.round();
    try {
      return baseline.add(Duration(microseconds: rounded));
    } on ArgumentError {
      throw ArgumentError.value(
        microseconds,
        'microseconds',
        'Occurrence date is outside the supported range.',
      );
    }
  }

  static DateTime _weeklyOccurrenceAt({
    required DateTime baseline,
    required List<int> weekdays,
    required int occurrenceNumber,
  }) {
    final List<int> firstCycleDeltas = weekdays.map((int weekday) {
      final int rawDelta = (weekday - baseline.weekday + 7) % 7;
      return rawDelta == 0 ? 7 : rawDelta;
    }).toList()..sort();

    final int zeroBased = occurrenceNumber - 1;
    final int cycle = zeroBased ~/ firstCycleDeltas.length;
    final int position = zeroBased % firstCycleDeltas.length;
    final int dayOffset = cycle * 7 + firstCycleDeltas[position];

    try {
      if (baseline.isUtc) {
        return DateTime.utc(
          baseline.year,
          baseline.month,
          baseline.day + dayOffset,
          baseline.hour,
          baseline.minute,
          baseline.second,
          baseline.millisecond,
          baseline.microsecond,
        );
      }
      return DateTime(
        baseline.year,
        baseline.month,
        baseline.day + dayOffset,
        baseline.hour,
        baseline.minute,
        baseline.second,
        baseline.millisecond,
        baseline.microsecond,
      );
    } on ArgumentError {
      throw ArgumentError.value(
        occurrenceNumber,
        'occurrenceNumber',
        'Weekly occurrence date is outside the supported range.',
      );
    }
  }
}
