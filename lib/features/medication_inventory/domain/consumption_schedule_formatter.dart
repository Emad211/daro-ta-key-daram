import 'consumption_schedule.dart';
import 'medication_unit.dart';

abstract final class ConsumptionScheduleFormatter {
  static String describe(ConsumptionSchedule schedule, MedicationUnit unit) {
    final String amount = formatNumber(schedule.amountPerOccurrence);
    final String unitLabel = unit.persianLabel;

    return switch (schedule) {
      DailyConsumptionSchedule(:final occurrencesPerDay) =>
        '$amount $unitLabel × $occurrencesPerDay نوبت در روز',
      EveryNDaysConsumptionSchedule(:final intervalDays) =>
        intervalDays == 1
            ? '$amount $unitLabel روزی یک نوبت'
            : '$amount $unitLabel هر $intervalDays روز یک‌بار',
    };
  }

  static String formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    final String fixed = value.toStringAsFixed(3);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String weekdayLabel(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'دوشنبه',
      DateTime.tuesday => 'سه‌شنبه',
      DateTime.wednesday => 'چهارشنبه',
      DateTime.thursday => 'پنجشنبه',
      DateTime.friday => 'جمعه',
      DateTime.saturday => 'شنبه',
      DateTime.sunday => 'یکشنبه',
      _ => throw RangeError.range(
        weekday,
        DateTime.monday,
        DateTime.sunday,
        'weekday',
      ),
    };
  }
}
