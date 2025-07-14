import '../entities/budget.dart';

/// Repository interface for budget operations
abstract class BudgetRepository {
  /// Gets the budget for a specific month
  Future<Budget?> getBudget(String monthId);

  /// Sets the budget for a specific month
  Future<void> setBudget(String monthId, Budget budget);

  /// Deletes the budget for a specific month
  Future<void> deleteBudget(String monthId);

  /// Gets budgets for multiple months with savings data
  Future<List<BudgetWithMonth>> getBudgetsWithSavings(List<String> monthIds);

  /// Gets all budgets that have savings (left > 0)
  Future<List<BudgetWithMonth>> getBudgetsWithAvailableSavings();

  /// Gets budgets from previous months only that have savings available for goal funding
  Future<List<BudgetWithMonth>> getPreviousMonthBudgetsWithSavings();
}

/// Budget with month ID for multi-month operations
class BudgetWithMonth {
  final String monthId;
  final Budget budget;

  BudgetWithMonth({
    required this.monthId,
    required this.budget,
  });
}
