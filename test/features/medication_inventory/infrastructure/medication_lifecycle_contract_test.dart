import 'package:daro_ta_key_daram/core/database/app_database.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/application/medication_details_update.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/application/medication_lifecycle.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/application/medication_repository.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/inventory_event.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/drift_medication_repository.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/in_memory_medication_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 7, 19, 8);

  group('medication lifecycle contract', () {
    test('in-memory repository enforces all transitions', () async {
      final InMemoryMedicationRepository repository =
          InMemoryMedicationRepository(clock: () => now);
      await _verifyLifecycle(repository, now);
    });

    test('Drift repository enforces all transitions', () async {
      final AppDatabase database = AppDatabase(NativeDatabase.memory());
      final DriftMedicationRepository repository = DriftMedicationRepository(
        database,
        clock: () => now,
      );
      addTearDown(database.close);
      await _verifyLifecycle(repository, now);
    });
  });
}

Future<void> _verifyLifecycle(
  MedicationRepository repository,
  DateTime now,
) async {
  final Medication aggregate = _aggregate('lifecycle-1', now);
  await repository.create(aggregate);

  await expectLater(
    repository.restore(aggregate.id),
    _violation(
      state: MedicationLifecycleState.active,
      operation: MedicationLifecycleOperation.restore,
    ),
  );

  await repository.archive(aggregate.id);
  final Medication archived = (await repository.findById(aggregate.id))!;
  expect(archived.isArchived, isTrue);
  expect(await repository.watchActiveMedications().first, isEmpty);
  expect(await repository.watchArchivedMedications().first, hasLength(1));

  final int historyBeforeRejectedWrites =
      (await repository.watchInventoryEvents(aggregate.id).first).length;
  await expectLater(
    repository.archive(aggregate.id),
    _violation(
      state: MedicationLifecycleState.archived,
      operation: MedicationLifecycleOperation.archive,
    ),
  );
  await expectLater(
    repository.updateDetails(_details(archived)),
    _violation(
      state: MedicationLifecycleState.archived,
      operation: MedicationLifecycleOperation.updateDetails,
    ),
  );
  await expectLater(
    repository.recordInventoryEvent(
      InventoryEvent(
        id: 'rejected-event',
        medicationId: aggregate.id,
        type: InventoryEventType.correction,
        stockUnits: 99,
        effectiveAt: now,
        createdAt: now,
      ),
    ),
    _violation(
      state: MedicationLifecycleState.archived,
      operation: MedicationLifecycleOperation.recordInventoryEvent,
    ),
  );
  expect(
    await repository.watchInventoryEvents(aggregate.id).first,
    hasLength(historyBeforeRejectedWrites),
  );

  await repository.restore(aggregate.id);
  expect((await repository.findById(aggregate.id))?.isArchived, isFalse);
  await expectLater(
    repository.restore(aggregate.id),
    _violation(
      state: MedicationLifecycleState.active,
      operation: MedicationLifecycleOperation.restore,
    ),
  );

  await repository.deletePermanently(aggregate.id);
  expect(await repository.findById(aggregate.id), isNull);
  expect(await repository.watchActiveMedications().first, isEmpty);
  expect(await repository.watchArchivedMedications().first, isEmpty);
  expect(await repository.watchInventoryEvents(aggregate.id).first, isEmpty);

  await expectLater(
    repository.deletePermanently(aggregate.id),
    _notFound(MedicationLifecycleOperation.deletePermanently),
  );
  await expectLater(
    repository.archive(aggregate.id),
    _notFound(MedicationLifecycleOperation.archive),
  );
  await expectLater(
    repository.restore(aggregate.id),
    _notFound(MedicationLifecycleOperation.restore),
  );
  await expectLater(
    repository.updateDetails(_details(aggregate)),
    _notFound(MedicationLifecycleOperation.updateDetails),
  );
  await expectLater(
    repository.recordInventoryEvent(
      InventoryEvent(
        id: 'missing-event',
        medicationId: aggregate.id,
        type: InventoryEventType.correction,
        stockUnits: 1,
        effectiveAt: now,
        createdAt: now,
      ),
    ),
    _notFound(MedicationLifecycleOperation.recordInventoryEvent),
  );

  await expectLater(
    repository.create(_aggregate('archived-create', now, isArchived: true)),
    _violation(
      state: MedicationLifecycleState.archived,
      operation: MedicationLifecycleOperation.create,
    ),
  );

  final Medication deletableArchived = _aggregate('archived-delete', now);
  await repository.create(deletableArchived);
  await repository.archive(deletableArchived.id);
  await repository.deletePermanently(deletableArchived.id);
  expect(await repository.findById(deletableArchived.id), isNull);
}

Matcher _violation({
  required MedicationLifecycleState state,
  required MedicationLifecycleOperation operation,
}) {
  return throwsA(
    isA<MedicationLifecycleViolation>()
        .having(
          (MedicationLifecycleViolation error) => error.state,
          'state',
          state,
        )
        .having(
          (MedicationLifecycleViolation error) => error.operation,
          'operation',
          operation,
        ),
  );
}

Matcher _notFound(MedicationLifecycleOperation operation) {
  return throwsA(
    isA<MedicationNotFoundException>().having(
      (MedicationNotFoundException error) => error.operation,
      'operation',
      operation,
    ),
  );
}

Medication _aggregate(
  String id,
  DateTime now, {
  bool isArchived = false,
}) {
  return Medication(
    id: id,
    name: 'Aggregate',
    unit: MedicationUnit.tablet,
    stockAtRecord: 10,
    unitsPerDay: 1,
    inventoryRecordedAt: now,
    isArchived: isArchived,
  );
}

MedicationDetailsUpdate _details(Medication aggregate) {
  return MedicationDetailsUpdate(
    medicationId: aggregate.id,
    name: 'Updated',
    unit: aggregate.unit,
    consumptionSchedule: aggregate.consumptionSchedule,
    alertLeadDays: aggregate.alertLeadDays,
    notes: aggregate.notes,
  );
}
