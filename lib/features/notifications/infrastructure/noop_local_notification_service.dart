import '../application/local_notification_service.dart';
import '../domain/notification_plan.dart';

final class NoopLocalNotificationService implements LocalNotificationService {
  const NoopLocalNotificationService();

  @override
  Future<void> cancel(int notificationId) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> initialize({required NotificationTapHandler onTap}) async {}

  @override
  Future<NotificationPermissionState> permissionState() async {
    return NotificationPermissionState.unsupported;
  }

  @override
  Future<NotificationPermissionState> requestPermission() async {
    return NotificationPermissionState.unsupported;
  }

  @override
  Future<void> schedule(NotificationPlan plan) async {}
}
