import 'package:budgie/domain/entities/expense.dart';
import 'package:budgie/domain/repositories/expenses_repository.dart';

import '../budget/refresh_budget_usecase.dart';
import '../../../data/infrastructure/errors/app_error.dart';
import '../../../data/infrastructure/network/connectivity_service.dart';
import '../../../data/infrastructure/services/settings_service.dart';

/// Use case for adding a new expense
class AddExpenseUseCase {
  final ExpensesRepository _expensesRepository;
  final RefreshBudgetUseCase _refreshBudgetUseCase;
  // ignore: unused_field
  final ConnectivityService _connectivityService;
  // ignore: unused_field
  final SettingsService _settingsService;

  AddExpenseUseCase({
    required ExpensesRepository expensesRepository,
    required RefreshBudgetUseCase refreshBudgetUseCase,
    required ConnectivityService connectivityService,
    required SettingsService settingsService,
  })  : _expensesRepository = expensesRepository,
        _refreshBudgetUseCase = refreshBudgetUseCase,
        _connectivityService = connectivityService,
        _settingsService = settingsService;

  /// Execute the add expense use case
  Future<void> execute(Expense expense) async {
    try {
      // Add expense to local database
      await _expensesRepository.addExpense(expense);

      // Update budget after expense change
      await _updateBudgetAfterExpenseChange(expense);
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
