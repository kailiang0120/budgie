import '../entities/recurring_expense.dart';

/// Repository interface for recurring expense operations
abstract class RecurringExpensesRepository {
  /// Gets all recurring expenses for the current user
  Future<List<RecurringExpense>> getRecurringExpenses();

  /// Adds a new recurring expense
  Future<RecurringExpense> addRecurringExpense(
      RecurringExpense recurringExpense);

  /// Updates an existing recurring expense
  Future<void> updateRecurringExpense(RecurringExpense recurringExpense);

  /// Deletes a recurring expense by ID
  Future<void> deleteRecurringExpense(String id);

  /// Gets active recurring expenses that need to be processed
  Future<List<RecurringExpense>> getActiveRecurringExpenses();

  /// Updates the last processed date for a recurring expense
  Future<void> updateLastProcessedDate(String id, DateTime lastProcessedDate);
}
