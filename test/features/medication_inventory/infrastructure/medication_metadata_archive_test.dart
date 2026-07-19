import 'package:daro_ta_key_daram/core/database/app_database.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/consumption_schedule.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/inventory_event.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/drift_medication_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime baseline = DateTime.utc(2026, 7, 1, 8);
  final DateTime changeTime = DateTime.utc(2026, 7, 3, 8);

  test('metadata-only update preserves schedule and inventory history', () async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    final DriftMedicationRepository repository = DriftMedicationRepository(
      database,
      clock: () => changeTime,
    );
    addTearDown(database.close);

    final Medication initial = _dailyMedication(baseline);
    await repository.upsert(initial);

    await repository.upsert(
      initial.copyWith(
        name: 'متفورمین ۵۰۰',
        unit: MedicationUnit.capsule,
        alertLeadDays: 9,
        clearNotes: true,
      ),
    );

    final Medication? updated = await repository.findById(initial.id);
    final List<InventoryEventRow> events = await database
        .select(database.inventoryEvents)
        .get();

    expect(updated?.name, 'متفورمین ۵۰۰');
    expect(updated?.unit, MedicationUnit.capsule);
    expect(updated?.consumptionSchedule, initial.consumptionSchedule);
    expect(updated?.alertLeadDays, 9);
    expect(updated?.notes, isNull);
    expect(events, hasLength(1));
  });

  test('schedule change creates a new current-stock baseline', () async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    final DriftMedicationRepository repository = DriftMedicationRepository(
      database,
      clock: () => changeTime,
    );
    addTearDown(database.close);

    final Medication initial = _dailyMedication(baseline);
    await repository.upsert(initial);
    await repository.upsert(
      initial.copyWith(
        consumptionSchedule: EveryNDaysConsumptionSchedule(
          amountPerOccurrence: 1,
          intervalDays: 2,
        ),
      ),
    );

    final Medication updated = (await repository.findById(initial.id))!;
    final List<InventoryEvent> events = await repository
        .watchInventoryEvents(initial.id)
        .first;

    expect(
      updated.consumptionSchedule,
      EveryNDaysConsumptionSchedule(
        amountPerOccurrence: 1,
        intervalDays: 2,
      ),
    );
    expect(updated.stockAtRecord, 8);
    expect(updated.inventoryRecordedAt.toUtc(), changeTime);
    expect(events, hasLength(2));
    expect(events.first.type, InventoryEventType.scheduleChange);
    expect(events.first.stockUnits, 8);
    expect(events.first.effectiveAt.toUtc(), changeTime);
  });

  test('rejects changing schedule and explicit baseline together', () async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    final DriftMedicationRepository repository = DriftMedicationRepository(
      database,
      clock: () => changeTime,
    );
    addTearDown(database.close);

    final Medication initial = _dailyMedication(baseline);
    await repository.upsert(initial);

    expect(
      () => repository.upsert(
        initial.copyWith(
          consumptionSchedule: WeeklyConsumptionSchedule(
            amountPerOccurrence: 1,
            weekdays: <int>{DateTime.friday},
          ),
          stockAtRecord: 50,
          inventoryRecordedAt: changeTime,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('archived stream preserves history across restore', () async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    final DriftMedicationRepository repository = DriftMedicationRepository(
      database,
      clock: () => changeTime,
    );
    addTearDown(database.close);

    final Medication medication = _dailyMedication(baseline);
    await repository.upsert(medication);
    await repository.archive(medication.id);

    expect(await repository.watchActiveMedications().first, isEmpty);
    expect(await repository.watchArchivedMedications().first, hasLength(1));
    expect(
      await repository.watchInventoryEvents(medication.id).first,
      hasLength(1),
    );

    await repository.restore(medication.id);

    expect(await repository.watchActiveMedications().first, hasLength(1));
    expect(await repository.watchArchivedMedications().first, isEmpty);
    expect(
      await repository.watchInventoryEvents(medication.id).first,
      hasLength(1),
    );
  });
}

Medication _dailyMedication(DateTime baseline) {
  return Medication(
    id: 'medication-1',
    name: 'متفورمین',
    unit: MedicationUnit.tablet,
    stockAtRecord: 10,
    consumptionSchedule: DailyConsumptionSchedule(
      amountPerOccurrence: 1,
      occurrencesPerDay: 1,
    ),
    inventoryRecordedAt: baseline,
    notes: 'یادداشت قبلی',
  );
}
