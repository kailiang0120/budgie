import '../../domain/entities/budget.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/user.dart';

/// Abstract interface for local data source operations
abstract class LocalDataSource {
  // User operations
  Future<User?> getUser(String userId);
  Future<void> saveUser(User user);
  Future<List<User>> getUsers();

  // User Settings operations
  Future<Map<String, dynamic>?> getUserSettings(String userId);
  Future<void> saveUserSettings(String userId, Map<String, dynamic> settings);
  Future<void> markUserSettingsAsSynced(String userId);

  // Expenses operations (now includes embedded recurring details)
  Future<List<Expense>> getExpenses();
  Future<void> saveExpense(Expense expense);
  Future<void> saveSyncedExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);
  Future<List<Expense>> getUnsyncedExpenses();
  Future<void> markExpenseAsSynced(String id);

  // Budget operations
  Future<Budget?> getBudget(String monthId, String userId);
  Future<void> saveBudget(String monthId, Budget budget, String userId,
      {bool isSynced = false});
  Future<List<String>> getUnsyncedBudgetIds(String userId);
  Future<void> markBudgetAsSynced(String monthId, String userId);
  Future<void> clearAllBudgetSyncOperations(String userId);

  // Budget reallocation settings are handled via user settings

  // Exchange rates operations
  Future<Map<String, double>?> getExchangeRates(
      String baseCurrency, String userId);
  Future<void> saveExchangeRates(String baseCurrency, String userId,
      Map<String, double> rates, DateTime timestamp);
  Future<DateTime?> getExchangeRatesTimestamp(
      String baseCurrency, String userId);

  // Sync queue operations
  Future<List<Map<String, dynamic>>> getSyncQueue();
  Future<void> addToSyncQueue(
      String entityType, String entityId, String userId, String operation);
  Future<void> removeSyncOperation(int id);
  Future<void> clearAllSyncOperations();
}
