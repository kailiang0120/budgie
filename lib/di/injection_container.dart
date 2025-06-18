import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/expenses_repository_impl.dart';
import '../data/repositories/budget_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/expenses_repository.dart';
import '../domain/repositories/budget_repository.dart';
import '../presentation/viewmodels/auth_viewmodel.dart';
import '../presentation/viewmodels/expenses_viewmodel.dart';
import '../presentation/viewmodels/budget_viewmodel.dart';
import '../presentation/viewmodels/theme_viewmodel.dart';
import '../data/local/database/app_database.dart';
import '../data/datasources/local_data_source.dart';
import '../data/datasources/local_data_source_impl.dart';
import '../data/infrastructure/network/connectivity_service.dart';
import '../data/infrastructure/services/sync_service.dart';
import '../data/infrastructure/services/notification_manager_service.dart';
import '../data/infrastructure/services/settings_service.dart';
import '../data/infrastructure/services/currency_conversion_service.dart';
import '../data/infrastructure/services/data_collection_service.dart';
import '../data/infrastructure/services/notification_sender_service.dart';
import '../data/infrastructure/services/permission_handler_service.dart';
import '../data/infrastructure/services/notification_permission_service.dart';
import '../domain/services/ai_expense_prediction_service.dart';
import '../domain/services/budget_calculation_service.dart';
import '../domain/services/budget_reallocation_service.dart';
import '../domain/services/expense_detection_service.dart';
import '../presentation/services/expense_card_manager_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/infrastructure/services/secure_storage_service.dart';
import '../data/infrastructure/services/background_task_service.dart';
import '../data/infrastructure/services/offline_notification_service.dart';
import '../data/infrastructure/services/firebase_data_fetcher_service.dart';

// Auth use cases
import '../domain/usecase/auth/sign_in_with_email_usecase.dart';
import '../domain/usecase/auth/create_user_with_email_usecase.dart';
import '../domain/usecase/auth/sign_in_with_google_usecase.dart';
import '../domain/usecase/auth/sign_in_as_guest_usecase.dart';
import '../domain/usecase/auth/upgrade_guest_account_usecase.dart';
import '../domain/usecase/auth/secure_sign_out_anonymous_user_usecase.dart';
import '../domain/usecase/auth/refresh_auth_state_usecase.dart';
import '../domain/usecase/auth/update_profile_usecase.dart';
import '../domain/usecase/auth/update_user_settings_usecase.dart';
import '../domain/usecase/auth/initialize_user_data_usecase.dart';
import '../domain/usecase/auth/is_guest_user_usecase.dart';

// Budget use cases
import '../domain/usecase/budget/load_budget_usecase.dart';
import '../domain/usecase/budget/save_budget_usecase.dart';
import '../domain/usecase/budget/convert_budget_currency_usecase.dart';
import '../domain/usecase/budget/calculate_budget_remaining_usecase.dart';
import '../domain/usecase/budget/refresh_budget_usecase.dart';

// Expense use cases
import '../domain/usecase/expense/add_expense_usecase.dart';
import '../domain/usecase/expense/update_expense_usecase.dart';
import '../domain/usecase/expense/delete_expense_usecase.dart';
import '../domain/usecase/expense/load_expenses_usecase.dart';
import '../domain/usecase/expense/filter_expenses_usecase.dart';
import '../domain/usecase/expense/calculate_expense_totals_usecase.dart';
import '../domain/usecase/expense/process_recurring_expenses_usecase.dart';

/// Service locator instance
final sl = GetIt.instance;

/// Initialization priority levels
enum InitializationPriority {
  critical, // Must be available immediately (Firebase, Core services)
  essential, // Required for basic app functionality (Auth, Database)
  important, // Major features (Expenses, Budget)
  background, // Background services (Sync, Notifications)
  optional, // Nice-to-have features (Analytics, AI)
}

/// Service initialization tracker
class ServiceTracker {
  static final Map<Type, bool> _initialized = {};
  static final Map<InitializationPriority, List<String>> _pendingByPriority =
      {};
  static final Set<String> _initializing = {};

