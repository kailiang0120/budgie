import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/expenses_repository_impl.dart';
import '../data/repositories/budget_repository_impl.dart';
import '../data/repositories/recurring_expenses_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/expenses_repository.dart';
import '../domain/repositories/budget_repository.dart';
import '../domain/repositories/recurring_expenses_repository.dart';
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
import '../domain/services/google_ai_expense_prediction_service.dart';
import '../domain/services/budget_calculation_service.dart';
import '../domain/services/budget_reallocation_service.dart';
import '../presentation/services/expense_card_manager_service.dart';

// Auth use cases
import '../domain/usecase/auth/sign_in_with_email_usecase.dart';
import '../domain/usecase/auth/create_user_with_email_usecase.dart';
import '../domain/usecase/auth/sign_in_with_google_usecase.dart';
import '../domain/usecase/auth/sign_in_with_apple_usecase.dart';
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

/// Initialize all dependencies for the application
Future<void> init() async {
  // Register Firebase services as global singletons
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => GoogleSignIn());

  // Local database
  sl.registerLazySingleton(() => AppDatabase());

  // Data sources
  sl.registerLazySingleton<LocalDataSource>(
    () => LocalDataSourceImpl(
      sl(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  // Network connectivity service
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityServiceImpl(),
  );

  // Notification manager (main notification orchestrator)
  sl.registerLazySingleton(() => NotificationManagerService());

  // Settings service
  sl.registerLazySingleton(() => SettingsService(
        localDataSource: sl(),
        connectivityService: sl(),
      ));

  // Data collector (analytics and model improvement)
  sl.registerLazySingleton(() => DataCollectionService());

  // Notification sender service
  sl.registerLazySingleton(() => NotificationSenderService());

  // Permission handler service
  sl.registerLazySingleton(() => PermissionHandlerService());

  // Comprehensive notification permission service
  sl.registerLazySingleton(() {
    final service = NotificationPermissionService();
    service.initialize(sl<NotificationManagerService>());
    return service;
  });

  // UI service for overlays and expense cards
  sl.registerLazySingleton(() => ExpenseCardManagerService());

  // Currency conversion service
  sl.registerLazySingleton(() {
    final service = CurrencyConversionService();
    service.setConnectivityService(sl<ConnectivityService>());
    return service;
  });

  // Google AI expense prediction service (single prediction service)
  sl.registerLazySingleton(() {
    final service = GoogleAIExpensePredictionService();
    service.setConnectivityService(sl<ConnectivityService>());
    return service;
  });

  // Domain services
  sl.registerLazySingleton(() => BudgetCalculationService(
        currencyService: sl(),
      ));

  // Budget reallocation service
  sl.registerLazySingleton(() => BudgetReallocationService(
        budgetRepository: sl(),
      ));

  // ViewModels - Register ThemeViewModel as singleton first
  sl.registerLazySingleton(() => ThemeViewModel(settingsService: sl()));

  // Register AuthViewModel as factory with proper dependencies
  sl.registerFactory(
    () => AuthViewModel(
      authRepository: sl(),
      signInWithEmailUseCase: sl(),
      createUserWithEmailUseCase: sl(),
      signInWithGoogleUseCase: sl(),
      signInWithAppleUseCase: sl(),
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

  // Repositories - using injected services
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      auth: sl<FirebaseAuth>(),
      googleSignIn: sl<GoogleSignIn>(),
    ),
  );

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

  sl.registerLazySingleton<RecurringExpensesRepository>(
    () => RecurringExpensesRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
      localDataSource: sl(),
      connectivityService: sl(),
    ),
  );

  // Synchronization service
  sl.registerLazySingleton(
    () => SyncService(
      localDataSource: sl(),
      expensesRepository: sl(),
      budgetRepository: sl(),
      connectivityService: sl(),
      auth: sl(),
    ),
  );

  // Use cases - Auth
  sl.registerLazySingleton(() => SignInWithEmailUseCase(
        authRepository: sl(),
        syncService: sl(),
        themeViewModel: sl(),
        settingsService: sl(),
      ));

  sl.registerLazySingleton(() => CreateUserWithEmailUseCase(
        authRepository: sl(),
        syncService: sl(),
        themeViewModel: sl(),
        settingsService: sl(),
      ));

  sl.registerLazySingleton(() => SignInWithGoogleUseCase(
        authRepository: sl(),
        syncService: sl(),
        themeViewModel: sl(),
        settingsService: sl(),
      ));

  sl.registerLazySingleton(() => SignInWithAppleUseCase(
        authRepository: sl(),
        syncService: sl(),
        themeViewModel: sl(),
        settingsService: sl(),
      ));

  sl.registerLazySingleton(() => SignInAsGuestUseCase(
        authRepository: sl(),
        syncService: sl(),
        themeViewModel: sl(),
        settingsService: sl(),
      ));

  sl.registerLazySingleton(() => UpgradeGuestAccountUseCase(
        authRepository: sl(),
        syncService: sl(),
      ));

  sl.registerLazySingleton(() => SecureSignOutAnonymousUserUseCase(
        authRepository: sl(),
      ));

  sl.registerLazySingleton(() => RefreshAuthStateUseCase(
        authRepository: sl(),
        themeViewModel: sl(),
      ));

  sl.registerLazySingleton(() => UpdateProfileUseCase(
        authRepository: sl(),
      ));

  sl.registerLazySingleton(() => UpdateUserSettingsUseCase(
        authRepository: sl(),
      ));

  sl.registerLazySingleton(() => InitializeUserDataUseCase(
        syncService: sl(),
        themeViewModel: sl(),
        settingsService: sl(),
      ));

  sl.registerLazySingleton(() => IsGuestUserUseCase());

  // Budget use cases
  sl.registerLazySingleton(() => LoadBudgetUseCase(
        budgetRepository: sl(),
        connectivityService: sl(),
        syncService: sl(),
        settingsService: sl(),
      ));

  sl.registerLazySingleton(() => SaveBudgetUseCase(
        budgetRepository: sl(),
      ));

  sl.registerLazySingleton(() => ConvertBudgetCurrencyUseCase(
        budgetRepository: sl(),
        currencyConversionService: sl(),
      ));

  sl.registerLazySingleton(() => CalculateBudgetRemainingUseCase(
        currencyConversionService: sl(),
        budgetCalculationService: sl(),
      ));

  sl.registerLazySingleton(() => RefreshBudgetUseCase(
        connectivityService: sl(),
        syncService: sl(),
        loadBudgetUseCase: sl(),
      ));

  // Use cases - Expense
  sl.registerLazySingleton(() => AddExpenseUseCase(
        expensesRepository: sl(),
        budgetRepository: sl(),
        budgetCalculationService: sl(),
      ));

  sl.registerLazySingleton(() => UpdateExpenseUseCase(
        expensesRepository: sl(),
        budgetRepository: sl(),
        budgetCalculationService: sl(),
      ));

  sl.registerLazySingleton(() => DeleteExpenseUseCase(
        expensesRepository: sl(),
        budgetRepository: sl(),
        budgetCalculationService: sl(),
      ));

  sl.registerLazySingleton(() => LoadExpensesUseCase(
        expensesRepository: sl(),
        connectivityService: sl(),
      ));

  sl.registerLazySingleton(() => FilterExpensesUseCase());

  sl.registerLazySingleton(() => CalculateExpenseTotalsUseCase(
        settingsService: sl(),
      ));

  sl.registerLazySingleton(() => ProcessRecurringExpensesUseCase(
        expensesRepository: sl(),
        recurringExpensesRepository: sl(),
      ));
}
