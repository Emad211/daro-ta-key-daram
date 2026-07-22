import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/performance/startup_diagnostics.dart';

void main() {
  StartupDiagnostics.start();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DaroTaKeyApp()));
}
