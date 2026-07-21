import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/in_memory_medication_repository.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/presentation/providers/medication_providers.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/presentation/screens/medication_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('records a restock from the medication details flow', (
    WidgetTester tester,
  ) async {
    final DateTime initialTime = DateTime.utc(2026, 7, 18, 8);
    final DateTime actionTime = DateTime.utc(2026, 7, 20, 10);
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(
          seed: <Medication>[
            Medication(
              id: 'medication-1',
              name: 'متفورمین',
              unit: MedicationUnit.tablet,
              stockAtRecord: 30,
              unitsPerDay: 2,
              inventoryRecordedAt: initialTime,
            ),
          ],
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          medicationRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => actionTime),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MedicationDetailsScreen(medicationId: 'medication-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('متفورمین'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'خرید مجدد'));
    await tester.pumpAndSettle();

    expect(find.text('ثبت خرید مجدد'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '۴۰');
    await tester.tap(find.byKey(const Key('review-inventory-event')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-inventory-event')));
    await tester.pumpAndSettle();

    final Finder historyTitle = find.text('تاریخچه موجودی');
    await tester.scrollUntilVisible(
      historyTitle,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(historyTitle, findsOneWidget);
    expect(find.text('40\nقرص'), findsOneWidget);
    expect(find.text('خرید مجدد'), findsWidgets);
    expect(find.text('خرید مجدد با موفقیت ثبت شد.'), findsOneWidget);
  });

  testWidgets('shows a recoverable not-found state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          medicationRepositoryProvider.overrideWithValue(
            InMemoryMedicationRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MedicationDetailsScreen(medicationId: 'missing'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('دارو پیدا نشد'), findsOneWidget);
    expect(
      find.text('این دارو حذف شده یا شناسه آن معتبر نیست.'),
      findsOneWidget,
    );
  });
}
