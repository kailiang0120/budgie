import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../di/injection_container.dart' as di;
import 'settings_service.dart';
import 'sync_service.dart';
import '../../../domain/services/budget_reallocation_service.dart';
import '../../../domain/repositories/user_behavior_repository.dart';

const autoReallocationTask = 'autoReallocationTask';
const dataSyncTask = 'dataSyncTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize Firebase and DI container
      await Firebase.initializeApp();
      await di.init();

      final settingsService = di.sl<SettingsService>();

      // For auto budget task
      if (task == autoReallocationTask && !settingsService.autoBudget) {
        debugPrint(
            'Background task skipped: User has disabled automatic budget features.');
        return Future.value(true);
      }

      // For data sync task
      if (task == dataSyncTask && !settingsService.syncEnabled) {
        debugPrint(
            'Background sync task skipped: User has disabled sync feature.');
        return Future.value(true);
      }

      debugPrint('Background task started: $task');

      switch (task) {
        case autoReallocationTask:
          // Execute auto budget reallocation
          try {
            final reallocationService = di.sl<BudgetReallocationService>();
            final userBehaviorRepository = di.sl<UserBehaviorRepository>();
            final allUsers =
                await userBehaviorRepository.getAllUserBehaviorProfiles();
            final now = DateTime.now();
            final monthId =
                '${now.year}-${now.month.toString().padLeft(2, '0')}';
            for (final user in allUsers) {
              debugPrint(
                  '🔄 Background: Starting auto budget reallocation for ${user.userId} in $monthId');
              await reallocationService.reallocateBudget(user.userId, monthId);
              debugPrint(
                  '✅ Background: Auto budget reallocation for ${user.userId} completed successfully');
            }
          } catch (e) {
            debugPrint('❌ Background: Auto budget reallocation failed: $e');
          }
          break;
        case dataSyncTask:
          // Execute data sync
          final syncService = di.sl<SyncService>();
          await syncService.syncData(fullSync: true);
          debugPrint('Background data sync completed.');
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

  Future<void> scheduleDataSyncTask() async {
    await Workmanager().registerPeriodicTask(
      '2',
      dataSyncTask,
      frequency: const Duration(hours: 6), // Sync every 6 hours
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    debugPrint('Data sync task scheduled.');
  }

  Future<void> cancelDataSyncTask() async {
    await Workmanager().cancelByUniqueName('2');
    debugPrint('Data sync task canceled.');
  }

  // Update sync task based on settings
  Future<void> updateSyncTask(bool enabled) async {
    if (enabled) {
      await scheduleDataSyncTask();
    } else {
      await cancelDataSyncTask();
    }
  }
}
