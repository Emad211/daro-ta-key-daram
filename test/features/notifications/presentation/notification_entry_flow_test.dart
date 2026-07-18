import 'package:daro_ta_key_daram/app/app.dart';
import 'package:daro_ta_key_daram/app/router.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/in_memory_medication_repository.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/presentation/providers/medication_providers.dart';
import 'package:daro_ta_key_daram/features/notifications/application/local_notification_service.dart';
import 'package:daro_ta_key_daram/features/notifications/domain/notification_payload.dart';
import 'package:daro_ta_key_daram/features/notifications/domain/notification_plan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    appRouter.go('/');
  });

  testWidgets('does not request permission automatically at startup', (
    WidgetTester tester,
  ) async {
    final _FakeNotificationService notifications = _FakeNotificationService(
      permission: NotificationPermissionState.denied,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          medicationRepositoryProvider.overrideWithValue(
            InMemoryMedicationRepository(),
          ),
          localNotificationServiceProvider.overrideWithValue(notifications),
        ],
        child: const DaroTaKeyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(notifications.initializeCalls, 1);
    expect(notifications.requestCalls, 0);

    await tester.tap(find.byTooltip('فعال‌کردن یادآوری موجودی'));
    await tester.pumpAndSettle();

    expect(notifications.requestCalls, 1);
    expect(
      find.textContaining('همه امکانات مدیریت دارو همچنان قابل استفاده‌اند'),
      findsOneWidget,
    );
  });

  testWidgets('notification launch payload opens the related medication', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 7, 18, 8);
    final Medication medication = Medication(
      id: 'medication-1',
      name: 'متفورمین',
      unit: MedicationUnit.tablet,
      stockAtRecord: 30,
      unitsPerDay: 2,
      inventoryRecordedAt: now,
    );
    final _FakeNotificationService notifications = _FakeNotificationService(
      permission: NotificationPermissionState.denied,
      launchPayload: const NotificationPayload(
        medicationId: 'medication-1',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          medicationRepositoryProvider.overrideWithValue(
            InMemoryMedicationRepository(seed: <Medication>[medication]),
          ),
          clockProvider.overrideWithValue(() => now),
          localNotificationServiceProvider.overrideWithValue(notifications),
        ],
        child: const DaroTaKeyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('متفورمین'), findsWidgets);
    expect(find.text('خرید مجدد'), findsOneWidget);
    expect(find.text('تاریخچه موجودی'), findsOneWidget);
  });
}

final class _FakeNotificationService implements LocalNotificationService {
  _FakeNotificationService({required this.permission, this.launchPayload});

  final NotificationPermissionState permission;
  final NotificationPayload? launchPayload;
  int initializeCalls = 0;
  int requestCalls = 0;

  @override
  Future<void> initialize({required NotificationTapHandler onTap}) async {
    initializeCalls += 1;
    if (launchPayload != null) {
      await onTap(launchPayload!);
    }
  }

  @override
  Future<NotificationPermissionState> permissionState() async => permission;

  @override
  Future<NotificationPermissionState> requestPermission() async {
    requestCalls += 1;
    return permission;
  }

  @override
  Future<void> schedule(NotificationPlan plan) async {}

  @override
  Future<void> cancel(int notificationId) async {}

  @override
  Future<void> cancelAll() async {}
}
