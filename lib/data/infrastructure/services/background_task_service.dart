import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../di/injection_container.dart' as di;
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_service.dart';

const autoReallocationTask = 'autoReallocationTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize Firebase and DI container
      await Firebase.initializeApp();
      await di.init();

      final settingsService = di.sl<SettingsService>();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await settingsService.initializeForUser(currentUser.uid);
        // Check if auto budget reallocation is enabled
        if (!settingsService.automaticRebalanceSuggestions) {
          debugPrint(
              'Background task skipped: User has disabled automatic budget reallocation.');
          return Future.value(true);
        }
      } else {
        debugPrint('Background task skipped: No user is logged in.');
        return Future.value(true);
      }

      debugPrint('Background task started: $task');

      switch (task) {
        case autoReallocationTask:
          // Placeholder for future implementation
          debugPrint(
              'Auto budget reallocation functionality will be implemented in the future.');
          break;
      }
      return Future.value(true);
    } catch (err) {
      debugPrint('Error in background task: $err');
      return Future.value(false);
    }
  });
}

class BackgroundTaskService {
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  Future<void> scheduleAutoReallocationTask() async {
    await Workmanager().registerPeriodicTask(
      '1',
      autoReallocationTask,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    debugPrint('Auto budget reallocation task scheduled.');
  }

  Future<void> cancelAutoReallocationTask() async {
    await Workmanager().cancelByUniqueName('1');
    debugPrint('Auto budget reallocation task canceled.');
  }
}
