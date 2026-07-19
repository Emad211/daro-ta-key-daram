import 'dart:convert';

import 'consumption_schedule.dart';

abstract final class ConsumptionScheduleCodec {
  static const int currentVersion = 1;

  static String encode(ConsumptionSchedule schedule) {
    final Map<String, Object> data = <String, Object>{
      'version': currentVersion,
      'kind': schedule.kind.name,
      'amountPerOccurrence': schedule.amountPerOccurrence,
    };

    switch (schedule) {
      case DailyConsumptionSchedule(:final occurrencesPerDay):
        data['occurrencesPerDay'] = occurrencesPerDay;
      case EveryNDaysConsumptionSchedule(:final intervalDays):
        data['intervalDays'] = intervalDays;
      case WeeklyConsumptionSchedule(:final weekdays):
        data['weekdays'] = weekdays;
    }

    return jsonEncode(data);
  }

  static ConsumptionSchedule decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Invalid consumption schedule JSON.', source, error.offset);
    }

    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Consumption schedule must be a JSON object.');
    }

    final int version = _readInt(decoded, 'version');
    if (version != currentVersion) {
      throw FormatException('Unsupported consumption schedule version: $version');
    }

    final String kindName = _readString(decoded, 'kind');
    final ConsumptionScheduleKind kind;
    try {
      kind = ConsumptionScheduleKind.values.byName(kindName);
    } on ArgumentError {
      throw FormatException('Unknown consumption schedule kind: $kindName');
    }

    final double amount = _readDouble(decoded, 'amountPerOccurrence');
    try {
      return switch (kind) {
        ConsumptionScheduleKind.daily => DailyConsumptionSchedule(
          amountPerOccurrence: amount,
          occurrencesPerDay: _readInt(decoded, 'occurrencesPerDay'),
        ),
        ConsumptionScheduleKind.everyNDays => EveryNDaysConsumptionSchedule(
          amountPerOccurrence: amount,
          intervalDays: _readInt(decoded, 'intervalDays'),
        ),
        ConsumptionScheduleKind.weekly => WeeklyConsumptionSchedule(
          amountPerOccurrence: amount,
          weekdays: _readIntList(decoded, 'weekdays'),
        ),
      };
    } on ArgumentError catch (error) {
      throw FormatException('Invalid consumption schedule values: $error');
    }
  }

  static String _readString(Map<String, Object?> data, String key) {
    final Object? value = data[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Expected a non-empty string for "$key".');
    }
    return value;
  }

  static int _readInt(Map<String, Object?> data, String key) {
    final Object? value = data[key];
    if (value is int) {
      return value;
    }
    if (value is double && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    throw FormatException('Expected an integer for "$key".');
  }

  static double _readDouble(Map<String, Object?> data, String key) {
    final Object? value = data[key];
    if (value is num && value.toDouble().isFinite) {
      return value.toDouble();
    }
    throw FormatException('Expected a finite number for "$key".');
  }

  static List<int> _readIntList(Map<String, Object?> data, String key) {
    final Object? value = data[key];
    if (value is! List<Object?>) {
      throw FormatException('Expected an integer list for "$key".');
    }
    return value.map((Object? item) {
      if (item is int) {
        return item;
      }
      if (item is double && item.isFinite && item == item.roundToDouble()) {
        return item.toInt();
      }
      throw FormatException('Expected integers inside "$key".');
    }).toList(growable: false);
  }
}
