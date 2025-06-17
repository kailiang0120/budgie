import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'dart:async';

import 'data/infrastructure/config/firebase_options.dart';
import 'core/constants/routes.dart';
import 'core/router/app_router.dart';
import 'domain/repositories/auth_repository.dart';
import 'data/infrastructure/services/settings_service.dart';
import 'data/infrastructure/services/sync_service.dart';
import 'domain/usecase/expense/process_recurring_expenses_usecase.dart';
import 'presentation/viewmodels/expenses_viewmodel.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/budget_viewmodel.dart';
import 'presentation/viewmodels/theme_viewmodel.dart';
import 'presentation/utils/app_theme.dart';
import 'di/injection_container.dart' as di;
import 'di/performance_tracker.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/analytic_screen.dart';
import 'presentation/screens/setting_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/widgets/animated_float_button.dart';
import 'data/infrastructure/services/background_task_service.dart';
import 'data/infrastructure/services/offline_notification_service.dart';

Future<void> main() async {
  // Ensure we can call async code before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Start performance tracking
  PerformanceTracker.startAppTracking();

  try {
    // Stage 1: Critical initialization (blocking) - only what's absolutely necessary
    await PerformanceTracker.benchmark(
        'Critical Path', _initializeCriticalPath);

    // Stage 2: Start the app with minimal providers
    runApp(const BudgieAppBootstrap());

    // Stage 3: Initialize background services (non-blocking)
    _initializeBackgroundServices();

    // Stage 4: Initialize optional services (non-blocking, delayed)
    _initializeOptionalServices();

    // Print performance report after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      PerformanceTracker.printPerformanceReport();
    });
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint(stackTrace.toString());
    // Show error UI
    runApp(_buildErrorApp(e));
  }
}

/// Stage 1: Initialize only critical services needed for app startup
Future<void> _initializeCriticalPath() async {
  final stopwatch = Stopwatch()..start();
  debugPrint('🚀 Stage 1: Critical path initialization...');

  try {
    // Initialize Firebase with proper error handling
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized (${stopwatch.elapsedMilliseconds}ms)');

    // Check Firebase Auth status
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    debugPrint(
        '👤 Current Firebase user: ${currentUser?.uid ?? 'Not signed in'}');

    // Set up persistence for Auth
    try {
      await auth.setPersistence(Persistence.LOCAL);
      debugPrint('✅ Firebase Auth persistence set');
    } catch (e) {
      debugPrint('⚠️ Failed to set persistence: $e');
    }

    // Initialize dependency injection - Critical and Essential services only
    await di.init();
    debugPrint(
        '✅ Critical services initialized (${stopwatch.elapsedMilliseconds}ms)');
  } catch (e) {
    debugPrint('❌ Critical path initialization failed: $e');
    rethrow;
  }
}

/// Stage 3: Initialize background services after app is running
void _initializeBackgroundServices() {
  Future.delayed(const Duration(milliseconds: 500), () async {
    final stopwatch = Stopwatch()..start();
    debugPrint('🔄 Stage 3: Background services initialization...');

    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      // Initialize background services in parallel where possible
      await Future.wait([
        _initializeSyncService(),
        _initializeUserSpecificServices(currentUser),
        di.sl<BackgroundTaskService>().initialize(),
        // _initializeNotificationServices(), // This is now handled on-demand by NotificationPermissionService
      ]);

      debugPrint(
          '✅ Background services initialized (${stopwatch.elapsedMilliseconds}ms)');
    } catch (e) {
      debugPrint('⚠️ Background services initialization error: $e');
      // Don't crash the app for background service failures
    }
  });
}

/// Stage 4: Initialize optional services with additional delay
void _initializeOptionalServices() {
  Future.delayed(const Duration(seconds: 2), () async {
    final stopwatch = Stopwatch()..start();
    debugPrint('🎯 Stage 4: Optional services initialization...');

    try {
      // Initialize optional services
      await di.initializeOptionalServices();

      // Start recurring expense service
      _startRecurringExpenseService();

      // Initialize background service permissions (optional)
      _initializeBackgroundServicePermissions();

      debugPrint(
          '✅ Optional services initialized (${stopwatch.elapsedMilliseconds}ms)');
    } catch (e) {
      debugPrint('⚠️ Optional services initialization error: $e');
      // Non-critical, don't affect app functionality
    }
  });
}

