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
import '../../domain/usecase/budget/delete_budget_usecase.dart';
import 'package:flutter/foundation.dart';

class BudgetViewModel extends ChangeNotifier {
  final BudgetRepository _budgetRepository;
  final LoadBudgetUseCase _loadBudgetUseCase;
  final SaveBudgetUseCase _saveBudgetUseCase;
  final ConvertBudgetCurrencyUseCase _convertBudgetCurrencyUseCase;
  final CalculateBudgetRemainingUseCase _calculateBudgetRemainingUseCase;
  final RefreshBudgetUseCase _refreshBudgetUseCase;
  final DeleteBudgetUseCase _deleteBudgetUseCase;

  Budget? budget;
  bool isLoading = false;
  String? errorMessage;

  Future<void>? _activeLoad;
  String? _activeLoadMonthId;

  BudgetViewModel({
    required BudgetRepository budgetRepository,
    required LoadBudgetUseCase loadBudgetUseCase,
    required SaveBudgetUseCase saveBudgetUseCase,
    required ConvertBudgetCurrencyUseCase convertBudgetCurrencyUseCase,
    required CalculateBudgetRemainingUseCase calculateBudgetRemainingUseCase,
    required RefreshBudgetUseCase refreshBudgetUseCase,
    required DeleteBudgetUseCase deleteBudgetUseCase,
  })  : _budgetRepository = budgetRepository,
        _loadBudgetUseCase = loadBudgetUseCase,
        _saveBudgetUseCase = saveBudgetUseCase,
        _convertBudgetCurrencyUseCase = convertBudgetCurrencyUseCase,
        _calculateBudgetRemainingUseCase = calculateBudgetRemainingUseCase,
        _refreshBudgetUseCase = refreshBudgetUseCase,
        _deleteBudgetUseCase = deleteBudgetUseCase;

  /// Load budget for a specific month and check if currency conversion is needed
  Future<void> loadBudget(String monthId, {bool checkCurrency = false}) async {
    if (_activeLoad != null) {
      final pendingLoad = _activeLoad!;
      final pendingMonth = _activeLoadMonthId;
      await pendingLoad;
      if (pendingMonth == monthId) {
        return;
      }
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final loadFuture =
        _performBudgetLoad(monthId, checkCurrency: checkCurrency);
    _activeLoad = loadFuture;
    _activeLoadMonthId = monthId;

    try {
      await loadFuture;
    } finally {
      _activeLoad = null;
      _activeLoadMonthId = null;
    }
  }

  Future<void> _performBudgetLoad(String monthId,
      {required bool checkCurrency}) async {
    try {
      final loadedBudget = await _loadBudgetUseCase.execute(monthId,
          checkCurrency: checkCurrency);

      if (budget != loadedBudget) {
        budget = loadedBudget;
      }

      isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      errorMessage = error.message;
      isLoading = false;
      notifyListeners();
    }
  }

  /// Force refresh the budget data
  Future<void> refreshBudget(String monthId) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🔄 BudgetViewModel: Manual budget refresh requested for month: $monthId');
      }
      isLoading = true;
      notifyListeners();

      // First try to get the budget directly from repository to check if it exists
      final existingBudget = await _budgetRepository.getBudget(monthId);
      if (kDebugMode) {
        debugPrint(
            '🔄 BudgetViewModel: Existing budget found: ${existingBudget != null}');
      }
      if (existingBudget != null) {
        if (kDebugMode) {
          debugPrint(
              '🔄 BudgetViewModel: Existing budget total: ${existingBudget.total}, currency: ${existingBudget.currency}');
        }
      }

      // Now use the refresh use case to recalculate with expenses
      final refreshedBudget = await _refreshBudgetUseCase.execute(monthId);
      if (kDebugMode) {
        debugPrint(
            '🔄 BudgetViewModel: Refresh use case returned budget: ${refreshedBudget != null}');
      }

      if (refreshedBudget != null) {
        if (kDebugMode) {
          debugPrint(
              '🔄 BudgetViewModel: Refreshed budget total: ${refreshedBudget.total}, currency: ${refreshedBudget.currency}');
        }
      }

