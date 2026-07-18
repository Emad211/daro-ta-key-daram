import 'notification_payload.dart';

enum StockNotificationKind { lowStock, depleted }

final class NotificationPlan {
  const NotificationPlan({
    required this.id,
    required this.medicationId,
    required this.kind,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.payload,
  });

  final int id;
  final String medicationId;
  final StockNotificationKind kind;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final NotificationPayload payload;
}
