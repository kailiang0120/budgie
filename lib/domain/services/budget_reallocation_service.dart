import 'package:flutter/foundation.dart';
import '../entities/budget.dart';
import '../entities/expense.dart';
import '../entities/category.dart' as entities;
import '../repositories/budget_repository.dart';
import '../repositories/expenses_repository.dart';
import '../../data/models/budget_reallocation_models.dart';
import '../../data/infrastructure/errors/app_error.dart';
import '../../data/infrastructure/services/gemini_api_client.dart';
import '../../data/infrastructure/services/settings_service.dart';
import 'spending_behavior_analysis_service.dart';

/// Service for intelligent budget reallocation using AI analysis via FastAPI backend
///
/// This service analyzes spending patterns and budget utilization to provide
/// smart reallocation recommendations and automatically optimize budget distribution.
class BudgetReallocationService {
  final BudgetRepository _budgetRepository;
  final ExpensesRepository _expensesRepository;
  final GeminiApiClient _apiClient;
  final SettingsService _settingsService;
  final SpendingBehaviorAnalysisService _spendingBehaviorService;

  BudgetReallocationService({
    required BudgetRepository budgetRepository,
    required ExpensesRepository expensesRepository,
    required GeminiApiClient geminiApiClient,
    required SettingsService settingsService,
    required SpendingBehaviorAnalysisService spendingBehaviorService,
  })  : _budgetRepository = budgetRepository,
        _expensesRepository = expensesRepository,
        _apiClient = geminiApiClient,
        _settingsService = settingsService,
        _spendingBehaviorService = spendingBehaviorService;

  /// Analyze and reallocate budget for the given month
  /// Returns the updated budget with AI-recommended reallocations applied
  /// NOTE: Auto-reallocation is currently disabled - returns current budget only
  Future<Budget> reallocateBudget(String monthId) async {
    try {
      debugPrint(
          '🔄 BudgetReallocationService: Starting budget reallocation for $monthId');

      // Validate input
      if (!_isValidMonthId(monthId)) {
        throw ReallocationException(
          'Invalid month ID format: $monthId',
          code: 'INVALID_MONTH_ID',
        );
      }

      // Get current budget
      final currentBudget = await _budgetRepository.getBudget(monthId);
      if (currentBudget == null) {
        throw ReallocationException(
          'Budget not found for month $monthId',
          code: 'BUDGET_NOT_FOUND',
        );
      }

      // Check if user has enabled auto budget feature
      if (!_settingsService.autoBudget) {
        debugPrint(
            '🔄 Auto budget feature is disabled, returning current budget');
        return currentBudget;
      }

      // TODO: Budget reallocation is temporarily disabled until expense detection is complete
      // This ensures we focus on expense detection first before implementing budget adjustments
      debugPrint(
          '🔄 BudgetReallocationService: Auto-reallocation temporarily disabled, returning current budget');
      return currentBudget;

      // COMMENTED OUT: Original reallocation logic
      // // Get analysis data
      // final reallocationRequest =
      //     await _prepareAnalysisRequest(monthId, currentBudget);

      // // Get AI recommendations
      // final recommendations = await _getAIRecommendations(reallocationRequest);

      // // Apply recommendations if they meet criteria
      // final optimizedBudget = await _applyRecommendations(
      //   currentBudget,
      //   recommendations,
      //   monthId,
      // );

      // debugPrint(
      //     '✅ BudgetReallocationService: Reallocation completed successfully');
      // return optimizedBudget;
    } catch (e, stackTrace) {
      debugPrint('❌ BudgetReallocationService: Reallocation failed: $e');
      final error = AppError.from(e, stackTrace);
      error.log();
      rethrow;
    }
  }

  /// Get reallocation recommendations without applying them
  Future<BudgetReallocationResponse> getReallocationRecommendations(
      String monthId) async {
    try {
      debugPrint(
          '🔍 BudgetReallocationService: Getting recommendations for $monthId');

      final currentBudget = await _budgetRepository.getBudget(monthId);
      if (currentBudget == null) {
        throw ReallocationException(
          'Budget not found for month $monthId',
          code: 'BUDGET_NOT_FOUND',
        );
      }

      final request = await _prepareAnalysisRequest(monthId, currentBudget);
      return await _getAIRecommendations(request);
    } catch (e, stackTrace) {
      debugPrint(
          '❌ BudgetReallocationService: Failed to get recommendations: $e');
      final error = AppError.from(e, stackTrace);
      error.log();
      rethrow;
    }
  }

