import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/recurring_expense.dart';
import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/user_behavior_profile.dart';

/// Comprehensive analysis request that includes user behavior profile
class ComprehensiveAnalysisRequest {
  final List<SpendingExpenseData> historicalExpenses;
  final SpendingBudgetData currentBudget;
  final UserBehaviorProfileData userProfile;
  final List<FinancialGoalData>? goals;
  final DateTime analysisDate;

  ComprehensiveAnalysisRequest({
    required this.historicalExpenses,
    required this.currentBudget,
    required this.userProfile,
    required this.analysisDate,
    this.goals,
  });

  Map<String, dynamic> toJson() {
    return {
      'historicalExpenses': historicalExpenses.map((e) => e.toJson()).toList(),
      'currentBudget': currentBudget.toJson(),
      'userProfile': userProfile.toJson(),
      'goals': goals?.map((g) => g.toJson()).toList(),
      'analysisDate': analysisDate.toIso8601String(),
    };
  }
}

/// User behavior profile data for API requests
class UserBehaviorProfileData {
  final String id;
  final String userId;
  final String primaryFinancialGoal;
  final String incomeStability;
  final String spendingMentality;
  final String riskAppetite;
  final double monthlyIncome;
  final double emergencyFundTarget;
  final Map<String, dynamic> aiPreferences;
  final Map<String, dynamic> categoryPreferences;
  final bool isComplete;

  UserBehaviorProfileData({
    required this.id,
    required this.userId,
    required this.primaryFinancialGoal,
    required this.incomeStability,
    required this.spendingMentality,
    required this.riskAppetite,
    required this.monthlyIncome,
    required this.emergencyFundTarget,
    required this.aiPreferences,
    required this.categoryPreferences,
    required this.isComplete,
  });

  factory UserBehaviorProfileData.fromProfile(UserBehaviorProfile profile) {
    return UserBehaviorProfileData(
      id: profile.id,
      userId: profile.userId,
      primaryFinancialGoal: profile.primaryFinancialGoal.name,
      incomeStability: profile.incomeStability.name,
      spendingMentality: profile.spendingMentality.name,
      riskAppetite: profile.riskAppetite.name,
      monthlyIncome: profile.monthlyIncome,
      emergencyFundTarget: profile.emergencyFundTarget,
      aiPreferences: profile.aiPreferences.toMap(),
      categoryPreferences: profile.categoryPreferences.toMap(),
      isComplete: profile.isComplete,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'primaryFinancialGoal': primaryFinancialGoal,
      'incomeStability': incomeStability,
      'spendingMentality': spendingMentality,
      'riskAppetite': riskAppetite,
      'monthlyIncome': monthlyIncome,
      'emergencyFundTarget': emergencyFundTarget,
      'aiPreferences': aiPreferences,
      'categoryPreferences': categoryPreferences,
      'isComplete': isComplete,
    };
  }
}

/// Financial goal data for API requests
class FinancialGoalData {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String iconName;
  final String colorValue;
  final bool isCompleted;

  FinancialGoalData({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.iconName,
    required this.colorValue,
    required this.isCompleted,
  });

  factory FinancialGoalData.fromGoal(FinancialGoal goal) {
    return FinancialGoalData(
      id: goal.id,
      title: goal.title,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      deadline: goal.deadline,
      iconName: goal.icon.iconName,
      colorValue: goal.icon.colorValue,
      isCompleted: goal.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline.toIso8601String(),
      'iconName': iconName,
      'colorValue': colorValue,
      'isCompleted': isCompleted,
    };
  }
}

/// Request model for spending behavior analysis.
/// This model is sent to the backend API for analysis.
class SpendingBehaviorRequest {
  /// A list of historical expenses, typically for the last 30 days.
  final List<SpendingExpenseData> historicalExpenses;

  /// A snapshot of the user's current budget.
  final SpendingBudgetData currentBudget;

  /// User profile information for personalized analysis (currently empty).
  final Map<String, dynamic>? userProfile;

  /// The date of the analysis.
  final DateTime analysisDate;

