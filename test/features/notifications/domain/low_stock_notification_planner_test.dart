import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/notifications/domain/low_stock_notification_planner.dart';
import 'package:daro_ta_key_daram/features/notifications/domain/notification_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final LowStockNotificationPlanner planner = LowStockNotificationPlanner();

  test('schedules a future reorder date at the preferred local hour', () {
    final DateTime now = DateTime(2026, 7, 18, 8);
    final Medication medication = _medication(
      recordedAt: now,
      stock: 30,
      dailyUse: 2,
      alertLeadDays: 5,
    );

    final NotificationPlan? plan = planner.plan(
      medication: medication,
      now: now,
    );

    expect(plan, isNotNull);
    expect(plan?.kind, StockNotificationKind.lowStock);
    expect(plan?.scheduledAt, DateTime(2026, 7, 28, 9));
    expect(plan?.payload.medicationId, medication.id);
  });

  test('schedules a near-future alert when reorder time already passed', () {
    final DateTime recordedAt = DateTime(2026, 7, 1, 8);
    final DateTime now = DateTime(2026, 7, 14, 15);
    final Medication medication = _medication(
      recordedAt: recordedAt,
      stock: 30,
      dailyUse: 2,
      alertLeadDays: 5,
    );

    final NotificationPlan? plan = planner.plan(
      medication: medication,
      now: now,
    );

    expect(plan?.kind, StockNotificationKind.lowStock);
    expect(plan?.scheduledAt, now.add(const Duration(minutes: 1)));
  });

  test('schedules one depleted alert when estimated stock is exhausted', () {
    final DateTime recordedAt = DateTime(2026, 7, 1, 8);
    final DateTime now = DateTime(2026, 7, 20, 12);
    final Medication medication = _medication(
      recordedAt: recordedAt,
      stock: 10,
      dailyUse: 1,
      alertLeadDays: 3,
    );

    final NotificationPlan? plan = planner.plan(
      medication: medication,
      now: now,
    );

    expect(plan?.kind, StockNotificationKind.depleted);
    expect(plan?.scheduledAt, now.add(const Duration(minutes: 1)));
    expect(plan?.title, contains('تمام شده'));
  });

  test('returns no plan for an archived medication', () {
    final DateTime now = DateTime(2026, 7, 18, 8);
    final Medication medication = _medication(
      recordedAt: now,
      stock: 30,
      dailyUse: 2,
      alertLeadDays: 5,
      isArchived: true,
    );

    expect(planner.plan(medication: medication, now: now), isNull);
  });

  test('rejects invalid planner configuration', () {
    expect(
      () => LowStockNotificationPlanner(preferredLocalHour: 24),
      throwsRangeError,
    );
    expect(
      () => LowStockNotificationPlanner(
        minimumLeadTime: const Duration(seconds: -1),
      ),
      throwsArgumentError,
    );
  });
}

Medication _medication({
  required DateTime recordedAt,
  required double stock,
  required double dailyUse,
  required int alertLeadDays,
  bool isArchived = false,
}) {
  return Medication(
    id: 'medication-1',
    name: 'متفورمین',
    unit: MedicationUnit.tablet,
    stockAtRecord: stock,
    unitsPerDay: dailyUse,
    inventoryRecordedAt: recordedAt,
    alertLeadDays: alertLeadDays,
    isArchived: isArchived,
  );
}
