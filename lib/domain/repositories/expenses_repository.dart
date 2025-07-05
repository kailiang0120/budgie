import '../entities/expense.dart';

/// Repository interface for expense operations
abstract class ExpensesRepository {
  /// Gets all expenses
  Future<List<Expense>> getExpenses();

  /// Adds a new expense
  Future<void> addExpense(Expense expense);

  /// Updates an existing expense
  Future<void> updateExpense(Expense expense);

  /// Deletes an expense by ID
  Future<void> deleteExpense(String id);
}
