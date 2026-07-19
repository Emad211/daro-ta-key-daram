import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('MedicationRow')
class Medications extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 80)();

  TextColumn get unit => text()();

  RealColumn get unitsPerDay =>
      real().customConstraint('NOT NULL CHECK (units_per_day > 0)')();

  TextColumn get consumptionScheduleJson => text().nullable()();

  IntColumn get alertLeadDays => integer().customConstraint(
    'NOT NULL DEFAULT 5 '
    'CHECK (alert_lead_days BETWEEN 0 AND 365)',
  )();

  TextColumn get notes => text().nullable()();

  BoolColumn get isArchived =>
      boolean().withDefault(const Constant<bool>(false))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('InventoryEventRow')
@TableIndex(
  name: 'idx_inventory_events_medication_effective',
  columns: <Symbol>{#medicationId, #effectiveAt},
)
class InventoryEvents extends Table {
  TextColumn get id => text()();

  TextColumn get medicationId =>
      text().references(Medications, #id, onDelete: KeyAction.cascade)();

  TextColumn get eventType => text()();

  RealColumn get stockUnits =>
      real().customConstraint('NOT NULL CHECK (stock_units >= 0)')();

  DateTimeColumn get effectiveAt => dateTime()();

  DateTimeColumn get createdAt => dateTime()();

  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('AppPreferenceRow')
class AppPreferences extends Table {
  TextColumn get key => text()();

  TextColumn get value => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

@DataClassName('AdFrequencyCapRow')
class AdFrequencyCaps extends Table {
  TextColumn get placement => text()();

  IntColumn get meaningfulActions =>
      integer().withDefault(const Constant<int>(0))();

  DateTimeColumn get lastShownAt => dateTime().nullable()();

  TextColumn get dayKey => text()();

  IntColumn get shownToday => integer().withDefault(const Constant<int>(0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{placement};
}

@DriftDatabase(
  tables: <Type>[Medications, InventoryEvents, AppPreferences, AdFrequencyCaps],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults()
    : super(
        driftDatabase(
          name: 'daro_ta_key_daram',
          native: const DriftNativeOptions(shareAcrossIsolates: true),
        ),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 2) {
        await migrator.addColumn(
          medications,
          medications.consumptionScheduleJson,
        );
        final List<QueryRow> rows = await customSelect(
          'SELECT id, units_per_day FROM medications',
        ).get();
        for (final QueryRow row in rows) {
          final String id = row.read<String>('id');
          final double legacyRate = row.read<double>('units_per_day');
          final String scheduleJson = jsonEncode(<String, Object>{
            'version': 1,
            'kind': 'daily',
            'amountPerOccurrence': legacyRate,
            'occurrencesPerDay': 1,
          });
          await customUpdate(
            'UPDATE medications '
            'SET consumption_schedule_json = ? '
            'WHERE id = ?',
            variables: <Variable<Object>>[
              Variable<String>(scheduleJson),
              Variable<String>(id),
            ],
            updates: <TableInfo<Table, Object>>{medications},
          );
        }
      }
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
