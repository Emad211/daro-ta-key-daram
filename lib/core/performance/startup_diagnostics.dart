import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

abstract final class StartupDiagnostics {
  static final Stopwatch _stopwatch = Stopwatch();
  static bool _started = false;

  static void start() {
    if (kReleaseMode || _started) {
      return;
    }
    _started = true;
    _stopwatch.start();
    mark('app.start');
  }

  static void markFirstFrame() {
    mark('first_frame.rendered');
  }

  static void mark(String milestone) {
    if (kReleaseMode || !_started) {
      return;
    }
    developer.log(
      '$milestone at ${_stopwatch.elapsedMicroseconds} µs',
      name: 'daro_ta_key.startup',
    );
  }
}
