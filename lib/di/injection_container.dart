import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

// Repositories
import '../data/repositories/analysis_repository_impl.dart';
import '../data/repositories/budget_repository_impl.dart';
import '../data/repositories/expenses_repository_impl.dart';
import '../data/repositories/goals_repository_impl.dart';
import '../data/repositories/user_behavior_repository_impl.dart';
import '../domain/repositories/analysis_repository.dart';
import '../domain/repositories/budget_repository.dart';
import '../domain/repositories/expenses_repository.dart';
import '../domain/repositories/goals_repository.dart';
import '../domain/repositories/user_behavior_repository.dart';

// ViewModels
import '../presentation/viewmodels/budget_viewmodel.dart';
import '../presentation/viewmodels/expenses_viewmodel.dart';
import '../presentation/viewmodels/goals_viewmodel.dart';
import '../presentation/viewmodels/theme_viewmodel.dart';
import '../presentation/viewmodels/analysis_viewmodel.dart';

// DataSources
import '../data/datasources/local_data_source.dart';
import '../data/datasources/local_data_source_impl.dart';
import '../data/datasources/user_behavior_local_data_source.dart';
import '../data/datasources/analysis_local_data_source.dart';

// Services
import '../data/infrastructure/services/background_task_service.dart';
import '../data/infrastructure/services/currency_conversion_service.dart';

import '../data/infrastructure/services/expense_extraction_service_impl.dart';
import '../data/infrastructure/services/gemini_api_client.dart';
import '../data/infrastructure/services/notification_listener_service.dart';
import '../data/infrastructure/services/notification_service.dart';
import '../data/infrastructure/services/permission_handler_service.dart';
import '../data/infrastructure/services/settings_service.dart';
import '../data/infrastructure/services/sync_service.dart';
import '../domain/services/budget_calculation_service.dart';
import '../domain/services/budget_reallocation_service.dart';
import '../domain/services/goal_funding_service.dart';
import '../domain/services/spending_behavior_analysis_service.dart';
import '../data/infrastructure/network/connectivity_service.dart';
import '../domain/services/expense_extraction_service.dart';

// Database
import '../data/local/database/app_database.dart';

// UseCases
import '../domain/usecase/budget/calculate_budget_remaining_usecase.dart';
import '../domain/usecase/budget/convert_budget_currency_usecase.dart';
import '../domain/usecase/budget/delete_budget_usecase.dart';
import '../domain/usecase/budget/load_budget_usecase.dart';
import '../domain/usecase/budget/refresh_budget_usecase.dart';
import '../domain/usecase/budget/save_budget_usecase.dart';
import '../domain/usecase/budget/reallocate_budget_usecase.dart';
import '../domain/usecase/expense/add_expense_usecase.dart';
import '../domain/usecase/expense/calculate_expense_totals_usecase.dart';
import '../domain/usecase/expense/delete_expense_usecase.dart';
import '../domain/usecase/expense/filter_expenses_usecase.dart';
import '../domain/usecase/expense/load_expenses_usecase.dart';
import '../domain/usecase/expense/process_recurring_expenses_usecase.dart';
import '../domain/usecase/expense/update_expense_usecase.dart';
import '../domain/usecase/goals/get_goals_usecase.dart';
import '../domain/usecase/goals/manage_goals_usecase.dart';
import '../domain/usecase/goals/allocate_savings_to_goals_usecase.dart';

import 'performance_tracker.dart';

/// Service locator instance
final sl = GetIt.instance;

