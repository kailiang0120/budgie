import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/recurring_expense.dart';
import '../../domain/entities/user_behavior_profile.dart';

// -----------------------------------------------------------------------------
// REQUEST MODELS
// -----------------------------------------------------------------------------

/// **Spending Behavior Analysis Request**
///
/// The root object for the analysis request. It bundles all necessary user data,
/// including their financial profile, budget, historical expenses, and goals.
class SpendingBehaviorAnalysisRequest {
  /// A list of the user's recent expenses for historical context.
  final List<AnalysisExpenseData> historicalExpenses;

  /// The user's current budget setup.
  final AnalysisBudgetData currentBudget;

  /// The user's self-reported financial behavior and preferences.
  final AnalysisUserProfileData userProfile;

  /// The user's active financial goals.
  final List<AnalysisFinancialGoalData>? financialGoals;

  /// The timestamp when the analysis was requested.
  final DateTime analysisDate;

  SpendingBehaviorAnalysisRequest({
    required this.historicalExpenses,
    required this.currentBudget,
    required this.userProfile,
    this.financialGoals,
    required this.analysisDate,
  });

  /// Serializes the request object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'historicalExpenses': historicalExpenses.map((e) => e.toJson()).toList(),
      'currentBudget': currentBudget.toJson(),
      'userProfile': userProfile.toJson(),
      'financialGoals': financialGoals?.map((g) => g.toJson()).toList(),
      'analysisDate': analysisDate.toIso8601String(),
    };
  }
}

/// **Analysis Budget Data**
///
/// A simplified snapshot of the user's [Budget] for the analysis request.
class AnalysisBudgetData {
  final double total;
  final double left;
  final Map<String, AnalysisCategoryBudgetData> categories;
  final double saving;
  final String currency;

  AnalysisBudgetData({
    required this.total,
    required this.left,
    required this.categories,
    required this.saving,
    required this.currency,
  });

  /// Creates an instance from a domain [Budget] object.
  factory AnalysisBudgetData.fromBudget(Budget budget) {
    return AnalysisBudgetData(
      total: budget.total,
      left: budget.left,
      categories: budget.categories.map(
        (key, value) => MapEntry(
          key,
          AnalysisCategoryBudgetData(
            budget: value.budget,
            left: value.left,
          ),
        ),
      ),
      saving: budget.saving,
      currency: budget.currency,
    );
  }

  /// Serializes the object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'left': left,
      'categories':
          categories.map((key, value) => MapEntry(key, value.toJson())),
      'saving': saving,
      'currency': currency,
    };
  }
}

/// **Analysis Category Budget Data**
///
/// Represents the budget for a single category.
class AnalysisCategoryBudgetData {
  final double budget;
  final double left;

  AnalysisCategoryBudgetData({
    required this.budget,
    required this.left,
  });

  /// Serializes the object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'budget': budget,
      'left': left,
    };
  }
}

/// **Analysis Expense Data**
///
/// A simplified snapshot of an [Expense] for the analysis request.
class AnalysisExpenseData {
  final double amount;
  final DateTime date;
  final String categoryId;
  final String categoryName;
  final String paymentMethod;
  final String remark;
  final String? description;
  final String currency;
  final RecurringDetails? recurringDetails;

  AnalysisExpenseData({
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.categoryName,
    required this.paymentMethod,
    required this.remark,
    this.description,
    required this.currency,
    this.recurringDetails,
  });

  /// Creates an instance from a domain [Expense] object.
  factory AnalysisExpenseData.fromExpense(Expense expense) {
    return AnalysisExpenseData(
      amount: expense.amount,
      date: expense.date,
      categoryId: expense.category.id,
      categoryName: expense.category.name,
      paymentMethod: expense.method.name,
      remark: expense.remark,
      description: expense.description,
      currency: expense.currency,
      recurringDetails: expense.recurringDetails,
    );
  }

  /// Serializes the object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'categoryName': categoryName,
      'paymentMethod': paymentMethod,
      'remark': remark,
      'description': description,
      'currency': currency,
      'recurringDetails': recurringDetails?.toJson(),
    };
  }
}

/// **Analysis Financial Goal Data**
///
/// A simplified snapshot of a [FinancialGoal] for the analysis request.
class AnalysisFinancialGoalData {
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final bool isCompleted;

