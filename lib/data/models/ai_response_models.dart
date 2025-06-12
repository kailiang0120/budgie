import '../../domain/entities/expense.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';

/// Request model for expense prediction API
class ExpensePredictionRequest {
  final List<ExpenseData> pastExpenses;
  final BudgetData currentBudget;
  final String currency;
  final DateTime targetMonth;
  final Map<String, dynamic>? userProfile;

  ExpensePredictionRequest({
    required this.pastExpenses,
    required this.currentBudget,
    required this.currency,
    required this.targetMonth,
    this.userProfile,
  });

  Map<String, dynamic> toJson() {
    return {
      'pastExpenses': pastExpenses.map((e) => e.toJson()).toList(),
      'currentBudget': currentBudget.toJson(),
      'currency': currency,
      'targetMonth': targetMonth.toIso8601String(),
      'userProfile': userProfile,
    };
  }
}

/// Simplified expense data for prediction
class ExpenseData {
  final double amount;
  final String categoryId;
  final String categoryName;
  final DateTime date;
  final String currency;
  final String? description;

  ExpenseData({
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    required this.currency,
    this.description,
  });

  factory ExpenseData.fromExpense(Expense expense) {
    return ExpenseData(
      amount: expense.amount,
      categoryId: expense.category.id,
      categoryName: expense.category.name,
      date: expense.date,
      currency: expense.currency,
      description: expense.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'date': date.toIso8601String(),
      'currency': currency,
      'description': description,
    };
  }
}

/// Simplified budget data for prediction
class BudgetData {
  final double totalBudget;
  final double remainingBudget;
  final Map<String, CategoryBudgetData> categoryBudgets;
  final String currency;

  BudgetData({
    required this.totalBudget,
    required this.remainingBudget,
    required this.categoryBudgets,
    required this.currency,
  });

  factory BudgetData.fromBudget(Budget budget) {
    final categoryBudgets = budget.categories.map(
      (key, value) => MapEntry(
        key,
        CategoryBudgetData(
          budget: value.budget,
          remaining: value.left,
        ),
      ),
    );

    return BudgetData(
      totalBudget: budget.total,
      remainingBudget: budget.left,
      categoryBudgets: categoryBudgets,
      currency: budget.currency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBudget': totalBudget,
      'remainingBudget': remainingBudget,
      'categoryBudgets': categoryBudgets.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'currency': currency,
    };
  }
}

/// Category budget data for prediction
class CategoryBudgetData {
  final double budget;
  final double remaining;

  CategoryBudgetData({
    required this.budget,
    required this.remaining,
  });

  Map<String, dynamic> toJson() {
    return {
      'budget': budget,
      'remaining': remaining,
    };
  }
}

/// Response model for expense prediction
class ExpensePredictionResponse {
  final List<PredictedExpense> predictedExpenses;
  final PredictionSummary summary;
  final double confidenceScore;
  final List<SpendingInsight> insights;
  final List<BudgetReallocationSuggestion> budgetReallocationSuggestions;
  final Map<String, dynamic> metadata;

  ExpensePredictionResponse({
    required this.predictedExpenses,
    required this.summary,
    required this.confidenceScore,
    required this.insights,
    required this.budgetReallocationSuggestions,
    required this.metadata,
  });

  factory ExpensePredictionResponse.fromJson(Map<String, dynamic> json) {
    return ExpensePredictionResponse(
      predictedExpenses: (json['predictedExpenses'] as List? ?? [])
          .map((item) => PredictedExpense.fromJson(item))
          .toList(),
      summary: PredictionSummary.fromJson(json['summary'] ?? {}),
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      insights: (json['insights'] as List? ?? [])
          .map((item) => SpendingInsight.fromJson(item))
          .toList(),
      budgetReallocationSuggestions:
          (json['budgetReallocationSuggestions'] as List? ?? [])
              .map((item) => BudgetReallocationSuggestion.fromJson(item))
              .toList(),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'predictedExpenses': predictedExpenses.map((e) => e.toJson()).toList(),
      'summary': summary.toJson(),
      'confidenceScore': confidenceScore,
      'insights': insights.map((e) => e.toJson()).toList(),
      'budgetReallocationSuggestions':
          budgetReallocationSuggestions.map((e) => e.toJson()).toList(),
      'metadata': metadata,
    };
  }
}

