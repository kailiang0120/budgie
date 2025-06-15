import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../di/injection_container.dart' as di;
import '../../../domain/services/ai_budget_suggestion_service.dart';
import '../../../domain/repositories/budget_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../data/datasources/local_data_source.dart';
import '../../../domain/entities/budget_suggestion.dart';
import 'settings_service.dart';

const fetchBudgetSuggestionTask = "fetchBudgetSuggestionTask";

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
        // Check if auto budget reallocation is enabled (check both settings for compatibility)
        if (!settingsService.automaticRebalanceSuggestions &&
            !settingsService.autoBudget) {
          debugPrint(
              "Background task skipped: User has disabled automatic budget reallocation.");
          return Future.value(true);
        }
      } else {
        debugPrint("Background task skipped: No user is logged in.");
        return Future.value(true);
      }

      debugPrint("Background task started: $task");

      switch (task) {
        case fetchBudgetSuggestionTask:
          final budgetRepository = di.sl<BudgetRepository>();
          final aiSuggestionService = di.sl<AIBudgetSuggestionService>();
          final localDataSource = di.sl<LocalDataSource>();

          final monthId = DateFormat('yyyy-MM').format(DateTime.now());
          final budget = await budgetRepository.getBudget(monthId);

          if (budget != null) {
            final suggestions =
                await aiSuggestionService.getBudgetSuggestions(budget);
            final suggestionEntity = BudgetSuggestion(
              monthId: monthId,
              userId: currentUser.uid,
              suggestions: suggestions,
              timestamp: DateTime.now(),
            );
            await localDataSource.saveBudgetSuggestion(suggestionEntity);
            debugPrint("Successfully fetched and saved budget suggestion.");
          } else {
            debugPrint("No budget found for the current month.");
          }
          break;
      }
      return Future.value(true);
    } catch (err) {
      debugPrint("Error in background task: $err");
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

  Future<void> scheduleBudgetSuggestionTask() async {
    await Workmanager().registerPeriodicTask(
      "1",
      fetchBudgetSuggestionTask,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    debugPrint("Budget suggestion task scheduled.");
  }

  Future<void> cancelBudgetSuggestionTask() async {
    await Workmanager().cancelByUniqueName("1");
    debugPrint("Budget suggestion task canceled.");
  }
}