  SpendingBehaviorRequest({
    required this.historicalExpenses,
    required this.currentBudget,
    required this.analysisDate,
    this.userProfile,
  });

  /// Converts the request object to a JSON format for the API.
  Map<String, dynamic> toJson() {
    return {
      'historicalExpenses': historicalExpenses.map((e) => e.toJson()).toList(),
      'currentBudget': currentBudget.toJson(),
      'userProfile': userProfile ?? {},
      'analysisDate': analysisDate.toIso8601String(),
    };
  }
}

/// A snapshot of an expense, simplified for spending analysis.
class SpendingExpenseData {
  final double amount;
  final String categoryId;
  final String categoryName;
  final DateTime date;
  final String currency;
  final String remark;
  final bool isRecurring;
  final int? recurrenceFrequencyDays;

  SpendingExpenseData({
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    required this.currency,
    required this.remark,
    required this.isRecurring,
    this.recurrenceFrequencyDays,
  });

  /// Creates an instance of [SpendingExpenseData] from a domain [Expense] object.
  factory SpendingExpenseData.fromExpense(Expense expense) {
    int? getFrequencyInDays(RecurringDetails? details) {
      if (details == null) return null;
      switch (details.frequency) {
        case RecurringFrequency.weekly:
          return 7;
        case RecurringFrequency.monthly:
          return 30; // Approximate
      }
    }

    return SpendingExpenseData(
      amount: expense.amount,
      categoryId: expense.category.id,
      categoryName: expense.category.name,
      date: expense.date,
      currency: expense.currency,
      remark: expense.remark,
      isRecurring: expense.isRecurring,
      recurrenceFrequencyDays: getFrequencyInDays(expense.recurringDetails),
    );
  }

  /// Converts the object to a JSON format.
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'date': date.toIso8601String(),
      'currency': currency,
      'remark': remark,
      'isRecurring': isRecurring,
      'recurrenceFrequencyDays': recurrenceFrequencyDays,
    };
  }
}

/// A snapshot of the budget, simplified for spending analysis.
class SpendingBudgetData {
  final double totalBudget;
  final double totalRemaining;
  final Map<String, SpendingCategoryBudgetData> categoryBudgets;
  final double savings;
  final String currency;

  SpendingBudgetData({
    required this.totalBudget,
    required this.totalRemaining,
    required this.categoryBudgets,
    required this.savings,
    required this.currency,
  });

  /// Creates an instance of [SpendingBudgetData] from a domain [Budget] object.
  factory SpendingBudgetData.fromBudget(Budget budget) {
    return SpendingBudgetData(
      totalBudget: budget.total,
      totalRemaining: budget.left,
      categoryBudgets: budget.categories.map(
        (key, value) => MapEntry(
          key,
          SpendingCategoryBudgetData(
            allocated: value.budget,
            remaining: value.left,
            categoryName: CategoryExtension.fromId(key)?.name ?? key,
          ),
        ),
      ),
      savings: budget.saving,
      currency: budget.currency,
    );
  }

  /// Converts the object to a JSON format.
  Map<String, dynamic> toJson() {
    return {
      'totalBudget': totalBudget,
      'totalRemaining': totalRemaining,
      'categoryBudgets':
          categoryBudgets.map((key, value) => MapEntry(key, value.toJson())),
      'savings': savings,
      'currency': currency,
    };
  }
}

/// A snapshot of a category's budget, simplified for spending analysis.
class SpendingCategoryBudgetData {
  final String categoryName;
  final double allocated;
  final double remaining;

  SpendingCategoryBudgetData({
    required this.categoryName,
    required this.allocated,
    required this.remaining,
  });

  /// Converts the object to a JSON format.
  Map<String, dynamic> toJson() {
    return {
      'categoryName': categoryName,
      'allocated': allocated,
      'remaining': remaining,
    };
  }
}

/// Comprehensive analysis result combining all analysis types
class ComprehensiveAnalysisResult {
  final SpendingAnalysisResult spendingAnalysis;
  final BudgetReallocationRecommendation budgetRecommendation;
  final List<FinancialInsight> personalizedInsights;
  final List<SpendingAnomaly> anomalies;
  final SavingsAllocationRecommendation savingsRecommendation;