  static void markInitialized<T>() {
    _initialized[T] = true;
    debugPrint('✅ Service ${T.toString()} initialized');
  }

  static bool isInitialized<T>() => _initialized[T] ?? false;

  static void addPending(InitializationPriority priority, String serviceName) {
    _pendingByPriority.putIfAbsent(priority, () => []).add(serviceName);
  }

  static void markInitializing(String serviceName) {
    _initializing.add(serviceName);
  }

  static void markCompleted(String serviceName) {
    _initializing.remove(serviceName);
    _pendingByPriority.values.forEach((list) => list.remove(serviceName));
  }

  static bool isInitializing(String serviceName) =>
      _initializing.contains(serviceName);

  static Map<String, dynamic> getStatus() {
    return {
      'initialized': _initialized.length,
      'pending':
          _pendingByPriority.values.fold(0, (sum, list) => sum + list.length),
      'initializing': _initializing.length,
      'details': {
        'byPriority': _pendingByPriority,
        'initializing': _initializing.toList(),
      }
    };
  }
}

/// Lazy initialization wrapper
class LazyService<T> {
  T? _instance;
  final T Function() _factory;
  final String _serviceName;
  bool _isInitializing = false;

  LazyService(this._factory, this._serviceName);

  T get instance {
    if (_instance != null) return _instance!;

    if (_isInitializing) {
      throw Exception('Circular dependency detected for $_serviceName');
    }

    _isInitializing = true;
    try {
      debugPrint('🔄 Lazy initializing $_serviceName...');
      _instance = _factory();
      ServiceTracker.markCompleted(_serviceName);
      debugPrint('✅ Lazy initialized $_serviceName');
      return _instance!;
    } finally {
      _isInitializing = false;
    }
  }

  bool get isInitialized => _instance != null;
}

/// Enhanced dependency injection container with priority-based initialization
class DependencyContainer {
  static bool _criticalInitialized = false;
  static bool _essentialInitialized = false;
  static bool _importantInitialized = false;

