import 'package:daro_ta_key_daram/core/database/app_database.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/inventory_event.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/drift_medication_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Drift history returns domain events newest first', () async {
    final DateTime initialTime = DateTime.utc(2026, 7, 18, 8);
    DateTime currentTime = initialTime;
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    final DriftMedicationRepository repository = DriftMedicationRepository(
      database,
      clock: () => currentTime,
    );

    try {
      await repository.create(
        Medication(
          id: 'medication-1',
          name: 'متفورمین',
          unit: MedicationUnit.tablet,
          stockAtRecord: 30,
          unitsPerDay: 2,
          inventoryRecordedAt: initialTime,
        ),
      );
      currentTime = initialTime.add(const Duration(days: 2));
      await repository.recordInventoryEvent(
        InventoryEvent(
          id: 'restock-1',
          medicationId: 'medication-1',
          type: InventoryEventType.restock,
          stockUnits: 60,
          effectiveAt: currentTime,
          createdAt: currentTime,
          note: 'خرید مجدد',
        ),
      );

      final List<InventoryEvent> events = await repository
          .watchInventoryEvents('medication-1')
          .first;

      expect(events, hasLength(2));
      expect(events.first.type, InventoryEventType.restock);
      expect(events.first.stockUnits, 60);
      expect(events.last.type, InventoryEventType.initial);
    } finally {
      await database.close();
    }
  });
}
