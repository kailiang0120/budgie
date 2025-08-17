import 'package:budgie/domain/entities/expense.dart';
import 'package:budgie/domain/repositories/expenses_repository.dart';
import 'package:flutter/foundation.dart';

import '../budget/refresh_budget_usecase.dart';
import '../../../data/infrastructure/errors/app_error.dart';
import '../../../data/infrastructure/network/connectivity_service.dart';
import '../../../data/infrastructure/services/settings_service.dart';

/// Use case for updating an existing expense
class UpdateExpenseUseCase {
  final ExpensesRepository _expensesRepository;
  final RefreshBudgetUseCase _refreshBudgetUseCase;
  // ignore: unused_field
  final ConnectivityService _connectivityService;
  // ignore: unused_field
  final SettingsService _settingsService;

  UpdateExpenseUseCase({
    required ExpensesRepository expensesRepository,
    required RefreshBudgetUseCase refreshBudgetUseCase,
    required ConnectivityService connectivityService,
    required SettingsService settingsService,
  })  : _expensesRepository = expensesRepository,
        _refreshBudgetUseCase = refreshBudgetUseCase,
        _connectivityService = connectivityService,
        _settingsService = settingsService;

  /// Execute the update expense use case
  Future<void> execute(Expense expense) async {
    try {
      debugPrint('Updating expense: ${expense.id}');

      // Update expense in repository
      await _expensesRepository.updateExpense(expense);

      // Update budget after expense change
      await _updateBudgetAfterExpenseChange(expense);
    } catch (e, stackTrace) {
      final appError = AppError.from(e, stackTrace);
      debugPrint('Error updating expense: ${appError.message}');
      rethrow;
    }
  }

  /// Update budget after expense change
  Future<void> _updateBudgetAfterExpenseChange(Expense expense) async {
    try {
      // Get the month from the expense date
      final expenseDate = expense.date;
      final monthId =
          '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}';

      // Refresh budget for the month
      await _refreshBudgetUseCase.execute(monthId);
    } catch (e) {
      debugPrint('Error updating budget after expense change: $e');
      // Don't rethrow - this is a secondary operation
    }
  }
}
