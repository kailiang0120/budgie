import 'package:flutter/material.dart';
import 'dart:async';
import '../../domain/entities/budget.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../data/infrastructure/errors/app_error.dart';
import '../../domain/usecase/budget/load_budget_usecase.dart';
import '../../domain/usecase/budget/save_budget_usecase.dart';
import '../../domain/usecase/budget/convert_budget_currency_usecase.dart';
import '../../domain/usecase/budget/calculate_budget_remaining_usecase.dart';
import '../../domain/usecase/budget/refresh_budget_usecase.dart';

class BudgetViewModel extends ChangeNotifier {
  final BudgetRepository _budgetRepository;
  final LoadBudgetUseCase _loadBudgetUseCase;
  final SaveBudgetUseCase _saveBudgetUseCase;
  final ConvertBudgetCurrencyUseCase _convertBudgetCurrencyUseCase;
  final CalculateBudgetRemainingUseCase _calculateBudgetRemainingUseCase;
  final RefreshBudgetUseCase _refreshBudgetUseCase;

  Budget? budget;
  bool isLoading = false;
  String? errorMessage;

  BudgetViewModel({
    required BudgetRepository budgetRepository,
    required LoadBudgetUseCase loadBudgetUseCase,
    required SaveBudgetUseCase saveBudgetUseCase,
    required ConvertBudgetCurrencyUseCase convertBudgetCurrencyUseCase,
    required CalculateBudgetRemainingUseCase calculateBudgetRemainingUseCase,
    required RefreshBudgetUseCase refreshBudgetUseCase,
  })  : _budgetRepository = budgetRepository,
        _loadBudgetUseCase = loadBudgetUseCase,
        _saveBudgetUseCase = saveBudgetUseCase,
        _convertBudgetCurrencyUseCase = convertBudgetCurrencyUseCase,
        _calculateBudgetRemainingUseCase = calculateBudgetRemainingUseCase,
        _refreshBudgetUseCase = refreshBudgetUseCase;

  /// Load budget for a specific month and check if currency conversion is needed
  Future<void> loadBudget(String monthId, {bool checkCurrency = false}) async {
    // Set loading state without notifying
    isLoading = true;
    errorMessage = null;

    try {
      final loadedBudget = await _loadBudgetUseCase.execute(monthId,
          checkCurrency: checkCurrency);

      if (budget != loadedBudget) {
        budget = loadedBudget;
        isLoading = false;
        notifyListeners();
      } else {
        // Just update loading state without notifying if budget didn't change
        isLoading = false;
      }
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      errorMessage = error.message;
      // If authentication error, clear budget data
      if (error is AuthError) {
        budget = null;
      }
      isLoading = false;
      notifyListeners();
    }
  }

  /// Force refresh the budget data
  Future<void> refreshBudget(String monthId) async {
    try {
      debugPrint('🔄 BudgetViewModel: Manual budget refresh requested');
      isLoading = true;
      notifyListeners();

      final refreshedBudget = await _refreshBudgetUseCase.execute(monthId);
      budget = refreshedBudget;
    } catch (e) {
      debugPrint('🔄 BudgetViewModel: Error refreshing budget: $e');
      errorMessage = 'Failed to refresh budget: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Handle currency changes from settings
  Future<void> onCurrencyChanged(String newCurrency) async {
    // Check if we already have a budget to convert
    if (budget == null) {
      debugPrint('🔄 No budget to convert, skipping onCurrencyChanged');
      return; // No budget to convert
    }

    // Check if the currency is already the same
    if (budget!.currency == newCurrency) {
      debugPrint(
          '🔄 Budget currency already matches new currency: $newCurrency');
      return; // Already in the right currency
    }

    try {
      isLoading = true;
      notifyListeners();

      // Get current month ID for saving
      final now = DateTime.now();
      final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final convertedBudget =
          await _convertBudgetCurrencyUseCase.execute(monthId, newCurrency);
      budget = convertedBudget;
    } catch (e) {
      debugPrint('❌ Error handling currency change: $e');
      errorMessage = 'Failed to update budget with new currency';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveBudgetWithMonthId(String monthId, Budget newBudget) async {
    try {
      errorMessage = null;
      isLoading = true;
      notifyListeners();

      await _saveBudgetUseCase.execute(monthId, newBudget);
      budget = newBudget;
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // This is an alias for backwards compatibility with existing code
  Future<void> saveBudget(String monthId, Budget newBudget) async {
    await saveBudgetWithMonthId(monthId, newBudget);
  }

  // Save budget without explicit month ID
  Future<void> saveBudgetWithoutMonthId(Budget newBudget) async {
    // Extract month ID from the budget's data (this needs to be provided elsewhere)
    // For now, use the current month as a fallback
    final now = DateTime.now();
    final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    await saveBudgetWithMonthId(monthId, newBudget);
  }

  /// Calculate budget remaining amounts (total and by categories)
  Future<void> calculateBudgetRemaining(List<Expense> expenses,
      [String? monthId]) async {
    if (budget == null) return;

    try {
      errorMessage = null;
      isLoading = true;
      notifyListeners();

      // Use the calculate budget remaining use case
      final updatedBudget =
          await _calculateBudgetRemainingUseCase.execute(budget!, expenses);

      // Update budget data in memory
      budget = updatedBudget;

      // Save the updated budget to Firebase/local storage
      final targetMonthId = monthId ?? _getCurrentMonthId();
      await _saveBudgetUseCase.execute(targetMonthId, updatedBudget);

      debugPrint('💾 Budget recalculated and saved for month: $targetMonthId');
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Get current month ID
  String _getCurrentMonthId() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _saveBudgetUseCase.dispose();
    super.dispose();
  }
}
