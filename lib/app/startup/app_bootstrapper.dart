import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/infrastructure/config/firebase_options.dart';
import '../../data/infrastructure/services/background_task_service.dart';
import '../../data/infrastructure/services/notification_service.dart';
import '../../data/infrastructure/services/permission_handler_service.dart';
import '../../data/infrastructure/services/settings_service.dart';
import '../../data/infrastructure/services/sync_service.dart';
import '../../di/injection_container.dart' as di;
import '../../domain/services/expense_extraction_service.dart';
import '../../domain/usecase/expense/process_recurring_expenses_usecase.dart';
import '../../presentation/viewmodels/budget_viewmodel.dart';
import '../../presentation/viewmodels/expenses_viewmodel.dart';
import '../../presentation/viewmodels/theme_viewmodel.dart';

/// Coordinates all synchronous and deferred application start-up work.
class AppBootstrapper {
  bool _firebaseInitialized = false;

  /// Initializes the critical services that must be ready before the UI renders.
  Future<void> ensureCoreServices() async {
    if (kDebugMode) {
      debugPrint('🔧 Initializing core services...');
    }

    await di.init();

    // Don't wait for database here - it will open lazily when needed
    // This reduces startup time significantly
    
    await _primeSettings();

    if (kDebugMode) {
      debugPrint('✅ Core services initialized');
    }
  }

