import 'package:flutter/foundation.dart';
import '../../domain/services/spending_behavior_analysis_service.dart';
import '../../domain/services/budget_reallocation_service.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/user_behavior_repository.dart';
import '../../domain/repositories/goals_repository.dart';
import '../../domain/repositories/analysis_repository.dart';
import '../../domain/usecase/budget/reallocate_budget_usecase.dart';
import '../../data/models/spending_behavior_models.dart';
import '../../data/models/budget_reallocation_models.dart';
import '../../data/infrastructure/services/settings_service.dart';
import '../../data/infrastructure/services/gemini_api_client.dart';

/// ViewModel for managing AI analysis operations
/// Handles both spending behavior analysis and budget reallocation
class AnalysisViewModel extends ChangeNotifier {
  // Services
  final SpendingBehaviorAnalysisService _spendingBehaviorService;
  final BudgetReallocationService _budgetReallocationService;
  final ExpensesRepository _expensesRepository;
  final BudgetRepository _budgetRepository;
  final UserBehaviorRepository _userBehaviorRepository;
  final GoalsRepository _goalsRepository;
  final AnalysisRepository _analysisRepository;
  final GeminiApiClient _apiClient;
  final ReallocateBudgetUseCase _reallocateBudgetUseCase;

  // State management
  bool _isAnalyzing = false;
  bool _isReallocating = false;
  bool _isCheckingHealth = false;
  String? _errorMessage;

  // Analysis results
  SpendingBehaviorAnalysisResult? _spendingAnalysisResult;
  BudgetReallocationResponse? _reallocationResult;

  // Request/Response data for UI display
  SpendingBehaviorAnalysisRequest? _lastSpendingRequest;
  BudgetReallocationRequest? _lastReallocationRequest;

  AnalysisViewModel({
    required SpendingBehaviorAnalysisService spendingBehaviorService,
    required BudgetReallocationService budgetReallocationService,
    required ExpensesRepository expensesRepository,
    required BudgetRepository budgetRepository,
    required UserBehaviorRepository userBehaviorRepository,
    required GoalsRepository goalsRepository,
    required AnalysisRepository analysisRepository,
    required SettingsService settingsService,
    required GeminiApiClient apiClient,
    required ReallocateBudgetUseCase reallocateBudgetUseCase,
  })  : _spendingBehaviorService = spendingBehaviorService,
        _budgetReallocationService = budgetReallocationService,
        _expensesRepository = expensesRepository,
        _budgetRepository = budgetRepository,
        _userBehaviorRepository = userBehaviorRepository,
        _goalsRepository = goalsRepository,
        _analysisRepository = analysisRepository,
        _apiClient = apiClient,
        _reallocateBudgetUseCase = reallocateBudgetUseCase;

  // Getters
  bool get isAnalyzing => _isAnalyzing;
  bool get isReallocating => _isReallocating;
  bool get isCheckingHealth => _isCheckingHealth;
  bool get isLoading => _isAnalyzing || _isReallocating || _isCheckingHealth;
  String? get errorMessage => _errorMessage;

  SpendingBehaviorAnalysisResult? get spendingAnalysisResult =>
      _spendingAnalysisResult;
  BudgetReallocationResponse? get reallocationResult => _reallocationResult;

  SpendingBehaviorAnalysisRequest? get lastSpendingRequest =>
      _lastSpendingRequest;
  BudgetReallocationRequest? get lastReallocationRequest =>
      _lastReallocationRequest;

  // A constant ID for the guest user
  static const String _guestUserId = 'guest_user';

  /// Perform spending behavior analysis
  Future<void> analyzeSpendingBehavior({
    required DateTime selectedDate,
  }) async {
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint(
            '📊 AnalysisViewModel: Starting spending behavior analysis...');
      }

      // Use a constant guest user ID
      const userId = _guestUserId;

      // Get user behavior profile
      final userProfile =
          await _userBehaviorRepository.getUserBehaviorProfile(userId);
      if (userProfile == null) {
        throw Exception(
            'User behavior profile not found. Please build the profile in Settings');
      }

      // Get historical expenses (last 30 days)
      final allExpenses = await _expensesRepository.getExpenses();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final historicalExpenses = allExpenses
          .where((expense) => expense.date.isAfter(cutoffDate))
          .toList();

      if (historicalExpenses.length < 10) {
        throw Exception(
            'Not enough expense data for analysis. Please add at least 10 expenses in the last 30 days.');
      }

