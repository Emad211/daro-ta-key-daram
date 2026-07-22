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
    expect(events.first.effectiveAt, restockTime);
    expect(events.first.createdAt, restockTime);
    expect(medication?.stockAtRecord, 60);
    expect(medication?.inventoryRecordedAt, restockTime);
  });

  test('preserves selected effective time and real command time', () async {
    final DateTime initialTime = DateTime.utc(2026, 7, 10, 8);
    final DateTime commandTime = DateTime.utc(2026, 7, 20, 10);
    final DateTime selectedEffectiveTime = DateTime.utc(2026, 7, 19, 16, 30);
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
      () => commandTime,
    );

    await service.record(
      medicationId: 'medication-1',
      type: InventoryEventType.correction,
      stockUnits: 12,
      effectiveAt: selectedEffectiveTime,
    );

    final List<InventoryEvent> events = await repository
        .watchInventoryEvents('medication-1')
        .first;
    final Medication? medication = await repository.findById('medication-1');

    expect(events.first.effectiveAt, selectedEffectiveTime);
    expect(events.first.createdAt, commandTime);
    expect(medication?.inventoryRecordedAt, selectedEffectiveTime);
  });

  test('rejects future effective time without side effects', () async {
    final DateTime initialTime = DateTime.utc(2026, 7, 18, 8);
    final DateTime commandTime = DateTime.utc(2026, 7, 20, 10);
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
      () => commandTime,
    );

    await expectLater(
      service.record(
        medicationId: 'medication-1',
        type: InventoryEventType.restock,
        stockUnits: 60,
        effectiveAt: commandTime.add(const Duration(minutes: 1)),
      ),
      throwsArgumentError,
    );

    final List<InventoryEvent> events = await repository
        .watchInventoryEvents('medication-1')
        .first;
    final Medication? medication = await repository.findById('medication-1');

    expect(events, hasLength(1));
    expect(medication?.stockAtRecord, 30);
    expect(medication?.inventoryRecordedAt, initialTime);
  });

  test('rejects an effective time before the current baseline', () async {
    final DateTime baselineTime = DateTime.utc(2026, 7, 18, 8);
    final DateTime commandTime = DateTime.utc(2026, 7, 20, 10);
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(
          seed: <Medication>[
            Medication(
              id: 'medication-1',
              name: 'متفورمین',
              unit: MedicationUnit.tablet,
              stockAtRecord: 30,
              unitsPerDay: 2,
              inventoryRecordedAt: baselineTime,
            ),
          ],
        );
    final InventoryEventService service = InventoryEventService(
      repository,
      () => commandTime,
    );

    await expectLater(
      service.record(
        medicationId: 'medication-1',
        type: InventoryEventType.correction,
        stockUnits: 12,
        effectiveAt: baselineTime.subtract(const Duration(minutes: 1)),
      ),
      throwsArgumentError,
    );

    final List<InventoryEvent> events = await repository
        .watchInventoryEvents('medication-1')
        .first;
    final Medication? medication = await repository.findById('medication-1');

    expect(events, hasLength(1));
    expect(medication?.stockAtRecord, 30);
    expect(medication?.inventoryRecordedAt, baselineTime);
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