  ComprehensiveAnalysisResult({
    required this.spendingAnalysis,
    required this.budgetRecommendation,
    required this.personalizedInsights,
    required this.anomalies,
    required this.savingsRecommendation,
  });
}

/// Result of spending pattern analysis
class SpendingAnalysisResult {
  final Map<String, double> categorySpendingRatios;
  final double averageMonthlySpending;
  final double spendingVariability;
  final List<String> topSpendingCategories;
  final double savingsRate;
  final Map<String, SpendingTrend> categoryTrends;

  const SpendingAnalysisResult({
    required this.categorySpendingRatios,
    required this.averageMonthlySpending,
    required this.spendingVariability,
    required this.topSpendingCategories,
    required this.savingsRate,
    required this.categoryTrends,
  });
}

/// Budget reallocation recommendation
class BudgetReallocationRecommendation {
  final Map<String, double> recommendedAllocations;
  final List<String> categoriesNeedingIncrease;
  final List<String> categoriesNeedingDecrease;
  final double confidenceScore;
  final String reasoning;

  const BudgetReallocationRecommendation({
    required this.recommendedAllocations,
    required this.categoriesNeedingIncrease,
    required this.categoriesNeedingDecrease,
    required this.confidenceScore,
    required this.reasoning,
  });
}

/// Goal analysis result
class GoalAnalysisResult {
  final Map<String, double> goalAchievabilityScores;
  final Map<String, DateTime> estimatedCompletionDates;
  final List<String> recommendedGoalAdjustments;
  final double overallGoalHealthScore;

  const GoalAnalysisResult({
    required this.goalAchievabilityScores,
    required this.estimatedCompletionDates,
    required this.recommendedGoalAdjustments,
    required this.overallGoalHealthScore,
  });
}

/// Financial insight for users
class FinancialInsight {
  final String title;
  final String description;
  final FinancialInsightType type;
  final FinancialInsightPriority priority;
  final Map<String, dynamic> actionData;

  const FinancialInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.actionData,
  });
}

/// Types of financial insights
enum FinancialInsightType {
  budgetOptimization,
  spendingAlert,
  savingsOpportunity,
  goalRecommendation,
  riskWarning,
  achievementCelebration,
}

/// Priority levels for insights
enum FinancialInsightPriority {
  low,
  medium,
  high,
  critical,
}

/// Spending anomaly detection
class SpendingAnomaly {
  final String category;
  final double amount;
  final DateTime date;
  final double deviationScore;
  final String description;
  final AnomalyType type;

  const SpendingAnomaly({
    required this.category,
    required this.amount,
    required this.date,
    required this.deviationScore,
    required this.description,
    required this.type,
  });
}

/// Types of spending anomalies
enum AnomalyType {
  unusuallyHigh,
  unusuallyLow,
  newCategory,
  frequencyChange,
  timingAnomaly,
}

/// Spending trend analysis
class SpendingTrend {
  final double trendSlope;
  final TrendDirection direction;
  final double confidence;

  const SpendingTrend({
    required this.trendSlope,
    required this.direction,
    required this.confidence,
  });
}

/// Trend directions
enum TrendDirection {
  increasing,
  decreasing,
  stable,
  volatile,
}

/// Savings allocation recommendation
class SavingsAllocationRecommendation {
  final Map<String, double> goalAllocations;
  final double emergencyFundAllocation;
  final double investmentAllocation;
  final String reasoning;
  final double confidenceScore;

  const SavingsAllocationRecommendation({
    required this.goalAllocations,
    required this.emergencyFundAllocation,
    required this.investmentAllocation,
    required this.reasoning,
    required this.confidenceScore,
  });
}

/// Response model for spending behavior analysis.
///
/// NOTE: This is a placeholder and will be implemented in the future.
class SpendingBehaviorResponse {
  // TODO: Define the structure of the spending behavior response from the API.
}