  /// Prepare analysis request with expense data and budget state
  Future<Map<String, dynamic>> _prepareAnalysisRequest(
    String monthId,
    Budget currentBudget,
  ) async {
    debugPrint('📊 Preparing analysis request for $monthId');

    // Parse month ID
    final monthParts = monthId.split('-');
    final year = int.parse(monthParts[0]);
    final month = int.parse(monthParts[1]);

    // Get all expenses and filter by date range (last 3 months for pattern analysis)
    final endDate = DateTime(year, month + 1, 0); // Last day of target month
    final startDate = DateTime(year, month - 2, 1); // 3 months back

    final allExpenses = await _expensesRepository.getExpenses();
    final recentExpenses = allExpenses
        .where((expense) =>
            expense.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    // Convert expenses to API format
    final recentExpenseData = recentExpenses
        .map((expense) => {
              'amount': expense.amount,
              'category_id': expense.category.id,
              'category_name': expense.category.id,
              'date': expense.date.toIso8601String(),
              'currency': expense.currency,
              'description': expense.description,
            })
        .toList();

    // Calculate category utilization
    final categoryUtilization = _calculateCategoryUtilization(
      currentBudget,
      recentExpenses
          .where((e) => e.date.year == year && e.date.month == month)
          .toList(),
    );

    // Create budget data for API
    final budgetData = {
      'total_budget': currentBudget.total,
      'total_remaining': currentBudget.left,
      'categories': currentBudget.categories.map((k, v) => MapEntry(k, {
            'allocated': v.budget,
            'remaining': v.left,
          })),
      'savings': currentBudget.saving,
      'currency': currentBudget.currency,
    };

    return {
      'current_budget': budgetData,
      'recent_expenses': recentExpenseData,
      'category_utilization': categoryUtilization,
      'user_preferences': {
        'riskTolerance': 'medium', // Could be made configurable
        'preserveEmergencyFund': true,
        'minimumCategoryBuffer': 0.05, // 5% buffer
      },
    };
  }

  /// Get AI recommendations using FastAPI backend with spending behavior insights
  Future<BudgetReallocationResponse> _getAIRecommendations(
    Map<String, dynamic> request,
  ) async {
    debugPrint('🤖 Getting AI recommendations from FastAPI backend');

    try {
      // Ensure API client is initialized
      await _apiClient.initialize();

      // Get spending behavior insights to enhance recommendations
      final behaviorInsights = await _getSpendingBehaviorInsights();

      // Add behavior insights to request
      final enhancedRequest = {
        ...request,
        'spending_behavior_insights': behaviorInsights,
      };

      final response = await _apiClient.analyzeBudgetReallocation(
        currentBudget:
            enhancedRequest['current_budget'] as Map<String, dynamic>,
        recentExpenses:
            enhancedRequest['recent_expenses'] as List<Map<String, dynamic>>,
        categoryUtilization:
            enhancedRequest['category_utilization'] as Map<String, double>,
        userPreferences:
            enhancedRequest['user_preferences'] as Map<String, dynamic>?,
      );

      return BudgetReallocationResponse.fromJson(response);
    } catch (e) {
      debugPrint('❌ Failed to get AI recommendations: $e');
      throw ReallocationException(
        'AI analysis failed: $e',
        code: 'AI_ANALYSIS_FAILED',
        originalError: e,
      );
    }
  }

  /// Get spending behavior insights for enhanced budget reallocation
  Future<Map<String, dynamic>> _getSpendingBehaviorInsights() async {
    // TODO: This functionality is temporarily disabled because the underlying
    // spending behavior analysis service is being refactored. It will be
    // re-enabled once the service and its models are finalized.
    debugPrint(
        '⚠️ Spending behavior insights are temporarily disabled. Returning empty data.');
    return {
      'reallocations': [],
      'savings_opportunities': [],
      'potential_monthly_savings': 0.0,
    };
  }

  /// Apply AI recommendations to create optimized budget
  Future<Budget> _applyRecommendations(
    Budget currentBudget,
    BudgetReallocationResponse recommendations,
    String monthId,
  ) async {
    debugPrint(
        '🔧 Applying ${recommendations.recommendations.length} recommendations');

    // Check if reallocation is needed and meets confidence threshold
    if (!recommendations.reallocationNeeded ||
        recommendations.confidenceScore < 0.7) {
      debugPrint('📊 Reallocation not recommended or confidence too low');
      return currentBudget;
    }

    // Filter recommendations by priority and impact
    final applicableRecommendations = recommendations.recommendations
        .where((rec) => rec.impactScore > 0.3 && rec.priority != 'low')
        .toList();

    if (applicableRecommendations.isEmpty) {
      debugPrint('📊 No applicable recommendations found');
      return currentBudget;
    }

    // Create new category budgets with reallocations applied
    final newCategories =
        Map<String, CategoryBudget>.from(currentBudget.categories);
    double totalReallocated = 0;

    for (final recommendation in applicableRecommendations) {
      final fromCat = newCategories[recommendation.fromCategory];
      final toCat = newCategories[recommendation.toCategory];

      if (fromCat == null || toCat == null) {
        debugPrint('⚠️ Skipping recommendation for unknown categories');
        continue;
      }

      // Validate reallocation amount
      final maxTransfer = fromCat.left * 0.8; // Max 80% of remaining
      final transferAmount = recommendation.amount.clamp(0, maxTransfer);

      if (transferAmount < 5.0) {
        debugPrint(
            '⚠️ Skipping small transfer: ${transferAmount.toStringAsFixed(2)}');
        continue;
      }

      // Apply reallocation
      newCategories[recommendation.fromCategory] = CategoryBudget(
        budget: fromCat.budget - transferAmount,
        left: fromCat.left - transferAmount,
      );

      newCategories[recommendation.toCategory] = CategoryBudget(
        budget: toCat.budget + transferAmount,
        left: toCat.left + transferAmount,
      );

      totalReallocated += transferAmount;
      debugPrint(
          '💸 Reallocated ${transferAmount.toStringAsFixed(2)} from ${recommendation.fromCategory} to ${recommendation.toCategory}');
    }

    // Create optimized budget
    final optimizedBudget = Budget(
      total: currentBudget.total,
      left: currentBudget.left,
      categories: newCategories,
      saving: currentBudget.saving,
      currency: currentBudget.currency,
    );

    // Save optimized budget
    await _budgetRepository.setBudget(monthId, optimizedBudget);

    debugPrint(
        '✅ Applied reallocations totaling ${totalReallocated.toStringAsFixed(2)} ${currentBudget.currency}');
    return optimizedBudget;
  }

  /// Calculate category utilization rates
  Map<String, double> _calculateCategoryUtilization(
    Budget budget,
    List<Expense> monthExpenses,
  ) {
    final utilization = <String, double>{};

    for (final entry in budget.categories.entries) {
      final categoryId = entry.key;
      final categoryBudget = entry.value;

      if (categoryBudget.budget <= 0) {
        utilization[categoryId] = 0.0;
        continue;
      }

      final categoryExpenses = monthExpenses
          .where((expense) => expense.category.id == categoryId)
          .fold(0.0, (sum, expense) => sum + expense.amount);

      utilization[categoryId] =
          (categoryExpenses / categoryBudget.budget).clamp(0.0, 2.0);
    }

    return utilization;
  }

  /// Validate month ID format
  bool _isValidMonthId(String monthId) {
    final regex = RegExp(r'^\d{4}-\d{2}$');
    if (!regex.hasMatch(monthId)) return false;

    final parts = monthId.split('-');
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);

    return year != null &&
        month != null &&
        year >= 2020 &&
        year <= 2100 &&
        month >= 1 &&
        month <= 12;
  }

  /// Get category name from ID for display purposes
  String getCategoryName(String categoryId) {
    try {
      final category = entities.CategoryExtension.fromId(categoryId);
      return category?.id ?? categoryId;
    } catch (e) {
      return categoryId;
    }
  }
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
