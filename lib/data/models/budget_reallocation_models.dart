import '../../domain/entities/expense.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/recurring_expense.dart';

/// Request model for budget reallocation analysis
class BudgetReallocationRequest {
  final BudgetSnapshot currentBudget;
  final List<ExpenseSnapshot> recentExpenses;
  final List<ExpenseSnapshot> recurringExpenses;
  final Map<String, double> categoryUtilization;
  final DateTime analysisDate;
  final String currency;
  final Map<String, dynamic>? userPreferences;

  BudgetReallocationRequest({
    required this.currentBudget,
    required this.recentExpenses,
    required this.recurringExpenses,
    required this.categoryUtilization,
    required this.analysisDate,
    required this.currency,
    this.userPreferences,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentBudget': currentBudget.toJson(),
      'recentExpenses': recentExpenses.map((e) => e.toJson()).toList(),
      'recurringExpenses': recurringExpenses.map((e) => e.toJson()).toList(),
      'categoryUtilization': categoryUtilization,
      'analysisDate': analysisDate.toIso8601String(),
      'currency': currency,
      'userPreferences': userPreferences,
    };
  }
}

/// Snapshot of current budget state for analysis
class BudgetSnapshot {
  final double totalBudget;
  final double totalRemaining;
  final Map<String, CategoryBudgetSnapshot> categories;
  final double savings;
  final String currency;
  final DateTime lastModified;

  BudgetSnapshot({
    required this.totalBudget,
    required this.totalRemaining,
    required this.categories,
    required this.savings,
    required this.currency,
    required this.lastModified,
  });

  factory BudgetSnapshot.fromBudget(Budget budget) {
    final categorySnapshots = budget.categories.map(
      (key, value) => MapEntry(
        key,
        CategoryBudgetSnapshot(
          categoryId: key,
          categoryName: CategoryExtension.fromId(key)?.name ?? key,
          allocated: value.budget,
          remaining: value.left,
          utilizationRate:
              value.budget > 0 ? (value.budget - value.left) / value.budget : 0,
        ),
      ),
    );

    return BudgetSnapshot(
      totalBudget: budget.total,
      totalRemaining: budget.left,
      categories: categorySnapshots,
      savings: budget.saving,
      currency: budget.currency,
      lastModified: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBudget': totalBudget,
      'totalRemaining': totalRemaining,
      'categories':
          categories.map((key, value) => MapEntry(key, value.toJson())),
      'savings': savings,
      'currency': currency,
      'lastModified': lastModified.toIso8601String(),
    };
  }
}

/// Category budget snapshot for analysis
class CategoryBudgetSnapshot {
  final String categoryId;
  final String categoryName;
  final double allocated;
  final double remaining;
  final double utilizationRate;

  CategoryBudgetSnapshot({
    required this.categoryId,
    required this.categoryName,
    required this.allocated,
    required this.remaining,
    required this.utilizationRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'allocated': allocated,
      'remaining': remaining,
      'utilizationRate': utilizationRate,
    };
  }
}

/// Simplified expense snapshot for reallocation analysis
class ExpenseSnapshot {
  final double amount;
  final String categoryId;
  final String categoryName;
  final DateTime date;
  final String description;
  final bool isRecurring;
  final int frequency; // days between occurrences for recurring expenses

  ExpenseSnapshot({
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    required this.description,
    this.isRecurring = false,
    this.frequency = 0,
  });

  factory ExpenseSnapshot.fromExpense(Expense expense) {
    int getFrequencyInDays(RecurringDetails? details) {
      if (details == null) return 0;
      switch (details.frequency) {
        case RecurringFrequency.weekly:
          return 7;
        case RecurringFrequency.monthly:
          return 30; // approximate
      }
    }

    return ExpenseSnapshot(
      amount: expense.amount,
      categoryId: expense.category.id,
      categoryName: expense.category.name,
      date: expense.date,
      description: expense.remark,
      isRecurring: expense.recurringDetails != null,
      frequency: getFrequencyInDays(expense.recurringDetails),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'date': date.toIso8601String(),
      'description': description,
      'isRecurring': isRecurring,
      'frequency': frequency,
    };
  }
}

/// Response model for budget reallocation recommendations
class BudgetReallocationResponse {
  final bool reallocationNeeded;
  final double confidenceScore;
  final List<ReallocationRecommendation> recommendations;
  final BudgetOptimizationSummary summary;
  final List<BudgetInsight> insights;
  final Map<String, dynamic> metadata;

