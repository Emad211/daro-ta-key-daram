import 'package:daro_ta_key_daram/features/medication_inventory/domain/inventory_event.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/in_memory_medication_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('direct repository call rejects an event before the current baseline', () async {
    final DateTime initialTime = DateTime.utc(2026, 7, 18, 8);
    final DateTime currentTime = DateTime.utc(2026, 7, 20, 10);
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(
          clock: () => currentTime,
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

    await repository.recordInventoryEvent(
      InventoryEvent(
        id: 'restock-1',
        medicationId: 'medication-1',
        type: InventoryEventType.restock,
        stockUnits: 60,
        effectiveAt: currentTime,
        createdAt: currentTime,
      ),
    );

    await expectLater(
      repository.recordInventoryEvent(
        InventoryEvent(
          id: 'stale-correction',
          medicationId: 'medication-1',
          type: InventoryEventType.correction,
          stockUnits: 12,
          effectiveAt: currentTime.subtract(const Duration(seconds: 1)),
          createdAt: currentTime,
        ),
      ),
      throwsArgumentError,
    );

    final Medication? stored = await repository.findById('medication-1');
    final List<InventoryEvent> events = await repository
        .watchInventoryEvents('medication-1')
        .first;
    expect(stored?.stockAtRecord, 60);
    expect(stored?.inventoryRecordedAt, currentTime);
    expect(events, hasLength(2));
  });

  test('direct repository call rejects a future event', () async {
    final DateTime currentTime = DateTime.utc(2026, 7, 20, 10);
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(
          clock: () => currentTime,
          seed: <Medication>[
            Medication(
              id: 'medication-1',
              name: 'متفورمین',
              unit: MedicationUnit.tablet,
              stockAtRecord: 30,
              unitsPerDay: 2,
              inventoryRecordedAt: currentTime,
            ),
          ],
        );

    await expectLater(
      repository.recordInventoryEvent(
        InventoryEvent(
          id: 'future-restock',
          medicationId: 'medication-1',
          type: InventoryEventType.restock,
          stockUnits: 60,
          effectiveAt: currentTime.add(const Duration(seconds: 1)),
          createdAt: currentTime,
        ),
      ),
      throwsArgumentError,
    );

    final Medication? stored = await repository.findById('medication-1');
    final List<InventoryEvent> events = await repository
        .watchInventoryEvents('medication-1')
        .first;
    expect(stored?.stockAtRecord, 30);
    expect(events, hasLength(1));
  });
}
