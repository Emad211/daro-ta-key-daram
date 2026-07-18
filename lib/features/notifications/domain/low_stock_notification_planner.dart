import '../../medication_inventory/domain/medication.dart';
import 'notification_id.dart';
import 'notification_payload.dart';
import 'notification_plan.dart';

final class LowStockNotificationPlanner {
  LowStockNotificationPlanner({
    this.preferredLocalHour = 9,
    this.minimumLeadTime = const Duration(minutes: 1),
  }) {
    if (preferredLocalHour < 0 || preferredLocalHour > 23) {
      throw RangeError.range(
        preferredLocalHour,
        0,
        23,
        'preferredLocalHour',
      );
    }
    if (minimumLeadTime.isNegative) {
      throw ArgumentError.value(
        minimumLeadTime,
        'minimumLeadTime',
        'Minimum lead time cannot be negative.',
      );
    }
  }

  final int preferredLocalHour;
  final Duration minimumLeadTime;

  NotificationPlan? plan({
    required Medication medication,
    required DateTime now,
  }) {
    if (medication.isArchived) {
      return null;
    }

    final DateTime localNow = now.toLocal();
    final stock = medication.stockAt(localNow);
    final DateTime depletionAt = stock.depletionAt.toLocal();
    final DateTime reorderAt = stock.reorderAt.toLocal();
    final DateTime preferredReorderTime = DateTime(
      reorderAt.year,
      reorderAt.month,
      reorderAt.day,
      preferredLocalHour,
    );

    final bool isDepleted = !depletionAt.isAfter(localNow);
    final DateTime scheduledAt = preferredReorderTime.isAfter(localNow)
        ? preferredReorderTime
        : localNow.add(minimumLeadTime);
    final NotificationPayload payload = NotificationPayload(
      medicationId: medication.id,
    );

    return NotificationPlan(
      id: NotificationId.forMedication(medication.id),
      medicationId: medication.id,
      kind: isDepleted
          ? StockNotificationKind.depleted
          : StockNotificationKind.lowStock,
      title: isDepleted
          ? 'موجودی دارو احتمالاً تمام شده'
          : 'موجودی دارو رو به اتمام است',
      body: isDepleted
          ? 'موجودی ${medication.name} را بررسی و در صورت خرید، عدد جدید را ثبت کنید.'
          : 'برای ${medication.name} حدود ${stock.fullRemainingDays} روز کامل موجودی باقی مانده است.',
      scheduledAt: scheduledAt,
      payload: payload,
    );
  }
}
