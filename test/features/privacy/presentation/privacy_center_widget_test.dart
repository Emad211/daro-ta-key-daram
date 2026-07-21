import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/in_memory_medication_repository.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/presentation/providers/medication_providers.dart';
import 'package:daro_ta_key_daram/features/notifications/application/local_notification_service.dart';
import 'package:daro_ta_key_daram/features/notifications/domain/notification_plan.dart';
import 'package:daro_ta_key_daram/features/privacy/presentation/privacy_center_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 7, 21, 12);

  testWidgets('cancelling the destructive dialog has no side effects', (
    WidgetTester tester,
  ) async {
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(
          seed: <Medication>[_medication('active', now)],
          clock: () => now,
        );
    final _PrivacyNotificationService notifications =
        _PrivacyNotificationService();
    await _pumpPrivacyCenter(tester, repository, notifications, now);

    await _openDeleteDialog(tester);
    await tester.tap(
      find.byKey(const Key('cancel-delete-all-medication-data')),
    );
    await tester.pumpAndSettle();

    expect(await repository.watchActiveMedications().first, hasLength(1));
    expect(notifications.cancelAllCalls, 0);
  });

  testWidgets('confirmation deletes active and archived medication data', (
    WidgetTester tester,
  ) async {
    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(
          seed: <Medication>[
            _medication('active', now),
            _medication('archived', now, isArchived: true),
          ],
          clock: () => now,
        );
    final _PrivacyNotificationService notifications =
        _PrivacyNotificationService();
    await _pumpPrivacyCenter(tester, repository, notifications, now);

    await _openDeleteDialog(tester);
    await tester.tap(
      find.byKey(const Key('confirm-delete-all-medication-data')),
    );
    await tester.pumpAndSettle();

    expect(await repository.watchActiveMedications().first, isEmpty);
    expect(await repository.watchArchivedMedications().first, isEmpty);
    expect(notifications.cancelAllCalls, 1);
    expect(find.text('اطلاعات دارویی محلی حذف شده‌اند.'), findsOneWidget);
  });

  testWidgets(
    'notification cleanup failure is recoverable without data rollback',
    (WidgetTester tester) async {
      final InMemoryMedicationRepository repository =
          InMemoryMedicationRepository(
            seed: <Medication>[_medication('active', now)],
            clock: () => now,
          );
      final _PrivacyNotificationService notifications =
          _PrivacyNotificationService()..failCancelAll = true;
      await _pumpPrivacyCenter(tester, repository, notifications, now);

      await _openDeleteDialog(tester);
      await tester.tap(
        find.byKey(const Key('confirm-delete-all-medication-data')),
      );
      await tester.pumpAndSettle();

      expect(await repository.watchActiveMedications().first, isEmpty);
      expect(notifications.cancelAllCalls, 1);
      expect(
        find.byKey(const Key('retry-notification-cleanup')),
        findsOneWidget,
      );

      notifications.failCancelAll = false;
      final Finder retryCleanup = find.byKey(
        const Key('retry-notification-cleanup'),
      );
      await tester.scrollUntilVisible(
        retryCleanup,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(retryCleanup);
      await tester.pumpAndSettle();

      expect(notifications.cancelAllCalls, 2);
      expect(find.byKey(const Key('retry-notification-cleanup')), findsNothing);
      expect(find.text('اطلاعات دارویی محلی حذف شده‌اند.'), findsOneWidget);
    },
  );

  testWidgets('privacy controls remain reachable in RTL at text scale 2.0', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    final InMemoryMedicationRepository repository =
        InMemoryMedicationRepository(
          seed: <Medication>[_medication('active', now)],
          clock: () => now,
        );
    await _pumpPrivacyCenter(
      tester,
      repository,
      _PrivacyNotificationService(),
      now,
    );

    final Finder deleteButton = find.byKey(
      const Key('delete-all-medication-data'),
    );
    await tester.scrollUntilVisible(
      deleteButton,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(deleteButton, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPrivacyCenter(
  WidgetTester tester,
  InMemoryMedicationRepository repository,
  _PrivacyNotificationService notifications,
  DateTime now,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        rawMedicationRepositoryProvider.overrideWithValue(repository),
        localNotificationServiceProvider.overrideWithValue(notifications),
        clockProvider.overrideWithValue(() => now),
      ],
      child: const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: PrivacyCenterScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openDeleteDialog(WidgetTester tester) async {
  final Finder deleteButton = find.byKey(
    const Key('delete-all-medication-data'),
  );
  await tester.scrollUntilVisible(
    deleteButton,
    260,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(deleteButton);
  await tester.pumpAndSettle();
  expect(find.text('حذف همه اطلاعات دارویی؟'), findsOneWidget);
}

Medication _medication(String id, DateTime now, {bool isArchived = false}) {
  return Medication(
    id: id,
    name: 'داروی $id',
    unit: MedicationUnit.tablet,
    stockAtRecord: 20,
    unitsPerDay: 1,
    inventoryRecordedAt: now,
    isArchived: isArchived,
  );
}

final class _PrivacyNotificationService implements LocalNotificationService {
  bool failCancelAll = false;
  int cancelAllCalls = 0;

  @override
  Future<void> cancelAll() async {
    cancelAllCalls += 1;
    if (failCancelAll) {
      throw StateError('cancelAll failed');
    }
  }

  @override
  Future<void> cancel(int notificationId) async {}

  @override
  Future<void> initialize({required NotificationTapHandler onTap}) async {}

  @override
  Future<NotificationPermissionState> permissionState() async {
    return NotificationPermissionState.granted;
  }

  @override
  Future<NotificationPermissionState> requestPermission() async {
    return NotificationPermissionState.granted;
  }

  @override
  Future<void> schedule(NotificationPlan plan) async {}
}
