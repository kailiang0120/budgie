import 'package:flutter/foundation.dart';
import '../../domain/repositories/user_behavior_repository.dart';
import '../entities/budget.dart';
import '../entities/expense.dart';
import '../entities/category.dart' as entities;
import '../repositories/budget_repository.dart';
import '../repositories/expenses_repository.dart';
import '../repositories/goals_repository.dart';
import '../repositories/analysis_repository.dart';
import '../../data/models/budget_reallocation_models.dart';
import '../../data/models/spending_behavior_models.dart';
import '../../data/infrastructure/errors/app_error.dart';
import '../../data/infrastructure/services/gemini_api_client.dart';
import '../../data/infrastructure/services/settings_service.dart';
import 'dart:convert'; // Added for JsonEncoder

/// Service for intelligent budget reallocation using AI analysis.
///
/// This service analyzes spending patterns and budget utilization to provide
/// smart reallocation recommendations and automatically optimize budget distribution.
class BudgetReallocationService {
  final BudgetRepository _budgetRepository;
  final ExpensesRepository _expensesRepository;
  final UserBehaviorRepository _userBehaviorRepository;
  final GoalsRepository _goalsRepository;
  final AnalysisRepository _analysisRepository;
  final GeminiApiClient _apiClient;
  final SettingsService _settingsService;

  BudgetReallocationService({
    required BudgetRepository budgetRepository,
    required ExpensesRepository expensesRepository,
    required UserBehaviorRepository userBehaviorRepository,
    required GoalsRepository goalsRepository,
    required AnalysisRepository analysisRepository,
    required GeminiApiClient geminiApiClient,
    required SettingsService settingsService,
  })  : _budgetRepository = budgetRepository,
        _expensesRepository = expensesRepository,
        _userBehaviorRepository = userBehaviorRepository,
        _goalsRepository = goalsRepository,
        _analysisRepository = analysisRepository,
        _apiClient = geminiApiClient,
        _settingsService = settingsService;

  /// Analyze and reallocate budget for the given month.
  /// Returns the updated budget with AI-recommended reallocations applied.
  Future<Budget> reallocateBudget(String userId, String monthId) async {
    try {
      debugPrint(
          '🔄 BudgetReallocationService: Starting budget reallocation for $monthId');

      if (!_isValidMonthId(monthId)) {
        throw ReallocationException('Invalid month ID format: $monthId');
      }

      final currentBudget = await _budgetRepository.getBudget(monthId);
      if (currentBudget == null) {
        throw ReallocationException('Budget not found for month $monthId');
      }

      if (!_settingsService.autoBudget) {
        debugPrint(
            '🔄 Auto budget feature is disabled, returning current budget');
        return currentBudget;
      }

      final reallocationRequest =
          await _prepareAnalysisRequest(userId, monthId, currentBudget);

      final recommendations = await _getAIRecommendations(reallocationRequest);

      final optimizedBudget = await _applyRecommendations(
        currentBudget,
        recommendations,
        monthId,
      );

      debugPrint(
          '✅ BudgetReallocationService: Reallocation completed successfully');
      return optimizedBudget;
    } catch (e, stackTrace) {
      debugPrint('❌ BudgetReallocationService: Reallocation failed: $e');
      final error = AppError.from(e, stackTrace);
      error.log();
      rethrow;
    }
  }

  /// Get reallocation recommendations without applying them.
  Future<BudgetReallocationResponse> getReallocationRecommendations(
    String userId,
    String monthId,
  ) async {
    try {
      debugPrint(
          '🔍 BudgetReallocationService: Getting recommendations for $monthId');

      final currentBudget = await _budgetRepository.getBudget(monthId);
      if (currentBudget == null) {
        throw ReallocationException('Budget not found for month $monthId');
      }

      final request =
          await _prepareAnalysisRequest(userId, monthId, currentBudget);
      return await _getAIRecommendations(request);
    } catch (e, stackTrace) {
      debugPrint(
          '❌ BudgetReallocationService: Failed to get recommendations: $e');
      final error = AppError.from(e, stackTrace);
      error.log();
      rethrow;
    }
  }