      budget = refreshedBudget;
      if (kDebugMode) {
        debugPrint(
            '🔄 BudgetViewModel: Budget after refresh: ${budget != null}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔄 BudgetViewModel: Error refreshing budget: $e');
      }
      errorMessage = 'Failed to refresh budget: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Handle currency changes from settings
  Future<void> onCurrencyChanged(String newCurrency) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '💱 BudgetViewModel: Currency change requested to: $newCurrency');
      }

      isLoading = true;
      errorMessage = null;
      notifyListeners();

      // Get current month ID for saving
      final now = DateTime.now();
      final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Load the current budget first
      final currentBudget = await _loadBudgetUseCase.execute(monthId);

      if (currentBudget == null) {
        if (kDebugMode) {
          debugPrint('💱 BudgetViewModel: No budget found for month: $monthId');
        }
        return;
      }

      // Check if conversion is needed
      if (currentBudget.currency == newCurrency) {
        if (kDebugMode) {
          debugPrint(
              '💱 BudgetViewModel: Budget already in target currency: $newCurrency');
        }
        budget = currentBudget;
        return;
      }

      if (kDebugMode) {
        debugPrint(
            '💱 BudgetViewModel: Converting budget from ${currentBudget.currency} to $newCurrency');
      }

      // Perform currency conversion
      final convertedBudget =
          await _convertBudgetCurrencyUseCase.execute(monthId, newCurrency);

      if (convertedBudget != null) {
        budget = convertedBudget;
        if (kDebugMode) {
          debugPrint(
              '💱 BudgetViewModel: Currency conversion completed successfully');
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '💱 BudgetViewModel: Currency conversion failed, keeping original budget');
        }
        budget = currentBudget;
        errorMessage = 'Failed to convert budget currency';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💱 BudgetViewModel: Error handling currency change: $e');
      }
      errorMessage =
          'Failed to update budget with new currency: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveBudgetWithMonthId(String monthId, Budget newBudget) async {
    try {
      if (kDebugMode) {
        debugPrint('💾 BudgetViewModel: Saving budget for month: $monthId');
        debugPrint(
            '💾 BudgetViewModel: Budget total: ${newBudget.total}, left: ${newBudget.left}, currency: ${newBudget.currency}');
      }

      errorMessage = null;
      isLoading = true;
      notifyListeners();

      await _saveBudgetUseCase.execute(monthId, newBudget);

      // Explicitly set the budget property to ensure UI updates
      budget = newBudget;

      if (kDebugMode) {
        debugPrint('💾 BudgetViewModel: Budget saved successfully');
      }
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      errorMessage = error.message;
      if (kDebugMode) {
        debugPrint('💾 BudgetViewModel: Error saving budget: ${error.message}');
      }
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

      final updatedBudget =
          await _calculateBudgetRemainingUseCase.execute(budget!, expenses);
      budget = updatedBudget;
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new budget with just the total amount and currency
  Future<void> createBudget(
      String monthId, double totalAmount, String currency) async {
    try {
      errorMessage = null;
      isLoading = true;
      notifyListeners();

      // Create a simple budget with just the total amount
      final newBudget = Budget(
        total: totalAmount,
        left: totalAmount,
        categories: {}, // No predefined categories
        saving: 0,
        currency: currency,
      );

      // Save the budget
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

  /// Delete budget for a specific month
  Future<void> deleteBudget(String monthId) async {
    try {
      if (kDebugMode) {
        debugPrint('🗑️ BudgetViewModel: Deleting budget for month: $monthId');
      }

      isLoading = true;
      errorMessage = null;
      notifyListeners();

      // Delete the budget using the use case
      await _deleteBudgetUseCase.execute(monthId);

      // Clear the current budget if it's the one that was deleted
      if (budget != null && monthId == _getCurrentMonthId()) {
        budget = null;
      }

      if (kDebugMode) {
        debugPrint('🗑️ BudgetViewModel: Budget deleted successfully');
      }
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      if (kDebugMode) {
        debugPrint(
            '🗑️ BudgetViewModel: Error deleting budget: ${error.message}');
      }
      errorMessage = 'Failed to delete budget: ${error.message}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Helper method to get the current month ID
  String _getCurrentMonthId() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
