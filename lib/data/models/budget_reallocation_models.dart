import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/recurring_expense.dart';
import '../../domain/entities/user_behavior_profile.dart';
import 'spending_behavior_models.dart';

// -----------------------------------------------------------------------------
// REQUEST MODELS
// -----------------------------------------------------------------------------

/// Request model for budget reallocation analysis.
class BudgetReallocationRequest {
  final ReallocationUserProfileData userProfile;
  final ReallocationBudgetData currentBudget;
  final List<ReallocationExpenseData> recentExpenses;
  final List<ReallocationGoalData> goals;
  final SpendingBehaviorAnalysisResult spendingAnalysis;

  BudgetReallocationRequest({
    required this.userProfile,
    required this.currentBudget,
    required this.recentExpenses,
    required this.goals,
    required this.spendingAnalysis,
  });

  Map<String, dynamic> toJson() {
    // Create a copy of spending analysis without metadata for the request
    final spendingAnalysisForRequest = {
      'categoryInsights': spendingAnalysis.categoryInsights
          .map((item) => item.toJson())
          .toList(),
      'keyInsights': spendingAnalysis.keyInsights,
      'actionableRecommendations': spendingAnalysis.actionableRecommendations,
      'summary': spendingAnalysis.summary,
      // Exclude metadata field from request
    };

    return {
      'userProfile': userProfile.toJson(),
      'currentBudget': currentBudget.toJson(),
      'recentExpenses': recentExpenses.map((e) => e.toJson()).toList(),
      'goals': goals.map((g) => g.toJson()).toList(),
      'spendingAnalysis': spendingAnalysisForRequest,
    };
  }
}

/// A snapshot of the user's behavior profile, simplified for reallocation analysis.
class ReallocationUserProfileData {
  final String userId;
  final String incomeStability;
  final String spendingMentality;
  final String riskAppetite;
  final String financialLiteracyLevel;
  final String financialPriority;
  final String savingHabit;
  final String financialStressLevel;
  final String occupation;
  final bool hasDataConsent;

  ReallocationUserProfileData({
    required this.userId,
    required this.incomeStability,
    required this.spendingMentality,
    required this.riskAppetite,
    required this.financialLiteracyLevel,
    required this.financialPriority,
    required this.savingHabit,
    required this.financialStressLevel,
    required this.occupation,
    required this.hasDataConsent,
  });

  factory ReallocationUserProfileData.fromProfile(UserBehaviorProfile profile) {
    return ReallocationUserProfileData(
      userId: profile.userId,
      incomeStability: profile.incomeStability.displayName,
      spendingMentality: profile.spendingMentality.displayName,
      riskAppetite: profile.riskAppetite.displayName,
      financialLiteracyLevel: profile.financialLiteracyLevel.displayName,
      financialPriority: profile.financialPriority.displayName,
      savingHabit: profile.savingHabit.displayName,
      financialStressLevel: profile.financialStressLevel.displayName,
      occupation: profile.occupation.displayName,
      hasDataConsent: profile.hasDataConsent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'incomeStability': incomeStability,
      'spendingMentality': spendingMentality,
      'riskAppetite': riskAppetite,
      'financialLiteracyLevel': financialLiteracyLevel,
      'financialPriority': financialPriority,
      'savingHabit': savingHabit,
      'financialStressLevel': financialStressLevel,
      'occupation': occupation,
      'hasDataConsent': hasDataConsent,
      'adviceComplexityLevel': _getAdviceComplexityLevel(),
      'adviceTone': _getAdviceTone(),
    };
  }

  /// Get appropriate advice complexity based on financial literacy
  String _getAdviceComplexityLevel() {
    switch (financialLiteracyLevel) {
      case 'beginner':
        return 'simple';
      case 'intermediate':
        return 'moderate';
      case 'advanced':
        return 'detailed';
      case 'expert':
        return 'comprehensive';
      default:
        return 'moderate';
    }
  }

  /// Get personalized advice tone based on literacy level
  String _getAdviceTone() {
    switch (financialLiteracyLevel) {
      case 'beginner':
        return 'educational and encouraging';
      case 'intermediate':
        return 'informative and supportive';
      case 'advanced':
        return 'detailed and analytical';
      case 'expert':
        return 'technical and comprehensive';
      default:
        return 'informative and supportive';
    }
  }
}

/// A snapshot of the budget, simplified for reallocation analysis.
class ReallocationBudgetData {
  final double total;
  final double left;
  final Map<String, ReallocationCategoryBudgetData> categories;
  final double saving;
  final String currency;

  ReallocationBudgetData({
    required this.total,
    required this.left,
    required this.categories,
    required this.saving,
    required this.currency,
  });