  /// Prepare analysis request with budget state, user profile, and recent expenses.
  Future<BudgetReallocationRequest> _prepareAnalysisRequest(
    String userId,
    String monthId,
    Budget currentBudget,
  ) async {
    debugPrint('📊 Preparing analysis request for $monthId');

    // 1. Fetch user behavior profile
    final userProfile =
        await _userBehaviorRepository.getUserBehaviorProfile(userId);
    if (userProfile == null) {
      throw ReallocationException(
        'User behavior profile not found for user $userId',
        code: 'PROFILE_NOT_FOUND',
      );
    }

    // 2. Fetch latest spending analysis
    final spendingAnalysis =
        await _analysisRepository.getLatestAnalysis(userId);
    if (spendingAnalysis == null) {
      debugPrint(
          '⚠️ No spending analysis found for user $userId. Using minimal context.');
    } else {
      debugPrint(
          '✅ Found spending analysis from ${spendingAnalysis.metadata['analysis_timestamp']}');
      debugPrint(
          '📊 Summary length: ${spendingAnalysis.summary.length} characters');
      debugPrint('📊 AI Model used: ${spendingAnalysis.metadata['ai_model']}');
    }

    // 3. Fetch active financial goals
    final activeGoals = await _goalsRepository.getActiveGoals();
    debugPrint('🎯 Found ${activeGoals.length} active financial goals');

    // 4. Fetch historical expenses for the last 10 days
    final allExpenses = await _expensesRepository.getExpenses();
    final toDate = DateTime.now();
    final fromDate = toDate.subtract(const Duration(days: 10));
    final recentExpenses = allExpenses
        .where((e) => e.date.isAfter(fromDate) && e.date.isBefore(toDate))
        .toList();

    debugPrint(
        '💰 Found ${recentExpenses.length} recent expenses (last 10 days)');
    if (recentExpenses.isNotEmpty) {
      final totalAmount = recentExpenses.fold(0.0, (sum, e) => sum + e.amount);
      debugPrint(
          '💰 Total recent spending: ${totalAmount.toStringAsFixed(2)} ${currentBudget.currency}');
    }

    // 5. Create the request model
    final request = BudgetReallocationRequest(
      userProfile: ReallocationUserProfileData.fromProfile(userProfile),
      currentBudget: ReallocationBudgetData.fromBudget(currentBudget),
      recentExpenses: recentExpenses
          .map((e) => ReallocationExpenseData.fromExpense(e))
          .toList(),
      goals: activeGoals.map((g) => ReallocationGoalData.fromGoal(g)).toList(),
      spendingAnalysis:
          spendingAnalysis ?? _createEmptySpendingAnalysis(userId),
    );

    debugPrint('📊 Request prepared with:');
    debugPrint('  - User profile: ${userProfile.userId}');
    debugPrint(
        '  - Budget total: ${currentBudget.total} ${currentBudget.currency}');
    debugPrint('  - Recent expenses: ${recentExpenses.length}');
    debugPrint('  - Goals: ${activeGoals.length}');
    debugPrint('  - Analysis available: ${spendingAnalysis != null}');

    return request;
  }

  /// Create a minimal spending analysis object when none is available
  SpendingBehaviorAnalysisResult _createEmptySpendingAnalysis(String userId) {
    debugPrint('🔄 Creating empty spending analysis for user $userId');

    // Create a minimal metadata map directly
    final metadataMap = {
      'analysis_timestamp': DateTime.now().toIso8601String(),
      'ai_model': 'placeholder',
      'version': '1.0.0',
      'user_id': userId,
      'analysis_type': 'empty_placeholder',
    };

    try {
      // Create minimal simplified analysis
      final result = SpendingBehaviorAnalysisResult(
        categoryInsights: [], // Empty category insights
        keyInsights: ['No previous analysis available'],
        actionableRecommendations: [
          'Complete spending behavior analysis first'
        ],
        summary:
            'No previous spending behavior analysis available for this user.',
        metadata: metadataMap,
      );

      debugPrint('🔄 Empty analysis created successfully');
      return result;
    } catch (e) {
      debugPrint('❌ Failed to create empty analysis: $e');
      // Fallback - this should not happen but provides safety
      throw ReallocationException(
        'Failed to create placeholder spending analysis: $e',
        code: 'PLACEHOLDER_CREATION_FAILED',
        originalError: e,
      );
    }
  }

