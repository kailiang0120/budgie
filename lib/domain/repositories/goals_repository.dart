import '../entities/financial_goal.dart';

/// Repository interface for financial goals operations
abstract class GoalsRepository {
  /// Get all active financial goals (max 3)
  Future<List<FinancialGoal>> getActiveGoals();

  /// Get a specific goal by ID
  Future<FinancialGoal?> getGoalById(String id);

  /// Save a new financial goal
  /// Returns true if successful, false if the limit of 3 active goals is reached
  Future<bool> saveGoal(FinancialGoal goal);

  /// Update an existing financial goal
  Future<void> updateGoal(FinancialGoal goal);

  /// Delete a financial goal
  Future<void> deleteGoal(String id);

  /// Mark a goal as completed and move to history
  Future<void> completeGoal(String id, {String? notes});

  /// Get completed goals history
  Future<List<GoalHistory>> getGoalHistory();

  /// Count active goals
  Future<int> countActiveGoals();

  /// Check if more goals can be added (limit is 3)
  Future<bool> canAddMoreGoals();
}
