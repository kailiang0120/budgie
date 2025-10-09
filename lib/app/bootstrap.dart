import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../di/performance_tracker.dart';
import 'startup/app_bootstrapper.dart';

/// Application bootstrap entry-point used by `main.dart`.
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();
  PerformanceTracker.startAppTracking();

  final bootstrapper = AppBootstrapper();

  try {
    await bootstrapper.ensureCoreServices();
    final app = await builder();

    runApp(app);
    bootstrapper.startPostLaunchServices();
    _schedulePerformanceReport();
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('? App initialization failed: $e');
      debugPrint(stackTrace.toString());
    }

    runApp(await builder());
  }
}

void _schedulePerformanceReport() {
  if (!kDebugMode) {
    return;
  }

  Future.delayed(const Duration(seconds: 5), () {
    PerformanceTracker.printPerformanceReport();
  });
}
