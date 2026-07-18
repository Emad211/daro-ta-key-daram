import 'package:daro_ta_key_daram/app/app.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/in_memory_medication_repository.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/presentation/providers/medication_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders Persian app title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          medicationRepositoryProvider.overrideWithValue(
            InMemoryMedicationRepository.withDemoData(),
          ),
        ],
        child: const DaroTaKeyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('دارو تا کی دارم؟'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
