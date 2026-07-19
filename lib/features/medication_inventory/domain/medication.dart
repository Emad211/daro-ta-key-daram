import 'consumption_schedule.dart';
import 'medication_stock_snapshot.dart';
import 'medication_unit.dart';
import 'stock_calculator.dart';

class Medication {
  Medication({
    required this.id,
    required String name,
    required this.unit,
    required double stockAtRecord,
    required this.inventoryRecordedAt,
    ConsumptionSchedule? consumptionSchedule,
    double? unitsPerDay,
    this.alertLeadDays = 5,
    String? notes,
    this.isArchived = false,
  }) : name = name.trim(),
       stockAtRecord = stockAtRecord,
       consumptionSchedule = _resolveSchedule(
         consumptionSchedule: consumptionSchedule,
         unitsPerDay: unitsPerDay,
       ),
       notes = _normalizeNotes(notes) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'شناسه دارو نمی‌تواند خالی باشد.');
    }
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'نام دارو نمی‌تواند خالی باشد.');
    }
    if (!stockAtRecord.isFinite || stockAtRecord < 0) {
      throw ArgumentError.value(
        stockAtRecord,
        'stockAtRecord',
        'موجودی باید عددی نامنفی باشد.',
      );
    }
    if (alertLeadDays < 0 || alertLeadDays > 365) {
      throw ArgumentError.value(
        alertLeadDays,
        'alertLeadDays',
        'فاصله هشدار باید بین صفر تا ۳۶۵ روز باشد.',
      );
    }
  }

  final String id;
  final String name;
  final MedicationUnit unit;
  final double stockAtRecord;
  final ConsumptionSchedule consumptionSchedule;
  final DateTime inventoryRecordedAt;
  final int alertLeadDays;
  final String? notes;
  final bool isArchived;

  double get unitsPerDay => consumptionSchedule.averageUnitsPerDay;

  MedicationStockSnapshot stockAt(DateTime now) {
    return StockCalculator.calculate(medication: this, now: now);
  }

  Medication copyWith({
    String? name,
    MedicationUnit? unit,
    double? stockAtRecord,
    ConsumptionSchedule? consumptionSchedule,
    double? unitsPerDay,
    DateTime? inventoryRecordedAt,
    int? alertLeadDays,
    String? notes,
    bool clearNotes = false,
    bool? isArchived,
  }) {
    if (consumptionSchedule != null && unitsPerDay != null) {
      throw ArgumentError(
        'Provide either consumptionSchedule or unitsPerDay, not both.',
      );
    }
    return Medication(
      id: id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      stockAtRecord: stockAtRecord ?? this.stockAtRecord,
      consumptionSchedule:
          consumptionSchedule ??
          (unitsPerDay == null
              ? this.consumptionSchedule
              : DailyConsumptionSchedule(
                  amountPerOccurrence: unitsPerDay,
                  occurrencesPerDay: 1,
                )),
      inventoryRecordedAt: inventoryRecordedAt ?? this.inventoryRecordedAt,
      alertLeadDays: alertLeadDays ?? this.alertLeadDays,
      notes: clearNotes ? null : notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  static ConsumptionSchedule _resolveSchedule({
    required ConsumptionSchedule? consumptionSchedule,
    required double? unitsPerDay,
  }) {
    if (consumptionSchedule != null && unitsPerDay != null) {
      throw ArgumentError(
        'Provide either consumptionSchedule or unitsPerDay, not both.',
      );
    }
    if (consumptionSchedule != null) {
      return consumptionSchedule;
    }
    if (unitsPerDay != null) {
      return DailyConsumptionSchedule(
        amountPerOccurrence: unitsPerDay,
        occurrencesPerDay: 1,
      );
    }
    throw ArgumentError('A consumption schedule is required.');
  }

  static String? _normalizeNotes(String? value) {
    final String? normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
