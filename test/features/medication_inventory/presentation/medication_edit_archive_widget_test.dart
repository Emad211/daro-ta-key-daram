import 'package:daro_ta_key_daram/app/app.dart';
import 'package:daro_ta_key_daram/app/router.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/consumption_schedule.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/inventory_event.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/in_memory_medication_repository.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/presentation/providers/medication_providers.dart';
import 'package:daro_ta_key_daram/features/notifications/infrastructure/noop_local_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2026, 7, 18, 8);

  setUp(() {
    appRouter.go('/');
  });

  testWidgets('edits metadata without changing schedule or stock history', (
    WidgetTester tester,
  ) async {
    final Medication medication = _medication(now, notes: 'قدیمی');
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(
          seed: <Medication>[medication],
          clock: () => now,
        );

    await _pumpAppAt(
      tester,
      repository,
      now,
      '/medications/${medication.id}/edit',
    );

    await tester.enterText(
      find.byKey(const Key('edit-medication-name')),
      'متفورمین جدید',
    );
    final Finder alertDays = find.byKey(
      const Key('edit-medication-alert-days'),
    );
    await _scrollTo(tester, alertDays);
    await tester.enterText(alertDays, '۷');

    final Finder notes = find.byKey(const Key('edit-medication-notes'));
    await _scrollTo(tester, notes);
    await tester.enterText(notes, '');

    final Finder save = find.byKey(const Key('save-medication-metadata'));
    await _scrollTo(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    final Medication updated = (await repository.findById(medication.id))!;
    final List<InventoryEvent> events = await repository
        .watchInventoryEvents(medication.id)
        .first;
    expect(updated.name, 'متفورمین جدید');
    expect(updated.consumptionSchedule, medication.consumptionSchedule);
    expect(updated.alertLeadDays, 7);
    expect(updated.notes, isNull);
    expect(updated.stockAtRecord, 30);
    expect(events, hasLength(1));
    expect(events.single.type, InventoryEventType.initial);
  });

  testWidgets(
    'changes to an every-N-days schedule after explicit confirmation',
    (WidgetTester tester) async {
      final Medication medication = _medication(now);
      final InMemoryMedicationRepository repository =
          InMemoryMedicationRepository(
            seed: <Medication>[medication],
            clock: () => now,
          );

      await _pumpAppAt(
        tester,
        repository,
        now,
        '/medications/${medication.id}/edit',
      );

      await tester.tap(find.byKey(const Key('schedule-kind')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('هر چند روز یک‌بار').last);
      await tester.pumpAndSettle();

      final Finder save = find.byKey(const Key('save-medication-metadata'));
      await _scrollTo(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.text('تغییر برنامه مصرف؟'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-schedule-change')));
      await tester.pumpAndSettle();

      final Medication updated = (await repository.findById(medication.id))!;
      final List<InventoryEvent> events = await repository
          .watchInventoryEvents(medication.id)
          .first;
      expect(
        updated.consumptionSchedule,
        EveryNDaysConsumptionSchedule(amountPerOccurrence: 1, intervalDays: 2),
      );
      expect(events, hasLength(2));
      expect(
        events.where(
          (InventoryEvent event) =>
              event.type == InventoryEventType.scheduleChange,
        ),
        hasLength(1),
      );
      expect(
        events.where(
          (InventoryEvent event) => event.type == InventoryEventType.initial,
        ),
        hasLength(1),
      );
    },
  );

  testWidgets('creates a selected-weekday schedule without decimal averaging', (
    WidgetTester tester,
  ) async {
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(clock: () => now);

    await _pumpAppAt(tester, repository, now, '/add');

    await tester.enterText(
      find.byKey(const Key('add-medication-name')),
      'ویتامین D',
    );
    await tester.enterText(find.byKey(const Key('add-medication-stock')), '۴');
    await tester.tap(find.byKey(const Key('schedule-kind')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('روزهای مشخص هفته').last);
    await tester.pumpAndSettle();

    final Finder friday = find.byKey(const Key('schedule-weekday-5'));
    await _scrollTo(tester, friday);
    await tester.tap(friday);
    await tester.pumpAndSettle();

    final Finder save = find.byKey(const Key('save-new-medication'));
    await _scrollTo(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    final List<Medication> medications = await repository
        .watchActiveMedications()
        .first;
    expect(medications, hasLength(1));
    expect(
      medications.single.consumptionSchedule,
      WeeklyConsumptionSchedule(
        amountPerOccurrence: 1,
        weekdays: <int>{DateTime.friday},
      ),
    );
  });

  testWidgets('restores an archived medication from archive management', (
    WidgetTester tester,
  ) async {
    final Medication medication = _medication(now).copyWith(isArchived: true);
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(seed: <Medication>[medication]);

    await _pumpAppAt(tester, repository, now, '/archive');

    expect(find.text('متفورمین'), findsOneWidget);
    await tester.tap(find.byKey(Key('restore-${medication.id}')));
    await tester.pumpAndSettle();

    expect(await repository.watchArchivedMedications().first, isEmpty);
    expect(await repository.watchActiveMedications().first, hasLength(1));
  });
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpAppAt(
  WidgetTester tester,
  InMemoryMedicationRepository repository,
  DateTime now,
  String route,
) async {
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
  appRouter.go(route);
  await tester.pumpAndSettle();
}

Medication _medication(DateTime now, {String? notes}) {
  return Medication(
    id: 'medication-1',
    name: 'متفورمین',
    unit: MedicationUnit.tablet,
    stockAtRecord: 30,
    consumptionSchedule: DailyConsumptionSchedule(
      amountPerOccurrence: 1,
      occurrencesPerDay: 2,
    ),
    inventoryRecordedAt: now,
    notes: notes,
  );
}