  /// Get AI recommendations using the backend API.
  Future<BudgetReallocationResponse> _getAIRecommendations(
    BudgetReallocationRequest request,
  ) async {
    debugPrint('🤖 Getting AI recommendations from API backend');

    try {
      await _apiClient.initialize();

      debugPrint('🤖 Sending request to budget reallocation API...');
      debugPrint('🤖 Request contains:');
      debugPrint(
          '  - Analysis summary: ${request.spendingAnalysis.summary.length} chars');
      debugPrint(
          '  - Budget categories: ${request.currentBudget.categories.length}');
      debugPrint('  - Recent expenses: ${request.recentExpenses.length}');
      debugPrint('  - Goals: ${request.goals.length}');

      final response = await _apiClient.analyzeBudgetReallocation(
        request: request,
      );

      debugPrint('🤖 API response received');
      debugPrint('🤖 Response keys: ${response.keys.toList()}');

      final result = BudgetReallocationResponse.fromJson(response);

      debugPrint(
          '🤖 Parsed ${result.suggestions.length} reallocation suggestions');
      if (result.metadata != null) {
        debugPrint('🤖 Analysis ID: ${result.metadata!.analysisId}');
        debugPrint('🤖 Model version: ${result.metadata!.modelVersion}');
      }

      // Log suggestions summary
      if (result.suggestions.isNotEmpty) {
        final totalReallocation =
            result.suggestions.fold(0.0, (sum, s) => sum + s.amount);
        debugPrint(
            '🤖 Total suggested reallocation: ${totalReallocation.toStringAsFixed(2)}');

        for (final suggestion in result.suggestions) {
          debugPrint(
              '🤖 ${suggestion.fromCategory} → ${suggestion.toCategory}: ${suggestion.amount} (${suggestion.criticality})');
        }
      }

      return result;
    } catch (e) {
      debugPrint('❌ Failed to get AI recommendations: $e');
      throw ReallocationException(
        'AI analysis failed: $e',
        code: 'AI_ANALYSIS_FAILED',
        originalError: e,
      );
    }
  }

