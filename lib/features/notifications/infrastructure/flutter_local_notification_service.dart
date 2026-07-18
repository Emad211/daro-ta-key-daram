import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../application/local_notification_service.dart';
import '../domain/notification_payload.dart';
import '../domain/notification_plan.dart';

final class FlutterLocalNotificationService
    implements LocalNotificationService {
  FlutterLocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'medication_stock_alerts',
        'یادآوری موجودی دارو',
        channelDescription: 'هشدار نزدیک‌شدن موجودی دارو به پایان',
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.private,
        icon: 'ic_notification',
      );

  final FlutterLocalNotificationsPlugin _plugin;
  NotificationTapHandler? _onTap;
  bool _initialized = false;

  @override
  Future<void> initialize({required NotificationTapHandler onTap}) async {
    _onTap = onTap;
    if (_initialized) {
      return;
    }

    await _configureLocalTimeZone();
    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    _initialized = true;

    final NotificationAppLaunchDetails? launchDetails = await _plugin
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      await _dispatchPayload(launchDetails?.notificationResponse?.payload);
    }
  }

  @override
  Future<NotificationPermissionState> permissionState() async {
    final AndroidFlutterLocalNotificationsPlugin? android = _androidPlugin;
    if (android == null) {
      return NotificationPermissionState.unsupported;
    }

    final bool? enabled = await android.areNotificationsEnabled();
    if (enabled == null) {
      return NotificationPermissionState.notDetermined;
    }
    return enabled
        ? NotificationPermissionState.granted
        : NotificationPermissionState.denied;
  }

  @override
  Future<NotificationPermissionState> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? android = _androidPlugin;
    if (android == null) {
      return NotificationPermissionState.unsupported;
    }

    final bool? granted = await android.requestNotificationsPermission();
    if (granted == null) {
      return NotificationPermissionState.notDetermined;
    }
    return granted
        ? NotificationPermissionState.granted
        : NotificationPermissionState.denied;
  }

  @override
  Future<void> schedule(NotificationPlan plan) async {
    _ensureInitialized();
    final DateTime localDate = plan.scheduledAt.toLocal();
    final tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      localDate.year,
      localDate.month,
      localDate.day,
      localDate.hour,
      localDate.minute,
      localDate.second,
    );

    await _plugin.zonedSchedule(
      id: plan.id,
      title: plan.title,
      body: plan.body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(android: _androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: plan.payload.encode(),
    );
  }

  @override
  Future<void> cancel(int notificationId) {
    return _plugin.cancel(id: notificationId);
  }

  @override
  Future<void> cancelAll() {
    return _plugin.cancelAll();
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin {
    return _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
  }

  Future<void> _configureLocalTimeZone() async {
    tz_data.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    unawaited(_dispatchPayload(response.payload));
  }

  Future<void> _dispatchPayload(String? encodedPayload) async {
    final NotificationPayload? payload = NotificationPayload.tryDecode(
      encodedPayload,
    );
    if (payload == null) {
      return;
    }
    await _onTap?.call(payload);
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('Local notification service is not initialized.');
    }
  }
}