  Future<void> _primeSettings() async {
    try {
      final settingsService = di.sl<SettingsService>();
      await settingsService.loadPersistedSettings();

  _refreshThemeFromSettings();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('?? SettingsService warmup error: $e');
      }
    }
  }

  void _refreshThemeFromSettings() {
    try {
      di.sl<ThemeViewModel>().refreshFromSettings();
      if (kDebugMode) {
        debugPrint('? ThemeViewModel refreshed from settings');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('?? ThemeViewModel refresh error: $e');
      }
    }
  }

  /// Schedules background initialization once the first frame has rendered.
  void startPostLaunchServices() {
    // Ensure database is ready immediately after app renders
    unawaited(Future.microtask(() async {
      try {
        // Use dynamic type to avoid import issues
        await di.sl.isReady();
        if (kDebugMode) {
          debugPrint('✅ Database ready');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Database initialization error: $e');
        }
      }
    }));
    
    unawaited(Future.microtask(_completeSettingsInitialization));
    unawaited(Future.microtask(_initializeFirebaseIfNeeded));

    unawaited(Future.delayed(const Duration(milliseconds: 500), () async {
      if (kDebugMode) {
        debugPrint('?? Initializing essential services...');
      }

      try {
        await Future.wait([
          _initializeSyncService(),
          _initializeNotificationServices(),
          di.sl<BackgroundTaskService>().initialize(),
        ]);

        if (kDebugMode) {
          debugPrint('? Essential services initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('?? Essential services initialization error: $e');
        }
      }
    }));

    unawaited(Future.delayed(const Duration(seconds: 2), () async {
      if (kDebugMode) {
        debugPrint('?? Initializing optional services...');
      }

      try {
        await _startRecurringExpenseService();
        if (kDebugMode) {
          debugPrint('? Optional services initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('?? Optional services initialization error: $e');
        }
      }
    }));

    unawaited(Future.delayed(const Duration(seconds: 3), _checkWelcomeStatus));
  }

  Future<void> _completeSettingsInitialization() async {
    try {
      if (kDebugMode) {
        debugPrint('?? Completing settings initialization...');
      }

      final settingsService = di.sl<SettingsService>();
      final permissionHandler = di.sl<PermissionHandlerService>();

      if (Platform.isAndroid) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      await settingsService.initialize(permissionHandler: permissionHandler);

      _refreshThemeFromSettings();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('?? SettingsService deferred initialization error: $e');
      }
    }
  }

  Future<void> _initializeFirebaseIfNeeded() async {
    if (_firebaseInitialized) {
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firebaseInitialized = true;
      if (kDebugMode) {
        debugPrint('? Firebase initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('?? Firebase initialization error: $e');
      }
    }
  }

  Future<void> _initializeNotificationServices() async {
    try {
      final notificationService = di.sl<NotificationService>();
      await notificationService.initialize();
      if (kDebugMode) {
        debugPrint('? Main: NotificationService initialized successfully');
      }

      notificationService
          .setExpenseRefreshCallback(_refreshAppDataAfterExpenseAdded);
      if (kDebugMode) {
        debugPrint('? Main: Expense refresh callback registered');
      }

      final settingsService = di.sl<SettingsService>();
      if (settingsService.allowNotification) {
        try {
          final extractionService = di.sl<ExpenseExtractionDomainService>();
          if (!extractionService.isInitialized) {
            if (kDebugMode) {
              debugPrint('?? Main: Initializing expense extraction service...');
            }
            await extractionService.initialize();
            if (kDebugMode) {
              debugPrint('? Main: Expense extraction service initialized');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '?? Main: Failed to initialize expense extraction service: $e',
            );
          }
        }
      } else if (kDebugMode) {
        debugPrint(
          '?? Main: Expense extraction service skipped (notifications disabled)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('? Main: Failed to initialize notification services: $e');
      }
    }
  }

  Future<void> _refreshAppDataAfterExpenseAdded() async {
    try {
      if (kDebugMode) {
        debugPrint(
          '?? Main: Refreshing app data after notification expense addition...',
        );
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (di.sl.isRegistered<ExpensesViewModel>()) {
        try {
          await di.sl<ExpensesViewModel>().refreshData();
          if (kDebugMode) {
            debugPrint('? Main: ExpensesViewModel refreshed');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('?? Main: Failed to refresh ExpensesViewModel: $e');
          }
        }
      } else if (kDebugMode) {
        debugPrint('?? Main: ExpensesViewModel not registered, skipping refresh');
      }

      if (di.sl.isRegistered<BudgetViewModel>()) {
        try {
          final now = DateTime.now();
          final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';
          await di.sl<BudgetViewModel>().refreshBudget(monthId);
          if (kDebugMode) {
            debugPrint(
              '? Main: BudgetViewModel refreshed for month $monthId',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('?? Main: Failed to refresh BudgetViewModel: $e');
          }
        }
      } else if (kDebugMode) {
        debugPrint('?? Main: BudgetViewModel not registered, skipping refresh');
      }

      if (kDebugMode) {
        debugPrint('?? Main: App data refresh completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('? Main: Error refreshing app data: $e');
      }
    }
  }

  Future<void> _initializeSyncService() async {
    try {
      final syncService = di.sl<SyncService>();
      final settingsService = di.sl<SettingsService>();

      await syncService.initialize(startPeriodicSync: false);
      if (kDebugMode) {
        debugPrint('? SyncService initialized');
      }

      if (settingsService.syncEnabled) {
        syncService.initialize(startPeriodicSync: true);
        if (kDebugMode) {
          debugPrint('? SyncService periodic sync enabled');
        }

        final backgroundTaskService = di.sl<BackgroundTaskService>();
        await backgroundTaskService.updateSyncTask(true);

        Future.delayed(const Duration(seconds: 3), () {
          syncService.forceFullSync();
          if (kDebugMode) {
            debugPrint('?? Initial sync started');
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('?? Sync service initialization error: $e');
      }
    }
  }

  Future<void> _startRecurringExpenseService() async {
    try {
      final backgroundTaskService = di.sl<BackgroundTaskService>();
      await backgroundTaskService.scheduleRecurringExpenseTask();

      Future.delayed(const Duration(seconds: 10), () {
        di.sl<ProcessRecurringExpensesUseCase>().execute();
        if (kDebugMode) {
          debugPrint('? Initial recurring expense processing completed');
        }
      });

      if (kDebugMode) {
        debugPrint('? Recurring expense service started');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('?? Recurring expense service error: $e');
      }
    }
  }

  Future<void> _checkWelcomeStatus() async {
    try {
      if (kDebugMode) {
        debugPrint('?? Checking welcome screen status...');
      }

      final prefs = await SharedPreferences.getInstance();
      final welcomeCompleted = prefs.getBool('welcome_completed') ?? false;

      if (welcomeCompleted) {
        if (kDebugMode) {
          debugPrint('? Welcome completed - permissions already handled');
        }
      } else if (kDebugMode) {
        debugPrint('?? Welcome screen will handle permissions on last page');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('?? Welcome status check error: $e');
      }
    }
  }
}
