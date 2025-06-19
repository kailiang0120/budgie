import '../../entities/expense.dart';
import '../../repositories/expenses_repository.dart';
import '../budget/refresh_budget_usecase.dart';
import '../../../data/infrastructure/errors/app_error.dart';

/// Use case for deleting an expense
class DeleteExpenseUseCase {
  final ExpensesRepository _expensesRepository;
  final RefreshBudgetUseCase _refreshBudgetUseCase;

  DeleteExpenseUseCase({
    required ExpensesRepository expensesRepository,
    required RefreshBudgetUseCase refreshBudgetUseCase,
  })  : _expensesRepository = expensesRepository,
        _refreshBudgetUseCase = refreshBudgetUseCase;

  /// Execute the delete expense use case
  Future<void> execute(String expenseId, Expense expenseToDelete) async {
    try {
      // Delete expense from local database
      await _expensesRepository.deleteExpense(expenseId);

      // Update budget after expense deletion
      await _updateBudgetAfterExpenseChange(expenseToDelete);
    } catch (e, stackTrace) {
      final appError = AppError.from(e, stackTrace);
      appError.log();
      rethrow;
    }
  }

  /// Update budget after expense change
  Future<void> _updateBudgetAfterExpenseChange(Expense expense) async {
    try {
      // Get the month ID for this expense
      final monthId = _getMonthIdFromDate(expense.date);

      // Use the refresh budget use case to update the budget
      await _refreshBudgetUseCase.execute(monthId);
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
    }
  }

  /// Get month ID from date
  String _getMonthIdFromDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }
}
