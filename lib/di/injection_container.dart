import 'package:get_it/get_it.dart';

// Repositories
import '../data/repositories/expenses_repository_impl.dart';
import '../data/repositories/budget_repository_impl.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../data/repositories/goals_repository_impl.dart';
import '../domain/repositories/expenses_repository.dart';
import '../domain/repositories/budget_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/goals_repository.dart';

// ViewModels
import '../presentation/viewmodels/expenses_viewmodel.dart';
import '../presentation/viewmodels/budget_viewmodel.dart';
import '../presentation/viewmodels/theme_viewmodel.dart';
import '../presentation/viewmodels/goals_viewmodel.dart';

// Data sources and database
import '../data/local/database/app_database.dart';
import '../data/datasources/local_data_source.dart';
import '../data/datasources/local_data_source_impl.dart';

// Services
import '../data/infrastructure/services/currency_conversion_service.dart';
import '../data/infrastructure/services/settings_service.dart';
import '../data/infrastructure/services/background_task_service.dart';
import '../data/infrastructure/network/connectivity_service.dart';
import '../data/infrastructure/services/notification_service.dart';
import '../data/infrastructure/services/notification_listener_service.dart';
import '../data/infrastructure/services/permission_handler_service.dart';
import '../data/infrastructure/services/data_collection_service.dart';
import '../data/infrastructure/services/expense_extraction_service_impl.dart';
import '../domain/services/expense_extraction_service.dart';
import '../domain/services/budget_calculation_service.dart';
import '../domain/services/goal_funding_service.dart';

import '../domain/services/budget_reallocation_service.dart';
import '../data/infrastructure/services/gemini_api_client.dart';

// Use cases
import '../domain/usecase/budget/load_budget_usecase.dart';
import '../domain/usecase/budget/save_budget_usecase.dart';
import '../domain/usecase/budget/convert_budget_currency_usecase.dart';
import '../domain/usecase/budget/calculate_budget_remaining_usecase.dart';
import '../domain/usecase/budget/refresh_budget_usecase.dart';
import '../domain/usecase/budget/delete_budget_usecase.dart';

import '../domain/usecase/expense/add_expense_usecase.dart';
import '../domain/usecase/expense/update_expense_usecase.dart';
import '../domain/usecase/expense/delete_expense_usecase.dart';
import '../domain/usecase/expense/load_expenses_usecase.dart';
import '../domain/usecase/expense/filter_expenses_usecase.dart';
import '../domain/usecase/expense/calculate_expense_totals_usecase.dart';
import '../domain/usecase/expense/process_recurring_expenses_usecase.dart';
import '../domain/services/spending_behavior_analysis_service.dart';
import '../domain/usecase/notification/record_notification_detection_usecase.dart';

// Goals use cases
import '../domain/usecase/goals/get_goals_usecase.dart';
import '../domain/usecase/goals/manage_goals_usecase.dart';
import '../domain/usecase/goals/allocate_savings_to_goals_usecase.dart';