  AnalysisFinancialGoalData({
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.isCompleted,
  });

  /// Creates an instance from a domain [FinancialGoal] object.
  factory AnalysisFinancialGoalData.fromGoal(FinancialGoal goal) {
    return AnalysisFinancialGoalData(
      title: goal.title,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      deadline: goal.deadline,
      isCompleted: goal.isCompleted,
    );
  }

  /// Serializes the object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}

/// **Analysis User Profile Data**
///
/// A simplified snapshot of the [UserBehaviorProfile] for the analysis request.
class AnalysisUserProfileData {
  final String userId;
  final String incomeStability;
  final String spendingMentality;
  final String riskAppetite;
  final double monthlyIncome;
  final double emergencyFundTarget;
  final FinancialLiteracyLevel financialLiteracyLevel;
  final DateTime? dataConsentAcceptedAt;

  AnalysisUserProfileData({
    required this.userId,
    required this.incomeStability,
    required this.spendingMentality,
    required this.riskAppetite,
    required this.monthlyIncome,
    required this.emergencyFundTarget,
    required this.financialLiteracyLevel,
    this.dataConsentAcceptedAt,
  });

  /// Creates an instance from a domain [UserBehaviorProfile] object.
  factory AnalysisUserProfileData.fromProfile(UserBehaviorProfile profile) {
    return AnalysisUserProfileData(
      userId: profile.userId,
      incomeStability: profile.incomeStability.name,
      spendingMentality: profile.spendingMentality.name,
      riskAppetite: profile.riskAppetite.name,
      monthlyIncome: profile.monthlyIncome,
      emergencyFundTarget: profile.emergencyFundTarget,
      financialLiteracyLevel: profile.financialLiteracyLevel,
      dataConsentAcceptedAt: profile.dataConsentAcceptedAt,
    );
  }

  /// Serializes the object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'incomeStability': incomeStability,
      'spendingMentality': spendingMentality,
      'riskAppetite': riskAppetite,
      'monthlyIncome': monthlyIncome,
      'emergencyFundTarget': emergencyFundTarget,
      'financialLiteracyLevel': financialLiteracyLevel.name,
      'dataConsentAcceptedAt': dataConsentAcceptedAt?.toIso8601String(),
    };
  }
}

// -----------------------------------------------------------------------------
// RESPONSE MODELS - NEW SIMPLIFIED STRUCTURE
// -----------------------------------------------------------------------------

/// **Spending Behavior Analysis Result**
///
/// The new simplified response structure from the analysis engine.
class SpendingBehaviorAnalysisResult {
  /// Detailed insights for individual spending categories.
  final List<CategoryInsight> categoryInsights;

  /// Key behavioral insights about the user's spending patterns.
  final List<String> keyInsights;

  /// Actionable recommendations for improving financial behavior.
  final List<String> actionableRecommendations;

  /// Executive summary of the analysis.
  final String summary;

  /// Metadata about the analysis process.
  final Map<String, dynamic> metadata;

  SpendingBehaviorAnalysisResult({
    required this.categoryInsights,
    required this.keyInsights,
    required this.actionableRecommendations,
    required this.summary,
    required this.metadata,
  });

