import 'dart:async';
import 'package:flutter/foundation.dart';

import '../entities/expense.dart';
import '../entities/budget.dart';
import '../entities/category.dart';
import '../entities/financial_goal.dart';
import '../entities/user_behavior_profile.dart';
import '../../data/models/spending_behavior_models.dart';
import '../../data/models/exceptions.dart';
import '../../data/infrastructure/network/connectivity_service.dart';
import '../../data/infrastructure/services/gemini_api_client.dart';

/// Comprehensive service for analyzing user spending behavior and providing AI-driven insights
///
/// This unified service combines:
/// - User behavior profile analysis
/// - Historical spending pattern analysis
/// - Budget optimization recommendations
/// - Financial goal achievement analysis
/// - Personalized insights and alerts
/// - Anomaly detection
class SpendingBehaviorAnalysisService {
  static final SpendingBehaviorAnalysisService _instance =
      SpendingBehaviorAnalysisService._internal();
  factory SpendingBehaviorAnalysisService() => _instance;
  SpendingBehaviorAnalysisService._internal();

  // Services
  GeminiApiClient? _apiClient;
  ConnectivityService? _connectivityService;
  bool _isInitialized = false;

  /// Set the API client (for dependency injection)
  void setGeminiApiClient(GeminiApiClient apiClient) {
    _apiClient = apiClient;
  }

  /// Set the connectivity service (for dependency injection)
  void setConnectivityService(ConnectivityService connectivityService) {
    _connectivityService = connectivityService;
  }

  /// Initialize the spending behavior analysis service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('💡 SpendingBehaviorAnalysisService: Initializing...');

      if (_apiClient == null) {
        throw AIApiException(
          'API client not set',
          code: 'CLIENT_NOT_SET',
        );
      }

      // Initialize the API client
      await _apiClient!.initialize();

