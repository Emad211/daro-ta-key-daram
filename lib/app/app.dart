import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

import '../core/performance/startup_diagnostics.dart';
import '../core/theme/app_theme.dart';
import '../features/medication_inventory/presentation/providers/medication_providers.dart';
import '../features/notifications/application/local_notification_service.dart';
import '../features/notifications/domain/notification_payload.dart';
import 'router.dart';

class DaroTaKeyApp extends ConsumerStatefulWidget {
  const DaroTaKeyApp({super.key});

  @override
  ConsumerState<DaroTaKeyApp> createState() => _DaroTaKeyAppState();
}

class _DaroTaKeyAppState extends ConsumerState<DaroTaKeyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      StartupDiagnostics.markFirstFrame();
      unawaited(_initializeNotifications());
    });
  }

  Future<void> _initializeNotifications() async {
    StartupDiagnostics.mark('notifications.initialize.start');
    try {
      final LocalNotificationService service = ref.read(
        localNotificationServiceProvider,
      );
      await service.initialize(onTap: _openNotificationPayload);
      final NotificationPermissionState permission = await service
          .permissionState();
      if (permission == NotificationPermissionState.granted) {
        await ref.read(notificationSyncCoordinatorProvider).rebuildAll();
      }
      StartupDiagnostics.mark('notifications.initialize.complete');
    } on Object {
      StartupDiagnostics.mark('notifications.initialize.failed');
      // Notifications are optional and must never block app startup.
    }
  }

  Future<void> _openNotificationPayload(NotificationPayload payload) async {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        appRouter.go(payload.route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'دارو تا کی دارم؟',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const <Locale>[
        Locale('fa', 'IR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        PersianMaterialLocalizations.delegate,
        PersianCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      routerConfig: appRouter,
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