  factory SpendingBehaviorAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SpendingBehaviorAnalysisResult(
      categoryInsights: (json['categoryInsights'] as List<dynamic>? ?? [])
          .map((item) => CategoryInsight.fromJson(item as Map<String, dynamic>))
          .toList(),
      keyInsights: (json['keyInsights'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      actionableRecommendations:
          (json['actionableRecommendations'] as List<dynamic>? ?? [])
              .map((item) => item.toString())
              .toList(),
      summary: json['summary'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryInsights':
          categoryInsights.map((item) => item.toJson()).toList(),
      'keyInsights': keyInsights,
      'actionableRecommendations': actionableRecommendations,
      'summary': summary,
      'metadata': metadata,
    };
  }
}

/// **Category Analysis**
///
/// Detailed insights for individual spending categories.
class CategoryInsight {
  final String categoryName;
  final double budgetAmount;
  final double spentAmount;
  final double utilizationRate;
  final String status; // 'over_budget', 'on_track', 'under_budget'
  final String insight;
  final String? recommendation;

  CategoryInsight({
    required this.categoryName,
    required this.budgetAmount,
    required this.spentAmount,
    required this.utilizationRate,
    required this.status,
    required this.insight,
    this.recommendation,
  });

  factory CategoryInsight.fromJson(Map<String, dynamic> json) {
    return CategoryInsight(
      categoryName: json['categoryName'] as String? ?? '',
      budgetAmount: (json['budgetAmount'] as num?)?.toDouble() ?? 0.0,
      spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0.0,
      utilizationRate: (json['utilizationRate'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'unknown',
      insight: json['insight'] as String? ?? '',
      recommendation: json['recommendation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryName': categoryName,
      'budgetAmount': budgetAmount,
      'spentAmount': spentAmount,
      'utilizationRate': utilizationRate,
      'status': status,
      'insight': insight,
      'recommendation': recommendation,
    };
  }
}

// -----------------------------------------------------------------------------
// LEGACY COMPATIBILITY
// -----------------------------------------------------------------------------

/// **Legacy Spending Behavior Analysis Response**
///
/// Kept for backward compatibility. Use [SpendingBehaviorAnalysisResult] instead.
@Deprecated('Use SpendingBehaviorAnalysisResult instead')
class SpendingBehaviorAnalysisResponse {
  /// The full text analysis as a single string.
  final String analysis;

  /// Metadata about the analysis process.
  final AnalysisMetadata metadata;

  SpendingBehaviorAnalysisResponse({
    required this.analysis,
    required this.metadata,
  });

  factory SpendingBehaviorAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return SpendingBehaviorAnalysisResponse(
      analysis: json['analysis'] as String? ?? '',
      metadata: AnalysisMetadata.fromJson(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysis': analysis,
      'metadata': metadata.toJson(),
    };
  }
}

/// **Analysis Metadata**
///
/// Contains technical details about the analysis process.
class AnalysisMetadata {
  final DateTime analysisTimestamp;
  final String aiModel;
  final String version;
  final String? userId;
  final String? analysisType;

  AnalysisMetadata({
    required this.analysisTimestamp,
    required this.aiModel,
    required this.version,
    this.userId,
    this.analysisType,
  });

  factory AnalysisMetadata.fromJson(Map<String, dynamic> json) {
    // Parse timestamp
    DateTime timestamp = DateTime.now();
    if (json.containsKey('analysis_timestamp')) {
      final value = json['analysis_timestamp'];
      if (value != null) {
        final parsed = DateTime.tryParse(value.toString());
        if (parsed != null) timestamp = parsed;
      }
    } else if (json.containsKey('analysisTimestamp')) {
      final value = json['analysisTimestamp'];
      if (value != null) {
        final parsed = DateTime.tryParse(value.toString());
        if (parsed != null) timestamp = parsed;
      }
    }

    // Parse model name
    String model = 'Unknown';
    if (json.containsKey('ai_model')) {
      final value = json['ai_model'];
      if (value != null) model = value.toString();
    } else if (json.containsKey('aiModel')) {
      final value = json['aiModel'];
      if (value != null) model = value.toString();
    }

    // Parse version
    String ver = '1.0.0';
    if (json.containsKey('version')) {
      final value = json['version'];
      if (value != null) ver = value.toString();
    } else if (json.containsKey('modelVersion')) {
      final value = json['modelVersion'];
      if (value != null) ver = value.toString();
    }

    // Parse userId
    String? uid;
    if (json.containsKey('user_id')) {
      final value = json['user_id'];
      if (value != null) uid = value.toString();
    }

    // Parse analysisType
    String? type;
    if (json.containsKey('analysis_type')) {
      final value = json['analysis_type'];
      if (value != null) type = value.toString();
    }

    return AnalysisMetadata(
      analysisTimestamp: timestamp,
      aiModel: model,
      version: ver,
      userId: uid,
      analysisType: type,
    );
  }

  Map<String, dynamic> toJson() {
    final result = {
      'analysis_timestamp': analysisTimestamp.toIso8601String(),
      'ai_model': aiModel,
      'version': version,
    };

    if (userId != null) result['user_id'] = userId!;
    if (analysisType != null) result['analysis_type'] = analysisType!;

    return result;
  }
}
