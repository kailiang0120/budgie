import 'package:budgie/presentation/screens/goals_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';

import 'data/infrastructure/config/firebase_options.dart';
import 'core/constants/routes.dart';
import 'core/router/app_router.dart';
import 'data/infrastructure/services/settings_service.dart';
import 'data/infrastructure/services/sync_service.dart';
import 'data/infrastructure/services/permission_handler_service.dart';
import 'domain/usecase/expense/process_recurring_expenses_usecase.dart';
import 'presentation/viewmodels/expenses_viewmodel.dart';
import 'presentation/viewmodels/budget_viewmodel.dart';
import 'presentation/viewmodels/theme_viewmodel.dart';
import 'presentation/viewmodels/analysis_viewmodel.dart';
import 'presentation/viewmodels/goals_viewmodel.dart';
import 'presentation/utils/app_theme.dart';
import 'presentation/utils/app_constants.dart';
import 'di/injection_container.dart' as di;
import 'di/performance_tracker.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/analytic_screen.dart';
import 'presentation/screens/setting_screen.dart';

import 'core/router/route_observers.dart';
import 'core/router/navigation_keys.dart';
import 'data/infrastructure/services/background_task_service.dart';
import 'data/infrastructure/services/notification_service.dart';
import 'domain/services/expense_extraction_service.dart';

// Global keys moved to core/router/navigation_keys.dart

/// Main entry point for the Budgie app
Future<void> main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Start performance tracking
  PerformanceTracker.startAppTracking();

  try {
    // Initialize core services (blocking)
    await _initializeCoreServices();

    // Launch the app
    runApp(const BudgieApp());

    // Initialize remaining services (non-blocking)
    _initializeRemainingServices();

    // Print performance report after app is fully loaded
    Future.delayed(const Duration(seconds: 5), () {
      if (kDebugMode) {
        PerformanceTracker.printPerformanceReport();
      }
    });
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('❌ App initialization failed: $e');
      debugPrint(stackTrace.toString());
    }

    // Run app with error state - let existing splash screen handle this
    runApp(const BudgieApp());
  }
}

/// Initialize core services required before UI rendering
Future<void> _initializeCoreServices() async {
  if (kDebugMode) {
    debugPrint('🚀 Initializing core services...');
  }

  // Initialize Firebase with proper error handling
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('✅ Firebase initialized');
  }

  // Initialize dependency injection - Critical and Essential services only
  await di.init();
  if (kDebugMode) {
    debugPrint('✅ Core services initialized');
  }

  // Initialize SettingsService to load theme and other settings BEFORE UI renders
  try {
    final settingsService = di.sl<SettingsService>();
    final permissionHandler = di.sl<PermissionHandlerService>();

    // Add a small delay to ensure Android method channels are properly initialized
    if (Platform.isAndroid) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (kDebugMode) {
        debugPrint('⏱️ Added delay for Android method channel initialization');
      }
    }

    // Initialize settings with permission handler to enable automatic notification listener management
    await settingsService.initialize(permissionHandler: permissionHandler);
    if (kDebugMode) {
      debugPrint('✅ SettingsService initialized and settings loaded');
    }

    // Refresh ThemeViewModel after settings are loaded to ensure theme persists
    try {
      final themeViewModel = di.sl<ThemeViewModel>();
      themeViewModel.refreshFromSettings();
      if (kDebugMode) {
        debugPrint('✅ ThemeViewModel refreshed from loaded settings');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ ThemeViewModel refresh error: $e');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ SettingsService initialization error: $e');
    }
  }
}

/// Initialize remaining services after UI is rendered
void _initializeRemainingServices() {
  // Schedule service initialization with appropriate delays

  // Stage 1: Essential background services (500ms delay)
  Future.delayed(const Duration(milliseconds: 500), () async {
    if (kDebugMode) {
      debugPrint('🔄 Initializing essential services...');
    }

    try {
      // Initialize services in parallel where possible
      await Future.wait([
        _initializeSyncService(),
        _initializeNotificationServices(),
        di.sl<BackgroundTaskService>().initialize(),
      ]);

      if (kDebugMode) {
        debugPrint('✅ Essential services initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Essential services initialization error: $e');
      }
    }
  });

  // Stage 2: Optional services (2s delay)
  Future.delayed(const Duration(seconds: 2), () async {
    if (kDebugMode) {
      debugPrint('🎯 Initializing optional services...');
    }

    try {
      // Start recurring expense service
      await _startRecurringExpenseService();

      // Background service permissions no longer needed for notification listener

      if (kDebugMode) {
        debugPrint('✅ Optional services initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Optional services initialization error: $e');
      }
    }
  });

  // Stage 3: Check welcome screen status (3s delay)
  Future.delayed(const Duration(seconds: 3), () async {
    _checkWelcomeStatus();
  });
}

