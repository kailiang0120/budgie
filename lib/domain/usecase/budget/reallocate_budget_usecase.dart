import 'package:flutter/foundation.dart';
import '../../entities/budget.dart';
import '../../entities/expense.dart';
import '../../entities/category.dart' as cat;
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

  /// Normalize category name to match the category IDs used in budget storage
  String? _normalizeCategoryName(String categoryName) {
    // Handle special savings categories
    final lowerName = categoryName.toLowerCase().trim();

    if (lowerName == 'saving' ||
        lowerName == 'savings' ||
        lowerName == 'emergency fund' ||
        lowerName == 'house down payment') {
      return lowerName;
    }

    // Try to match against known categories first
    for (final category in cat.Category.values) {
      final categoryId = category.id; // e.g., "entertainment"

      // Direct match with category ID
      if (lowerName == categoryId) {
        return categoryId;
      }

      // Match with capitalized version (e.g., "Entertainment" -> "entertainment")
      if (lowerName == categoryId.toLowerCase()) {
        return categoryId;
      }
    }

    // If no match found, return the original lowercase name
    // This handles custom categories that might not be in the enum
    return lowerName;
  }

  /// Find the actual category key in the budget that matches the suggested category name
  String? _findCategoryKey(
      Map<String, CategoryBudget> categories, String suggestedName) {
    final normalizedName = _normalizeCategoryName(suggestedName);

    if (normalizedName == null) return null;

    // Direct key match
    if (categories.containsKey(normalizedName)) {
      return normalizedName;
    }

    // Try to find a key that matches when both are normalized
    for (final key in categories.keys) {
      if (_normalizeCategoryName(key) == normalizedName) {
        return key;
      }
    }

    return null;
  }

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
      // The budget calculation service will properly recalculate the 'left' amounts
      // based on the new budget allocations and existing expenses
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
    debugPrint('🔧 Applying reallocation suggestions...');
    debugPrint('🔧 Total suggestions received: ${suggestions.length}');

    // Filter to only process High priority suggestions
    final highPrioritySuggestions = suggestions
        .where((suggestion) => suggestion.criticality.toLowerCase() == 'high')
        .toList();

    debugPrint(
        '🔧 High priority suggestions: ${highPrioritySuggestions.length}');

    if (highPrioritySuggestions.isEmpty) {
      debugPrint('🔧 No high priority suggestions to apply');
      return currentBudget;
    }

    final newCategories =
        Map<String, CategoryBudget>.from(currentBudget.categories);
    double totalReallocated = 0;

    for (final suggestion in highPrioritySuggestions) {
      final fromCategory = suggestion.fromCategory;
      final toCategory = suggestion.toCategory;
      final amount = suggestion.amount;

      debugPrint(
          '🔧 Processing: $fromCategory → $toCategory: ${amount.toStringAsFixed(2)}');

      if (amount <= 0) {
        debugPrint(
            '⚠️ Skipping non-positive amount: ${amount.toStringAsFixed(2)}');
        continue;
      }

      // Normalize category names for matching
      final normalizedToCategory = _normalizeCategoryName(toCategory);
      final normalizedFromCategory = _normalizeCategoryName(fromCategory);

      debugPrint(
          '🔧 Normalized: $normalizedFromCategory → $normalizedToCategory');

      // Handle transfers to/from saving
      if (normalizedToCategory == 'saving' ||
          normalizedToCategory == 'savings' ||
          normalizedToCategory == 'emergency fund' ||
          normalizedToCategory == 'house down payment') {
        // Transfer from category to saving (reduce category budget allocation)
        final fromCategoryKey = _findCategoryKey(newCategories, fromCategory);

        if (fromCategoryKey != null) {
          final fromCat = newCategories[fromCategoryKey]!;

          // Validate: Don't exceed available amount in category
          if (fromCat.left < amount) {
            debugPrint(
                '⚠️ Transfer amount ${amount.toStringAsFixed(2)} exceeds available ${fromCat.left.toStringAsFixed(2)} in $fromCategory. Skipping.');
            continue;
          }

          // Reduce budget allocation (this moves money back to savings)
          final newBudgetAmount =
              (fromCat.budget - amount).clamp(0.0, double.infinity);

          newCategories[fromCategoryKey] = CategoryBudget(
            budget: newBudgetAmount,
            left: fromCat
                .left, // Will be recalculated by budget calculation service
          );

          totalReallocated += amount;
          debugPrint(
              '💰 Reduced $fromCategory budget by ${amount.toStringAsFixed(2)} (moved to saving)');
        } else {
          debugPrint('⚠️ Category $fromCategory not found in budget');
        }
      } else if (normalizedFromCategory == 'saving' ||
          normalizedFromCategory == 'savings' ||
          normalizedFromCategory == 'emergency fund' ||
          normalizedFromCategory == 'house down payment') {
        // Transfer from saving to category (increase category budget allocation)
        final toCategoryKey = _findCategoryKey(newCategories, toCategory);

        if (toCategoryKey != null) {
          // Validate: Don't exceed available savings
          if (currentBudget.saving < amount) {
            debugPrint(
                '⚠️ Transfer amount ${amount.toStringAsFixed(2)} exceeds available savings ${currentBudget.saving.toStringAsFixed(2)}. Skipping.');
            continue;
          }

          final toCat = newCategories[toCategoryKey]!;

          newCategories[toCategoryKey] = CategoryBudget(
            budget: toCat.budget + amount,
            left: toCat
                .left, // Will be recalculated by budget calculation service
          );

          totalReallocated += amount;
          debugPrint(
              '💰 Increased $toCategory budget by ${amount.toStringAsFixed(2)} (from saving)');
        } else {
          debugPrint('⚠️ Category $toCategory not found in budget');
        }
      } else {
        // Transfer between categories
        final fromCategoryKey = _findCategoryKey(newCategories, fromCategory);
        final toCategoryKey = _findCategoryKey(newCategories, toCategory);

        if (fromCategoryKey != null && toCategoryKey != null) {
          final fromCat = newCategories[fromCategoryKey]!;
          final toCat = newCategories[toCategoryKey]!;

          // Validate: Don't exceed available amount in source category
          if (fromCat.left < amount) {
            debugPrint(
                '⚠️ Transfer amount ${amount.toStringAsFixed(2)} exceeds available ${fromCat.left.toStringAsFixed(2)} in $fromCategory. Skipping.');
            continue;
          }

          // Ensure we don't reduce budget below zero
          final actualTransferAmount = amount.clamp(0.0, fromCat.budget);

          newCategories[fromCategoryKey] = CategoryBudget(
            budget: fromCat.budget - actualTransferAmount,
            left: fromCat
                .left, // Will be recalculated by budget calculation service
          );

          newCategories[toCategoryKey] = CategoryBudget(
            budget: toCat.budget + actualTransferAmount,
            left: toCat
                .left, // Will be recalculated by budget calculation service
          );

          totalReallocated += actualTransferAmount;
          debugPrint(
              '💸 Transferred ${actualTransferAmount.toStringAsFixed(2)} from $fromCategory to $toCategory');
        } else {
          debugPrint(
              '⚠️ One or both categories not found: $fromCategory ($fromCategoryKey), $toCategory ($toCategoryKey)');
          debugPrint(
              '🔧 Available categories: ${newCategories.keys.join(', ')}');
        }
      }
    }

    if (totalReallocated == 0) {
      debugPrint('🔧 No reallocations applied');
      return currentBudget;
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
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: code ?? 'REALLOCATION_ERROR',
        );
}
