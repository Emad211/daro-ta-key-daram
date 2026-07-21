import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../application/medication_details_update.dart';
import '../application/medication_lifecycle.dart';
import '../application/medication_repository.dart';
import '../domain/consumption_schedule.dart';
import '../domain/consumption_schedule_codec.dart';
import '../domain/inventory_event.dart';
import '../domain/medication.dart';
import '../domain/medication_unit.dart';

final class DriftMedicationRepository implements MedicationRepository {
  DriftMedicationRepository(
    this._database, {
    Uuid? uuid,
    DateTime Function()? clock,
  }) : _uuid = uuid ?? Uuid(),
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final Uuid _uuid;
  final DateTime Function() _clock;

  @override
  Future<void> archive(String medicationId) {
    return _setArchiveState(
      medicationId: medicationId,
      targetIsArchived: true,
      operation: MedicationLifecycleOperation.archive,
    );
  }

  @override
  Future<void> deletePermanently(String medicationId) async {
    await _database.transaction(() async {
      final MedicationRow? existing = await _findMedicationRow(medicationId);
      MedicationLifecyclePolicy.ensureAllowed(
        medicationId: medicationId,
        isArchived: existing?.isArchived,
        operation: MedicationLifecycleOperation.deletePermanently,
      );
      final int affected = await (_database.delete(
        _database.medications,
      )..where((Medications table) => table.id.equals(medicationId))).go();
      if (affected != 1) {
        throw StateError('Permanent deletion did not affect one aggregate.');
      }
    });
  }

  @override
  Future<Medication?> findById(String medicationId) async {
    final MedicationRow? medicationRow =
        await (_database.select(_database.medications)
              ..where((Medications table) => table.id.equals(medicationId)))
            .getSingleOrNull();
    if (medicationRow == null) {
      return null;
    }

    final InventoryEventRow? inventoryRow = await _latestInventoryEvent(
      medicationId,
    );
    if (inventoryRow == null) {
      throw StateError(
        'Medication $medicationId has no inventory baseline event.',
      );
    }

    return _toMedicationDomain(medicationRow, inventoryRow);
  }

  @override
  Future<void> recordInventoryEvent(InventoryEvent event) async {
    final DateTime now = _nowUtc();
    final DateTime effectiveAt = _normalizeUtc(event.effectiveAt);
    if (effectiveAt.isAfter(now)) {
      throw ArgumentError.value(
        event.effectiveAt,
        'event.effectiveAt',
        'Inventory events cannot become effective in the future.',
      );
    }

    await _database.transaction(() async {
      final MedicationRow? medication =
          await (_database.select(_database.medications)..where(
                (Medications table) => table.id.equals(event.medicationId),
              ))
              .getSingleOrNull();
      MedicationLifecyclePolicy.ensureAllowed(
        medicationId: event.medicationId,
        isArchived: medication?.isArchived,
        operation: MedicationLifecycleOperation.recordInventoryEvent,
      );

      await _insertInventoryEvent(event, effectiveAt: effectiveAt);
      await (_database.update(_database.medications)
            ..where((Medications table) => table.id.equals(event.medicationId)))
          .write(MedicationsCompanion(updatedAt: Value<DateTime>(now)));
    });
  }

  @override
  Future<void> restore(String medicationId) {
    return _setArchiveState(
      medicationId: medicationId,
      targetIsArchived: false,
      operation: MedicationLifecycleOperation.restore,
    );
  }

  @override
  Future<void> create(Medication medication) async {
    MedicationLifecyclePolicy.ensureCreatable(
      medicationId: medication.id,
      isArchived: medication.isArchived,
    );
    final DateTime now = _nowUtc();
    final DateTime effectiveAt = _normalizeUtc(medication.inventoryRecordedAt);
    if (effectiveAt.isAfter(now)) {
      throw ArgumentError.value(
        medication.inventoryRecordedAt,
        'medication.inventoryRecordedAt',
        'The initial baseline cannot become effective in the future.',
      );
    }

    await _database.transaction(() async {
      final MedicationRow? existing =
          await (_database.select(_database.medications)
                ..where((Medications table) => table.id.equals(medication.id)))
              .getSingleOrNull();
      if (existing != null) {
        throw StateError('An aggregate with this identifier already exists.');
      }

      await _database
          .into(_database.medications)
          .insert(
            MedicationsCompanion(
              id: Value<String>(medication.id),
              name: Value<String>(medication.name),
              unit: Value<String>(medication.unit.name),
              unitsPerDay: Value<double>(medication.unitsPerDay),
              consumptionScheduleJson: Value<String>(
                ConsumptionScheduleCodec.encode(medication.consumptionSchedule),
              ),
              alertLeadDays: Value<int>(medication.alertLeadDays),
              notes: Value<String?>(medication.notes),
              isArchived: Value<bool>(medication.isArchived),
              createdAt: Value<DateTime>(now),
              updatedAt: Value<DateTime>(now),
            ),
          );
      await _insertInventoryEvent(
        InventoryEvent(
          id: _uuid.v4(),
          medicationId: medication.id,
          type: InventoryEventType.initial,
          stockUnits: medication.stockAtRecord,
          effectiveAt: effectiveAt,
          createdAt: now,
        ),
        effectiveAt: effectiveAt,
      );
    });
  }

