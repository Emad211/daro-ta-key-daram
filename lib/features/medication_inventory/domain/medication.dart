import 'medication_stock_snapshot.dart';
import 'medication_unit.dart';
import 'stock_calculator.dart';

class Medication {
  Medication({
    required this.id,
    required String name,
    required this.unit,
    required double stockAtRecord,
    required double unitsPerDay,
    required this.inventoryRecordedAt,
    this.alertLeadDays = 5,
    String? notes,
    this.isArchived = false,
  })  : name = name.trim(),
        stockAtRecord = stockAtRecord,
        unitsPerDay = unitsPerDay,
        notes = notes?.trim() {
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
    if (!unitsPerDay.isFinite || unitsPerDay <= 0) {
      throw ArgumentError.value(
        unitsPerDay,
        'unitsPerDay',
        'مصرف روزانه باید عددی بزرگ‌تر از صفر باشد.',
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
  final double unitsPerDay;
  final DateTime inventoryRecordedAt;
  final int alertLeadDays;
  final String? notes;
  final bool isArchived;

  MedicationStockSnapshot stockAt(DateTime now) {
    return StockCalculator.calculate(medication: this, now: now);
  }

  Medication copyWith({
    String? name,
    MedicationUnit? unit,
    double? stockAtRecord,
    double? unitsPerDay,
    DateTime? inventoryRecordedAt,
    int? alertLeadDays,
    String? notes,
    bool? isArchived,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      stockAtRecord: stockAtRecord ?? this.stockAtRecord,
      unitsPerDay: unitsPerDay ?? this.unitsPerDay,
      inventoryRecordedAt: inventoryRecordedAt ?? this.inventoryRecordedAt,
      alertLeadDays: alertLeadDays ?? this.alertLeadDays,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
