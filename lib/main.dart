import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background/flutter_background.dart';
import 'dart:io';

import 'core/constants/firebase_options.dart';
import 'core/constants/routes.dart';
import 'core/router/app_router.dart';
import 'core/services/settings_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/recurring_expense_service.dart';
import 'core/network/connectivity_service.dart';
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
    // Initialize Firebase with proper error handling
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    // Check Firebase Auth status
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    debugPrint('Current Firebase user: ${currentUser?.uid ?? 'Not signed in'}');

    // Set up persistence for Auth
    try {
      await auth.setPersistence(Persistence.LOCAL);
      debugPrint('Firebase Auth persistence set to LOCAL');
    } catch (e) {
      debugPrint('Failed to set persistence: $e');
    }

    // Initialize flutter_background for Android
    if (Platform.isAndroid) {
      try {
        debugPrint('Initializing flutter_background for Android...');
        const androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: "Budgie",
          notificationText: "Running in background",
          notificationImportance: AndroidNotificationImportance.normal,
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
            defType: 'mipmap',
          ),
        );

        // First initialization - may trigger permission dialog
        bool initialized =
            await FlutterBackground.initialize(androidConfig: androidConfig);
        debugPrint(
            'First flutter_background initialization result: $initialized');

        // Check if we have permissions but initialization still returned false
        if (!initialized && await FlutterBackground.hasPermissions) {
          // Try again - this should succeed now that permissions are granted
          initialized =
              await FlutterBackground.initialize(androidConfig: androidConfig);
          debugPrint(
              'Second flutter_background initialization result: $initialized');
        }

        if (initialized) {
          debugPrint('flutter_background initialized successfully');
        } else {
          debugPrint(
              'flutter_background initialization failed, will retry when needed');
        }
      } catch (e) {
        debugPrint('Error initializing flutter_background: $e');
      }
    }

    // Initialize dependency injection
    debugPrint('Initializing dependency injection...');
    await di.init();
    debugPrint('Dependency injection initialized');

    // Initialize ConnectivityService first to monitor network state
    debugPrint('Initializing ConnectivityService...');
    di.sl<ConnectivityService>();

    // Initialize SyncService for all users (logged in or not)
    debugPrint('Initializing SyncService...');
    final syncService = di.sl<SyncService>();
    await syncService.initialize(startPeriodicSync: true);
    debugPrint('SyncService initialized with automatic periodic sync');

    // Initialize local data for logged in user
    if (currentUser != null) {
      debugPrint('User is logged in, initializing local data...');

      // Initialize SettingsService for the current user
      final settingsService = di.sl<SettingsService>();
      await settingsService.initializeForUser(currentUser.uid);

      // Start recurring expense service
      debugPrint('Starting RecurringExpenseService...');
      di.sl<RecurringExpenseService>().startProcessing();
      debugPrint('RecurringExpenseService started');

      // Perform initial sync after a short delay to ensure everything is ready
      Future.delayed(const Duration(seconds: 5), () {
        syncService.forceFullSync();
      });
    }

    // Disable Provider type checking in debug mode if needed
    // Provider.debugCheckInvalidValueType = null;

    // Wrap your entire app in all the providers you'll need
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => di.sl<AuthViewModel>()),
          ChangeNotifierProvider(create: (_) => di.sl<ExpensesViewModel>()),
          ChangeNotifierProvider(create: (_) => di.sl<BudgetViewModel>()),
          ChangeNotifierProvider(create: (_) => di.sl<ThemeViewModel>()),
          // TODO: add more providers here as you build out other features
        ],
        child: const BudgieApp(),
      ),
    );
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
      final syncService = di.sl<SyncService>();
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) {
        // App is resumed and user is logged in, trigger sync
        debugPrint('App resumed - checking for pending syncs');
        Future.delayed(const Duration(seconds: 1), () {
          syncService.syncData(fullSync: false);
        });
      }
    } else if (state == AppLifecycleState.detached) {
      // App is being killed, clean up resources
      di.sl<SyncService>().dispose();
      di.sl<RecurringExpenseService>().stopProcessing();
      debugPrint(
          'App detached: disposed SyncService and RecurringExpenseService');
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