  factory ReallocationBudgetData.fromBudget(Budget budget) {
    return ReallocationBudgetData(
      total: budget.total,
      left: budget.left,
      categories: budget.categories.map(
        (key, value) => MapEntry(
          key,
          ReallocationCategoryBudgetData.fromCategoryBudget(value),
        ),
      ),
      saving: budget.saving,
      currency: budget.currency,
    );
  }

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

/// A snapshot of a category's budget, simplified for analysis.
class ReallocationCategoryBudgetData {
  final double budget;
  final double left;

  ReallocationCategoryBudgetData({
    required this.budget,
    required this.left,
  });

  factory ReallocationCategoryBudgetData.fromCategoryBudget(
      CategoryBudget categoryBudget) {
    return ReallocationCategoryBudgetData(
      budget: categoryBudget.budget,
      left: categoryBudget.left,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'budget': budget,
      'left': left,
    };
  }
}

/// A snapshot of an expense, simplified for reallocation analysis.
class ReallocationExpenseData {
  final double amount;
  final String categoryId;
  final DateTime date;
  final String currency;
  final String remark;
  final String? description;
  final String method;
  final RecurringDetails? recurringDetails;

  ReallocationExpenseData({
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.currency,
    required this.remark,
    this.description,
    required this.method,
    this.recurringDetails,
  });

  factory ReallocationExpenseData.fromExpense(Expense expense) {
    return ReallocationExpenseData(
      amount: expense.amount,
      categoryId: expense.category.id,
      date: expense.date,
      currency: expense.currency,
      remark: expense.remark,
      description: expense.description,
      method: expense.method.name,
      recurringDetails: expense.recurringDetails,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'currency': currency,
      'remark': remark,
      'description': description,
      'method': method,
      'recurringDetails': recurringDetails?.toJson(),
    };
  }
}

/// A snapshot of a financial goal, simplified for reallocation analysis.
class ReallocationGoalData {
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final bool isCompleted;

  ReallocationGoalData({
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.isCompleted,
  });

  factory ReallocationGoalData.fromGoal(FinancialGoal goal) {
    return ReallocationGoalData(
      title: goal.title,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      deadline: goal.deadline,
      isCompleted: goal.isCompleted,
    );
  }

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

// -----------------------------------------------------------------------------
// RESPONSE MODELS
// -----------------------------------------------------------------------------

/// Response model for budget reallocation suggestions.
class BudgetReallocationResponse {
  final List<ReallocationSuggestion> suggestions;
  final ReallocationMetadata? metadata;

  BudgetReallocationResponse({
    required this.suggestions,
    this.metadata,
  });

  factory BudgetReallocationResponse.fromJson(Map<String, dynamic> json) {
    return BudgetReallocationResponse(
      suggestions: (json['suggestions'] as List<dynamic>? ?? [])
          .map((item) => ReallocationSuggestion.fromJson(item))
          .toList(),
      metadata: json.containsKey('metadata')
          ? ReallocationMetadata.fromJson(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {
      'suggestions': suggestions.map((item) => item.toJson()).toList(),
    };

    if (metadata != null) {
      result['metadata'] = metadata!.toJson();
    }

    return result;
  }
}

/// Metadata for budget reallocation response.
class ReallocationMetadata {
  final String analysisId;
  final DateTime generatedAt;
  final String modelVersion;

  ReallocationMetadata({
    required this.analysisId,
    required this.generatedAt,
    required this.modelVersion,
  });

  factory ReallocationMetadata.fromJson(Map<String, dynamic> json) {
    return ReallocationMetadata(
      analysisId: json['analysis_id']?.toString() ?? '',
      generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? '') ??
          DateTime.now(),
      modelVersion: json['model_version']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysis_id': analysisId,
      'generated_at': generatedAt.toIso8601String(),
      'model_version': modelVersion,
    };
  }
}

/// A single budget reallocation suggestion from the AI model.
class ReallocationSuggestion {
  final String fromCategory;
  final String toCategory;
  final double amount;
  final String criticality;
  final String reason;

  ReallocationSuggestion({
    required this.fromCategory,
    required this.toCategory,
    required this.amount,
    required this.criticality,
    required this.reason,
  });

  factory ReallocationSuggestion.fromJson(Map<String, dynamic> json) {
    return ReallocationSuggestion(
      fromCategory: json['fromCategory'] ?? '',
      toCategory: json['toCategory'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      criticality: json['criticality'] ?? 'low',
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromCategory': fromCategory,
      'toCategory': toCategory,
      'amount': amount,
      'criticality': criticality,
      'reason': reason,
    };
  }
}
