import 'package:daro_ta_key_daram/features/medication_inventory/application/inventory_event_service.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/inventory_event.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/in_memory_medication_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('records a restock through the application service', () async {
    final DateTime initialTime = DateTime.utc(2026, 7, 18, 8);
    final DateTime restockTime = DateTime.utc(2026, 7, 20, 10);
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(
          seed: <Medication>[
            Medication(
              id: 'medication-1',
              name: 'متفورمین',
              unit: MedicationUnit.tablet,
              stockAtRecord: 30,
              unitsPerDay: 2,
              inventoryRecordedAt: initialTime,
            ),
          ],
        );
    final InventoryEventService service = InventoryEventService(
      repository,
      () => restockTime,
    );

    await service.record(
      medicationId: 'medication-1',
      type: InventoryEventType.restock,
      stockUnits: 60,
      note: 'خرید از داروخانه',
    );

    final List<InventoryEvent> events = await repository
        .watchInventoryEvents('medication-1')
        .first;
    final Medication? medication = await repository.findById('medication-1');

    expect(events, hasLength(2));
    expect(events.first.type, InventoryEventType.restock);
    expect(events.first.stockUnits, 60);
    expect(events.first.note, 'خرید از داروخانه');
    expect(medication?.stockAtRecord, 60);
    expect(medication?.inventoryRecordedAt, restockTime);
  });

  test('rejects manual creation of an initial event', () async {
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository();
    final InventoryEventService service = InventoryEventService(
      repository,
      DateTime.now,
    );

    await expectLater(
      service.record(
        medicationId: 'missing',
        type: InventoryEventType.initial,
        stockUnits: 1,
      ),
      throwsArgumentError,
    );
  });
}
