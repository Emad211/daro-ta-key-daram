enum ConsumptionScheduleKind {
  daily,
  everyNDays,
  weekly;

  String get persianLabel {
    return switch (this) {
      ConsumptionScheduleKind.daily => 'روزانه',
      ConsumptionScheduleKind.everyNDays => 'هر چند روز یک‌بار',
      ConsumptionScheduleKind.weekly => 'روزهای مشخص هفته',
    };
  }
}

sealed class ConsumptionSchedule {
  const ConsumptionSchedule();

  ConsumptionScheduleKind get kind;

  double get amountPerOccurrence;

  double get averageUnitsPerDay;

  static double validateAmount(double value) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(
        value,
        'amountPerOccurrence',
        'مقدار هر نوبت باید عددی محدود و بزرگ‌تر از صفر باشد.',
      );
    }
    return value;
  }
}

final class DailyConsumptionSchedule extends ConsumptionSchedule {
  DailyConsumptionSchedule({
    required double amountPerOccurrence,
    required this.occurrencesPerDay,
  }) : amountPerOccurrence = ConsumptionSchedule.validateAmount(
         amountPerOccurrence,
       ) {
    if (occurrencesPerDay < 1 || occurrencesPerDay > 24) {
      throw RangeError.range(occurrencesPerDay, 1, 24, 'occurrencesPerDay');
    }
    if (!averageUnitsPerDay.isFinite) {
      throw ArgumentError.value(
        averageUnitsPerDay,
        'averageUnitsPerDay',
        'مصرف روزانه قابل محاسبه نیست.',
      );
    }
  }

  @override
  final double amountPerOccurrence;

  final int occurrencesPerDay;

  @override
  ConsumptionScheduleKind get kind => ConsumptionScheduleKind.daily;

  @override
  double get averageUnitsPerDay => amountPerOccurrence * occurrencesPerDay;

  @override
  bool operator ==(Object other) {
    return other is DailyConsumptionSchedule &&
        other.amountPerOccurrence == amountPerOccurrence &&
        other.occurrencesPerDay == occurrencesPerDay;
  }

  @override
  int get hashCode => Object.hash(kind, amountPerOccurrence, occurrencesPerDay);
}

final class EveryNDaysConsumptionSchedule extends ConsumptionSchedule {
  EveryNDaysConsumptionSchedule({
    required double amountPerOccurrence,
    required this.intervalDays,
  }) : amountPerOccurrence = ConsumptionSchedule.validateAmount(
         amountPerOccurrence,
       ) {
    if (intervalDays < 1 || intervalDays > 365) {
      throw RangeError.range(intervalDays, 1, 365, 'intervalDays');
    }
    if (!averageUnitsPerDay.isFinite) {
      throw ArgumentError.value(
        averageUnitsPerDay,
        'averageUnitsPerDay',
        'میانگین مصرف قابل محاسبه نیست.',
      );
    }
  }

  @override
  final double amountPerOccurrence;

  final int intervalDays;

  @override
  ConsumptionScheduleKind get kind => ConsumptionScheduleKind.everyNDays;

  @override
  double get averageUnitsPerDay => amountPerOccurrence / intervalDays;

  @override
  bool operator ==(Object other) {
    return other is EveryNDaysConsumptionSchedule &&
        other.amountPerOccurrence == amountPerOccurrence &&
        other.intervalDays == intervalDays;
  }

  @override
  int get hashCode => Object.hash(kind, amountPerOccurrence, intervalDays);
}

final class WeeklyConsumptionSchedule extends ConsumptionSchedule {
  WeeklyConsumptionSchedule({
    required double amountPerOccurrence,
    required Iterable<int> weekdays,
  }) : amountPerOccurrence = ConsumptionSchedule.validateAmount(
         amountPerOccurrence,
       ),
       weekdays = _normalizeWeekdays(weekdays) {
    if (!averageUnitsPerDay.isFinite) {
      throw ArgumentError.value(
        averageUnitsPerDay,
        'averageUnitsPerDay',
        'میانگین مصرف هفتگی قابل محاسبه نیست.',
      );
    }
  }

  @override
  final double amountPerOccurrence;

  final List<int> weekdays;

  @override
  ConsumptionScheduleKind get kind => ConsumptionScheduleKind.weekly;

  @override
  double get averageUnitsPerDay => amountPerOccurrence * weekdays.length / 7;

  static List<int> _normalizeWeekdays(Iterable<int> values) {
    final List<int> normalized = values.toSet().toList()..sort();
    if (normalized.isEmpty) {
      throw ArgumentError.value(values, 'weekdays', 'حداقل یک روز لازم است.');
    }
    for (final int weekday in normalized) {
      if (weekday < DateTime.monday || weekday > DateTime.sunday) {
        throw RangeError.range(
          weekday,
          DateTime.monday,
          DateTime.sunday,
          'weekday',
        );
      }
    }
    return List<int>.unmodifiable(normalized);
  }

  @override
  bool operator ==(Object other) {
    if (other is! WeeklyConsumptionSchedule ||
        other.amountPerOccurrence != amountPerOccurrence ||
        other.weekdays.length != weekdays.length) {
      return false;
    }
    for (int index = 0; index < weekdays.length; index += 1) {
      if (other.weekdays[index] != weekdays[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(kind, amountPerOccurrence, Object.hashAll(weekdays));
  }
}