      _isInitialized = true;
      debugPrint(
          '💡 SpendingBehaviorAnalysisService: Initialized successfully');
    } catch (e) {
      debugPrint(
          '💡 SpendingBehaviorAnalysisService: Initialization error: $e');
      throw AIApiException(
        'Failed to initialize spending behavior analysis service: $e',
        code: 'INITIALIZATION_ERROR',
      );
    }
  }

  /// Comprehensive spending behavior analysis with user profile integration
  ///
  /// This method provides a complete analysis including:
  /// - Spending pattern analysis based on user behavior profile
  /// - Budget reallocation recommendations
  /// - Goal achievement analysis
  /// - Personalized financial insights
  /// - Anomaly detection
  Future<ComprehensiveAnalysisResult> analyzeSpendingBehavior({
    required List<Expense> historicalExpenses,
    required Budget currentBudget,
    required UserBehaviorProfile userProfile,
    List<FinancialGoal>? goals,
  }) async {
    try {
      await _ensureInitialized();
      await _checkConnectivity();
      _validateInputData(historicalExpenses, currentBudget, userProfile);

      debugPrint('💡 Starting comprehensive spending behavior analysis...');

      final request = _prepareComprehensiveAnalysisRequest(
        historicalExpenses,
        currentBudget,
        userProfile,
        goals,
      );

      final response = await _callFastAPIBackend(request);
      final analysisResult = await _parseComprehensiveResponse(response);

      debugPrint(
          '💡 Comprehensive spending behavior analysis completed successfully');
      return analysisResult;
    } catch (e) {
      debugPrint('💡 Comprehensive spending behavior analysis error: $e');

      if (e is AIApiException) {
        rethrow;
      }

      throw AIApiException(
        'Failed to analyze spending behavior: $e',
        code: 'ANALYSIS_ERROR',
        details: {'originalError': e.toString()},
      );
    }
  }

  /// Quick budget optimization analysis
  Future<BudgetReallocationRecommendation> generateBudgetRecommendations({
    required List<Expense> recentExpenses,
    required Budget currentBudget,
    required UserBehaviorProfile userProfile,
  }) async {
    try {
      debugPrint('💡 Getting budget reallocation recommendations...');

      final fullAnalysis = await analyzeSpendingBehavior(
        historicalExpenses: recentExpenses,
        currentBudget: currentBudget,
        userProfile: userProfile,
      );

      return fullAnalysis.budgetRecommendation;
    } catch (e) {
      debugPrint('💡 Failed to get budget recommendations: $e');
      // Return default recommendations if analysis fails
      return BudgetReallocationRecommendation(
        recommendedAllocations: {},
        categoriesNeedingIncrease: [],
        categoriesNeedingDecrease: [],
        confidenceScore: 0.0,
        reasoning:
            'Unable to generate recommendations due to analysis error: $e',
      );
    }
  }

  /// Analyze goal achievement likelihood
  Future<GoalAnalysisResult> analyzeGoalAchievability({
    required UserBehaviorProfile userProfile,
    required List<FinancialGoal> goals,
    required List<Expense> expenses,
  }) async {
    try {
      debugPrint('💡 Analyzing goal achievability...');

      // For now, return mock analysis - TODO: Implement actual analysis
      return GoalAnalysisResult(
        goalAchievabilityScores: {
          for (final goal in goals)
            goal.id: _calculateGoalScore(goal, userProfile, expenses)
        },
        estimatedCompletionDates: {
          for (final goal in goals)
            goal.id: _estimateCompletionDate(goal, userProfile, expenses)
        },
        recommendedGoalAdjustments:
            _generateGoalAdjustments(goals, userProfile, expenses),
        overallGoalHealthScore:
            _calculateOverallGoalHealth(goals, userProfile, expenses),
      );
    } catch (e) {
      debugPrint('💡 Failed to analyze goal achievability: $e');
      rethrow;
    }
  }

  /// Generate personalized financial insights
  Future<List<FinancialInsight>> generatePersonalizedInsights({
    required UserBehaviorProfile userProfile,
    required List<Expense> expenses,
    Budget? currentBudget,
    List<FinancialGoal>? goals,
  }) async {
    try {
      debugPrint('💡 Generating personalized financial insights...');

      final insights = <FinancialInsight>[];

      // Generate insights based on user profile and spending patterns
      insights.addAll(_generateSpendingInsights(userProfile, expenses));

      if (currentBudget != null) {
        insights.addAll(
            _generateBudgetInsights(userProfile, currentBudget, expenses));
      }

      if (goals != null && goals.isNotEmpty) {
        insights.addAll(_generateGoalInsights(userProfile, goals, expenses));
      }

      // Sort by priority
      insights.sort((a, b) => b.priority.index.compareTo(a.priority.index));

      return insights;
    } catch (e) {
      debugPrint('💡 Failed to generate personalized insights: $e');
      return [];
    }
  }

  /// Detect spending anomalies based on user patterns
  Future<List<SpendingAnomaly>> detectSpendingAnomalies({
    required UserBehaviorProfile userProfile,
    required List<Expense> expenses,
  }) async {
    try {
      debugPrint('💡 Detecting spending anomalies...');

      final anomalies = <SpendingAnomaly>[];
      final recentExpenses = expenses
          .where((e) =>
              e.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
          .toList();

      // Analyze spending patterns based on user profile
      anomalies.addAll(_detectAmountAnomalies(userProfile, recentExpenses));
      anomalies.addAll(_detectFrequencyAnomalies(userProfile, recentExpenses));
      anomalies.addAll(_detectCategoryAnomalies(userProfile, recentExpenses));

      return anomalies;
    } catch (e) {
      debugPrint('💡 Failed to detect spending anomalies: $e');
      return [];
    }
  }

  /// Recommend optimal savings allocation
  Future<SavingsAllocationRecommendation> recommendSavingsAllocation({
    required UserBehaviorProfile userProfile,
    required double availableSavings,
    List<FinancialGoal>? goals,
  }) async {
    try {
      debugPrint('💡 Generating savings allocation recommendations...');

      final recommendation =
          _calculateSavingsAllocation(userProfile, availableSavings, goals);
      return recommendation;
    } catch (e) {
      debugPrint(
          '💡 Failed to generate savings allocation recommendations: $e');
      return SavingsAllocationRecommendation(
        goalAllocations: {},
        emergencyFundAllocation: availableSavings * 0.5,
        investmentAllocation: availableSavings * 0.5,
        reasoning: 'Default allocation due to analysis error: $e',
        confidenceScore: 0.0,
      );
    }
  }

  // Private helper methods for analysis logic

  double _calculateGoalScore(
      FinancialGoal goal, UserBehaviorProfile profile, List<Expense> expenses) {
    // TODO: Implement actual goal scoring algorithm
    final baseScore = goal.currentAmount / goal.targetAmount;
    final profileMultiplier =
        profile.primaryFinancialGoal == FinancialGoalType.aggressiveSaving
            ? 1.2
            : 1.0;
    return (baseScore * profileMultiplier).clamp(0.0, 1.0);
  }

  DateTime _estimateCompletionDate(
      FinancialGoal goal, UserBehaviorProfile profile, List<Expense> expenses) {
    // TODO: Implement actual completion date estimation
    final remainingAmount = goal.targetAmount - goal.currentAmount;
    final monthlyContribution =
        profile.monthlyIncome * 0.1; // Assume 10% contribution
    final monthsToComplete = (remainingAmount / monthlyContribution).ceil();
    return DateTime.now().add(Duration(days: monthsToComplete * 30));
  }

  List<String> _generateGoalAdjustments(List<FinancialGoal> goals,
      UserBehaviorProfile profile, List<Expense> expenses) {
    // TODO: Implement actual goal adjustment recommendations
    return [
      'Consider increasing emergency fund target to ${profile.emergencyFundTarget} months',
      'Adjust savings goals based on your ${profile.spendingMentality.displayName} spending style',
    ];
  }

  double _calculateOverallGoalHealth(List<FinancialGoal> goals,
      UserBehaviorProfile profile, List<Expense> expenses) {
    // TODO: Implement actual goal health calculation
    if (goals.isEmpty) return 1.0;
    final avgProgress = goals
            .map((g) => g.currentAmount / g.targetAmount)
            .reduce((a, b) => a + b) /
        goals.length;
    return avgProgress.clamp(0.0, 1.0);
  }

  List<FinancialInsight> _generateSpendingInsights(
      UserBehaviorProfile profile, List<Expense> expenses) {
    final insights = <FinancialInsight>[];

    // Example insight based on spending mentality
    if (profile.spendingMentality == SpendingMentality.spontaneous) {
      insights.add(FinancialInsight(
        title: 'Mindful Spending Opportunity',
        description:
            'As a spontaneous spender, setting up spending alerts could help you stay on track with your budget.',
        type: FinancialInsightType.spendingAlert,
        priority: FinancialInsightPriority.medium,
        actionData: {'suggestedAction': 'enable_spending_alerts'},
      ));
    }

    return insights;
  }

  List<FinancialInsight> _generateBudgetInsights(
      UserBehaviorProfile profile, Budget budget, List<Expense> expenses) {
    final insights = <FinancialInsight>[];

    // Example budget insight
    if (budget.saving / budget.total < 0.2 &&
        profile.primaryFinancialGoal == FinancialGoalType.aggressiveSaving) {
      insights.add(FinancialInsight(
        title: 'Savings Rate Below Target',
        description:
            'Your current savings rate is below 20%. Consider adjusting your budget to align with your aggressive saving goal.',
        type: FinancialInsightType.budgetOptimization,
        priority: FinancialInsightPriority.high,
        actionData: {
          'currentSavingsRate': budget.saving / budget.total,
          'targetRate': 0.2
        },
      ));
    }

    return insights;
  }

  List<FinancialInsight> _generateGoalInsights(UserBehaviorProfile profile,
      List<FinancialGoal> goals, List<Expense> expenses) {
    final insights = <FinancialInsight>[];

    // Example goal insight
    for (final goal in goals) {
      final progress = goal.currentAmount / goal.targetAmount;
      if (progress > 0.8) {
        insights.add(FinancialInsight(
          title: 'Goal Almost Achieved!',
          description:
              'You\'re ${(progress * 100).round()}% towards your ${goal.title} goal. Keep up the great work!',
          type: FinancialInsightType.achievementCelebration,
          priority: FinancialInsightPriority.low,
          actionData: {'goalId': goal.id, 'progress': progress},
        ));
      }
    }

    return insights;
  }

  List<SpendingAnomaly> _detectAmountAnomalies(
      UserBehaviorProfile profile, List<Expense> expenses) {
    // TODO: Implement actual anomaly detection
    return [];
  }

  List<SpendingAnomaly> _detectFrequencyAnomalies(
      UserBehaviorProfile profile, List<Expense> expenses) {
    // TODO: Implement actual frequency anomaly detection
    return [];
  }

  List<SpendingAnomaly> _detectCategoryAnomalies(
      UserBehaviorProfile profile, List<Expense> expenses) {
    // TODO: Implement actual category anomaly detection
    return [];
  }

  SavingsAllocationRecommendation _calculateSavingsAllocation(
      UserBehaviorProfile profile,
      double availableSavings,
      List<FinancialGoal>? goals) {
    final emergencyMultiplier = profile.riskAppetite == RiskAppetite.low
        ? 0.6
        : profile.riskAppetite == RiskAppetite.medium
            ? 0.4
            : 0.2;

    final emergencyAllocation = availableSavings * emergencyMultiplier;
    final investmentAllocation =
        availableSavings * (1 - emergencyMultiplier) * 0.3;
    final goalAllocation =
        availableSavings - emergencyAllocation - investmentAllocation;

    final goalAllocations = <String, double>{};
    if (goals != null && goals.isNotEmpty) {
      final perGoal = goalAllocation / goals.length;
      for (final goal in goals) {
        goalAllocations[goal.id] = perGoal;
      }
    }

    return SavingsAllocationRecommendation(
      goalAllocations: goalAllocations,
      emergencyFundAllocation: emergencyAllocation,
      investmentAllocation: investmentAllocation,
      reasoning:
          'Allocation based on your ${profile.riskAppetite.displayName} risk appetite and ${profile.primaryFinancialGoal.displayName} financial goal.',
      confidenceScore: 0.85,
    );
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized || _apiClient == null) {
      await initialize();
    }
  }

  Future<void> _checkConnectivity() async {
    if (_connectivityService == null) {
      throw AIApiException(
        'Connectivity service not initialized',
        code: 'SERVICE_NOT_INITIALIZED',
      );
    }

    final isConnected = await _connectivityService!.isConnected;
    if (!isConnected) {
      throw AIApiException(
        'Internet connection required for spending behavior analysis',
        code: 'NO_CONNECTIVITY',
      );
    }
  }

  void _validateInputData(
    List<Expense> historicalExpenses,
    Budget currentBudget,
    UserBehaviorProfile userProfile,
  ) {
    if (historicalExpenses.isEmpty) {
      throw AIApiException(
        'Historical expense data is required for spending behavior analysis',
        code: 'INSUFFICIENT_DATA',
      );
    }

    if (currentBudget.total <= 0) {
      throw AIApiException(
        'Valid budget data is required for analysis',
        code: 'INVALID_BUDGET',
      );
    }

    if (!userProfile.isComplete) {
      throw AIApiException(
        'Complete user behavior profile is required for personalized analysis',
        code: 'INCOMPLETE_PROFILE',
      );
    }

    // Check if we have enough data for meaningful analysis (past 30 days)
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final relevantExpenses = historicalExpenses
        .where((expense) => expense.date.isAfter(cutoffDate))
        .toList();

    if (relevantExpenses.length < 5) {
      throw AIApiException(
        'Not enough recent expense data for meaningful analysis (minimum 5 expenses required in the last 30 days)',
        code: 'INSUFFICIENT_RECENT_DATA',
      );
    }
  }

  ComprehensiveAnalysisRequest _prepareComprehensiveAnalysisRequest(
    List<Expense> historicalExpenses,
    Budget currentBudget,
    UserBehaviorProfile userProfile,
    List<FinancialGoal>? goals,
  ) {
    // Filter expenses to the last 30 days for analysis
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final relevantExpenses = historicalExpenses
        .where((expense) => expense.date.isAfter(cutoffDate))
        .toList();

    // Sort by date for pattern analysis
    relevantExpenses.sort((a, b) => a.date.compareTo(b.date));

    debugPrint('💡 [COMPREHENSIVE ANALYSIS DATA PREPARATION] ===============');
    debugPrint('💡 Total historical expenses: ${historicalExpenses.length}');
    debugPrint(
        '💡 Relevant expenses (last 30 days): ${relevantExpenses.length}');
    debugPrint('💡 User profile complete: ${userProfile.isComplete}');
    debugPrint('💡 Financial goals: ${goals?.length ?? 0}');
    debugPrint(
        '💡 Current budget total: ${currentBudget.total} ${currentBudget.currency}');

    return ComprehensiveAnalysisRequest(
      historicalExpenses: relevantExpenses
          .map((e) => SpendingExpenseData.fromExpense(e))
          .toList(),
      currentBudget: SpendingBudgetData.fromBudget(currentBudget),
      userProfile: UserBehaviorProfileData.fromProfile(userProfile),
      goals: goals?.map((g) => FinancialGoalData.fromGoal(g)).toList(),
      analysisDate: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>> _callFastAPIBackend(
      ComprehensiveAnalysisRequest request) async {
    try {
      debugPrint('💡 Calling FastAPI backend for comprehensive analysis...');

      final jsonRequest = request.toJson();
      final response = await _apiClient!.analyzeSpendingBehavior(
        historicalExpenses:
            jsonRequest['historicalExpenses'] as List<Map<String, dynamic>>,
        currentBudget: jsonRequest['currentBudget'] as Map<String, dynamic>,
        userProfile: jsonRequest['userProfile'] as Map<String, dynamic>,
      );

      debugPrint('💡 FastAPI backend response received successfully');
      return response;
    } catch (e) {
      debugPrint('💡 Failed to call FastAPI backend: $e');
      throw AIApiException(
        'AI analysis failed: $e',
        code: 'API_ERROR',
        details: {'originalError': e.toString()},
      );
    }
  }

  Future<ComprehensiveAnalysisResult> _parseComprehensiveResponse(
      Map<String, dynamic> response) async {
    try {
      debugPrint('💡 [AI COMPREHENSIVE RESPONSE] ===========================');
      debugPrint('💡 Raw response received: $response');

      // TODO: Implement full response parsing when the API is ready
      // For now, returning a mock comprehensive analysis result
      final analysisResult = ComprehensiveAnalysisResult(
        spendingAnalysis: SpendingAnalysisResult(
          categorySpendingRatios: {
            'food': 0.3,
            'transport': 0.2,
            'entertainment': 0.15
          },
          averageMonthlySpending: 2500.0,
          spendingVariability: 0.15,
          topSpendingCategories: ['food', 'transport', 'entertainment'],
          savingsRate: 0.25,
          categoryTrends: {},
        ),
        budgetRecommendation: BudgetReallocationRecommendation(
          recommendedAllocations: {'food': 800.0, 'transport': 500.0},
          categoriesNeedingIncrease: ['food'],
          categoriesNeedingDecrease: ['entertainment'],
          confidenceScore: 0.85,
          reasoning: 'Mock recommendation based on user profile analysis',
        ),
        personalizedInsights: [],
        anomalies: [],
        savingsRecommendation: SavingsAllocationRecommendation(
          goalAllocations: {},
          emergencyFundAllocation: 1000.0,
          investmentAllocation: 500.0,
          reasoning: 'Mock savings allocation',
          confidenceScore: 0.8,
        ),
      );

      debugPrint('💡 Comprehensive response parsing completed (mock data)');
      return analysisResult;
    } catch (e) {
      debugPrint('💡 Failed to parse comprehensive response: $e');
      throw AIApiException(
        'Failed to parse comprehensive analysis: $e',
        code: 'PARSE_ERROR',
        details: {
          'originalError': e.toString(),
          'rawResponse': response.toString()
        },
      );
    }
  }

  /// Clean up resources
  void dispose() {
    _apiClient = null;
    _connectivityService = null;
    _isInitialized = false;
    debugPrint('💡 SpendingBehaviorAnalysisService: Disposed');
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