  @override
  Future<void> updateDetails(MedicationDetailsUpdate update) async {
    final DateTime now = _nowUtc();

    await _database.transaction(() async {
      final MedicationRow? existing =
          await (_database.select(_database.medications)..where(
                (Medications table) => table.id.equals(update.medicationId),
              ))
              .getSingleOrNull();
      MedicationLifecyclePolicy.ensureAllowed(
        medicationId: update.medicationId,
        isArchived: existing?.isArchived,
        operation: MedicationLifecycleOperation.updateDetails,
      );

      final InventoryEventRow? latest = await _latestInventoryEvent(
        update.medicationId,
      );
      if (latest == null) {
        throw StateError('The aggregate has no baseline event.');
      }

      final Medication previous = _toMedicationDomain(existing!, latest);
      final bool scheduleChanged =
          previous.consumptionSchedule != update.consumptionSchedule;
      final Medication updated = update.applyTo(previous);

      await (_database.update(
            _database.medications,
          )..where((Medications table) => table.id.equals(update.medicationId)))
          .write(
            MedicationsCompanion(
              name: Value<String>(updated.name),
              unit: Value<String>(updated.unit.name),
              unitsPerDay: Value<double>(updated.unitsPerDay),
              consumptionScheduleJson: Value<String>(
                ConsumptionScheduleCodec.encode(updated.consumptionSchedule),
              ),
              alertLeadDays: Value<int>(updated.alertLeadDays),
              notes: Value<String?>(updated.notes),
              updatedAt: Value<DateTime>(now),
            ),
          );

      if (!scheduleChanged) {
        return;
      }

      final double currentEstimatedStock = previous
          .stockAt(now.toLocal())
          .estimatedRemainingUnits;
      await _insertInventoryEvent(
        InventoryEvent(
          id: _uuid.v4(),
          medicationId: update.medicationId,
          type: InventoryEventType.scheduleChange,
          stockUnits: currentEstimatedStock,
          effectiveAt: now,
          createdAt: now,
          note: 'Boundary created after a schedule update',
        ),
        effectiveAt: now,
      );
    });
  }

  @override
  Stream<List<Medication>> watchActiveMedications() {
    return _watchMedications(isArchived: false);
  }

  @override
  Stream<List<Medication>> watchArchivedMedications() {
    return _watchMedications(isArchived: true);
  }

  @override
  Stream<List<InventoryEvent>> watchInventoryEvents(String medicationId) {
    final SimpleSelectStatement<InventoryEvents, InventoryEventRow> query =
        _database.select(_database.inventoryEvents)
          ..where(
            (InventoryEvents table) => table.medicationId.equals(medicationId),
          )
          ..orderBy(<OrderingTerm Function(InventoryEvents)>[
            (InventoryEvents table) => OrderingTerm.desc(table.effectiveAt),
            (InventoryEvents table) => OrderingTerm.desc(table.createdAt),
          ]);

    return query.watch().map(
      (List<InventoryEventRow> rows) =>
          List<InventoryEvent>.unmodifiable(rows.map(_toInventoryEventDomain)),
    );
  }

  Stream<List<Medication>> _watchMedications({required bool isArchived}) {
    final JoinedSelectStatement<HasResultSet, dynamic> query =
        _database
            .select(_database.medications)
            .join(<Join<HasResultSet, dynamic>>[
              innerJoin(
                _database.inventoryEvents,
                _database.inventoryEvents.medicationId.equalsExp(
                  _database.medications.id,
                ),
              ),
            ])
          ..where(_database.medications.isArchived.equals(isArchived))
          ..orderBy(<OrderingTerm>[
            OrderingTerm.desc(_database.inventoryEvents.effectiveAt),
            OrderingTerm.desc(_database.inventoryEvents.createdAt),
          ]);

    return query.watch().map(_latestMedicationRows);
  }

  Future<void> _insertInventoryEvent(
    InventoryEvent event, {
    DateTime? effectiveAt,
  }) {
    return _database
        .into(_database.inventoryEvents)
        .insert(
          InventoryEventsCompanion(
            id: Value<String>(event.id),
            medicationId: Value<String>(event.medicationId),
            eventType: Value<String>(event.type.name),
            stockUnits: Value<double>(event.stockUnits),
            effectiveAt: Value<DateTime>(
              effectiveAt ?? _normalizeUtc(event.effectiveAt),
            ),
            createdAt: Value<DateTime>(_normalizeUtc(event.createdAt)),
            note: Value<String?>(event.note),
          ),
        );
  }