      // Get current budget
      final monthId =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}';
      final currentBudget = await _budgetRepository.getBudget(monthId);
      if (currentBudget == null) {
        throw Exception(
            'No budget found for the selected month. Please set up a budget first.');
      }

      // Get financial goals
      final goals = await _goalsRepository.getActiveGoals();

      if (kDebugMode) {
        debugPrint(
            '📊 AnalysisViewModel: Data collected - ${historicalExpenses.length} expenses, ${goals.length} goals');
      }

      // Perform analysis
      final result = await _spendingBehaviorService.analyzeSpendingBehavior(
        historicalExpenses: historicalExpenses,
        currentBudget: currentBudget,
        userProfile: userProfile,
        goals: goals,
      );

      // Store results
      _spendingAnalysisResult = result;

      // Save the analysis result to local database immediately
      if (kDebugMode) {
        debugPrint(
            '💾 AnalysisViewModel: Saving analysis result to local database...');
      }
      try {
        await _analysisRepository.saveAnalysis(userId, result);
        if (kDebugMode) {
          debugPrint('✅ AnalysisViewModel: Analysis result saved successfully');
        }
      } catch (saveError) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ AnalysisViewModel: Failed to save analysis result: $saveError');
        }
        // Continue execution even if save fails - don't break the user flow
      }

      // Create request object for display purposes
      _lastSpendingRequest = SpendingBehaviorAnalysisRequest(
        historicalExpenses: historicalExpenses
            .map((e) => AnalysisExpenseData.fromExpense(e))
            .toList(),
        currentBudget: AnalysisBudgetData.fromBudget(currentBudget),
        userProfile: AnalysisUserProfileData.fromProfile(userProfile),
        financialGoals:
            goals.map((g) => AnalysisFinancialGoalData.fromGoal(g)).toList(),
        analysisDate: DateTime.now(),
      );

      if (kDebugMode) {
        debugPrint(
            '📊 AnalysisViewModel: Spending behavior analysis completed successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ AnalysisViewModel: Spending behavior analysis error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      _errorMessage = e.toString();
      _spendingAnalysisResult = null;
      _lastSpendingRequest = null;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  /// Perform budget reallocation analysis
  Future<void> analyzeBudgetReallocation({
    required DateTime selectedDate,
  }) async {
    _isReallocating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint(
            '📊 AnalysisViewModel: Starting budget reallocation analysis...');
      }

      // Use a constant guest user ID
      const userId = _guestUserId;

      // Get current budget
      final monthId =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}';
      final currentBudget = await _budgetRepository.getBudget(monthId);
      if (currentBudget == null) {
        throw Exception(
            'No budget found for the selected month. Please set up a budget first.');
      }

      // Perform budget reallocation analysis
      final result =
          await _budgetReallocationService.getReallocationRecommendations(
        userId,
        monthId,
      );

      // Store results
      _reallocationResult = result;

      if (kDebugMode) {
        debugPrint(
            '📊 AnalysisViewModel: Budget reallocation analysis completed successfully');
        debugPrint(
            '📊 Found ${result.suggestions.length} reallocation suggestions');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
            '❌ AnalysisViewModel: Budget reallocation analysis error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      _errorMessage = e.toString();
      _reallocationResult = null;
    } finally {
      _isReallocating = false;
      notifyListeners();
    }
  }

  /// Check API health
  Future<void> checkApiHealth() async {
    _isCheckingHealth = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint('🔍 AnalysisViewModel: Checking API health...');
      }

      final healthStatus = await _apiClient.checkServicesHealth();
      if (kDebugMode) {
        debugPrint('✅ AnalysisViewModel: API health check completed');
        debugPrint('📊 Health status: $healthStatus');
      }

      // You can process the health status here if needed
      // For now, we'll just log it
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ AnalysisViewModel: API health check error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      _errorMessage = e.toString();
    } finally {
      _isCheckingHealth = false;
      notifyListeners();
    }
  }

  /// Apply budget reallocation recommendations
  Future<bool> applyBudgetRecommendations({
    required DateTime selectedDate,
  }) async {
    if (_reallocationResult == null ||
        _reallocationResult!.suggestions.isEmpty) {
      _errorMessage = 'No reallocation suggestions available to apply';
      notifyListeners();
      return false;
    }

    _isReallocating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint(
            '📊 AnalysisViewModel: Applying budget reallocation recommendations...');
      }

      // Get current budget
      final monthId =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}';
      final currentBudget = await _budgetRepository.getBudget(monthId);
      if (currentBudget == null) {
        throw Exception(
            'No budget found for the selected month. Cannot apply recommendations.');
      }

      // Apply recommendations using the use case
      final updatedBudget = await _reallocateBudgetUseCase.execute(
        monthId,
        _reallocationResult!.suggestions,
      );

      if (kDebugMode) {
        debugPrint(
            '✅ AnalysisViewModel: Budget recommendations applied successfully');
        debugPrint(
            '📊 Updated budget total: ${updatedBudget.total} ${updatedBudget.currency}');
      }
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
            '❌ AnalysisViewModel: Failed to apply budget recommendations: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      _errorMessage = 'Failed to apply recommendations: ${e.toString()}';
      return false;
    } finally {
      _isReallocating = false;
      notifyListeners();
    }
  }

  /// Get formatted request data for display
  String getFormattedSpendingRequest() {
    if (_lastSpendingRequest == null) return 'No request data available';

    final buffer = StringBuffer();
    buffer.writeln('=== SPENDING BEHAVIOR ANALYSIS REQUEST ===');
    buffer.writeln('Analysis Date: ${_lastSpendingRequest!.analysisDate}');
    buffer.writeln(
        'Historical Expenses: ${_lastSpendingRequest!.historicalExpenses.length} items');
    buffer.writeln(
        'Budget Total: ${_lastSpendingRequest!.currentBudget.total} ${_lastSpendingRequest!.currentBudget.currency}');
    buffer.writeln('User Profile: ${_lastSpendingRequest!.userProfile.userId}');
    buffer.writeln(
        'Financial Goals: ${_lastSpendingRequest!.financialGoals?.length ?? 0} items');
    buffer.writeln();

    // Add sample expenses
    if (_lastSpendingRequest!.historicalExpenses.isNotEmpty) {
      buffer.writeln('Sample Expenses:');
      for (int i = 0;
          i < 3 && i < _lastSpendingRequest!.historicalExpenses.length;
          i++) {
        final expense = _lastSpendingRequest!.historicalExpenses[i];
        buffer.writeln(
            '- ${expense.description}: ${expense.amount} ${expense.currency} (${expense.categoryName})');
      }
    }

    return buffer.toString();
  }

  /// Get formatted response data for display
  String getFormattedSpendingResponse() {
    if (_spendingAnalysisResult == null) return 'No response data available';

    final buffer = StringBuffer();
    buffer.writeln('=== SPENDING BEHAVIOR ANALYSIS RESPONSE ===');
    buffer.writeln('Analysis Type: Simplified Structure');
    buffer.writeln();

    // Display summary
    buffer.writeln('SUMMARY:');
    buffer.writeln(_spendingAnalysisResult!.summary);
    buffer.writeln();

    // Display key insights
    buffer.writeln('KEY INSIGHTS:');
    for (final insight in _spendingAnalysisResult!.keyInsights) {
      buffer.writeln('• $insight');
    }
    buffer.writeln();

    // Display actionable recommendations
    buffer.writeln('ACTIONABLE RECOMMENDATIONS:');
    for (final recommendation
        in _spendingAnalysisResult!.actionableRecommendations) {
      buffer.writeln('• $recommendation');
    }
    buffer.writeln();

    // Display category insights
    buffer.writeln('CATEGORY INSIGHTS:');
    for (final categoryInsight in _spendingAnalysisResult!.categoryInsights) {
      buffer.writeln('${categoryInsight.categoryName}:');
      buffer.writeln('  Status: ${categoryInsight.status}');
      buffer.writeln(
          '  Spent: ${categoryInsight.spentAmount} / Budget: ${categoryInsight.budgetAmount}');
      buffer.writeln(
          '  Utilization: ${(categoryInsight.utilizationRate * 100).toStringAsFixed(1)}%');
      buffer.writeln('  Insight: ${categoryInsight.insight}');
      if (categoryInsight.recommendation != null) {
        buffer.writeln('  Recommendation: ${categoryInsight.recommendation}');
      }
      buffer.writeln();
    }

    // Display metadata if available
    if (_spendingAnalysisResult!.metadata.isNotEmpty) {
      buffer.writeln('METADATA:');
      _spendingAnalysisResult!.metadata.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    return buffer.toString();
  }

  /// Get formatted budget reallocation response data for display
  String getFormattedReallocationResponse() {
    if (_reallocationResult == null) return 'No response data available';

    final buffer = StringBuffer();
    buffer.writeln('=== BUDGET REALLOCATION RESPONSE ===');
    if (_reallocationResult!.metadata != null) {
      buffer
          .writeln('Analysis ID: ${_reallocationResult!.metadata!.analysisId}');
      buffer.writeln(
          'Model Version: ${_reallocationResult!.metadata!.modelVersion}');
      buffer.writeln(
          'Generated At: ${_reallocationResult!.metadata!.generatedAt}');
    }
    buffer.writeln();
    buffer.writeln('Suggestions (${_reallocationResult!.suggestions.length}):');

    for (final suggestion in _reallocationResult!.suggestions) {
      buffer.writeln('- ${suggestion.fromCategory} → ${suggestion.toCategory}');
      buffer.writeln('  Amount: ${suggestion.amount}');
      buffer.writeln('  Criticality: ${suggestion.criticality}');
      buffer.writeln('  Reason: ${suggestion.reason}');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Load the latest analysis result from local database
  Future<void> loadLatestAnalysis() async {
    try {
      if (kDebugMode) {
        debugPrint(
            '📊 AnalysisViewModel: Loading latest analysis from local database...');
      }

      // Use a constant guest user ID
      const userId = _guestUserId;

      // Get the latest analysis result
      final latestAnalysis =
          await _analysisRepository.getLatestAnalysis(userId);

      if (latestAnalysis != null) {
        _spendingAnalysisResult = latestAnalysis;
        if (kDebugMode) {
          debugPrint(
              '✅ AnalysisViewModel: Latest analysis loaded successfully');
          debugPrint('📊 Analysis summary: ${latestAnalysis.summary}');
          debugPrint(
              '📊 Key insights: ${latestAnalysis.keyInsights.length} items');
          debugPrint(
              '📊 Category insights: ${latestAnalysis.categoryInsights.length} items');
        }
        notifyListeners();
      } else {
        if (kDebugMode) {
          debugPrint('📊 AnalysisViewModel: No previous analysis found');
        }
        _spendingAnalysisResult = null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ AnalysisViewModel: Error loading latest analysis: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      _errorMessage = 'Failed to load previous analysis: ${e.toString()}';
      _spendingAnalysisResult = null;
      notifyListeners();
    }
  }

  /// Check if there is a previous analysis available
  Future<bool> hasPreviousAnalysis() async {
    try {
      const userId = _guestUserId;
      final latestAnalysis =
          await _analysisRepository.getLatestAnalysis(userId);
      return latestAnalysis != null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ AnalysisViewModel: Error checking for previous analysis: $e');
      }
      return false;
    }
  }

  /// Clear all analysis results and reset state
  void clearResults() {
    _spendingAnalysisResult = null;
    _reallocationResult = null;
    _lastSpendingRequest = null;
    _lastReallocationRequest = null;
    _errorMessage = null;
    _isAnalyzing = false;
    _isReallocating = false;
    _isCheckingHealth = false;
    notifyListeners();
  }

  /// Perform full analysis including health check, spending behavior, and budget reallocation
  Future<void> performFullAnalysis({
    required DateTime selectedDate,
  }) async {
    if (kDebugMode) {
      debugPrint('🚀 AnalysisViewModel: Starting full analysis...');
    }

    // Clear previous results
    clearResults();

    try {
      // Step 1: Check API health
      await checkApiHealth();

      // If health check failed, stop here
      if (_errorMessage != null) {
        if (kDebugMode) {
          debugPrint(
              '❌ AnalysisViewModel: Health check failed, stopping analysis');
        }
        return;
      }

      // Step 2: Perform spending behavior analysis
      await analyzeSpendingBehavior(selectedDate: selectedDate);

      // If spending analysis failed, stop here
      if (_errorMessage != null) {
        if (kDebugMode) {
          debugPrint(
              '❌ AnalysisViewModel: Spending analysis failed, stopping full analysis');
        }
        return;
      }

      // Step 3: Perform budget reallocation analysis
      await analyzeBudgetReallocation(selectedDate: selectedDate);

      if (_errorMessage == null) {
        if (kDebugMode) {
          debugPrint(
              '✅ AnalysisViewModel: Full analysis completed successfully');
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '⚠️ AnalysisViewModel: Full analysis completed with errors in reallocation step');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ AnalysisViewModel: Full analysis failed: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