/// Initialize notification-related services
Future<void> _initializeNotificationServices() async {
  try {
    // Initialize notification services if permissions are granted
    final notificationService = di.sl<NotificationService>();
    await notificationService.initialize();
    if (kDebugMode) {
      debugPrint('✅ Main: NotificationService initialized successfully');
    }

    // Set up expense refresh callback for automatic app data refresh
    notificationService
        .setExpenseRefreshCallback(_refreshAppDataAfterExpenseAdded);
    if (kDebugMode) {
      debugPrint('✅ Main: Expense refresh callback registered');
    }

    // Initialize expense extraction service for notification processing
    try {
      final extractionService = di.sl<ExpenseExtractionDomainService>();
      if (!extractionService.isInitialized) {
        if (kDebugMode) {
          debugPrint('🔧 Main: Initializing expense extraction service...');
        }
        await extractionService.initialize();
        if (kDebugMode) {
          debugPrint('✅ Main: Expense extraction service initialized');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Main: Failed to initialize expense extraction service: $e');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Main: Failed to initialize notification services: $e');
    }
  }
}

/// Refresh app data after expense is added via notification extraction
Future<void> _refreshAppDataAfterExpenseAdded() async {
  try {
    if (kDebugMode) {
      debugPrint(
          '🔄 Main: Refreshing app data after notification expense addition...');
    }

    // Small delay to ensure UI has finished updating
    await Future.delayed(const Duration(milliseconds: 500));

    // Refresh ExpensesViewModel
    if (di.sl.isRegistered<ExpensesViewModel>()) {
      try {
        final expensesViewModel = di.sl<ExpensesViewModel>();
        await expensesViewModel.refreshData();
        if (kDebugMode) {
          debugPrint('✅ Main: ExpensesViewModel refreshed');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Main: Failed to refresh ExpensesViewModel: $e');
        }
      }
    } else {
      if (kDebugMode) {
        debugPrint(
            'ℹ️ Main: ExpensesViewModel not registered, skipping refresh');
      }
    }

    // Refresh BudgetViewModel for current month
    if (di.sl.isRegistered<BudgetViewModel>()) {
      try {
        final budgetViewModel = di.sl<BudgetViewModel>();
        final now = DateTime.now();
        final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        await budgetViewModel.refreshBudget(monthId);
        if (kDebugMode) {
          debugPrint('✅ Main: BudgetViewModel refreshed for month $monthId');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Main: Failed to refresh BudgetViewModel: $e');
        }
      }
    } else {
      if (kDebugMode) {
        debugPrint('ℹ️ Main: BudgetViewModel not registered, skipping refresh');
      }
    }

    if (kDebugMode) {
      debugPrint('🎉 Main: App data refresh completed successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Main: Error refreshing app data: $e');
    }
  }
}

/// Initialize sync service
Future<void> _initializeSyncService() async {
  try {
    final syncService = di.sl<SyncService>();
    final settingsService = di.sl<SettingsService>();

    // Initialize sync service
    await syncService.initialize(startPeriodicSync: false);
    if (kDebugMode) {
      debugPrint('✅ SyncService initialized');
    }

    // Enable periodic sync if enabled in settings
    if (settingsService.syncEnabled) {
      syncService.initialize(startPeriodicSync: true);
      if (kDebugMode) {
        debugPrint('✅ SyncService periodic sync enabled');
      }

      // Schedule background sync task
      final backgroundTaskService = di.sl<BackgroundTaskService>();
      await backgroundTaskService.updateSyncTask(true);

      // Perform initial sync with a delay
      Future.delayed(const Duration(seconds: 3), () {
        syncService.forceFullSync();
        if (kDebugMode) {
          debugPrint('🔄 Initial sync started');
        }
      });
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ Sync service initialization error: $e');
    }
  }
}

/// Start recurring expense processing service
Future<void> _startRecurringExpenseService() async {
  try {
    // Process recurring expenses periodically using Workmanager
    final backgroundTaskService = di.sl<BackgroundTaskService>();
    await backgroundTaskService.scheduleRecurringExpenseTask();

    // Also process immediately after startup (with delay)
    Future.delayed(const Duration(seconds: 10), () {
      di.sl<ProcessRecurringExpensesUseCase>().execute();
      if (kDebugMode) {
        debugPrint('✅ Initial recurring expense processing completed');
      }
    });

    if (kDebugMode) {
      debugPrint('✅ Recurring expense service started');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ Recurring expense service error: $e');
    }
  }
}

/// Check welcome screen status and handle accordingly
Future<void> _checkWelcomeStatus() async {
  try {
    if (kDebugMode) {
      debugPrint('🔑 Checking welcome screen status...');
    }

    final prefs = await SharedPreferences.getInstance();
    final welcomeCompleted = prefs.getBool('welcome_completed') ?? false;

    // If welcome screen was completed, user has already handled permissions
    // If not completed, welcome screen will handle permissions on last page
    if (welcomeCompleted) {
      if (kDebugMode) {
        debugPrint('✅ Welcome completed - permissions already handled');
      }
    } else {
      if (kDebugMode) {
        debugPrint('📱 Welcome screen will handle permissions on last page');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ Welcome status check error: $e');
    }
  }
}

/// Main app widget with providers and UI configuration
class BudgieApp extends StatefulWidget {
  const BudgieApp({super.key});

  @override
  State<BudgieApp> createState() => _BudgieAppState();
}

class _BudgieAppState extends State<BudgieApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App is resumed from background, trigger sync
      _handleAppResume();
    } else if (state == AppLifecycleState.detached) {
      // App is being killed, clean up resources
      _handleAppDetached();
    }
  }

  /// Handle app resume lifecycle event
  void _handleAppResume() {
    try {
      if (di.sl.isRegistered<SyncService>()) {
        final syncService = di.sl<SyncService>();
        if (kDebugMode) {
          debugPrint('📱 App resumed - checking for pending syncs');
        }
        Future.delayed(const Duration(seconds: 1), () {
          syncService.syncData(fullSync: false);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Resume sync failed: $e');
      }
    }
  }

  /// Handle app detached lifecycle event
  void _handleAppDetached() {
    try {
      if (di.sl.isRegistered<SyncService>()) {
        di.sl<SyncService>().dispose();
        if (kDebugMode) {
          debugPrint('🧹 App detached: disposed SyncService');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Cleanup failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _buildProviders(),
      child: ScreenUtilInit(
        designSize: const Size(430, 952),
        minTextAdapt: true, // Ensure text scales properly
        splitScreenMode: true,
        builder: (context, _) {
          // Debug text scaling on first build
          if (kDebugMode) {
            Future.delayed(const Duration(milliseconds: 500), () {
              AppConstants.debugTextSizes();
            });
          }
          return _buildMaterialApp(context);
        },
      ),
    );
  }

  /// Build the list of providers
  List<SingleChildWidget> _buildProviders() {
    return [
      ChangeNotifierProvider(create: (_) => di.sl<ThemeViewModel>()),
      ChangeNotifierProvider(create: (_) => di.sl<ExpensesViewModel>()),
      ChangeNotifierProvider(create: (_) => di.sl<BudgetViewModel>()),
      ChangeNotifierProvider(create: (_) => di.sl<AnalysisViewModel>()),
      ChangeNotifierProvider(create: (_) => di.sl<GoalsViewModel>()),
    ];
  }

  /// Build the MaterialApp
  Widget _buildMaterialApp(BuildContext context) {
    return Consumer<ThemeViewModel>(
      builder: (context, themeViewModel, _) {
        final responsiveTheme = themeViewModel.isDarkMode
            ? AppTheme.getDarkTheme(context)
            : AppTheme.getLightTheme(context);

        return MaterialApp(
          title: 'Budgie',
          theme: responsiveTheme,
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: scaffoldMessengerKey,
          navigatorKey: navigatorKey,
          navigatorObservers: [fabRouteObserver],
          routes: _buildAppRoutes(),
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: Routes.splash,
        );
      },
    );
  }

  /// Build app routes
  Map<String, WidgetBuilder> _buildAppRoutes() {
    return {
      Routes.home: (context) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => di.sl<SettingsService>()),
            ],
            child: const HomeScreen(),
          ),
      Routes.analytic: (context) => const AnalyticScreen(),
      Routes.settings: (context) => const SettingScreen(),
      Routes.goals: (context) => const GoalsScreen(),
    };
  }
}