  /// Apply AI recommendations to create an optimized budget.
  Future<Budget> _applyRecommendations(
    Budget currentBudget,
    BudgetReallocationResponse response,
    String monthId,
  ) async {
    debugPrint('🔧 Applying ${response.suggestions.length} recommendations');

    if (response.suggestions.isEmpty) {
      debugPrint('📊 No applicable recommendations found');
      return currentBudget;
    }

    // Filter to only process High priority suggestions
    final highPrioritySuggestions = response.suggestions
        .where((suggestion) => suggestion.criticality.toLowerCase() == 'high')
        .toList();

    debugPrint(
        '🔧 High priority suggestions: ${highPrioritySuggestions.length}');

    if (highPrioritySuggestions.isEmpty) {
      debugPrint('📊 No high priority recommendations to apply');
      return currentBudget;
    }

    final newCategories =
        Map<String, CategoryBudget>.from(currentBudget.categories);
    double totalReallocated = 0;

    for (final recommendation in highPrioritySuggestions) {
      final transferAmount = recommendation.amount;

      debugPrint(
          '🔧 Processing: ${recommendation.fromCategory} → ${recommendation.toCategory}: ${transferAmount.toStringAsFixed(2)} (${recommendation.criticality})');

      if (transferAmount <= 0) {
        debugPrint(
            '⚠️ Skipping non-positive transfer: ${transferAmount.toStringAsFixed(2)}');
        continue;
      }

      // Handle transfers to/from savings
      if (recommendation.toCategory.toLowerCase() == 'savings' ||
          recommendation.toCategory.toLowerCase() == 'saving') {
        // Transfer from category to savings (unallocate budget)
        final fromCat = newCategories[recommendation.fromCategory];
        if (fromCat != null) {
          // Validate: Do not allow transfer to exceed available amount in category
          if (fromCat.left < transferAmount) {
            debugPrint(
                '⚠️ Transfer amount ${transferAmount.toStringAsFixed(2)} exceeds available ${fromCat.left.toStringAsFixed(2)} in ${recommendation.fromCategory}. Skipping.');
            continue;
          }

          // Reduce budget allocation (this moves money back to savings)
          final newBudgetAmount =
              (fromCat.budget - transferAmount).clamp(0.0, double.infinity);

          newCategories[recommendation.fromCategory] = CategoryBudget(
            budget: newBudgetAmount,
            left: fromCat.left, // Keep remaining amount unchanged for now
          );

          debugPrint(
              '💰 Unallocated ${transferAmount.toStringAsFixed(2)} from ${recommendation.fromCategory} to savings');
        } else {
          debugPrint(
              '⚠️ Category ${recommendation.fromCategory} not found in budget');
        }
      } else if (recommendation.fromCategory.toLowerCase() == 'savings' ||
          recommendation.fromCategory.toLowerCase() == 'saving') {
        // Transfer from savings to category (allocate budget)
        final toCat = newCategories[recommendation.toCategory];
        if (toCat != null) {
          // Check if we have enough savings to allocate
          final currentSaving = currentBudget.saving;
          if (currentSaving < transferAmount) {
            debugPrint(
                '⚠️ Transfer amount ${transferAmount.toStringAsFixed(2)} exceeds available savings ${currentSaving.toStringAsFixed(2)}. Skipping.');
            continue;
          }

          newCategories[recommendation.toCategory] = CategoryBudget(
            budget: toCat.budget + transferAmount,
            left: toCat.left + transferAmount, // Increase available amount
          );

          debugPrint(
              '💰 Allocated ${transferAmount.toStringAsFixed(2)} from savings to ${recommendation.toCategory}');
        } else {
          debugPrint(
              '⚠️ Category ${recommendation.toCategory} not found in budget');
        }
      } else {
        // Transfer between categories
        final fromCat = newCategories[recommendation.fromCategory];
        final toCat = newCategories[recommendation.toCategory];

        if (fromCat != null && toCat != null) {
          // Validate: Do not allow transfer to exceed available amount in category
          if (fromCat.left < transferAmount) {
            debugPrint(
                '⚠️ Transfer amount ${transferAmount.toStringAsFixed(2)} exceeds available ${fromCat.left.toStringAsFixed(2)} in ${recommendation.fromCategory}. Skipping.');
            continue;
          }

          // Ensure we don't reduce budget below zero
          final actualTransferAmount =
              transferAmount.clamp(0.0, fromCat.budget);

          newCategories[recommendation.fromCategory] = CategoryBudget(
            budget: fromCat.budget - actualTransferAmount,
            left:
                fromCat.left - actualTransferAmount, // Reduce available amount
          );

          newCategories[recommendation.toCategory] = CategoryBudget(
            budget: toCat.budget + actualTransferAmount,
            left:
                toCat.left + actualTransferAmount, // Increase available amount
          );

          debugPrint(
              '💸 Transferred ${actualTransferAmount.toStringAsFixed(2)} from ${recommendation.fromCategory} to ${recommendation.toCategory}');
        } else {
          debugPrint(
              '⚠️ Skipping recommendation for unknown categories: ${recommendation.fromCategory} -> ${recommendation.toCategory}');
          continue;
        }
      }

      totalReallocated += transferAmount;
    }

    if (totalReallocated == 0) {
      debugPrint('🔧 No reallocations applied');
      return currentBudget;
    }

    // Calculate new saving amount (total budget - sum of category budgets)
    final totalCategoryBudgets = newCategories.values
        .fold(0.0, (sum, category) => sum + category.budget);
    final newSaving = currentBudget.total - totalCategoryBudgets;

    final optimizedBudget = currentBudget.copyWith(
      categories: newCategories,
      saving: newSaving,
    );

    // Save the updated budget to ensure persistence
    await _budgetRepository.setBudget(monthId, optimizedBudget);

    debugPrint(
        '✅ Applied reallocations totaling ${totalReallocated.toStringAsFixed(2)} ${currentBudget.currency}');
    debugPrint(
        '💰 Savings changed from ${currentBudget.saving.toStringAsFixed(2)} to ${newSaving.toStringAsFixed(2)} ${currentBudget.currency}');

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
