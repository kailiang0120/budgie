import '../../domain/entities/budget.dart';
import '../../domain/entities/expense.dart';

/// Abstract interface for local data source operations
abstract class LocalDataSource {
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
