import 'package:flutter/foundation.dart';
import '../../repositories/budget_repository.dart';
import '../../../data/infrastructure/errors/app_error.dart';

/// Use case for deleting a budget for a specific month
class DeleteBudgetUseCase {
  final BudgetRepository _budgetRepository;

  DeleteBudgetUseCase({
    required BudgetRepository budgetRepository,
  }) : _budgetRepository = budgetRepository;

  /// Execute the delete budget use case
  Future<void> execute(String monthId) async {
    try {
      debugPrint(
          '🗑️ DeleteBudgetUseCase: Deleting budget for month: $monthId');

      // Check if the budget exists first
      final budget = await _budgetRepository.getBudget(monthId);
      if (budget == null) {
        debugPrint(
            '🗑️ DeleteBudgetUseCase: No budget found for month: $monthId');
        return; // Nothing to delete
      }

      // Delete the budget
      await _budgetRepository.deleteBudget(monthId);
      debugPrint('🗑️ DeleteBudgetUseCase: Budget deleted successfully');
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      debugPrint(
          '🗑️ DeleteBudgetUseCase: Error deleting budget: ${error.message}');
      error.log();
      rethrow;
    }
  }
}
