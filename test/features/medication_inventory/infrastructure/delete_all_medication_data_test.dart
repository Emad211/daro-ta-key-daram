import 'package:daro_ta_key_daram/core/database/app_database.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/inventory_event.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/drift_medication_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'deleteAll removes every medication aggregate and cascaded history',
    () async {
      final DateTime now = DateTime.utc(2026, 7, 21, 12);
      final AppDatabase database = AppDatabase(NativeDatabase.memory());
      final DriftMedicationRepository repository = DriftMedicationRepository(
        database,
        clock: () => now,
      );

      try {
        final Medication active = _medication('active', now);
        final Medication archived = _medication('archived', now);
        await repository.create(active);
        await repository.create(archived);
        await repository.archive(archived.id);
        await repository.recordInventoryEvent(
          InventoryEvent(
            id: 'restock-active',
            medicationId: active.id,
            type: InventoryEventType.restock,
            stockUnits: 50,
            effectiveAt: now,
            createdAt: now,
          ),
        );
        await database
            .into(database.appPreferences)
            .insert(
              AppPreferencesCompanion(
                key: const Value<String>('unrelated.preference'),
                value: const Value<String>('keep'),
                updatedAt: Value<DateTime>(now),
              ),
            );

        expect(await database.select(database.medications).get(), hasLength(2));
        expect(
          await database.select(database.inventoryEvents).get(),
          hasLength(3),
        );

        await repository.deleteAll();

        expect(await database.select(database.medications).get(), isEmpty);
        expect(await database.select(database.inventoryEvents).get(), isEmpty);
        expect(await repository.watchActiveMedications().first, isEmpty);
        expect(await repository.watchArchivedMedications().first, isEmpty);
        expect(
          await database.select(database.appPreferences).get(),
          hasLength(1),
          reason: 'The command is scoped to medication-domain data.',
        );
      } finally {
        await database.close();
      }
    },
  );
}

Medication _medication(String id, DateTime now) {
  return Medication(
    id: id,
    name: 'داروی $id',
    unit: MedicationUnit.tablet,
    stockAtRecord: 20,
    unitsPerDay: 1,
    inventoryRecordedAt: now,
  );
}