  Future<InventoryEventRow?> _latestInventoryEvent(String medicationId) {
    final SimpleSelectStatement<InventoryEvents, InventoryEventRow> query =
        _database.select(_database.inventoryEvents)
          ..where(
            (InventoryEvents table) => table.medicationId.equals(medicationId),
          )
          ..orderBy(<OrderingTerm Function(InventoryEvents)>[
            (InventoryEvents table) => OrderingTerm.desc(table.effectiveAt),
            (InventoryEvents table) => OrderingTerm.desc(table.createdAt),
          ])
          ..limit(1);
    return query.getSingleOrNull();
  }

  List<Medication> _latestMedicationRows(List<TypedResult> rows) {
    final Map<String, Medication> medicationsById = <String, Medication>{};

    for (final TypedResult result in rows) {
      final MedicationRow medicationRow = result.readTable(
        _database.medications,
      );
      if (medicationsById.containsKey(medicationRow.id)) {
        continue;
      }
      final InventoryEventRow inventoryRow = result.readTable(
        _database.inventoryEvents,
      );
      medicationsById[medicationRow.id] = _toMedicationDomain(
        medicationRow,
        inventoryRow,
      );
    }

    return List<Medication>.unmodifiable(medicationsById.values);
  }

  InventoryEvent _toInventoryEventDomain(InventoryEventRow row) {
    final InventoryEventType type;
    try {
      type = InventoryEventType.values.byName(row.eventType);
    } on ArgumentError {
      throw StateError('Unknown inventory event type: ${row.eventType}');
    }

    return InventoryEvent(
      id: row.id,
      medicationId: row.medicationId,
      type: type,
      stockUnits: row.stockUnits,
      effectiveAt: row.effectiveAt.toLocal(),
      createdAt: row.createdAt.toLocal(),
      note: row.note,
    );
  }

  Medication _toMedicationDomain(
    MedicationRow medicationRow,
    InventoryEventRow inventoryRow,
  ) {
    final MedicationUnit unit;
    try {
      unit = MedicationUnit.values.byName(medicationRow.unit);
    } on ArgumentError {
      throw StateError('Unknown medication unit: ${medicationRow.unit}');
    }

    final ConsumptionSchedule schedule;
    final String? scheduleJson = medicationRow.consumptionScheduleJson;
    if (scheduleJson == null) {
      schedule = DailyConsumptionSchedule(
        amountPerOccurrence: medicationRow.unitsPerDay,
        occurrencesPerDay: 1,
      );
    } else {
      try {
        schedule = ConsumptionScheduleCodec.decode(scheduleJson);
      } on FormatException catch (error) {
        throw StateError(
          'Invalid consumption schedule for ${medicationRow.id}: $error',
        );
      }
    }

    return Medication(
      id: medicationRow.id,
      name: medicationRow.name,
      unit: unit,
      stockAtRecord: inventoryRow.stockUnits,
      consumptionSchedule: schedule,
      inventoryRecordedAt: inventoryRow.effectiveAt.toLocal(),
      alertLeadDays: medicationRow.alertLeadDays,
      notes: medicationRow.notes,
      isArchived: medicationRow.isArchived,
    );
  }

  DateTime _normalizeUtc(DateTime value) {
    final int millisecondsSinceEpoch =
        value.toUtc().millisecondsSinceEpoch ~/
        Duration.millisecondsPerSecond *
        Duration.millisecondsPerSecond;
    return DateTime.fromMillisecondsSinceEpoch(
      millisecondsSinceEpoch,
      isUtc: true,
    );
  }

  DateTime _nowUtc() => _normalizeUtc(_clock());

  Future<MedicationRow?> _findMedicationRow(String medicationId) {
    return (_database.select(_database.medications)
          ..where((Medications table) => table.id.equals(medicationId)))
        .getSingleOrNull();
  }

  Future<void> _setArchiveState({
    required String medicationId,
    required bool targetIsArchived,
    required MedicationLifecycleOperation operation,
  }) async {
    await _database.transaction(() async {
      final MedicationRow? existing = await _findMedicationRow(medicationId);
      MedicationLifecyclePolicy.ensureAllowed(
        medicationId: medicationId,
        isArchived: existing?.isArchived,
        operation: operation,
      );
      final int affected =
          await (_database.update(
            _database.medications,
          )..where((Medications table) => table.id.equals(medicationId))).write(
            MedicationsCompanion(
              isArchived: Value<bool>(targetIsArchived),
              updatedAt: Value<DateTime>(_nowUtc()),
            ),
          );
      if (affected != 1) {
        throw StateError('Lifecycle transition did not affect one aggregate.');
      }
    });
  }
}
