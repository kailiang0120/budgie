import '../../domain/entities/budget.dart';
import '../../domain/entities/expense.dart';

/// Abstract interface for local data source operations
abstract class LocalDataSource {
  // App Settings operations
  Future<Map<String, dynamic>> getAppSettings();
  Future<void> saveAppSettings(Map<String, dynamic> settings);
  Future<String> getAppTheme();
  Future<void> updateAppTheme(String theme);
  Future<String> getAppCurrency();
  Future<void> updateAppCurrency(String currency);
  Future<bool> getNotificationsEnabled();
  Future<void> updateNotificationsEnabled(bool enabled);
  Future<bool> getAutoBudgetEnabled();
  Future<void> updateAutoBudgetEnabled(bool enabled);
  Future<bool> getImproveAccuracyEnabled();
  Future<void> updateImproveAccuracyEnabled(bool enabled);
  Future<bool> getSyncEnabled();
  Future<void> updateSyncEnabled(bool enabled);

  // Expenses operations
  Future<List<Expense>> getExpenses();
  Future<void> saveExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);

  // Budget operations
  Future<Budget?> getBudget(String monthId);
  Future<void> saveBudget(String monthId, Budget budget);
  Future<void> deleteBudget(String monthId);

  // Exchange rates operations
  Future<Map<String, double>?> getExchangeRates(String baseCurrency);
  Future<void> saveExchangeRates(
      String baseCurrency, Map<String, double> rates, DateTime timestamp);
  Future<DateTime?> getExchangeRatesTimestamp(String baseCurrency);
}
