import 'package:flutter/foundation.dart';
import '../../entities/budget.dart';
import '../../entities/expense.dart';
import '../../repositories/budget_repository.dart';
import '../../repositories/expenses_repository.dart';
import '../../services/budget_calculation_service.dart';
import '../../../data/infrastructure/errors/app_error.dart';
import '../../../data/models/budget_reallocation_models.dart';

/// Use case for reallocating budget between categories based on AI recommendations
class ReallocateBudgetUseCase {
  final BudgetRepository _budgetRepository;
  final ExpensesRepository _expensesRepository;
  final BudgetCalculationService _budgetCalculationService;

  ReallocateBudgetUseCase({
    required BudgetRepository budgetRepository,
    required ExpensesRepository expensesRepository,
    required BudgetCalculationService budgetCalculationService,
  })  : _budgetRepository = budgetRepository,
        _expensesRepository = expensesRepository,
        _budgetCalculationService = budgetCalculationService;

  /// Execute budget reallocation based on AI recommendations
  Future<Budget> execute(
    String monthId,
    List<ReallocationSuggestion> suggestions,
  ) async {
    try {
      debugPrint(
          '🔧 ReallocateBudgetUseCase: Starting reallocation for $monthId');
      debugPrint('🔧 Processing ${suggestions.length} suggestions');

      // Get current budget
      final currentBudget = await _budgetRepository.getBudget(monthId);
      if (currentBudget == null) {
        throw ReallocationException('Budget not found for month $monthId');
      }

      // Apply reallocation suggestions
      final reallocatedBudget = _applyReallocationSuggestions(
        currentBudget,
        suggestions,
      );

      // Get current month expenses to recalculate remaining amounts
      final allExpenses = await _expensesRepository.getExpenses();
      final monthExpenses = _getExpensesForMonth(allExpenses, monthId);

      // Recalculate the budget with new allocations and current expenses
      final updatedBudget = await _budgetCalculationService.calculateBudget(
        reallocatedBudget,
        monthExpenses,
      );

      // Save the updated budget
      await _budgetRepository.setBudget(monthId, updatedBudget);

      debugPrint(
          '✅ ReallocateBudgetUseCase: Reallocation completed successfully');
      debugPrint(
          '🔧 New budget total: ${updatedBudget.total} ${updatedBudget.currency}');
      debugPrint(
          '🔧 New saving amount: ${updatedBudget.saving} ${updatedBudget.currency}');

      return updatedBudget;
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      debugPrint('❌ ReallocateBudgetUseCase: Error: ${error.message}');
      error.log();
      rethrow;
    }
  }

  /// Apply reallocation suggestions to budget allocations
  Budget _applyReallocationSuggestions(
    Budget currentBudget,
    List<ReallocationSuggestion> suggestions,
  ) {
    final newCategories =
        Map<String, CategoryBudget>.from(currentBudget.categories);
    double totalReallocated = 0;

    for (final suggestion in suggestions) {
      final fromCategory = suggestion.fromCategory;
      final toCategory = suggestion.toCategory;
      final amount = suggestion.amount;

      // Handle transfers to/from saving
      if (toCategory.toLowerCase() == 'saving' ||
          toCategory.toLowerCase() == 'emergency fund' ||
          toCategory.toLowerCase() == 'house down payment') {
        // Transfer from category to saving (reduce category budget allocation)
        if (newCategories.containsKey(fromCategory)) {
          final fromCat = newCategories[fromCategory]!;
          final newBudgetAmount =
              (fromCat.budget - amount).clamp(0.0, double.infinity);

          newCategories[fromCategory] = CategoryBudget(
            budget: newBudgetAmount,
            left: fromCat.left, // Will be recalculated later
          );

          totalReallocated += amount;
          debugPrint(
              '💰 Reduced $fromCategory budget by ${amount.toStringAsFixed(2)} (moved to saving)');
        }
      } else if (fromCategory.toLowerCase() == 'saving' ||
          fromCategory.toLowerCase() == 'emergency fund' ||
          fromCategory.toLowerCase() == 'house down payment') {
        // Transfer from saving to category (increase category budget allocation)
        if (newCategories.containsKey(toCategory)) {
          final toCat = newCategories[toCategory]!;

          newCategories[toCategory] = CategoryBudget(
            budget: toCat.budget + amount,
            left: toCat.left, // Will be recalculated later
          );

          totalReallocated += amount;
          debugPrint(
              '💰 Increased $toCategory budget by ${amount.toStringAsFixed(2)} (from saving)');
        }
      } else {
        // Transfer between categories
        if (newCategories.containsKey(fromCategory) &&
            newCategories.containsKey(toCategory)) {
          final fromCat = newCategories[fromCategory]!;
          final toCat = newCategories[toCategory]!;

          // Ensure we don't reduce below zero
          final transferAmount = amount.clamp(0.0, fromCat.budget);

          newCategories[fromCategory] = CategoryBudget(
            budget: fromCat.budget - transferAmount,
            left: fromCat.left, // Will be recalculated later
          );

          newCategories[toCategory] = CategoryBudget(
            budget: toCat.budget + transferAmount,
            left: toCat.left, // Will be recalculated later
          );

          totalReallocated += transferAmount;
          debugPrint(
              '💰 Transferred ${transferAmount.toStringAsFixed(2)} from $fromCategory to $toCategory');
        }
      }
    }

    // Calculate new saving amount (total budget - sum of category budgets)
    final totalCategoryBudgets = newCategories.values
        .fold(0.0, (sum, category) => sum + category.budget);
    final newSaving = currentBudget.total - totalCategoryBudgets;

    debugPrint('🔧 Total reallocated: ${totalReallocated.toStringAsFixed(2)}');
    debugPrint('🔧 New saving amount: ${newSaving.toStringAsFixed(2)}');

    return currentBudget.copyWith(
      categories: newCategories,
      saving: newSaving,
    );
  }

  /// Get expenses for a specific month
  List<Expense> _getExpensesForMonth(List<Expense> expenses, String monthId) {
    final parts = monthId.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    return expenses.where((expense) {
      return expense.date.year == year && expense.date.month == month;
    }).toList();
  }
}

/// Exception for budget reallocation errors
class ReallocationException extends AppError {
  ReallocationException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code ?? 'REALLOCATION_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
        );
}
