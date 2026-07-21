import 'dart:async';

import 'package:daro_ta_key_daram/app/app.dart';
import 'package:daro_ta_key_daram/app/router.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/application/medication_details_update.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/application/medication_lifecycle.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/application/medication_repository.dart';
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
  final DateTime now = DateTime.utc(2026, 7, 21, 9);

  setUp(() {
    appRouter.go('/');
  });

  testWidgets('failed create keeps form values and blocks duplicate submits', (
    WidgetTester tester,
  ) async {
    final _ControlledMedicationRepository repository =
        _ControlledMedicationRepository(clock: () => now);
    repository.createGate = Completer<void>();

    await _pumpAppAt(tester, repository, now, '/add');

    final Finder name = find.byKey(const Key('add-medication-name'));
    final Finder stock = find.byKey(const Key('add-medication-stock'));
    final Finder save = find.byKey(const Key('save-new-medication'));
    await tester.enterText(name, 'متفورمین آزمایشی');
    await tester.enterText(stock, '۲۴');
    await _scrollTo(tester, save);
    await tester.tap(save);
    await tester.pump();

    expect(repository.createCalls, 1);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.tap(save);
    await tester.pump();
    expect(repository.createCalls, 1);

    repository.createGate!.completeError(StateError('stale write'));
    await tester.pumpAndSettle();

    expect(
      find.text('اطلاعات در این فاصله تغییر کرده است. صفحه را تازه‌سازی کنید.'),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
    await _scrollTo(tester, name);
    expect(_fieldText(tester, name), 'متفورمین آزمایشی');
    expect(_fieldText(tester, stock), '۲۴');
    expect(await repository.watchActiveMedications().first, isEmpty);
  });

  testWidgets('failed edit keeps changed values and persists nothing', (
    WidgetTester tester,
  ) async {
    final Medication medication = _medication(now);
    final _ControlledMedicationRepository repository =
        _ControlledMedicationRepository(seed: <Medication>[medication]);
    repository.updateGate = Completer<void>();

    await _pumpAppAt(
      tester,
      repository,
      now,
      '/medications/${medication.id}/edit',
    );

    final Finder name = find.byKey(const Key('edit-medication-name'));
    final Finder save = find.byKey(const Key('save-medication-metadata'));
    await tester.enterText(name, 'نام ویرایش‌شده');
    await _scrollTo(tester, save);
    await tester.tap(save);
    await tester.pump();

    expect(repository.updateCalls, 1);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.tap(save);
    await tester.pump();
    expect(repository.updateCalls, 1);

    repository.updateGate!.completeError(
      const MedicationNotFoundException(
        'medication-1',
        MedicationLifecycleOperation.updateDetails,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('این دارو دیگر در دسترس نیست. صفحه را تازه‌سازی کنید.'),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
    await _scrollTo(tester, name);
    expect(_fieldText(tester, name), 'نام ویرایش‌شده');
    expect((await repository.findById(medication.id))!.name, medication.name);
  });

  testWidgets(
    'quantity review cancellation and rejected save create no history event',
    (WidgetTester tester) async {
      final Medication medication = _medication(now);
      final _ControlledMedicationRepository repository =
          _ControlledMedicationRepository(seed: <Medication>[medication]);
      repository.recordGate = Completer<void>();

      await _pumpAppAt(
        tester,
        repository,
        now,
        '/medications/${medication.id}',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'خرید مجدد'));
      await tester.pumpAndSettle();
      final Finder stock = find.byKey(const Key('inventory-stock-input'));
      final Finder note = find.byKey(const Key('inventory-note-input'));
      final Finder review = find.byKey(const Key('review-inventory-event'));
      await tester.enterText(stock, '۴۰');
      await tester.enterText(note, 'خرید آزمایشی');

      await tester.tap(review);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancel-inventory-event')));
      await tester.pumpAndSettle();

      expect(repository.recordCalls, 0);
      expect(_fieldText(tester, stock), '۴۰');
      expect(_fieldText(tester, note), 'خرید آزمایشی');
      expect(
        await repository.watchInventoryEvents(medication.id).first,
        hasLength(1),
      );

      await tester.tap(review);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-inventory-event')));
      await tester.pump();

      expect(repository.recordCalls, 1);
      expect(tester.widget<FilledButton>(review).onPressed, isNull);
      await tester.tap(review);
      await tester.pump();
      expect(repository.recordCalls, 1);

      repository.recordGate!.completeError(
        const MedicationLifecycleViolation(
          medicationId: 'medication-1',
          state: MedicationLifecycleState.archived,
          operation: MedicationLifecycleOperation.recordInventoryEvent,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('این دارو آرشیو شده است. ابتدا آن را بازیابی کنید.'),
        findsOneWidget,
      );
      expect(_fieldText(tester, stock), '۴۰');
      expect(_fieldText(tester, note), 'خرید آزمایشی');
      expect(
        await repository.watchInventoryEvents(medication.id).first,
        hasLength(1),
      );
      expect(tester.widget<FilledButton>(review).onPressed, isNotNull);
    },
  );

  testWidgets('failed archive blocks duplicates and keeps medication active', (
    WidgetTester tester,
  ) async {
    final Medication medication = _medication(now);
    final _ControlledMedicationRepository repository =
        _ControlledMedicationRepository(seed: <Medication>[medication]);
    repository.archiveGate = Completer<void>();

    await _pumpAppAt(tester, repository, now, '/medications/${medication.id}');

    final Finder archive = find.byKey(Key('archive-${medication.id}'));
    await tester.tap(archive);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-archive-medication')));
    await tester.pump();

    expect(repository.archiveCalls, 1);
    expect(tester.widget<IconButton>(archive).onPressed, isNull);
    await tester.tap(archive);
    await tester.pump();
    expect(repository.archiveCalls, 1);

    repository.archiveGate!.completeError(StateError('stale archive'));
    await tester.pumpAndSettle();

    expect(
      find.text('اطلاعات در این فاصله تغییر کرده است. صفحه را تازه‌سازی کنید.'),
      findsOneWidget,
    );
    expect((await repository.findById(medication.id))!.isArchived, isFalse);
    expect(tester.widget<IconButton>(archive).onPressed, isNotNull);
  });

  testWidgets('cancelled archive persists nothing and undo restores it', (
    WidgetTester tester,
  ) async {
    final Medication medication = _medication(now);
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(seed: <Medication>[medication]);

    await _pumpAppAt(tester, repository, now, '/medications/${medication.id}');

    final Finder archive = find.byKey(Key('archive-${medication.id}'));
    await tester.tap(archive);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cancel-archive-medication')));
    await tester.pumpAndSettle();
    expect((await repository.findById(medication.id))!.isArchived, isFalse);

    await tester.tap(archive);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-archive-medication')));
    await tester.pumpAndSettle();
    expect((await repository.findById(medication.id))!.isArchived, isTrue);
    expect(find.text('برگرداندن'), findsOneWidget);

    await tester.tap(find.text('برگرداندن'));
    await tester.pumpAndSettle();
    expect((await repository.findById(medication.id))!.isArchived, isFalse);
    expect(
      find.text('${medication.name} به فهرست فعال برگشت.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'restore blocks duplicate submissions and keeps item on failure',
    (WidgetTester tester) async {
      final Medication archived = _medication(now).copyWith(isArchived: true);
      final _ControlledMedicationRepository repository =
          _ControlledMedicationRepository(seed: <Medication>[archived]);
      repository.restoreGate = Completer<void>();

      await _pumpAppAt(tester, repository, now, '/archive');

      final Finder restore = find.byKey(Key('restore-${archived.id}'));
      await tester.tap(restore);
      await tester.pump();
      expect(repository.restoreCalls, 1);
      expect(tester.widget<FilledButton>(restore).onPressed, isNull);
      await tester.tap(restore);
      await tester.pump();
      expect(repository.restoreCalls, 1);

      repository.restoreGate!.completeError(
        const MedicationLifecycleViolation(
          medicationId: 'medication-1',
          state: MedicationLifecycleState.active,
          operation: MedicationLifecycleOperation.restore,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('این عملیات در وضعیت فعلی دارو قابل انجام نیست.'),
        findsOneWidget,
      );
      expect(await repository.watchArchivedMedications().first, hasLength(1));
      expect(tester.widget<FilledButton>(restore).onPressed, isNotNull);
    },
  );

  testWidgets('failed permanent deletion preserves aggregate and history', (
    WidgetTester tester,
  ) async {
    final Medication archived = _medication(now).copyWith(isArchived: true);
    final _ControlledMedicationRepository repository =
        _ControlledMedicationRepository(seed: <Medication>[archived]);
    repository.deleteGate = Completer<void>();

    await _pumpAppAt(tester, repository, now, '/archive');
    final Finder delete = find.byKey(Key('delete-${archived.id}'));
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('confirm-delete-${archived.id}')));
    await tester.pump();

    expect(repository.deleteCalls, 1);
    expect(tester.widget<IconButton>(delete).onPressed, isNull);
    await tester.tap(delete);
    await tester.pump();
    expect(repository.deleteCalls, 1);

    repository.deleteGate!.completeError(StateError('stale delete'));
    await tester.pumpAndSettle();

    expect(
      find.text('اطلاعات در این فاصله تغییر کرده است. صفحه را تازه‌سازی کنید.'),
      findsOneWidget,
    );
    expect(await repository.findById(archived.id), isNotNull);
    expect(
      await repository.watchInventoryEvents(archived.id).first,
      hasLength(1),
    );
    expect(tester.widget<IconButton>(delete).onPressed, isNotNull);
  });

  testWidgets(
    'cancelled permanent deletion leaves aggregate and history intact',
    (WidgetTester tester) async {
      final Medication archived = _medication(now).copyWith(isArchived: true);
      final InMemoryMedicationRepository repository =
          InMemoryMedicationRepository(seed: <Medication>[archived]);

      await _pumpAppAt(tester, repository, now, '/archive');
      await tester.tap(find.byKey(Key('delete-${archived.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('cancel-delete-${archived.id}')));
      await tester.pumpAndSettle();

      expect(await repository.findById(archived.id), isNotNull);
      expect(
        await repository.watchInventoryEvents(archived.id).first,
        hasLength(1),
      );
    },
  );
}

Future<void> _pumpAppAt(
  WidgetTester tester,
  MedicationRepository repository,
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

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester, Finder finder) {
  return tester.widget<TextFormField>(finder).controller!.text;
}

Medication _medication(DateTime now) {
  return Medication(
    id: 'medication-1',
    name: 'متفورمین',
    unit: MedicationUnit.tablet,
    stockAtRecord: 30,
    unitsPerDay: 2,
    inventoryRecordedAt: now,
  );
}

final class _ControlledMedicationRepository implements MedicationRepository {
  _ControlledMedicationRepository({
    List<Medication>? seed,
    DateTime Function()? clock,
  }) : _delegate = InMemoryMedicationRepository(seed: seed, clock: clock);

  final InMemoryMedicationRepository _delegate;
  Completer<void>? archiveGate;
  Completer<void>? createGate;
  Completer<void>? updateGate;
  Completer<void>? deleteGate;
  Completer<void>? recordGate;
  Completer<void>? restoreGate;
  int archiveCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int recordCalls = 0;
  int restoreCalls = 0;

  @override
  Future<void> archive(String medicationId) async {
    archiveCalls += 1;
    final Completer<void>? gate = archiveGate;
    if (gate != null) {
      await gate.future;
      return;
    }
    await _delegate.archive(medicationId);
  }

  @override
  Future<void> create(Medication medication) async {
    createCalls += 1;
    final Completer<void>? gate = createGate;
    if (gate != null) {
      await gate.future;
      return;
    }
    await _delegate.create(medication);
  }

  @override
  Future<void> deletePermanently(String medicationId) async {
    deleteCalls += 1;
    final Completer<void>? gate = deleteGate;
    if (gate != null) {
      await gate.future;
      return;
    }
    await _delegate.deletePermanently(medicationId);
  }

  @override
  Future<Medication?> findById(String medicationId) {
    return _delegate.findById(medicationId);
  }

  @override
  Future<void> recordInventoryEvent(InventoryEvent event) async {
    recordCalls += 1;
    final Completer<void>? gate = recordGate;
    if (gate != null) {
      await gate.future;
      return;
    }
    await _delegate.recordInventoryEvent(event);
  }

  @override
  Future<void> restore(String medicationId) async {
    restoreCalls += 1;
    final Completer<void>? gate = restoreGate;
    if (gate != null) {
      await gate.future;
      return;
    }
    await _delegate.restore(medicationId);
  }

  @override
  Future<void> updateDetails(MedicationDetailsUpdate update) async {
    updateCalls += 1;
    final Completer<void>? gate = updateGate;
    if (gate != null) {
      await gate.future;
      return;
    }
    await _delegate.updateDetails(update);
  }

  @override
  Stream<List<Medication>> watchActiveMedications() {
    return _delegate.watchActiveMedications();
  }

  @override
  Stream<List<Medication>> watchArchivedMedications() {
    return _delegate.watchArchivedMedications();
  }

  @override
  Stream<List<InventoryEvent>> watchInventoryEvents(String medicationId) {
    return _delegate.watchInventoryEvents(medicationId);
  }
}
