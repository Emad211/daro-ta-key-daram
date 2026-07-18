import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_stock_snapshot.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StockCalculator', () {
    final DateTime recordedAt = DateTime.utc(2026, 7, 18, 8);

    test('calculates 15 full days for 30 tablets at 2 per day', () {
      final Medication medication = Medication(
        id: 'm1',
        name: 'Metformin',
        unit: MedicationUnit.tablet,
        stockAtRecord: 30,
        unitsPerDay: 2,
        inventoryRecordedAt: recordedAt,
      );

      final MedicationStockSnapshot snapshot = medication.stockAt(recordedAt);

      expect(snapshot.estimatedRemainingUnits, 30);
      expect(snapshot.exactRemainingDays, 15);
      expect(snapshot.fullRemainingDays, 15);
      expect(snapshot.depletionAt, DateTime.utc(2026, 8, 2, 8));
      expect(snapshot.urgency, MedicationUrgency.safe);
    });

    test('decreases estimated stock as time passes', () {
      final Medication medication = Medication(
        id: 'm2',
        name: 'Test',
        unit: MedicationUnit.tablet,
        stockAtRecord: 10,
        unitsPerDay: 2,
        inventoryRecordedAt: recordedAt,
      );

      final MedicationStockSnapshot snapshot = medication.stockAt(
        recordedAt.add(const Duration(days: 2)),
      );

      expect(snapshot.estimatedRemainingUnits, 6);
      expect(snapshot.exactRemainingDays, 3);
      expect(snapshot.urgency, MedicationUrgency.critical);
    });

    test('never returns negative remaining stock', () {
      final Medication medication = Medication(
        id: 'm3',
        name: 'Test',
        unit: MedicationUnit.capsule,
        stockAtRecord: 2,
        unitsPerDay: 1,
        inventoryRecordedAt: recordedAt,
      );

      final MedicationStockSnapshot snapshot = medication.stockAt(
        recordedAt.add(const Duration(days: 10)),
      );

      expect(snapshot.estimatedRemainingUnits, 0);
      expect(snapshot.fullRemainingDays, 0);
      expect(snapshot.urgency, MedicationUrgency.depleted);
    });

    test('supports fractional daily use', () {
      final Medication medication = Medication(
        id: 'm4',
        name: 'Weekly medicine',
        unit: MedicationUnit.capsule,
        stockAtRecord: 4,
        unitsPerDay: 1 / 7,
        inventoryRecordedAt: recordedAt,
        alertLeadDays: 7,
      );

      final MedicationStockSnapshot snapshot = medication.stockAt(recordedAt);

      expect(snapshot.exactRemainingDays, 28);
      expect(snapshot.depletionAt, DateTime.utc(2026, 8, 15, 8));
    });

    test('does not consume stock when device time is before record time', () {
      final Medication medication = Medication(
        id: 'm5',
        name: 'Clock test',
        unit: MedicationUnit.tablet,
        stockAtRecord: 10,
        unitsPerDay: 1,
        inventoryRecordedAt: recordedAt,
      );

      final MedicationStockSnapshot snapshot = medication.stockAt(
        recordedAt.subtract(const Duration(days: 2)),
      );

      expect(snapshot.estimatedRemainingUnits, 10);
      expect(snapshot.exactRemainingDays, 10);
    });

    test('rejects zero daily use', () {
      expect(
        () => Medication(
          id: 'm6',
          name: 'Invalid',
          unit: MedicationUnit.tablet,
          stockAtRecord: 10,
          unitsPerDay: 0,
          inventoryRecordedAt: recordedAt,
        ),
        throwsArgumentError,
      );
    });
  });
}
