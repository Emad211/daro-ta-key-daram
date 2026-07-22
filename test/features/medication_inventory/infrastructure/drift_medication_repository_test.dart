import 'dart:io';

import 'package:daro_ta_key_daram/core/database/app_database.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/application/medication_details_update.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/application/medication_lifecycle.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/inventory_event.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/drift_medication_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 7, 18, 12);

  group('DriftMedicationRepository with an in-memory database', () {
    late AppDatabase database;
    late DriftMedicationRepository repository;
    late DateTime currentTime;

    setUp(() {
      currentTime = now;
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftMedicationRepository(
        database,
        clock: () => currentTime,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('create writes one aggregate and one initial event', () async {
      await repository.create(_medication(now: now));

      final Medication? stored = await repository.findById('medication-1');
      final List<InventoryEventRow> events = await database
          .select(database.inventoryEvents)
          .get();

      expect(stored, isNotNull);
      expect(stored?.name, 'متفورمین');
      expect(stored?.stockAtRecord, 30);
      expect(stored?.inventoryRecordedAt.toUtc(), now);
      expect(events, hasLength(1));
      expect(events.single.eventType, InventoryEventType.initial.name);
    });

    test('uses the newest inventory event as calculation baseline', () async {
      final Medication initial = _medication(now: now);
      await repository.create(initial);
      currentTime = now.add(const Duration(days: 2));

      await repository.recordInventoryEvent(
        InventoryEvent(
          id: 'restock-1',
          medicationId: initial.id,
          type: InventoryEventType.restock,
          stockUnits: 60,
          effectiveAt: currentTime,
          createdAt: currentTime,
        ),
      );

      final Medication? stored = await repository.findById(initial.id);

      expect(stored?.stockAtRecord, 60);
      expect(stored?.inventoryRecordedAt.toUtc(), currentTime);
      expect(stored?.name, initial.name);
      expect(stored?.consumptionSchedule, initial.consumptionSchedule);
      expect(
        await database.select(database.inventoryEvents).get(),
        hasLength(2),
      );
    });

    test('repeated unchanged details update does not add history', () async {
      final Medication medication = _medication(now: currentTime);
      await repository.create(medication);
      final MedicationDetailsUpdate details = _details(medication);

      await repository.updateDetails(details);
      await repository.updateDetails(details);

      expect(
        await database.select(database.inventoryEvents).get(),
        hasLength(1),
      );
    });

    test('rejects duplicate create without partial writes', () async {
      final Medication medication = _medication(now: now);
      await repository.create(medication);

      await expectLater(repository.create(medication), throwsStateError);
      expect(await database.select(database.medications).get(), hasLength(1));
      expect(
        await database.select(database.inventoryEvents).get(),
        hasLength(1),
      );
    });

    test('rejects an inventory event effective in the future', () async {
      await repository.create(_medication(now: now));

      final Future<void> operation = repository.recordInventoryEvent(
        InventoryEvent(
          id: 'future-event',
          medicationId: 'medication-1',
          type: InventoryEventType.restock,
          stockUnits: 60,
          effectiveAt: now.add(const Duration(minutes: 1)),
          createdAt: now,
        ),
      );

      await expectLater(operation, throwsArgumentError);
      expect(
        await database.select(database.inventoryEvents).get(),
        hasLength(1),
      );
    });

    test('rejects an inventory event before the current baseline', () async {
      await repository.create(_medication(now: now));
      currentTime = now.add(const Duration(days: 2));
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

      final Future<void> operation = repository.recordInventoryEvent(
        InventoryEvent(
          id: 'stale-correction',
          medicationId: 'medication-1',
          type: InventoryEventType.correction,
          stockUnits: 12,
          effectiveAt: currentTime.subtract(const Duration(seconds: 1)),
          createdAt: currentTime,
        ),
      );

      await expectLater(operation, throwsArgumentError);
      final Medication? stored = await repository.findById('medication-1');
      expect(stored?.stockAtRecord, 60);
      expect(stored?.inventoryRecordedAt.toUtc(), currentTime);
      expect(
        await database.select(database.inventoryEvents).get(),
        hasLength(2),
      );
    });

    test('archive hides an aggregate and restore makes it active', () async {
      await repository.create(_medication(now: now));

      await repository.archive('medication-1');
      expect(await repository.watchActiveMedications().first, isEmpty);
      expect((await repository.findById('medication-1'))?.isArchived, isTrue);

      await repository.restore('medication-1');
      expect(await repository.watchActiveMedications().first, hasLength(1));
      expect((await repository.findById('medication-1'))?.isArchived, isFalse);
    });

    test('permanent deletion cascades to inventory history', () async {
      await repository.create(_medication(now: now));

      await repository.deletePermanently('medication-1');

      expect(await repository.findById('medication-1'), isNull);
      expect(await database.select(database.inventoryEvents).get(), isEmpty);
    });

    test('rejects an inventory event for a missing medication', () async {
      final Future<void> operation = repository.recordInventoryEvent(
        InventoryEvent(
          id: 'orphan-event',
          medicationId: 'missing-medication',
          type: InventoryEventType.restock,
          stockUnits: 10,
          effectiveAt: now,
          createdAt: now,
        ),
      );

      await expectLater(operation, throwsA(isA<MedicationNotFoundException>()));
      expect(await database.select(database.inventoryEvents).get(), isEmpty);
    });
  });

  test('data survives closing and reopening a SQLite file', () async {
    final Directory directory = await Directory.systemTemp.createTemp(
      'daro-ta-key-daram-',
    );
    final File file = File('${directory.path}/repository.sqlite');

    try {
      final AppDatabase firstDatabase = AppDatabase(NativeDatabase(file));
      final DriftMedicationRepository firstRepository =
          DriftMedicationRepository(firstDatabase, clock: () => now);
      await firstRepository.create(_medication(now: now));
      await firstDatabase.close();

      final AppDatabase secondDatabase = AppDatabase(NativeDatabase(file));
      final DriftMedicationRepository secondRepository =
          DriftMedicationRepository(secondDatabase, clock: () => now);
      final Medication? restored = await secondRepository.findById(
        'medication-1',
      );

      expect(restored, isNotNull);
      expect(restored?.name, 'متفورمین');
      expect(restored?.stockAtRecord, 30);
      await secondDatabase.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });
}

Medication _medication({required DateTime now}) {
  return Medication(
    id: 'medication-1',
    name: 'متفورمین',
    unit: MedicationUnit.tablet,
    stockAtRecord: 30,
    unitsPerDay: 2,
    inventoryRecordedAt: now,
  );
}

MedicationDetailsUpdate _details(Medication medication) {
  return MedicationDetailsUpdate(
    medicationId: medication.id,
    name: medication.name,
    unit: medication.unit,
    consumptionSchedule: medication.consumptionSchedule,
    alertLeadDays: medication.alertLeadDays,
    notes: medication.notes,
  );
}
