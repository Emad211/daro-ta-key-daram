import 'package:daro_ta_key_daram/app/app.dart';
import 'package:daro_ta_key_daram/app/router.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/in_memory_medication_repository.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/presentation/providers/medication_providers.dart';
import 'package:daro_ta_key_daram/features/notifications/application/local_notification_service.dart';
import 'package:daro_ta_key_daram/features/notifications/infrastructure/noop_local_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2026, 7, 18, 8);

  setUp(() {
    appRouter.go('/');
  });

  testWidgets('edits metadata and clears notes without touching stock', (
    WidgetTester tester,
  ) async {
    final Medication medication = _medication(now, notes: 'قدیمی');
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(seed: <Medication>[medication]);

    appRouter.go('/medications/${medication.id}/edit');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          medicationRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => now),
          localNotificationServiceProvider.overrideWithValue(
            const NoopLocalNotificationService(),
          ),
        ],
        child: const DaroTaKeyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('edit-medication-name')),
      'متفورمین جدید',
    );
    await tester.enterText(
      find.byKey(const Key('edit-medication-daily-use')),
      '۳',
    );
    await tester.enterText(
      find.byKey(const Key('edit-medication-alert-days')),
      '۷',
    );
    await tester.enterText(find.byKey(const Key('edit-medication-notes')), '');
    await tester.tap(find.byKey(const Key('save-medication-metadata')));
    await tester.pumpAndSettle();

    final Medication? updated = await repository.findById(medication.id);
    final events = await repository.watchInventoryEvents(medication.id).first;
    expect(updated?.name, 'متفورمین جدید');
    expect(updated?.unitsPerDay, 3);
    expect(updated?.alertLeadDays, 7);
    expect(updated?.notes, isNull);
    expect(updated?.stockAtRecord, 30);
    expect(events, hasLength(1));
  });

  testWidgets('restores an archived medication from archive management', (
    WidgetTester tester,
  ) async {
    final Medication medication = _medication(now).copyWith(isArchived: true);
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(seed: <Medication>[medication]);

    appRouter.go('/archive');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          medicationRepositoryProvider.overrideWithValue(repository),
          localNotificationServiceProvider.overrideWithValue(
            const NoopLocalNotificationService(),
          ),
        ],
        child: const DaroTaKeyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('متفورمین'), findsOneWidget);
    await tester.tap(find.byKey(Key('restore-${medication.id}')));
    await tester.pumpAndSettle();

    expect(await repository.watchArchivedMedications().first, isEmpty);
    expect(await repository.watchActiveMedications().first, hasLength(1));
  });
}

Medication _medication(DateTime now, {String? notes}) {
  return Medication(
    id: 'medication-1',
    name: 'متفورمین',
    unit: MedicationUnit.tablet,
    stockAtRecord: 30,
    unitsPerDay: 2,
    inventoryRecordedAt: now,
    notes: notes,
  );
}
