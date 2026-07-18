import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../application/medication_repository.dart';
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
    return _setArchiveState(medicationId: medicationId, isArchived: true);
  }

  @override
  Future<void> deletePermanently(String medicationId) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.medications,
      )..where((Medications table) => table.id.equals(medicationId))).go();
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
      if (medication == null) {
        throw StateError(
          'Cannot create inventory event for a missing medication.',
        );
      }

      await _insertInventoryEvent(event, effectiveAt: effectiveAt);
      await (_database.update(_database.medications)
            ..where((Medications table) => table.id.equals(event.medicationId)))
          .write(MedicationsCompanion(updatedAt: Value<DateTime>(now)));
    });
  }

  @override
  Future<void> restore(String medicationId) {
    return _setArchiveState(medicationId: medicationId, isArchived: false);
  }

  @override
  Future<void> upsert(Medication medication) async {
    final DateTime now = _nowUtc();
    final DateTime effectiveAt = _normalizeUtc(medication.inventoryRecordedAt);
    if (effectiveAt.isAfter(now)) {
      throw ArgumentError.value(
        medication.inventoryRecordedAt,
        'medication.inventoryRecordedAt',
        'Inventory baselines cannot become effective in the future.',
      );
    }

    await _database.transaction(() async {
      final MedicationRow? existing =
          await (_database.select(_database.medications)
                ..where((Medications table) => table.id.equals(medication.id)))
              .getSingleOrNull();

      final MedicationsCompanion companion = MedicationsCompanion(
        id: Value<String>(medication.id),
        name: Value<String>(medication.name),
        unit: Value<String>(medication.unit.name),
        unitsPerDay: Value<double>(medication.unitsPerDay),
        alertLeadDays: Value<int>(medication.alertLeadDays),
        notes: Value<String?>(medication.notes),
        isArchived: Value<bool>(medication.isArchived),
        createdAt: Value<DateTime>(_normalizeUtc(existing?.createdAt ?? now)),
        updatedAt: Value<DateTime>(now),
      );

      if (existing == null) {
        await _database.into(_database.medications).insert(companion);
      } else {
        await (_database.update(_database.medications)
              ..where((Medications table) => table.id.equals(medication.id)))
            .write(companion);
      }

      final InventoryEventRow? latest = await _latestInventoryEvent(
        medication.id,
      );
      final bool baselineChanged =
          latest == null ||
          latest.stockUnits != medication.stockAtRecord ||
          _normalizeUtc(latest.effectiveAt) != effectiveAt;

      if (baselineChanged) {
        await _insertInventoryEvent(
          InventoryEvent(
            id: _uuid.v4(),
            medicationId: medication.id,
            type: latest == null
                ? InventoryEventType.initial
                : InventoryEventType.correction,
            stockUnits: medication.stockAtRecord,
            effectiveAt: effectiveAt,
            createdAt: now,
          ),
          effectiveAt: effectiveAt,
        );
      }
    });
  }

  @override
  Stream<List<Medication>> watchActiveMedications() {
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
          ..where(_database.medications.isArchived.equals(false))
          ..orderBy(<OrderingTerm>[
            OrderingTerm.desc(_database.inventoryEvents.effectiveAt),
            OrderingTerm.desc(_database.inventoryEvents.createdAt),
          ]);

    return query.watch().map(_latestMedicationRows);
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

    return Medication(
      id: medicationRow.id,
      name: medicationRow.name,
      unit: unit,
      stockAtRecord: inventoryRow.stockUnits,
      unitsPerDay: medicationRow.unitsPerDay,
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

  Future<void> _setArchiveState({
    required String medicationId,
    required bool isArchived,
  }) async {
    final int affected =
        await (_database.update(
          _database.medications,
        )..where((Medications table) => table.id.equals(medicationId))).write(
          MedicationsCompanion(
            isArchived: Value<bool>(isArchived),
            updatedAt: Value<DateTime>(_nowUtc()),
          ),
        );
    if (affected == 0) {
      throw StateError('Medication $medicationId does not exist.');
    }
  }
}
