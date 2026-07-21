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
  final DateTime now = DateTime(2026, 7, 21, 8);
  final Medication archived = Medication(
    id: 'archived-1',
    name: 'Archived',
    unit: MedicationUnit.tablet,
    stockAtRecord: 10,
    unitsPerDay: 1,
    inventoryRecordedAt: now,
    isArchived: true,
  );

  setUp(() {
    appRouter.go('/');
  });

  testWidgets('archived details expose no mutation controls', (
    WidgetTester tester,
  ) async {
    await _pumpAt(tester, archived, now, '/medications/${archived.id}');

    expect(find.byIcon(Icons.inventory_2_outlined), findsWidgets);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.archive_outlined), findsNothing);
    expect(find.byIcon(Icons.add_shopping_cart_outlined), findsNothing);
    expect(find.byIcon(Icons.edit_note_outlined), findsNothing);
  });

  testWidgets('direct archived edit route has no save command', (
    WidgetTester tester,
  ) async {
    await _pumpAt(
      tester,
      archived,
      now,
      '/medications/${archived.id}/edit',
    );

    expect(find.byKey(const Key('save-medication-metadata')), findsNothing);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });
}

Future<void> _pumpAt(
  WidgetTester tester,
  Medication archived,
  DateTime now,
  String route,
) async {
  final InMemoryMedicationRepository repository =
      InMemoryMedicationRepository(seed: <Medication>[archived]);
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
