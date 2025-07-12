import 'package:budgie/presentation/screens/goals_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';

import 'data/infrastructure/config/firebase_options.dart';
import 'core/constants/routes.dart';
import 'core/router/app_router.dart';
import 'data/infrastructure/services/settings_service.dart';
import 'data/infrastructure/services/sync_service.dart';
import 'domain/usecase/expense/process_recurring_expenses_usecase.dart';
import 'presentation/viewmodels/expenses_viewmodel.dart';
import 'presentation/viewmodels/budget_viewmodel.dart';
import 'presentation/viewmodels/theme_viewmodel.dart';
import 'presentation/viewmodels/analysis_viewmodel.dart';
import 'presentation/utils/app_theme.dart';
import 'di/injection_container.dart' as di;
import 'di/performance_tracker.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/analytic_screen.dart';
import 'presentation/screens/setting_screen.dart';

import 'presentation/widgets/animated_float_button.dart';
import 'data/infrastructure/services/background_task_service.dart';
import 'data/infrastructure/services/notification_service.dart';

// Global keys for app-wide access
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      PerformanceTracker.printPerformanceReport();
    });
  } catch (e, stackTrace) {
    debugPrint('❌ App initialization failed: $e');
    debugPrint(stackTrace.toString());

    // Run app with error state - let existing splash screen handle this
    runApp(const BudgieApp());
  }
}

/// Initialize core services required before UI rendering
Future<void> _initializeCoreServices() async {
  debugPrint('🚀 Initializing core services...');

  // Initialize Firebase with proper error handling
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('✅ Firebase initialized');

  // Initialize dependency injection - Critical and Essential services only
  await di.init();
  debugPrint('✅ Core services initialized');
}

/// Initialize remaining services after UI is rendered
void _initializeRemainingServices() {
  // Schedule service initialization with appropriate delays

  // Stage 1: Essential background services (500ms delay)
  Future.delayed(const Duration(milliseconds: 500), () async {
    debugPrint('🔄 Initializing essential services...');

    try {
      // Initialize services in parallel where possible
      await Future.wait([
        _initializeSyncService(),
        _initializeNotificationServices(),
        di.sl<BackgroundTaskService>().initialize(),
      ]);

      debugPrint('✅ Essential services initialized');
    } catch (e) {
      debugPrint('⚠️ Essential services initialization error: $e');
    }
  });

  // Stage 2: Optional services (2s delay)
  Future.delayed(const Duration(seconds: 2), () async {
    debugPrint('🎯 Initializing optional services...');

    try {
      // Start recurring expense service
      _startRecurringExpenseService();

      // Initialize background service permissions if needed
      if (Platform.isAndroid) {
        _initializeBackgroundServicePermissions();
      }

      debugPrint('✅ Optional services initialized');
    } catch (e) {
      debugPrint('⚠️ Optional services initialization error: $e');
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
    debugPrint('✅ Main: NotificationService initialized successfully');
  } catch (e) {
    debugPrint('❌ Main: Failed to initialize notification services: $e');
  }
}

/// Initialize sync service
Future<void> _initializeSyncService() async {
  try {
    final syncService = di.sl<SyncService>();
    final settingsService = di.sl<SettingsService>();

    // Initialize sync service
    await syncService.initialize(startPeriodicSync: false);
    debugPrint('✅ SyncService initialized');

    // Enable periodic sync if enabled in settings
    if (settingsService.syncEnabled) {
      syncService.initialize(startPeriodicSync: true);
      debugPrint('✅ SyncService periodic sync enabled');

      // Schedule background sync task
      final backgroundTaskService = di.sl<BackgroundTaskService>();
      await backgroundTaskService.updateSyncTask(true);

      // Perform initial sync with a delay
      Future.delayed(const Duration(seconds: 3), () {
        syncService.forceFullSync();
        debugPrint('🔄 Initial sync started');
      });
    }
  } catch (e) {
    debugPrint('⚠️ Sync service initialization error: $e');
  }
}

/// Start recurring expense processing service
void _startRecurringExpenseService() {
  try {
    // Process recurring expenses periodically
    Timer.periodic(const Duration(hours: 1), (_) {
      di.sl<ProcessRecurringExpensesUseCase>().execute();
    });

    // Also process immediately after startup (with delay)
    Future.delayed(const Duration(seconds: 10), () {
      di.sl<ProcessRecurringExpensesUseCase>().execute();
      debugPrint('✅ Initial recurring expense processing completed');
    });

    debugPrint('✅ Recurring expense service started');
  } catch (e) {
    debugPrint('⚠️ Recurring expense service error: $e');
  }
}

/// Initialize background service permissions (Android only)
void _initializeBackgroundServicePermissions() {
  Future.delayed(const Duration(seconds: 3), () async {
    try {
      final hasPermissions = await FlutterBackground.hasPermissions;

      if (hasPermissions) {
        // Initialize silently if we already have permissions
        await _setupFlutterBackground();
      } else {
        // Delay permission request to avoid disrupting startup
        Future.delayed(const Duration(seconds: 10), () async {
          await _setupFlutterBackground();
        });
      }
    } catch (e) {
      debugPrint('⚠️ Background service permissions error: $e');
    }
  });
}

/// Configure and initialize Flutter Background service
Future<void> _setupFlutterBackground() async {
  try {
    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: 'Budgie',
      notificationText: 'Tracking expenses in background',
      notificationImportance: AndroidNotificationImportance.normal,
      notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    );

    final initialized =
        await FlutterBackground.initialize(androidConfig: androidConfig);
    debugPrint(initialized
        ? '✅ Background service initialized'
        : '⚠️ Background service initialization failed');
  } catch (e) {
    debugPrint('⚠️ Background service setup error: $e');
  }
}

/// Check welcome screen status and handle accordingly
Future<void> _checkWelcomeStatus() async {
  try {
    debugPrint('🔑 Checking welcome screen status...');

    final prefs = await SharedPreferences.getInstance();
    final welcomeCompleted = prefs.getBool('welcome_completed') ?? false;

    // If welcome screen was completed, user has already handled permissions
    // If not completed, welcome screen will handle permissions on last page
    if (welcomeCompleted) {
      debugPrint('✅ Welcome completed - permissions already handled');
    } else {
      debugPrint('📱 Welcome screen will handle permissions on last page');
    }
  } catch (e) {
    debugPrint('⚠️ Welcome status check error: $e');
  }
}

/// Main app widget with providers and UI configuration
class BudgieApp extends StatefulWidget {
  const BudgieApp({Key? key}) : super(key: key);

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
        debugPrint('📱 App resumed - checking for pending syncs');
        Future.delayed(const Duration(seconds: 1), () {
          syncService.syncData(fullSync: false);
        });
      }
    } catch (e) {
      debugPrint('⚠️ Resume sync failed: $e');
    }
  }

  /// Handle app detached lifecycle event
  void _handleAppDetached() {
    try {
      if (di.sl.isRegistered<SyncService>()) {
        di.sl<SyncService>().dispose();
        debugPrint('🧹 App detached: disposed SyncService');
      }
    } catch (e) {
      debugPrint('⚠️ Cleanup failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _buildProviders(),
      child: ScreenUtilInit(
        designSize: const Size(430, 952),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, _) => _buildMaterialApp(context),
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
