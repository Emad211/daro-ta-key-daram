import 'package:daro_ta_key_daram/core/database/app_database.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/drift_medication_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 7, 18, 12);

  test('metadata-only update preserves the inventory history baseline', () async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    final DriftMedicationRepository repository = DriftMedicationRepository(
      database,
      clock: () => now,
    );
    addTearDown(database.close);

    final Medication initial = Medication(
      id: 'medication-1',
      name: 'متفورمین',
      unit: MedicationUnit.tablet,
      stockAtRecord: 30,
      unitsPerDay: 2,
      inventoryRecordedAt: now,
      alertLeadDays: 5,
      notes: 'یادداشت قبلی',
    );
    await repository.upsert(initial);

    await repository.upsert(
      initial.copyWith(
        name: 'متفورمین ۵۰۰',
        unit: MedicationUnit.capsule,
        unitsPerDay: 3,
        alertLeadDays: 9,
        clearNotes: true,
      ),
    );

    final Medication? updated = await repository.findById(initial.id);
    final events = await database.select(database.inventoryEvents).get();

    expect(updated?.name, 'متفورمین ۵۰۰');
    expect(updated?.unit, MedicationUnit.capsule);
    expect(updated?.unitsPerDay, 3);
    expect(updated?.alertLeadDays, 9);
    expect(updated?.notes, isNull);
    expect(events, hasLength(1));
  });

  test('archived stream preserves history across restore', () async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    final DriftMedicationRepository repository = DriftMedicationRepository(
      database,
      clock: () => now,
    );
    addTearDown(database.close);

    final Medication medication = Medication(
      id: 'medication-2',
      name: 'آملودیپین',
      unit: MedicationUnit.tablet,
      stockAtRecord: 20,
      unitsPerDay: 1,
      inventoryRecordedAt: now,
    );
    await repository.upsert(medication);
    await repository.archive(medication.id);

    expect(await repository.watchActiveMedications().first, isEmpty);
    expect(await repository.watchArchivedMedications().first, hasLength(1));
    expect(await repository.watchInventoryEvents(medication.id).first, hasLength(1));

    await repository.restore(medication.id);

    expect(await repository.watchActiveMedications().first, hasLength(1));
    expect(await repository.watchArchivedMedications().first, isEmpty);
    expect(await repository.watchInventoryEvents(medication.id).first, hasLength(1));
  });
}
