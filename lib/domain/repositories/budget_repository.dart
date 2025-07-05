import '../entities/budget.dart';

/// Repository interface for budget operations
abstract class BudgetRepository {
  /// Gets the budget for a specific month
  Future<Budget?> getBudget(String monthId);

  /// Sets the budget for a specific month
  Future<void> setBudget(String monthId, Budget budget);

  /// Deletes the budget for a specific month
  Future<void> deleteBudget(String monthId);
}
