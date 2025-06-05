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
import '../core/network/connectivity_service.dart';
import '../core/services/sync_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/settings_service.dart';
import '../core/services/currency_conversion_service.dart';
import '../core/services/recurring_expense_service.dart';

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

  // Notification service
  sl.registerLazySingleton(() => NotificationService());

  // Settings service
  sl.registerLazySingleton(() => SettingsService(
        localDataSource: sl(),
        connectivityService: sl(),
      ));

  // Currency conversion service
  sl.registerLazySingleton(() {
    final service = CurrencyConversionService();
    service.setConnectivityService(sl<ConnectivityService>());
    return service;
  });

  // ViewModels - Register ThemeViewModel as singleton first
  sl.registerLazySingleton(() => ThemeViewModel());

  // Register AuthViewModel as factory with proper dependencies
  sl.registerFactory(
    () => AuthViewModel(
      authRepository: sl(),
      syncService: sl(),
      themeViewModel: sl(),
      settingsService: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => ExpensesViewModel(
      expensesRepository: sl(),
      budgetRepository: sl(),
      connectivityService: sl(),
      settingsService: sl(),
    ),
  );

  sl.registerFactory(
    () => BudgetViewModel(
      budgetRepository: sl(),
      currencyConversionService: sl(),
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

  // Recurring expense service
  sl.registerLazySingleton(
    () => RecurringExpenseService(
      expensesRepository: sl(),
      recurringExpensesRepository: sl(),
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

  // Use cases
  // TODO: Add use cases here

  // Data sources
  // TODO: Add data sources here
}