/// Initialize sync service
Future<void> _initializeSyncService() async {
  try {
    final syncService = di.sl<SyncService>();
    await syncService.initialize(startPeriodicSync: true);
    debugPrint('✅ SyncService initialized with automatic periodic sync');

    // Perform initial sync after initialization
    Future.delayed(const Duration(seconds: 3), () {
      if (FirebaseAuth.instance.currentUser != null) {
        syncService.forceFullSync();
      }
    });
  } catch (e) {
    debugPrint('⚠️ SyncService initialization failed: $e');
  }
}

/*
/// Initialize notification services
Future<void> _initializeNotificationServices() async {
  try {
    // Initialize background notification services
    await di.initializeBackgroundServices();
    debugPrint('✅ Notification services initialized');
  } catch (e) {
    debugPrint('⚠️ Notification services initialization failed: $e');
  }
}
*/

/// Initialize user-specific services if user is logged in
Future<void> _initializeUserSpecificServices(User? currentUser) async {
  if (currentUser == null) return;

  try {
    debugPrint('👤 User logged in, initializing user-specific services...');

    // Initialize SettingsService for the current user
    final settingsService = di.sl<SettingsService>();
    await settingsService.initializeForUser(currentUser.uid);
    debugPrint('✅ SettingsService initialized for user');
  } catch (e) {
    debugPrint('⚠️ User-specific services initialization failed: $e');
  }
}

/// Start recurring expense processing
void _startRecurringExpenseService() {
  try {
    // Create a timer to process recurring expenses periodically
    Timer.periodic(const Duration(hours: 1), (timer) {
      try {
        di.sl<ProcessRecurringExpensesUseCase>().execute();
      } catch (e) {
        debugPrint('⚠️ Recurring expense processing failed: $e');
      }
    });

    // Also process immediately when app starts (with delay)
    Future.delayed(const Duration(seconds: 10), () {
      try {
        di.sl<ProcessRecurringExpensesUseCase>().execute();
      } catch (e) {
        debugPrint('⚠️ Initial recurring expense processing failed: $e');
      }
    });

    debugPrint('✅ RecurringExpenseService started');
  } catch (e) {
    debugPrint('⚠️ RecurringExpenseService start failed: $e');
  }
}

/// Initialize background service permissions (optional, non-blocking)
void _initializeBackgroundServicePermissions() {
  // Only initialize if Android and we haven't asked for permissions yet
  if (!Platform.isAndroid) return;

  Future.delayed(const Duration(seconds: 5), () async {
    try {
      // Check if we already have permissions to avoid showing dialog repeatedly
      final hasPermissions = await FlutterBackground.hasPermissions;

      if (hasPermissions) {
        // We have permissions, initialize silently
        await _setupFlutterBackground();
      } else {
        // We don't have permissions - initialize in background after app is fully loaded
        // This prevents the permission dialog from blocking app startup
        Future.delayed(const Duration(seconds: 10), () async {
          try {
            await _setupFlutterBackground();
          } catch (e) {
            debugPrint('⚠️ Background service setup failed (non-critical): $e');
          }
        });
      }
    } catch (e) {
      debugPrint('⚠️ Background service check failed (non-critical): $e');
    }
  });
}

/// Setup Flutter Background with proper configuration
Future<void> _setupFlutterBackground() async {
  try {
    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: 'Budgie',
      notificationText: 'Tracking expenses in background',
      notificationImportance: AndroidNotificationImportance.normal,
      notificationIcon: AndroidResource(
        name: 'ic_launcher',
        defType: 'mipmap',
      ),
    );

    final initialized =
        await FlutterBackground.initialize(androidConfig: androidConfig);

    if (initialized) {
      debugPrint('✅ Flutter background service initialized');
    } else {
      debugPrint(
          '⚠️ Flutter background service not initialized (permissions may be needed)');
    }
  } catch (e) {
    debugPrint('⚠️ Flutter background setup error: $e');
  }
}

