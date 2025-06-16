import '../../entities/expense.dart';
import '../../repositories/expenses_repository.dart';
import '../../repositories/budget_repository.dart';
import '../../services/budget_calculation_service.dart';
import '../../../data/infrastructure/errors/app_error.dart';

/// Use case for deleting an expense
class DeleteExpenseUseCase {
  final ExpensesRepository _expensesRepository;
  final BudgetRepository _budgetRepository;
  final BudgetCalculationService _budgetCalculationService;

  DeleteExpenseUseCase({
    required ExpensesRepository expensesRepository,
    required BudgetRepository budgetRepository,
    required BudgetCalculationService budgetCalculationService,
  })  : _expensesRepository = expensesRepository,
        _budgetRepository = budgetRepository,
        _budgetCalculationService = budgetCalculationService;

  /// Execute the delete expense use case
  Future<void> execute(String expenseId, Expense expenseToDelete,
      List<Expense> allExpenses) async {
    try {
      // Delete expense
      await Future.microtask(() async {
        return await _expensesRepository.deleteExpense(expenseId);
      });

      // Update budget after expense deletion
      await _updateBudgetAfterExpenseChange(expenseToDelete, allExpenses);
    } catch (e, stackTrace) {
      final appError = AppError.from(e, stackTrace);
      appError.log();
      rethrow;
    }
  }

  /// Update budget after expense change
  Future<void> _updateBudgetAfterExpenseChange(
      Expense expense, List<Expense> allExpenses) async {
    try {
      // Get the month ID for this expense
      final monthId = _getMonthIdFromDate(expense.date);

      // Get the budget for this month
      final currentBudget = await _budgetRepository.getBudget(monthId);
      if (currentBudget == null) {
        return; // No budget data, no need to update
      }

      // Get all expenses for this month (excluding the deleted one)
      final monthExpenses = _getExpensesForMonth(
              allExpenses, expense.date.year, expense.date.month)
          .where((e) => e.id != expense.id)
          .toList();

      // Calculate new budget remaining amounts
      final updatedBudget = await _budgetCalculationService.calculateBudget(
          currentBudget, monthExpenses);

      // Only save if budget actually changed
      if (currentBudget != updatedBudget) {
        await _budgetRepository.setBudget(monthId, updatedBudget);
      }
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
    }
  }

  /// Get month ID from date
  String _getMonthIdFromDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Get expenses for a specific month
  List<Expense> _getExpensesForMonth(
      List<Expense> expenses, int year, int month) {
    return expenses.where((expense) {
      return expense.date.year == year && expense.date.month == month;
    }).toList();
  }
}