/// Individual predicted expense
class PredictedExpense {
  final String categoryId;
  final String categoryName;
  final double predictedAmount;
  final DateTime estimatedDate;
  final double confidence;
  final String reasoning;
  final bool willExceedBudget;
  final double budgetShortfall;

  PredictedExpense({
    required this.categoryId,
    required this.categoryName,
    required this.predictedAmount,
    required this.estimatedDate,
    required this.confidence,
    required this.reasoning,
    required this.willExceedBudget,
    required this.budgetShortfall,
  });

  factory PredictedExpense.fromJson(Map<String, dynamic> json) {
    return PredictedExpense(
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      predictedAmount: (json['predictedAmount'] as num?)?.toDouble() ?? 0.0,
      estimatedDate:
          DateTime.tryParse(json['estimatedDate'] ?? '') ?? DateTime.now(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning'] ?? '',
      willExceedBudget: json['willExceedBudget'] ?? false,
      budgetShortfall: (json['budgetShortfall'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'predictedAmount': predictedAmount,
      'estimatedDate': estimatedDate.toIso8601String(),
      'confidence': confidence,
      'reasoning': reasoning,
      'willExceedBudget': willExceedBudget,
      'budgetShortfall': budgetShortfall,
    };
  }
}

/// Summary of prediction results
class PredictionSummary {
  final double totalPredictedSpending;
  final double budgetUtilizationRate;
  final String riskLevel;
  final List<String> categoriesAtRisk;
  final double totalBudgetShortfall;

  PredictionSummary({
    required this.totalPredictedSpending,
    required this.budgetUtilizationRate,
    required this.riskLevel,
    required this.categoriesAtRisk,
    required this.totalBudgetShortfall,
  });

  factory PredictionSummary.fromJson(Map<String, dynamic> json) {
    return PredictionSummary(
      totalPredictedSpending:
          (json['totalPredictedSpending'] as num?)?.toDouble() ?? 0.0,
      budgetUtilizationRate:
          (json['budgetUtilizationRate'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['riskLevel'] ?? 'low',
      categoriesAtRisk: List<String>.from(json['categoriesAtRisk'] ?? []),
      totalBudgetShortfall:
          (json['totalBudgetShortfall'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPredictedSpending': totalPredictedSpending,
      'budgetUtilizationRate': budgetUtilizationRate,
      'riskLevel': riskLevel,
      'categoriesAtRisk': categoriesAtRisk,
      'totalBudgetShortfall': totalBudgetShortfall,
    };
  }
}

/// Spending insight from AI analysis
class SpendingInsight {
  final String type;
  final String category;
  final String message;
  final double impact;
  final List<String> recommendations;

  SpendingInsight({
    required this.type,
    required this.category,
    required this.message,
    required this.impact,
    required this.recommendations,
  });

  factory SpendingInsight.fromJson(Map<String, dynamic> json) {
    return SpendingInsight(
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      message: json['message'] ?? '',
      impact: (json['impact'] as num?)?.toDouble() ?? 0.0,
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'category': category,
      'message': message,
      'impact': impact,
      'recommendations': recommendations,
    };
  }
}

/// Budget reallocation suggestion
class BudgetReallocationSuggestion {
  final String fromCategory;
  final String toCategory;
  final double suggestedAmount;
  final String reason;

  BudgetReallocationSuggestion({
    required this.fromCategory,
    required this.toCategory,
    required this.suggestedAmount,
    required this.reason,
  });

  factory BudgetReallocationSuggestion.fromJson(Map<String, dynamic> json) {
    return BudgetReallocationSuggestion(
      fromCategory: json['fromCategory'] ?? '',
      toCategory: json['toCategory'] ?? '',
      suggestedAmount: (json['suggestedAmount'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromCategory': fromCategory,
      'toCategory': toCategory,
      'suggestedAmount': suggestedAmount,
      'reason': reason,
    };
  }
}