Future<void> init() async {
  // Performance Tracker
  sl.registerLazySingleton(() => PerformanceTracker());

  // App Database
  sl.registerLazySingleton(() => AppDatabase());

  // Register DAOs
  sl.registerLazySingleton(() => sl<AppDatabase>().exchangeRatesDao);
  sl.registerLazySingleton(() => sl<AppDatabase>().userProfilesDao);
  sl.registerLazySingleton(() => sl<AppDatabase>().analysisResultDao);
  sl.registerLazySingleton(() => sl<AppDatabase>().budgetsDao);
  sl.registerLazySingleton(() => sl<AppDatabase>().expensesDao);
  sl.registerLazySingleton(() => sl<AppDatabase>().financialGoalsDao);
  sl.registerLazySingleton(() => sl<AppDatabase>().goalHistoryDao);

  // External
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => const Uuid());

  // =================================================================
  // DataSources
  // =================================================================
  sl.registerLazySingleton<LocalDataSource>(
      () => LocalDataSourceImpl(sl(), sl()));
  sl.registerLazySingleton<UserBehaviorLocalDataSource>(
      () => UserBehaviorLocalDataSourceImpl(sl<AppDatabase>()));
  sl.registerLazySingleton<AnalysisLocalDataSource>(
      () => AnalysisLocalDataSourceImpl(sl<AnalysisResultDao>(), sl<Uuid>()));

  // =================================================================
  // Repositories
  // =================================================================
  sl.registerLazySingleton<AnalysisRepository>(
      () => AnalysisRepositoryImpl(sl<AnalysisLocalDataSource>()));
  sl.registerLazySingleton<ExpensesRepository>(
      () => ExpensesRepositoryImpl(localDataSource: sl<LocalDataSource>()));
  sl.registerLazySingleton<BudgetRepository>(
      () => BudgetRepositoryImpl(localDataSource: sl<LocalDataSource>()));
  sl.registerLazySingleton<GoalsRepository>(() => GoalsRepositoryImpl(
      localDataSource: sl<LocalDataSource>(), database: sl<AppDatabase>()));
  sl.registerLazySingleton<UserBehaviorRepository>(
      () => UserBehaviorRepositoryImpl(sl<UserBehaviorLocalDataSource>()));

  // =================================================================
  // Services
  // =================================================================
  sl.registerLazySingleton<ConnectivityService>(
      () => ConnectivityServiceImpl());
  sl.registerLazySingleton(() => GeminiApiClient());
  sl.registerLazySingleton(() => SettingsService());
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => PermissionHandlerService());
  sl.registerLazySingleton(() => NotificationListenerService());

  sl.registerLazySingleton(() => BackgroundTaskService());
  sl.registerLazySingleton(() => SyncService(
      expensesRepository: sl(),
      budgetRepository: sl(),
      connectivityService: sl(),
      settingsService: sl()));

  sl.registerLazySingleton(() {
    final service = CurrencyConversionService();
    service.setConnectivityService(sl<ConnectivityService>());
    return service;
  });

  sl.registerLazySingleton<ExpenseExtractionService>(
      () => ExpenseExtractionServiceImpl());

  // Register ExpenseExtractionDomainService
  sl.registerLazySingleton(() {
    final domainService = ExpenseExtractionDomainService();
    // Set up dependencies
    domainService.setExtractionService(sl<ExpenseExtractionService>());
    domainService.setNotificationService(sl<NotificationService>());
    return domainService;
  });

  sl.registerLazySingleton(() => BudgetCalculationService(
        currencyService: sl<CurrencyConversionService>(),
      ));
  sl.registerLazySingleton(() => BudgetReallocationService(
        budgetRepository: sl<BudgetRepository>(),
        expensesRepository: sl<ExpensesRepository>(),
        userBehaviorRepository: sl<UserBehaviorRepository>(),
        goalsRepository: sl<GoalsRepository>(),
        analysisRepository: sl<AnalysisRepository>(),
        geminiApiClient: sl<GeminiApiClient>(),
        settingsService: sl<SettingsService>(),
      ));
  sl.registerLazySingleton(() {
    final service = SpendingBehaviorAnalysisService();
    service.setGeminiApiClient(sl<GeminiApiClient>());
    service.setConnectivityService(sl<ConnectivityService>());
    return service;
  });
  sl.registerLazySingleton(() => GoalFundingService());

  // =================================================================
  // UseCases
  // =================================================================

  // Budget use cases
  sl.registerLazySingleton(() => CalculateBudgetRemainingUseCase(
      currencyConversionService: sl(), budgetCalculationService: sl()));
  sl.registerLazySingleton(() => ConvertBudgetCurrencyUseCase(
      budgetRepository: sl(), currencyConversionService: sl()));
  sl.registerLazySingleton(() => DeleteBudgetUseCase(budgetRepository: sl()));
  sl.registerLazySingleton(
      () => LoadBudgetUseCase(budgetRepository: sl(), settingsService: sl()));
  sl.registerLazySingleton(() => RefreshBudgetUseCase(
      budgetRepository: sl(),
      expensesRepository: sl(),
      budgetCalculationService: sl(),
      settingsService: sl(),
      loadBudgetUseCase: sl()));
  sl.registerLazySingleton(() => SaveBudgetUseCase(budgetRepository: sl()));
  sl.registerLazySingleton(() => ReallocateBudgetUseCase(
      budgetRepository: sl(),
      expensesRepository: sl(),
      budgetCalculationService: sl()));

  // Expenses use cases
  sl.registerLazySingleton(() => AddExpenseUseCase(
      expensesRepository: sl(),
      refreshBudgetUseCase: sl(),
      connectivityService: sl(),
      settingsService: sl()));
  sl.registerLazySingleton(
      () => CalculateExpenseTotalsUseCase(settingsService: sl()));
  sl.registerLazySingleton(() => DeleteExpenseUseCase(
      expensesRepository: sl(),
      refreshBudgetUseCase: sl(),
      connectivityService: sl(),
      settingsService: sl()));
  sl.registerLazySingleton(() => FilterExpensesUseCase());
  sl.registerLazySingleton(() => LoadExpensesUseCase(expensesRepository: sl()));
  sl.registerLazySingleton(
      () => ProcessRecurringExpensesUseCase(expensesRepository: sl()));
  sl.registerLazySingleton(() => UpdateExpenseUseCase(
      expensesRepository: sl(),
      refreshBudgetUseCase: sl(),
      connectivityService: sl(),
      settingsService: sl()));

  // Goals use cases
  sl.registerLazySingleton(() => GetGoalsUseCase(goalsRepository: sl()));
  sl.registerLazySingleton(() => GetGoalHistoryUseCase(goalsRepository: sl()));
  sl.registerLazySingleton(() => GetGoalByIdUseCase(goalsRepository: sl()));
  sl.registerLazySingleton(() => SaveGoalUseCase(goalsRepository: sl()));
  sl.registerLazySingleton(() => UpdateGoalUseCase(goalsRepository: sl()));
  sl.registerLazySingleton(() => DeleteGoalUseCase(goalsRepository: sl()));
  sl.registerLazySingleton(() => CompleteGoalUseCase(goalsRepository: sl()));
  sl.registerLazySingleton(() => CanAddGoalUseCase(goalsRepository: sl()));
  sl.registerLazySingleton(() => AllocateSavingsToGoalsUseCase(
      goalsRepository: sl(),
      budgetRepository: sl(),
      expensesRepository: sl(),
      fundingService: sl()));

  // =================================================================
  // ViewModels
  // =================================================================
  sl.registerLazySingleton(() => BudgetViewModel(
        budgetRepository: sl(),
        loadBudgetUseCase: sl(),
        saveBudgetUseCase: sl(),
        deleteBudgetUseCase: sl(),
        calculateBudgetRemainingUseCase: sl(),
        convertBudgetCurrencyUseCase: sl(),
        refreshBudgetUseCase: sl(),
      ));
  sl.registerLazySingleton(() => ExpensesViewModel(
        expensesRepository: sl(),
        connectivityService: sl(),
        settingsService: sl(),
        loadExpensesUseCase: sl(),
        addExpenseUseCase: sl(),
        updateExpenseUseCase: sl(),
        deleteExpenseUseCase: sl(),
        calculateExpenseTotalsUseCase: sl(),
        filterExpensesUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GoalsViewModel(
        getGoalsUseCase: sl(),
        getGoalHistoryUseCase: sl(),
        getGoalByIdUseCase: sl(),
        saveGoalUseCase: sl(),
        updateGoalUseCase: sl(),
        deleteGoalUseCase: sl(),
        completeGoalUseCase: sl(),
        canAddGoalUseCase: sl(),
        allocateSavingsUseCase: sl(),
      ));
  sl.registerLazySingleton(() => ThemeViewModel(settingsService: sl()));
  sl.registerLazySingleton(() => AnalysisViewModel(
        spendingBehaviorService: sl<SpendingBehaviorAnalysisService>(),
        budgetReallocationService: sl<BudgetReallocationService>(),
        expensesRepository: sl<ExpensesRepository>(),
        budgetRepository: sl<BudgetRepository>(),
        userBehaviorRepository: sl<UserBehaviorRepository>(),
        goalsRepository: sl<GoalsRepository>(),
        analysisRepository: sl<AnalysisRepository>(),
        settingsService: sl<SettingsService>(),
        apiClient: sl<GeminiApiClient>(),
        reallocateBudgetUseCase: sl<ReallocateBudgetUseCase>(),
      ));
}
