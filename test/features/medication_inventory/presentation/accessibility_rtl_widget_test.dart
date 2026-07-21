import 'package:daro_ta_key_daram/app/app.dart';
import 'package:daro_ta_key_daram/app/router.dart';
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

  for (final double textScale in <double>[1, 1.3, 2]) {
    testWidgets('critical RTL flows remain operable at text scale $textScale', (
      WidgetTester tester,
    ) async {
      _configureViewport(tester, textScale);
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        final Medication active = _medication(now);
        final Medication archived = Medication(
          id: 'archived-medication',
          name: 'داروی آرشیوشده با نام نسبتاً طولانی',
          unit: MedicationUnit.capsule,
          stockAtRecord: 12,
          unitsPerDay: 1,
          inventoryRecordedAt: now,
          isArchived: true,
        );
        final InMemoryMedicationRepository repository =
            InMemoryMedicationRepository(
              seed: <Medication>[active, archived],
              clock: () => now,
            );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              rawMedicationRepositoryProvider.overrideWithValue(repository),
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

        await _openRoute(tester, '/');
        expect(find.text('دارو تا کی دارم؟'), findsOneWidget);
        expect(
          find.bySemanticsLabel('حریم خصوصی و مدیریت داده‌ها'),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('مدیریت آرشیو'), findsOneWidget);
        expect(
          find.bySemanticsLabel('فعال‌کردن یادآوری موجودی'),
          findsOneWidget,
        );
        _expectNoFlutterExceptions(tester, 'dashboard at scale $textScale');

        await _openRoute(tester, '/add');
        final Finder addSave = find.byKey(const Key('save-new-medication'));
        await _scrollTo(tester, addSave);
        expect(addSave, findsOneWidget);
        _expectNoFlutterExceptions(tester, 'add form at scale $textScale');

        await _openRoute(tester, '/medications/${active.id}');
        expect(find.bySemanticsLabel('ویرایش مشخصات'), findsOneWidget);
        expect(find.bySemanticsLabel('آرشیو دارو'), findsOneWidget);
        final Finder restock = find.widgetWithText(FilledButton, 'خرید مجدد');
        await _scrollTo(tester, restock);
        await tester.tap(restock);
        await tester.pumpAndSettle();
        final Finder stock = find.byKey(const Key('inventory-stock-input'));
        await tester.enterText(stock, '۴۰');
        FocusManager.instance.primaryFocus?.unfocus();
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        final Finder review = find.byKey(const Key('review-inventory-event'));
        await _dragSheetUntilVisible(tester, review);
        await tester.tap(review);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('confirm-inventory-event')),
          findsOneWidget,
        );
        _expectNoFlutterExceptions(
          tester,
          'inventory review at scale $textScale',
        );
        await tester.tap(find.byKey(const Key('cancel-inventory-event')));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(12, 12));
        await tester.pumpAndSettle();

        await _openRoute(tester, '/medications/${active.id}/edit');
        final Finder editSave = find.byKey(
          const Key('save-medication-metadata'),
        );
        await _scrollTo(tester, editSave);
        expect(editSave, findsOneWidget);
        _expectNoFlutterExceptions(tester, 'edit form at scale $textScale');

        await _openRoute(tester, '/archive');
        expect(find.byKey(Key('restore-${archived.id}')), findsOneWidget);
        expect(find.bySemanticsLabel('حذف دائمی'), findsOneWidget);
        _expectNoFlutterExceptions(tester, 'archive at scale $textScale');

        await _openRoute(tester, '/privacy');
        expect(find.text('حریم خصوصی و اطلاعات برنامه'), findsOneWidget);
        final Finder deleteAll = find.byKey(
          const Key('delete-all-medication-data'),
        );
        await _scrollTo(tester, deleteAll);
        expect(deleteAll, findsOneWidget);
        _expectNoFlutterExceptions(tester, 'privacy at scale $textScale');
      } finally {
        semantics.dispose();
      }
    });
  }
}

void _configureViewport(WidgetTester tester, double textScale) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

Future<void> _openRoute(WidgetTester tester, String route) async {
  appRouter.go(route);
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
}) async {
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: scrollable ?? find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _dragSheetUntilVisible(WidgetTester tester, Finder target) async {
  final double logicalWidth =
      tester.view.physicalSize.width / tester.view.devicePixelRatio;
  final double logicalHeight =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;

  for (int attempt = 0; attempt < 5; attempt += 1) {
    final Rect targetRect = tester.getRect(target);
    if (targetRect.top >= 0 && targetRect.bottom <= logicalHeight) {
      return;
    }
    await tester.dragFrom(
      Offset(logicalWidth / 2, logicalHeight - 96),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
  }

  final Rect finalRect = tester.getRect(target);
  expect(
    finalRect.bottom,
    lessThanOrEqualTo(logicalHeight),
    reason: 'The inventory review action must be reachable by swiping.',
  );
}

void _expectNoFlutterExceptions(WidgetTester tester, String context) {
  final List<Object> exceptions = <Object>[];
  Object? exception;
  while ((exception = tester.takeException()) != null) {
    exceptions.add(exception!);
  }
  expect(exceptions, isEmpty, reason: context);
}

Medication _medication(DateTime now) {
  return Medication(
    id: 'active-medication',
    name: 'متفورمین با نام نمایشی طولانی برای آزمون دسترس‌پذیری',
    unit: MedicationUnit.tablet,
    stockAtRecord: 30,
    unitsPerDay: 2,
    inventoryRecordedAt: now,
    notes: 'توضیح طولانی برای بررسی شکستن خطوط در چیدمان راست‌به‌چپ.',
  );
}
