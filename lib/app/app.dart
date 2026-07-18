import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class DaroTaKeyApp extends StatelessWidget {
  const DaroTaKeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'دارو تا کی دارم؟',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa'),
      supportedLocales: const <Locale>[
        Locale('fa'),
        Locale('en'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