  BudgetReallocationResponse({
    required this.reallocationNeeded,
    required this.confidenceScore,
    required this.recommendations,
    required this.summary,
    required this.insights,
    required this.metadata,
  });

  factory BudgetReallocationResponse.fromJson(Map<String, dynamic> json) {
    return BudgetReallocationResponse(
      reallocationNeeded: json['reallocationNeeded'] ?? false,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      recommendations: (json['recommendations'] as List? ?? [])
          .map((item) => ReallocationRecommendation.fromJson(item))
          .toList(),
      summary: BudgetOptimizationSummary.fromJson(json['summary'] ?? {}),
      insights: (json['insights'] as List? ?? [])
          .map((item) => BudgetInsight.fromJson(item))
          .toList(),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reallocationNeeded': reallocationNeeded,
      'confidenceScore': confidenceScore,
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'summary': summary.toJson(),
      'insights': insights.map((i) => i.toJson()).toList(),
      'metadata': metadata,
    };
  }
}

/// Individual reallocation recommendation
class ReallocationRecommendation {
  final String fromCategory;
  final String toCategory;
  final double amount;
  final String reasoning;
  final double impactScore; // 0-1 score indicating impact of this reallocation
  final String priority; // 'high', 'medium', 'low'
  final List<String> riskFactors;

  ReallocationRecommendation({
    required this.fromCategory,
    required this.toCategory,
    required this.amount,
    required this.reasoning,
    required this.impactScore,
    required this.priority,
    required this.riskFactors,
  });

  factory ReallocationRecommendation.fromJson(Map<String, dynamic> json) {
    return ReallocationRecommendation(
      fromCategory: json['fromCategory'] ?? '',
      toCategory: json['toCategory'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning'] ?? '',
      impactScore: (json['impactScore'] as num?)?.toDouble() ?? 0.0,
      priority: json['priority'] ?? 'low',
      riskFactors: List<String>.from(json['riskFactors'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromCategory': fromCategory,
      'toCategory': toCategory,
      'amount': amount,
      'reasoning': reasoning,
      'impactScore': impactScore,
      'priority': priority,
      'riskFactors': riskFactors,
    };
  }
}

/// Summary of budget optimization analysis
class BudgetOptimizationSummary {
  final double totalReallocationAmount;
  final int categoriesAffected;
  final double
      expectedImprovement; // percentage improvement in budget efficiency
  final String riskLevel; // 'low', 'medium', 'high'
  final List<String> primaryBenefits;
  final double implementationComplexity; // 0-1 score

  BudgetOptimizationSummary({
    required this.totalReallocationAmount,
    required this.categoriesAffected,
    required this.expectedImprovement,
    required this.riskLevel,
    required this.primaryBenefits,
    required this.implementationComplexity,
  });

  factory BudgetOptimizationSummary.fromJson(Map<String, dynamic> json) {
    return BudgetOptimizationSummary(
      totalReallocationAmount:
          (json['totalReallocationAmount'] as num?)?.toDouble() ?? 0.0,
      categoriesAffected: json['categoriesAffected'] ?? 0,
      expectedImprovement:
          (json['expectedImprovement'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['riskLevel'] ?? 'low',
      primaryBenefits: List<String>.from(json['primaryBenefits'] ?? []),
      implementationComplexity:
          (json['implementationComplexity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalReallocationAmount': totalReallocationAmount,
      'categoriesAffected': categoriesAffected,
      'expectedImprovement': expectedImprovement,
      'riskLevel': riskLevel,
      'primaryBenefits': primaryBenefits,
      'implementationComplexity': implementationComplexity,
    };
  }
}

/// Budget insight from AI analysis
class BudgetInsight {
  final String type; // 'opportunity', 'warning', 'optimization', 'trend'
  final String category;
  final String message;
  final double severity; // 0-1 score
  final List<String> actionItems;
  final Map<String, dynamic>? data; // Additional structured data

  BudgetInsight({
    required this.type,
    required this.category,
    required this.message,
    required this.severity,
    required this.actionItems,
    this.data,
  });

  factory BudgetInsight.fromJson(Map<String, dynamic> json) {
    return BudgetInsight(
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      message: json['message'] ?? '',
      severity: (json['severity'] as num?)?.toDouble() ?? 0.0,
      actionItems: List<String>.from(json['actionItems'] ?? []),
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'category': category,
      'message': message,
      'severity': severity,
      'actionItems': actionItems,
      'data': data,
    };
  }
}
