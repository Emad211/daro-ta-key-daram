import 'dart:async';

import '../domain/notification_payload.dart';
import '../domain/notification_plan.dart';

enum NotificationPermissionState {
  granted,
  denied,
  notDetermined,
  unsupported,
}

typedef NotificationTapHandler = FutureOr<void> Function(
  NotificationPayload payload,
);

abstract interface class LocalNotificationService {
  Future<void> initialize({required NotificationTapHandler onTap});

  Future<NotificationPermissionState> permissionState();

  Future<NotificationPermissionState> requestPermission();

  Future<void> schedule(NotificationPlan plan);

  Future<void> cancel(int notificationId);

  Future<void> cancelAll();
}
