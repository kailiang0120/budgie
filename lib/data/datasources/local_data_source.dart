import '../../domain/entities/budget.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/recurring_expense.dart';
import '../../domain/entities/user.dart';

/// Abstract interface for local data source operations
abstract class LocalDataSource {
  // User operations
  Future<User?> getUser(String userId);
  Future<void> saveUser(User user);

  // User Settings operations
  Future<Map<String, dynamic>?> getUserSettings(String userId);
  Future<void> saveUserSettings(String userId, Map<String, dynamic> settings);
  Future<void> markUserSettingsAsSynced(String userId);

  // Expenses operations
  Future<List<Expense>> getExpenses();
  Future<void> saveExpense(Expense expense);
  Future<void> saveSyncedExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);
  Future<List<Expense>> getUnsyncedExpenses();
  Future<void> markExpenseAsSynced(String id);

  // Recurring expenses operations
  Future<List<RecurringExpense>> getRecurringExpenses();
  Future<void> saveRecurringExpense(RecurringExpense recurringExpense);
  Future<void> saveSyncedRecurringExpense(RecurringExpense recurringExpense);
  Future<void> updateRecurringExpense(RecurringExpense recurringExpense);
  Future<void> deleteRecurringExpense(String id);
  Future<List<RecurringExpense>> getActiveRecurringExpenses();
  Future<void> markRecurringExpenseAsSynced(String id);
  Future<void> updateRecurringExpenseLastProcessed(
      String id, DateTime lastProcessedDate);

  // Budget operations
  Future<Budget?> getBudget(String monthId, String userId);
  Future<void> saveBudget(String monthId, Budget budget, String userId,
      {bool isSynced = false});
  Future<List<String>> getUnsyncedBudgetIds(String userId);
  Future<void> markBudgetAsSynced(String monthId, String userId);
  Future<void> clearAllBudgetSyncOperations(String userId);

  // Synchronization operations
  Future<void> addToSyncQueue(
      String entityType, String entityId, String userId, String operation);
  Future<List<Map<String, dynamic>>> getPendingSyncOperations();
  Future<void> clearSyncOperation(int syncId);

  // Exchange rates operations
  Future<Map<String, dynamic>?> getExchangeRates(
      String baseCurrency, String userId);
  Future<void> saveExchangeRates(String baseCurrency, Map<String, double> rates,
      String userId, DateTime timestamp);
}
