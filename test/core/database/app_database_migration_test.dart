import 'dart:io';

import 'package:daro_ta_key_daram/core/database/app_database.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/consumption_schedule.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/consumption_schedule_codec.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test('migrates a v1 daily rate to a versioned daily schedule', () async {
    final Directory directory = await Directory.systemTemp.createTemp(
      'daro-migration-',
    );
    final File file = File('${directory.path}/database.sqlite');
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });

    final sqlite.Database legacy = sqlite.sqlite3.open(file.path);
    legacy
      ..execute('''
        CREATE TABLE medications (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          unit TEXT NOT NULL,
          units_per_day REAL NOT NULL CHECK (units_per_day > 0),
          alert_lead_days INTEGER NOT NULL DEFAULT 5,
          notes TEXT NULL,
          is_archived INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''')
      ..execute('''
        CREATE TABLE inventory_events (
          id TEXT NOT NULL PRIMARY KEY,
          medication_id TEXT NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
          event_type TEXT NOT NULL,
          stock_units REAL NOT NULL CHECK (stock_units >= 0),
          effective_at INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          note TEXT NULL
        );
      ''')
      ..execute('''
        CREATE TABLE app_preferences (
          key TEXT NOT NULL PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''')
      ..execute('''
        CREATE TABLE ad_frequency_caps (
          placement TEXT NOT NULL PRIMARY KEY,
          meaningful_actions INTEGER NOT NULL DEFAULT 0,
          last_shown_at INTEGER NULL,
          day_key TEXT NOT NULL,
          shown_today INTEGER NOT NULL DEFAULT 0
        );
      ''')
      ..execute(
        'INSERT INTO medications '
        '(id, name, unit, units_per_day, alert_lead_days, notes, '
        'is_archived, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          'legacy-medication',
          'Legacy',
          'tablet',
          1.5,
          5,
          null,
          0,
          1,
          1,
        ],
      )
      ..execute('PRAGMA user_version = 1')
      ..close();

    final AppDatabase database = AppDatabase(NativeDatabase(file));
    addTearDown(database.close);

    final MedicationRow row = await database.select(database.medications).getSingle();
    final QueryRow versionRow = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    final ConsumptionSchedule schedule = ConsumptionScheduleCodec.decode(
      row.consumptionScheduleJson!,
    );

    expect(versionRow.read<int>('user_version'), 2);
    expect(row.unitsPerDay, 1.5);
    expect(
      schedule,
      DailyConsumptionSchedule(
        amountPerOccurrence: 1.5,
        occurrencesPerDay: 1,
      ),
    );
  });
}
