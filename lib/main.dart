import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background/flutter_background.dart';
import 'dart:io';
import 'dart:async';

import 'data/infrastructure/config/firebase_options.dart';
import 'core/constants/routes.dart';
import 'core/router/app_router.dart';
import 'data/infrastructure/services/settings_service.dart';
import 'data/infrastructure/services/sync_service.dart';
import 'domain/usecase/expense/process_recurring_expenses_usecase.dart';
import 'data/infrastructure/services/notification_manager_service.dart';
import 'data/infrastructure/network/connectivity_service.dart';
import 'presentation/viewmodels/expenses_viewmodel.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/budget_viewmodel.dart';
import 'presentation/viewmodels/theme_viewmodel.dart';
import 'di/injection_container.dart' as di;
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/analytic_screen.dart';
import 'presentation/screens/setting_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/widgets/animated_float_button.dart';

Future<void> main() async {
  // Ensure we can call async code before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Critical path initialization - must be sequential
    await _initializeCriticalServices();

    // Start the app immediately with providers
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => di.sl<AuthViewModel>()),
          ChangeNotifierProvider(create: (_) => di.sl<ExpensesViewModel>()),
          ChangeNotifierProvider(create: (_) => di.sl<BudgetViewModel>()),
          ChangeNotifierProvider(create: (_) => di.sl<ThemeViewModel>()),
        ],
        child: const BudgieApp(),
      ),
    );

    // Non-critical initialization can happen after app starts
    _initializeNonCriticalServices();
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint(stackTrace.toString());
    // Show error UI
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 48.0),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Initialization Error',
                    style:
                        TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Failed to initialize app: $e',
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
      ),
    );
  }
}

/// Initialize only critical services needed for app startup
Future<void> _initializeCriticalServices() async {
  final stopwatch = Stopwatch()..start();

  // Initialize Firebase with proper error handling
  debugPrint('🚀 Initializing critical services...');
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

  // Initialize dependency injection
  await di.init();
  debugPrint(
      '✅ Dependency injection initialized (${stopwatch.elapsedMilliseconds}ms)');

  // Initialize only essential services in parallel
  await Future.wait([
    _initializeConnectivityService(),
    _initializeNotificationService(),
  ]);

  debugPrint(
      '✅ Critical services initialized in ${stopwatch.elapsedMilliseconds}ms');
}

/// Initialize connectivity service
Future<void> _initializeConnectivityService() async {
  try {
    di.sl<ConnectivityService>();
    debugPrint('✅ ConnectivityService initialized');
  } catch (e) {
    debugPrint('⚠️ ConnectivityService initialization failed: $e');
  }
}

/// Initialize notification service
Future<void> _initializeNotificationService() async {
  try {
    final notificationManager = di.sl<NotificationManagerService>();
    await notificationManager.initialize();
    debugPrint('✅ NotificationManagerService initialized');
  } catch (e) {
    debugPrint('⚠️ NotificationManagerService initialization failed: $e');
  }
}

/// Initialize non-critical services after app startup
void _initializeNonCriticalServices() {
  Future.delayed(const Duration(milliseconds: 500), () async {
    final stopwatch = Stopwatch()..start();
    debugPrint('🔄 Starting non-critical services initialization...');

    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      // Initialize services in parallel where possible
      await Future.wait([
        _initializeSyncService(),
        _initializeUserSpecificServices(currentUser),
        _initializeBackgroundService(),
      ]);

      debugPrint(
          '✅ Non-critical services initialized in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      debugPrint('⚠️ Non-critical services initialization error: $e');
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

/// Initialize user-specific services if user is logged in
Future<void> _initializeUserSpecificServices(User? currentUser) async {
  if (currentUser == null) return;

  try {
    debugPrint('👤 User logged in, initializing user-specific services...');

    // Initialize SettingsService for the current user
    final settingsService = di.sl<SettingsService>();
    await settingsService.initializeForUser(currentUser.uid);
    debugPrint('✅ SettingsService initialized for user');

    // Start recurring expense service
    _startRecurringExpenseService();
  } catch (e) {
    debugPrint('⚠️ User-specific services initialization failed: $e');
  }
}

/// Start recurring expense processing
void _startRecurringExpenseService() {
  try {
    // Create a timer to process recurring expenses periodically
    Timer.periodic(const Duration(hours: 1), (timer) {
      di.sl<ProcessRecurringExpensesUseCase>().execute();
    });

    // Also process immediately when app starts (with delay)
    Future.delayed(const Duration(seconds: 10), () {
      di.sl<ProcessRecurringExpensesUseCase>().execute();
    });

    debugPrint('✅ ProcessRecurringExpensesUseCase started');
  } catch (e) {
    debugPrint('⚠️ RecurringExpenseService start failed: $e');
  }
}

/// Initialize background service (optional, non-blocking)
Future<void> _initializeBackgroundService() async {
  // Only initialize if Android and we haven't asked for permissions yet
  if (!Platform.isAndroid) return;

  try {
    // Check if we already have permissions to avoid showing dialog repeatedly
    final hasPermissions = await FlutterBackground.hasPermissions;

    if (hasPermissions) {
      // We have permissions, initialize silently
      await _setupFlutterBackground();
    } else {
      // We don't have permissions - initialize in background after app is fully loaded
      // This prevents the permission dialog from blocking app startup
      Future.delayed(const Duration(seconds: 5), () async {
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
}

/// Setup Flutter Background with proper configuration
Future<void> _setupFlutterBackground() async {
  try {
    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Budgie",
      notificationText: "Tracking expenses in background",
      notificationImportance:
          AndroidNotificationImportance.normal, // Standard importance
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
      // App is resumed from background, check for sync
      try {
        final syncService = di.sl<SyncService>();
        final auth = FirebaseAuth.instance;
        if (auth.currentUser != null) {
          // App is resumed and user is logged in, trigger sync
          debugPrint('📱 App resumed - checking for pending syncs');
          Future.delayed(const Duration(seconds: 1), () {
            syncService.syncData(fullSync: false);
          });
        }
      } catch (e) {
        debugPrint('⚠️ Resume sync failed: $e');
      }
    } else if (state == AppLifecycleState.detached) {
      // App is being killed, clean up resources
      try {
        di.sl<SyncService>().dispose();
        debugPrint('🧹 App detached: disposed SyncService');
      } catch (e) {
        debugPrint('⚠️ Cleanup failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeViewModel = Provider.of<ThemeViewModel>(context);

    return MaterialApp(
      title: 'Budgie',
      theme: themeViewModel.theme,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      navigatorObservers: [
        fabRouteObserver,
      ],
      routes: {
        Routes.home: (context) => MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => di.sl<SettingsService>()),
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
  }
}