  /// Initialize critical services only (Firebase, core infrastructure)
  static Future<void> initializeCritical() async {
    if (_criticalInitialized) return;

    final stopwatch = Stopwatch()..start();
    debugPrint('🚀 Initializing CRITICAL services...');

    try {
      // Firebase services - global singletons, no circular deps
      sl.registerLazySingleton(() => FirebaseAuth.instance);
      sl.registerLazySingleton(() => FirebaseFirestore.instance);
      sl.registerLazySingleton(() => GoogleSignIn());

      // Database - fundamental service, no deps
      sl.registerLazySingleton(() => AppDatabase());

      // Local data source - only depends on database and auth
      sl.registerLazySingleton<LocalDataSource>(
        () => LocalDataSourceImpl(sl(), auth: sl<FirebaseAuth>()),
      );

      // Connectivity service - no dependencies
      sl.registerLazySingleton<ConnectivityService>(
        () => ConnectivityServiceImpl(),
      );

      // Secure storage - no dependencies
      sl.registerLazySingleton(() => const FlutterSecureStorage());
      sl.registerLazySingleton(() => SecureStorageService(secureStorage: sl()));

      // Offline notification service - no dependencies
      sl.registerLazySingleton(() => OfflineNotificationService());

      // Firebase data fetcher service - depends on local data source and connectivity
      sl.registerLazySingleton(() => FirebaseDataFetcherService(
            localDataSource: sl(),
            connectivityService: sl(),
          ));

      _criticalInitialized = true;
      debugPrint(
          '✅ CRITICAL services initialized (${stopwatch.elapsedMilliseconds}ms)');
    } catch (e) {
      debugPrint('❌ CRITICAL services initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize essential services (Auth, Settings, Theme)
  static Future<void> initializeEssential() async {
    if (_essentialInitialized) return;
    await initializeCritical(); // Ensure critical services are ready

    final stopwatch = Stopwatch()..start();
    debugPrint('🔧 Initializing ESSENTIAL services...');

    try {
      // Settings service - depends on local data source and connectivity
      sl.registerLazySingleton(() => SettingsService());

      // Theme ViewModel - depends on settings service
      sl.registerLazySingleton(() => ThemeViewModel(settingsService: sl()));

      // Auth Repository - simple dependencies
      sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
          auth: sl<FirebaseAuth>(),
          googleSignIn: sl<GoogleSignIn>(),
        ),
      );

      _essentialInitialized = true;
      debugPrint(
          '✅ ESSENTIAL services initialized (${stopwatch.elapsedMilliseconds}ms)');
    } catch (e) {
      debugPrint('❌ ESSENTIAL services initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize important services (Repositories, Core ViewModels)
  static Future<void> initializeImportant() async {
    if (_importantInitialized) return;
    await initializeEssential(); // Ensure essential services are ready

    final stopwatch = Stopwatch()..start();
    debugPrint('📊 Initializing IMPORTANT services...');

    try {
      // Repositories - depend on critical services
      _registerRepositories();

      // Core domain services - lightweight
      _registerCoreDomainServices();

      // Core ViewModels - require repositories
      _registerCoreViewModels();

      _importantInitialized = true;
      debugPrint(
          '✅ IMPORTANT services initialized (${stopwatch.elapsedMilliseconds}ms)');
    } catch (e) {
      debugPrint('❌ IMPORTANT services initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize background services (lazily)
  static void initializeBackground() {
    debugPrint('🔄 Registering BACKGROUND services (lazy)...');

    // Notification services - heavy initialization, lazy load
    _registerLazyService<NotificationManagerService>(
      'NotificationManagerService',
      () => NotificationManagerService(),
      InitializationPriority.background,
    );

    _registerLazyService<NotificationSenderService>(
      'NotificationSenderService',
      () => NotificationSenderService(),
      InitializationPriority.background,
    );

    _registerLazyService<PermissionHandlerService>(
      'PermissionHandlerService',
      () => PermissionHandlerService(),
      InitializationPriority.background,
    );

    _registerLazyService<NotificationPermissionService>(
      'NotificationPermissionService',
      () => NotificationPermissionService(
        permissionHandler: sl(),
        notificationManager: sl(),
        settingsService: sl(),
      ),
      InitializationPriority.background,
    );

    _registerLazyService<BackgroundTaskService>(
      'BackgroundTaskService',
      () => BackgroundTaskService(),
      InitializationPriority.background,
    );

    // Sync service - depends on multiple services, lazy load
    _registerLazyService<SyncService>(
      'SyncService',
      () => SyncService(
        localDataSource: sl(),
        expensesRepository: sl(),
        budgetRepository: sl(),
        connectivityService: sl(),
        auth: sl(),
      ),
      InitializationPriority.background,
    );

    debugPrint('✅ BACKGROUND services registered (lazy)');
  }

  /// Initialize optional services (lazily)
  static void initializeOptional() {
    debugPrint('🎯 Registering OPTIONAL services (lazy)...');

    // AI and prediction services - expensive, lazy load
    _registerLazyService<AIExpensePredictionService>(
      'AIExpensePredictionService',
      () {
        final service = AIExpensePredictionService();
        service.setConnectivityService(sl<ConnectivityService>());
        return service;
      },
      InitializationPriority.optional,
    );

    _registerLazyService<ExpenseDetector>(
      'ExpenseDetector',
      () => ExpenseDetector(),
      InitializationPriority.optional,
    );

    // Currency conversion - network dependent, lazy load
    _registerLazyService<CurrencyConversionService>(
      'CurrencyConversionService',
      () {
        final service = CurrencyConversionService();
        service.setConnectivityService(sl<ConnectivityService>());
        return service;
      },
      InitializationPriority.optional,
    );

    // Data collection - optional feature
    _registerLazyService<DataCollectionService>(
      'DataCollectionService',
      () => DataCollectionService(),
      InitializationPriority.optional,
    );

    // UI services
    _registerLazyService<ExpenseCardManagerService>(
      'ExpenseCardManagerService',
      () => ExpenseCardManagerService(),
      InitializationPriority.optional,
    );

    debugPrint('✅ OPTIONAL services registered (lazy)');
  }

  /// Initialize use cases (lazily - they have complex dependency chains)
  static void initializeUseCases() {
    debugPrint('⚡ Registering USE CASES (lazy)...');

    // Auth use cases
    _registerAuthUseCases();

    // Budget use cases
    _registerBudgetUseCases();

    // Expense use cases
    _registerExpenseUseCases();

    debugPrint('✅ USE CASES registered (lazy)');
  }

  // Private helper methods

  static void _registerRepositories() {
    sl.registerLazySingleton<ExpensesRepository>(
      () => ExpensesRepositoryImpl(
        firestore: sl<FirebaseFirestore>(),
        auth: sl<FirebaseAuth>(),
        localDataSource: sl(),
        connectivityService: sl(),
      ),
    );

    sl.registerLazySingleton<BudgetRepository>(
      () => BudgetRepositoryImpl(
        firestore: sl<FirebaseFirestore>(),
        auth: sl<FirebaseAuth>(),
        localDataSource: sl(),
        connectivityService: sl(),
      ),
    );
  }

  static void _registerCoreDomainServices() {
    // Lightweight domain services with minimal dependencies
    sl.registerLazySingleton(() => BudgetCalculationService(
          currencyService: sl(),
        ));

    sl.registerLazySingleton(() => BudgetReallocationService(
          budgetRepository: sl(),
        ));
  }

  static void _registerCoreViewModels() {
    // ExpensesViewModel - singleton because it manages app state
    sl.registerLazySingleton(
      () => ExpensesViewModel(
        expensesRepository: sl(),
        connectivityService: sl(),
        settingsService: sl(),
        addExpenseUseCase: sl(),
        updateExpenseUseCase: sl(),
        deleteExpenseUseCase: sl(),
        loadExpensesUseCase: sl(),
        filterExpensesUseCase: sl(),
        calculateExpenseTotalsUseCase: sl(),
      ),
    );

    // AuthViewModel - factory because multiple instances may be needed
    sl.registerFactory(
      () => AuthViewModel(
        authRepository: sl(),
        signInWithEmailUseCase: sl(),
        createUserWithEmailUseCase: sl(),
        signInWithGoogleUseCase: sl(),
        signInAsGuestUseCase: sl(),
        upgradeGuestAccountUseCase: sl(),
        secureSignOutAnonymousUserUseCase: sl(),
        refreshAuthStateUseCase: sl(),
        updateProfileUseCase: sl(),
        updateUserSettingsUseCase: sl(),
        initializeUserDataUseCase: sl(),
        isGuestUserUseCase: sl(),
      ),
    );

    // BudgetViewModel - factory for screen-specific instances
    sl.registerFactory(
      () => BudgetViewModel(
        budgetRepository: sl(),
        loadBudgetUseCase: sl(),
        saveBudgetUseCase: sl(),
        convertBudgetCurrencyUseCase: sl(),
        calculateBudgetRemainingUseCase: sl(),
        refreshBudgetUseCase: sl(),
      ),
    );
  }

  static void _registerAuthUseCases() {
    _registerLazyService<SignInWithEmailUseCase>(
      'SignInWithEmailUseCase',
      () => SignInWithEmailUseCase(
        authRepository: sl(),
        syncService: sl(),
        themeViewModel: sl(),
        settingsService: sl(),
      ),
      InitializationPriority.important,
    );

    _registerLazyService<CreateUserWithEmailUseCase>(
      'CreateUserWithEmailUseCase',
      () => CreateUserWithEmailUseCase(
        authRepository: sl(),
        syncService: sl(),
        themeViewModel: sl(),
        settingsService: sl(),
      ),
      InitializationPriority.important,
    );

    _registerLazyService<SignInWithGoogleUseCase>(
      'SignInWithGoogleUseCase',
      () => SignInWithGoogleUseCase(
        authRepository: sl(),
        syncService: sl(),
        themeViewModel: sl(),
        settingsService: sl(),
      ),
      InitializationPriority.important,
    );

    _registerLazyService<SignInAsGuestUseCase>(
      'SignInAsGuestUseCase',
      () => SignInAsGuestUseCase(
        authRepository: sl(),
        syncService: sl(),
        themeViewModel: sl(),
        settingsService: sl(),
      ),
      InitializationPriority.important,
    );

    _registerLazyService<UpgradeGuestAccountUseCase>(
      'UpgradeGuestAccountUseCase',
      () => UpgradeGuestAccountUseCase(
        authRepository: sl(),
        syncService: sl(),
      ),
      InitializationPriority.background,
    );

    _registerLazyService<SecureSignOutAnonymousUserUseCase>(
      'SecureSignOutAnonymousUserUseCase',
      () => SecureSignOutAnonymousUserUseCase(authRepository: sl()),
      InitializationPriority.background,
    );

    _registerLazyService<RefreshAuthStateUseCase>(
      'RefreshAuthStateUseCase',
      () => RefreshAuthStateUseCase(
        authRepository: sl(),
        themeViewModel: sl(),
      ),
      InitializationPriority.important,
    );

    _registerLazyService<UpdateProfileUseCase>(
      'UpdateProfileUseCase',
      () => UpdateProfileUseCase(authRepository: sl()),
      InitializationPriority.background,
    );

    _registerLazyService<UpdateUserSettingsUseCase>(
      'UpdateUserSettingsUseCase',
      () => UpdateUserSettingsUseCase(authRepository: sl()),
      InitializationPriority.background,
    );

    _registerLazyService<InitializeUserDataUseCase>(
      'InitializeUserDataUseCase',
      () => InitializeUserDataUseCase(
        syncService: sl(),
        themeViewModel: sl(),
        settingsService: sl(),
      ),
      InitializationPriority.important,
    );

    _registerLazyService<IsGuestUserUseCase>(
      'IsGuestUserUseCase',
      () => IsGuestUserUseCase(),
      InitializationPriority.background,
    );
  }

  static void _registerBudgetUseCases() {
    _registerLazyService<LoadBudgetUseCase>(
      'LoadBudgetUseCase',
      () => LoadBudgetUseCase(
        budgetRepository: sl(),
        connectivityService: sl(),
        syncService: sl(),
        settingsService: sl(),
      ),
      InitializationPriority.important,
    );

    _registerLazyService<SaveBudgetUseCase>(
      'SaveBudgetUseCase',
      () => SaveBudgetUseCase(budgetRepository: sl()),
      InitializationPriority.important,
    );

    _registerLazyService<ConvertBudgetCurrencyUseCase>(
      'ConvertBudgetCurrencyUseCase',
      () => ConvertBudgetCurrencyUseCase(
        budgetRepository: sl(),
        currencyConversionService: sl(),
      ),
      InitializationPriority.background,
    );

    _registerLazyService<CalculateBudgetRemainingUseCase>(
      'CalculateBudgetRemainingUseCase',
      () => CalculateBudgetRemainingUseCase(
        currencyConversionService: sl(),
        budgetCalculationService: sl(),
      ),
      InitializationPriority.important,
    );

    _registerLazyService<RefreshBudgetUseCase>(
      'RefreshBudgetUseCase',
      () => RefreshBudgetUseCase(
        connectivityService: sl(),
        syncService: sl(),
        loadBudgetUseCase: sl(),
      ),
      InitializationPriority.background,
    );
  }

  static void _registerExpenseUseCases() {
    _registerLazyService<AddExpenseUseCase>(
      'AddExpenseUseCase',
      () => AddExpenseUseCase(
        expensesRepository: sl(),
        budgetRepository: sl(),
        budgetCalculationService: sl(),
      ),
      InitializationPriority.important,
    );

    _registerLazyService<UpdateExpenseUseCase>(
      'UpdateExpenseUseCase',
      () => UpdateExpenseUseCase(
        expensesRepository: sl(),
        budgetRepository: sl(),
        budgetCalculationService: sl(),
      ),
      InitializationPriority.important,
    );

    _registerLazyService<DeleteExpenseUseCase>(
      'DeleteExpenseUseCase',
      () => DeleteExpenseUseCase(
        expensesRepository: sl(),
        budgetRepository: sl(),
        budgetCalculationService: sl(),
      ),
      InitializationPriority.important,
    );

    _registerLazyService<LoadExpensesUseCase>(
      'LoadExpensesUseCase',
      () => LoadExpensesUseCase(
        expensesRepository: sl(),
        connectivityService: sl(),
      ),
      InitializationPriority.important,
    );

    _registerLazyService<FilterExpensesUseCase>(
      'FilterExpensesUseCase',
      () => FilterExpensesUseCase(),
      InitializationPriority.background,
    );

    _registerLazyService<CalculateExpenseTotalsUseCase>(
      'CalculateExpenseTotalsUseCase',
      () => CalculateExpenseTotalsUseCase(settingsService: sl()),
      InitializationPriority.background,
    );

    _registerLazyService<ProcessRecurringExpensesUseCase>(
      'ProcessRecurringExpensesUseCase',
      () => ProcessRecurringExpensesUseCase(
        expensesRepository: sl(),
      ),
      InitializationPriority.background,
    );
  }

  static void _registerLazyService<T extends Object>(
    String serviceName,
    T Function() factory,
    InitializationPriority priority,
  ) {
    ServiceTracker.addPending(priority, serviceName);

    sl.registerLazySingleton<T>(() {
      ServiceTracker.markInitializing(serviceName);
      try {
        final instance = factory();
        ServiceTracker.markCompleted(serviceName);
        return instance;
      } catch (e) {
        ServiceTracker.markCompleted(serviceName);
        debugPrint('❌ Failed to initialize $serviceName: $e');
        rethrow;
      }
    });
  }
}

/// Main initialization function - now with priority-based loading
Future<void> init() async {
  try {
    debugPrint('🚀 Starting priority-based dependency injection...');

    // Clear any existing registrations
    if (sl.isRegistered<FirebaseAuth>()) {
      await sl.reset();
    }

    // Initialize in priority order
    await DependencyContainer.initializeCritical();
    await DependencyContainer.initializeEssential();
    await DependencyContainer.initializeImportant();

    // Register lazy services (don't initialize yet)
    DependencyContainer.initializeBackground();
    DependencyContainer.initializeOptional();
    DependencyContainer.initializeUseCases();

    debugPrint('✅ Priority-based dependency injection completed');
    debugPrint('📊 Service status: ${ServiceTracker.getStatus()}');
  } catch (e) {
    debugPrint('❌ Dependency injection failed: $e');
    rethrow;
  }
}

/*
/// Initialize background services when needed
Future<void> initializeBackgroundServices() async {
  debugPrint('🔄 Initializing background services...');

  try {
    // Initialize notification services
    final notificationManager = sl<NotificationManagerService>();
    await notificationManager.initialize();

    // Initialize sync service
    final syncService = sl<SyncService>();
    await syncService.initialize();

    debugPrint('✅ Background services initialized');
  } catch (e) {
    debugPrint('⚠️ Background services initialization failed: $e');
    // Don't rethrow - background services are not critical
  }
}
*/

/// Initialize optional services when needed
Future<void> initializeOptionalServices() async {
  debugPrint('🎯 Initializing optional services...');

  try {
    // Initialize only if needed
    if (sl.isRegistered<AIExpensePredictionService>()) {
      sl<AIExpensePredictionService>();
    }

    if (sl.isRegistered<DataCollectionService>()) {
      final dataCollector = sl<DataCollectionService>();
      await dataCollector.initialize();
    }

    debugPrint('✅ Optional services initialized');
  } catch (e) {
    debugPrint('⚠️ Optional services initialization failed: $e');
    // Don't rethrow - optional services are not critical
  }
}

/// Check if service is ready (for debugging)
bool isServiceReady<T extends Object>() {
  try {
    return sl.isRegistered<T>() && ServiceTracker.isInitialized<T>();
  } catch (e) {
    return false;
  }
}

/// Get initialization status (for debugging)
Map<String, dynamic> getInitializationStatus() {
  return ServiceTracker.getStatus();
}
