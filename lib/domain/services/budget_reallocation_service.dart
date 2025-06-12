import 'package:flutter/foundation.dart';
import '../entities/budget.dart';
import '../entities/category.dart';
import '../repositories/budget_repository.dart';
import '../../data/models/ai_response_models.dart';
import '../../data/infrastructure/errors/app_error.dart';
import '../../data/infrastructure/monitoring/performance_monitor.dart';

/// Service for reallocating budget based on AI predictions and spending patterns
/// Implements business logic for smart budget redistribution
class BudgetReallocationService {
  final BudgetRepository _budgetRepository;

  BudgetReallocationService({
    required BudgetRepository budgetRepository,
  }) : _budgetRepository = budgetRepository;

  /// Reallocate budget based on AI predictions
  /// Returns the updated budget or throws an exception if reallocation is not possible
  Future<Budget> reallocateBudget({
    required Budget currentBudget,
    required ExpensePredictionResponse predictions,
    required String monthId,
  }) async {
    try {
      debugPrint(
          '🔄 BudgetReallocationService: Starting budget reallocation...');

      return await PerformanceMonitor.measureAsync('budget_reallocation',
          () async {
        // Validate input data
        _validateReallocationData(currentBudget, predictions);

        // Check if reallocation is needed and possible
        final reallocationAnalysis =
            _analyzeReallocationNeed(currentBudget, predictions);
        if (!reallocationAnalysis.isReallocationNeeded) {
          debugPrint(
              '🔄 No reallocation needed - all categories within budget');
          return currentBudget;
        }

        if (!reallocationAnalysis.isReallocationPossible) {
          throw ReallocationException(
            'Cannot reallocate budget - all categories exceed or will exceed their limits',
            code: 'REALLOCATION_IMPOSSIBLE',
          );
        }

        // Perform the actual reallocation
        final reallocatedBudget = _performReallocation(
          currentBudget,
          predictions,
          reallocationAnalysis,
        );

        // Save the updated budget
        await _budgetRepository.setBudget(monthId, reallocatedBudget);

        debugPrint(
            '✅ BudgetReallocationService: Reallocation completed successfully');
        return reallocatedBudget;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ BudgetReallocationService: Reallocation failed: $e');
      final error = AppError.from(e, stackTrace);
      error.log();
      rethrow;
    }
  }

  /// Validate that we have sufficient data for reallocation
  void _validateReallocationData(
      Budget budget, ExpensePredictionResponse predictions) {
    if (budget.total <= 0) {
      throw ReallocationException(
        'Invalid budget data - total budget must be greater than 0',
        code: 'INVALID_BUDGET',
      );
    }

    if (predictions.predictedExpenses.isEmpty) {
      throw ReallocationException(
        'No prediction data available for reallocation',
        code: 'NO_PREDICTIONS',
      );
    }

    if (predictions.budgetReallocationSuggestions.isEmpty) {
      throw ReallocationException(
        'No reallocation suggestions provided by AI',
        code: 'NO_SUGGESTIONS',
      );
    }
  }

  /// Analyze whether reallocation is needed and possible
  ReallocationAnalysis _analyzeReallocationNeed(
    Budget budget,
    ExpensePredictionResponse predictions,
  ) {
    final categoriesNeedingMore = <String>[];
    final categoriesWithSurplus = <String>[];
    double totalShortfall = 0.0;
    double totalSurplus = 0.0;

    // Check each predicted expense against current budget
    for (final prediction in predictions.predictedExpenses) {
      final categoryId = prediction.categoryId;
      final predictedAmount = prediction.predictedAmount;

      // Get current category budget
      final categoryBudget = budget.categories[categoryId];
      if (categoryBudget == null) continue;

      final availableBudget = categoryBudget.left;

      if (predictedAmount > availableBudget) {
        // Category will exceed budget
        final shortfall = predictedAmount - availableBudget;
        categoriesNeedingMore.add(categoryId);
        totalShortfall += shortfall;

        debugPrint(
            '🔍 Category $categoryId needs ${shortfall.toStringAsFixed(2)} more');
      } else {
        // Category has surplus
        final surplus = availableBudget - predictedAmount;
        if (surplus > 5.0) {
          // Only consider meaningful surplus (> 5 currency units)
          categoriesWithSurplus.add(categoryId);
          totalSurplus += surplus;

          debugPrint(
              '🔍 Category $categoryId has surplus of ${surplus.toStringAsFixed(2)}');
        }
      }
    }

    final isReallocationNeeded = categoriesNeedingMore.isNotEmpty;
    final isReallocationPossible = totalSurplus >= totalShortfall;

    debugPrint('🔍 Reallocation analysis:');
    debugPrint('  - Categories needing more: ${categoriesNeedingMore.length}');
    debugPrint('  - Categories with surplus: ${categoriesWithSurplus.length}');
    debugPrint('  - Total shortfall: ${totalShortfall.toStringAsFixed(2)}');
    debugPrint('  - Total surplus: ${totalSurplus.toStringAsFixed(2)}');
    debugPrint('  - Reallocation needed: $isReallocationNeeded');
    debugPrint('  - Reallocation possible: $isReallocationPossible');

    return ReallocationAnalysis(
      categoriesNeedingMore: categoriesNeedingMore,
      categoriesWithSurplus: categoriesWithSurplus,
      totalShortfall: totalShortfall,
      totalSurplus: totalSurplus,
      isReallocationNeeded: isReallocationNeeded,
      isReallocationPossible: isReallocationPossible,
    );
  }

  /// Perform the actual budget reallocation
  Budget _performReallocation(
    Budget currentBudget,
    ExpensePredictionResponse predictions,
    ReallocationAnalysis analysis,
  ) {
    final newCategories =
        Map<String, CategoryBudget>.from(currentBudget.categories);
    final reallocationMoves = <ReallocationMove>[];

    // Calculate how much each category needs
    final categoryNeeds = <String, double>{};
    for (final prediction in predictions.predictedExpenses) {
      final categoryId = prediction.categoryId;
      if (analysis.categoriesNeedingMore.contains(categoryId)) {
        final categoryBudget = currentBudget.categories[categoryId];
        if (categoryBudget != null) {
          final shortfall = prediction.predictedAmount - categoryBudget.left;
          categoryNeeds[categoryId] = shortfall;
        }
      }
    }

    // Calculate available surplus from each category
    final categorySurplus = <String, double>{};
    for (final prediction in predictions.predictedExpenses) {
      final categoryId = prediction.categoryId;
      if (analysis.categoriesWithSurplus.contains(categoryId)) {
        final categoryBudget = currentBudget.categories[categoryId];
        if (categoryBudget != null) {
          final surplus = categoryBudget.left - prediction.predictedAmount;
          if (surplus > 5.0) {
            // Only consider meaningful surplus
            categorySurplus[categoryId] =
                surplus * 0.8; // Only use 80% of surplus for safety
          }
        }
      }
    }

    // Perform reallocation moves
    for (final needyCategory in analysis.categoriesNeedingMore) {
      final neededAmount = categoryNeeds[needyCategory] ?? 0.0;
      double amountToAllocate = neededAmount;

      // Find surplus categories to take from
      for (final surplusCategory in analysis.categoriesWithSurplus) {
        if (amountToAllocate <= 0) break;

        final availableSurplus = categorySurplus[surplusCategory] ?? 0.0;
        if (availableSurplus <= 0) continue;

        final transferAmount = (amountToAllocate > availableSurplus)
            ? availableSurplus
            : amountToAllocate;

        // Update source category (reduce budget and left)
        final sourceBudget = newCategories[surplusCategory]!;
        newCategories[surplusCategory] = CategoryBudget(
          budget: sourceBudget.budget - transferAmount,
          left: sourceBudget.left - transferAmount,
        );

        // Update target category (increase budget and left)
        final targetBudget = newCategories[needyCategory]!;
        newCategories[needyCategory] = CategoryBudget(
          budget: targetBudget.budget + transferAmount,
          left: targetBudget.left + transferAmount,
        );

        // Record the move
        reallocationMoves.add(ReallocationMove(
          fromCategory: surplusCategory,
          toCategory: needyCategory,
          amount: transferAmount,
        ));

        // Update remaining amounts
        categorySurplus[surplusCategory] = availableSurplus - transferAmount;
        amountToAllocate -= transferAmount;

        debugPrint(
            '💸 Moved ${transferAmount.toStringAsFixed(2)} from $surplusCategory to $needyCategory');
      }
    }

    // Log the reallocation summary
    debugPrint('🔄 Reallocation summary:');
    debugPrint('  - Total moves: ${reallocationMoves.length}');
    for (final move in reallocationMoves) {
      debugPrint(
          '    ${move.fromCategory} → ${move.toCategory}: ${move.amount.toStringAsFixed(2)}');
    }

    return Budget(
      total: currentBudget.total,
      left: currentBudget.left, // Overall left amount doesn't change
      categories: newCategories,
      currency: currentBudget.currency,
    );
  }

  /// Get category name from ID for display purposes
  String _getCategoryName(String categoryId) {
    try {
      final category = CategoryExtension.fromId(categoryId);
      return category?.name ?? categoryId;
    } catch (e) {
      return categoryId;
    }
  }
}

/// Analysis result for budget reallocation
class ReallocationAnalysis {
  final List<String> categoriesNeedingMore;
  final List<String> categoriesWithSurplus;
  final double totalShortfall;
  final double totalSurplus;
  final bool isReallocationNeeded;
  final bool isReallocationPossible;

  ReallocationAnalysis({
    required this.categoriesNeedingMore,
    required this.categoriesWithSurplus,
    required this.totalShortfall,
    required this.totalSurplus,
    required this.isReallocationNeeded,
    required this.isReallocationPossible,
  });
}

/// Represents a single budget reallocation move
class ReallocationMove {
  final String fromCategory;
  final String toCategory;
  final double amount;

  ReallocationMove({
    required this.fromCategory,
    required this.toCategory,
    required this.amount,
  });
}

/// Exception thrown when budget reallocation fails
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