/// Build error UI when initialization fails
Widget _buildErrorApp(dynamic error) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48.0),
              const SizedBox(height: 16.0),
              const Text(
                'Initialization Error',
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Failed to initialize app: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Bootstrap app widget that shows while background services initialize
class BudgieAppBootstrap extends StatefulWidget {
  const BudgieAppBootstrap({Key? key}) : super(key: key);

  @override
  State<BudgieAppBootstrap> createState() => _BudgieAppBootstrapState();
}

class _BudgieAppBootstrapState extends State<BudgieAppBootstrap> {
  bool _providersReady = false;

  @override
  void initState() {
    super.initState();
    _checkProvidersReady();
  }

  void _checkProvidersReady() {
    // Check if critical ViewModels are available
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        // Test if critical services are ready
        di.sl<ThemeViewModel>();
        di.sl<AuthRepository>();

        debugPrint('✅ Critical providers ready');
        if (mounted) {
          setState(() {
            _providersReady = true;
          });
        }
      } catch (e) {
        debugPrint('⚠️ Providers not ready yet, retrying...');
        // Retry after a short delay
        Future.delayed(const Duration(milliseconds: 200), _checkProvidersReady);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_providersReady) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/budgie_icon.png',
                  width: 80,
                  height: 80,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.account_balance_wallet,
                      size: 80,
                      color: Colors.blue,
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Budgie',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Initializing...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const BudgieApp();
  }
}

/// Main app widget with providers
class BudgieApp extends StatefulWidget {
  const BudgieApp({Key? key}) : super(key: key);

  @override
  State<BudgieApp> createState() => _BudgieAppState();
}

// Global scaffold messenger key for offline notifications
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class _BudgieAppState extends State<BudgieApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set up the scaffold messenger key for offline notifications
    OfflineNotificationService.setScaffoldMessengerKey(scaffoldMessengerKey);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App is resumed from background, check for sync
      try {
        if (di.sl.isRegistered<SyncService>()) {
          final syncService = di.sl<SyncService>();
          final auth = FirebaseAuth.instance;
          if (auth.currentUser != null) {
            // App is resumed and user is logged in, trigger sync
            debugPrint('📱 App resumed - checking for pending syncs');
            Future.delayed(const Duration(seconds: 1), () {
              syncService.syncData(fullSync: false);
            });
          }
        }
      } catch (e) {
        debugPrint('⚠️ Resume sync failed: $e');
      }
    } else if (state == AppLifecycleState.detached) {
      // App is being killed, clean up resources
      try {
        if (di.sl.isRegistered<SyncService>()) {
          di.sl<SyncService>().dispose();
          debugPrint('🧹 App detached: disposed SyncService');
        }
      } catch (e) {
        debugPrint('⚠️ Cleanup failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => di.sl<ThemeViewModel>()),
        ChangeNotifierProvider(create: (_) => di.sl<AuthViewModel>()),
        ChangeNotifierProvider(create: (_) => di.sl<ExpensesViewModel>()),
        ChangeNotifierProvider(create: (_) => di.sl<BudgetViewModel>()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(430, 952),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return Consumer<ThemeViewModel>(
            builder: (context, themeViewModel, child) {
              // Use responsive themes that adapt to screen size
              // Now that ScreenUtil is initialized, we can safely use responsive values
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
                routes: {
                  Routes.home: (context) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider(
                              create: (_) => di.sl<SettingsService>()),
                        ],
                        child: const HomeScreen(),
                      ),
                  Routes.analytic: (context) => const AnalyticScreen(),
                  Routes.settings: (context) => const SettingScreen(),
                  Routes.profile: (context) => const ProfileScreen(),
                },
                onGenerateRoute: AppRouter.generateRoute,
                initialRoute: Routes.splash,
              );
            },
          );
        },
      ),
    );
  }
}