/// Service locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> init() async {
  // Database
  sl.registerLazySingleton(() => AppDatabase());

  // Data sources
  sl.registerLazySingleton<LocalDataSource>(
    () => LocalDataSourceImpl(sl<AppDatabase>()),
  );

  // Basic services that don't depend on repositories
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityServiceImpl(),
  );

  // Register core services with proper initialization order

  // 1. Register PermissionHandlerService first (core service)
  sl.registerSingleton<PermissionHandlerService>(PermissionHandlerService());

  // 2. Register SettingsService with PermissionHandlerService dependency
  final settingsService = SettingsService();
  sl.registerSingleton<SettingsService>(settingsService);

  // Initialize SettingsService with PermissionHandlerService
  await settingsService.initialize(
    permissionHandler: sl<PermissionHandlerService>(),
  );

  // 3. Register core notification services
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => NotificationListenerService());

  // Register the TFLite expense extraction services
  sl.registerLazySingleton<ExpenseExtractionService>(() {
    return ExpenseExtractionServiceImpl();
  });

  sl.registerLazySingleton(() {
    final service = ExpenseExtractionDomainService();
    service.setExtractionService(sl<ExpenseExtractionService>());
    service.setNotificationService(sl<NotificationService>());
    service.setRecordUseCase(sl<RecordNotificationDetectionUseCase>());
    return service;
  });

  sl.registerLazySingleton(() => DataCollectionService());

  // Other services
  sl.registerLazySingleton(() {
    final service = CurrencyConversionService();
    service.setConnectivityService(sl<ConnectivityService>());
    return service;
  });

  // Register BackgroundTaskService (doesn't depend on repositories)
  sl.registerLazySingleton(() => BackgroundTaskService());

  // Register BudgetCalculationService
  sl.registerLazySingleton(() => BudgetCalculationService(
        currencyService: sl<CurrencyConversionService>(),
      ));

  // Register GoalFundingService
  sl.registerLazySingleton(() => GoalFundingService());

  // Repositories
  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(
      localDataSource: sl<LocalDataSource>(),
    ),
  );

  sl.registerLazySingleton<ExpensesRepository>(
    () => ExpensesRepositoryImpl(localDataSource: sl<LocalDataSource>()),
  );

  sl.registerLazySingleton<AppSettingsRepository>(
    () => AppSettingsRepositoryImpl(localDataSource: sl<LocalDataSource>()),
  );

  sl.registerLazySingleton<GoalsRepository>(
    () => GoalsRepositoryImpl(
      localDataSource: sl<LocalDataSource>(),
      database: sl<AppDatabase>(),
    ),
  );

  // Register GeminiApiClient
  sl.registerLazySingleton(() {
    final client = GeminiApiClient();
    client.setConnectivityService(sl<ConnectivityService>());
    return client;
  });

  // Register SpendingBehaviorAnalysisService
  sl.registerLazySingleton(() {
    final service = SpendingBehaviorAnalysisService();
    service.setGeminiApiClient(sl<GeminiApiClient>());
    service.setConnectivityService(sl<ConnectivityService>());
    return service;
  });

  // Register BudgetReallocationService
  sl.registerLazySingleton(() => BudgetReallocationService(
        budgetRepository: sl<BudgetRepository>(),
        expensesRepository: sl<ExpensesRepository>(),
        geminiApiClient: sl<GeminiApiClient>(),
        settingsService: sl<SettingsService>(),
        spendingBehaviorService: sl<SpendingBehaviorAnalysisService>(),
      ));

  // Budget use cases
  sl.registerLazySingleton(() => LoadBudgetUseCase(
        budgetRepository: sl<BudgetRepository>(),
        settingsService: sl<SettingsService>(),
      ));

  sl.registerLazySingleton(() => SaveBudgetUseCase(
        budgetRepository: sl<BudgetRepository>(),
      ));

  sl.registerLazySingleton(() => ConvertBudgetCurrencyUseCase(
        budgetRepository: sl<BudgetRepository>(),
        currencyConversionService: sl<CurrencyConversionService>(),
      ));

  sl.registerLazySingleton(() => CalculateBudgetRemainingUseCase(
        currencyConversionService: sl<CurrencyConversionService>(),
        budgetCalculationService: sl<BudgetCalculationService>(),
      ));

  sl.registerLazySingleton(() => RefreshBudgetUseCase(
        budgetRepository: sl<BudgetRepository>(),
        expensesRepository: sl<ExpensesRepository>(),
        budgetCalculationService: sl<BudgetCalculationService>(),
        settingsService: sl<SettingsService>(),
        loadBudgetUseCase: sl<LoadBudgetUseCase>(),
      ));

  sl.registerLazySingleton(() => DeleteBudgetUseCase(
        budgetRepository: sl<BudgetRepository>(),
      ));

  // Expense use cases
  sl.registerLazySingleton(() => AddExpenseUseCase(
        expensesRepository: sl<ExpensesRepository>(),
        refreshBudgetUseCase: sl<RefreshBudgetUseCase>(),
        connectivityService: sl<ConnectivityService>(),
        settingsService: sl<SettingsService>(),
      ));

  sl.registerLazySingleton(() => UpdateExpenseUseCase(
        expensesRepository: sl<ExpensesRepository>(),
        refreshBudgetUseCase: sl<RefreshBudgetUseCase>(),
        connectivityService: sl<ConnectivityService>(),
        settingsService: sl<SettingsService>(),
      ));

  sl.registerLazySingleton(() => DeleteExpenseUseCase(
        expensesRepository: sl<ExpensesRepository>(),
        refreshBudgetUseCase: sl<RefreshBudgetUseCase>(),
        connectivityService: sl<ConnectivityService>(),
        settingsService: sl<SettingsService>(),
      ));

  sl.registerLazySingleton(() => LoadExpensesUseCase(
        expensesRepository: sl<ExpensesRepository>(),
      ));

  sl.registerLazySingleton(() => FilterExpensesUseCase());

  sl.registerLazySingleton(() => CalculateExpenseTotalsUseCase(
        settingsService: sl<SettingsService>(),
      ));

  sl.registerLazySingleton(() => ProcessRecurringExpensesUseCase(
        expensesRepository: sl<ExpensesRepository>(),
      ));

  // Notification use cases
  sl.registerLazySingleton(() => RecordNotificationDetectionUseCase(
        settingsService: sl<SettingsService>(),
      ));

  // Goals use cases
  sl.registerLazySingleton(() => GetGoalsUseCase(
        goalsRepository: sl<GoalsRepository>(),
      ));

  sl.registerLazySingleton(() => GetGoalHistoryUseCase(
        goalsRepository: sl<GoalsRepository>(),
      ));

  sl.registerLazySingleton(() => GetGoalByIdUseCase(
        goalsRepository: sl<GoalsRepository>(),
      ));

  sl.registerLazySingleton(() => SaveGoalUseCase(
        goalsRepository: sl<GoalsRepository>(),
      ));

  sl.registerLazySingleton(() => UpdateGoalUseCase(
        goalsRepository: sl<GoalsRepository>(),
      ));

  sl.registerLazySingleton(() => DeleteGoalUseCase(
        goalsRepository: sl<GoalsRepository>(),
      ));

  sl.registerLazySingleton(() => CompleteGoalUseCase(
        goalsRepository: sl<GoalsRepository>(),
      ));

  sl.registerLazySingleton(() => CanAddGoalUseCase(
        goalsRepository: sl<GoalsRepository>(),
      ));

  // Register AllocateSavingsToGoalsUseCase
  sl.registerLazySingleton(() => AllocateSavingsToGoalsUseCase(
        goalsRepository: sl<GoalsRepository>(),
        budgetRepository: sl<BudgetRepository>(),
        expensesRepository: sl<ExpensesRepository>(),
        fundingService: sl<GoalFundingService>(),
      ));

  // ViewModels
  sl.registerLazySingleton(() => BudgetViewModel(
        budgetRepository: sl<BudgetRepository>(),
        loadBudgetUseCase: sl<LoadBudgetUseCase>(),
        saveBudgetUseCase: sl<SaveBudgetUseCase>(),
        convertBudgetCurrencyUseCase: sl<ConvertBudgetCurrencyUseCase>(),
        calculateBudgetRemainingUseCase: sl<CalculateBudgetRemainingUseCase>(),
        refreshBudgetUseCase: sl<RefreshBudgetUseCase>(),
        deleteBudgetUseCase: sl<DeleteBudgetUseCase>(),
      ));

  sl.registerLazySingleton(() => ExpensesViewModel(
        expensesRepository: sl<ExpensesRepository>(),
        connectivityService: sl<ConnectivityService>(),
        settingsService: sl<SettingsService>(),
        addExpenseUseCase: sl<AddExpenseUseCase>(),
        updateExpenseUseCase: sl<UpdateExpenseUseCase>(),
        deleteExpenseUseCase: sl<DeleteExpenseUseCase>(),
        loadExpensesUseCase: sl<LoadExpensesUseCase>(),
        filterExpensesUseCase: sl<FilterExpensesUseCase>(),
        calculateExpenseTotalsUseCase: sl<CalculateExpenseTotalsUseCase>(),
      ));

  sl.registerLazySingleton(() => ThemeViewModel(
        settingsService: sl<SettingsService>(),
      ));

  sl.registerLazySingleton(() => GoalsViewModel(
        getGoalsUseCase: sl<GetGoalsUseCase>(),
        getGoalHistoryUseCase: sl<GetGoalHistoryUseCase>(),
        getGoalByIdUseCase: sl<GetGoalByIdUseCase>(),
        saveGoalUseCase: sl<SaveGoalUseCase>(),
        updateGoalUseCase: sl<UpdateGoalUseCase>(),
        deleteGoalUseCase: sl<DeleteGoalUseCase>(),
        completeGoalUseCase: sl<CompleteGoalUseCase>(),
        canAddGoalUseCase: sl<CanAddGoalUseCase>(),
        allocateSavingsUseCase: sl<AllocateSavingsToGoalsUseCase>(),
      ));
}
