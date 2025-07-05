import 'package:equatable/equatable.dart';

/// Enumeration for primary financial goals
enum FinancialGoalType {
  aggressiveSaving(
      'Aggressive Saving', 'Focus on maximizing savings and building wealth'),
  balancedGrowth('Balanced Growth',
      'Balance between spending and saving for steady growth'),
  debtReduction(
      'Debt Reduction', 'Priority on paying off debts and becoming debt-free'),
  lifestyleSpending(
      'Lifestyle Spending', 'Enjoy life while maintaining financial stability');

  const FinancialGoalType(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// Enumeration for income stability patterns
enum IncomeStability {
  stable('Stable', 'Consistent monthly income (salary, pension)'),
  variable('Variable', 'Income varies but predictable (commission, freelance)'),
  irregular('Irregular', 'Unpredictable income patterns (gig work, seasonal)');

  const IncomeStability(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// Enumeration for spending mentality
enum SpendingMentality {
  conscious('Conscious Spender', 'Carefully consider every purchase'),
  balanced('Balanced Spender', 'Mix of planned and spontaneous spending'),
  spontaneous('Spontaneous Spender', 'Often make impulse purchases');

  const SpendingMentality(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// Enumeration for risk appetite
enum RiskAppetite {
  low('Low Risk', 'Prefer guaranteed returns and stability'),
  medium('Medium Risk', 'Balanced approach to risk and reward'),
  high('High Risk', 'Comfortable with higher risk for potential gains');

  const RiskAppetite(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// Enumeration for spending categories priority
enum CategoryPriority {
  essential('Essential', 'Necessary for basic living'),
  important('Important', 'Valuable but not critical'),
  optional('Optional', 'Nice to have but can be reduced');

  const CategoryPriority(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// User's AI automation preferences
class AIAutomationPreferences extends Equatable {
  final bool enableBudgetReallocation;
  final bool enableSpendingAlerts;
  final bool enableGoalRecommendations;
  final bool enableExpenseClassification;
  final bool enableSavingsOptimization;
  final double automationAggressiveness; // 0.0 to 1.0
  final double alertSensitivity; // 0.0 to 1.0

  const AIAutomationPreferences({
    this.enableBudgetReallocation = true,
    this.enableSpendingAlerts = true,
    this.enableGoalRecommendations = true,
    this.enableExpenseClassification = true,
    this.enableSavingsOptimization = true,
    this.automationAggressiveness = 0.5,
    this.alertSensitivity = 0.5,
  });

  @override
  List<Object?> get props => [
        enableBudgetReallocation,
        enableSpendingAlerts,
        enableGoalRecommendations,
        enableExpenseClassification,
        enableSavingsOptimization,
        automationAggressiveness,
        alertSensitivity,
      ];

  AIAutomationPreferences copyWith({
    bool? enableBudgetReallocation,
    bool? enableSpendingAlerts,
    bool? enableGoalRecommendations,
    bool? enableExpenseClassification,
    bool? enableSavingsOptimization,
    double? automationAggressiveness,
    double? alertSensitivity,
  }) {
    return AIAutomationPreferences(
      enableBudgetReallocation:
          enableBudgetReallocation ?? this.enableBudgetReallocation,
      enableSpendingAlerts: enableSpendingAlerts ?? this.enableSpendingAlerts,
      enableGoalRecommendations:
          enableGoalRecommendations ?? this.enableGoalRecommendations,
      enableExpenseClassification:
          enableExpenseClassification ?? this.enableExpenseClassification,
      enableSavingsOptimization:
          enableSavingsOptimization ?? this.enableSavingsOptimization,
      automationAggressiveness:
          automationAggressiveness ?? this.automationAggressiveness,
      alertSensitivity: alertSensitivity ?? this.alertSensitivity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableBudgetReallocation': enableBudgetReallocation,
      'enableSpendingAlerts': enableSpendingAlerts,
      'enableGoalRecommendations': enableGoalRecommendations,
      'enableExpenseClassification': enableExpenseClassification,
      'enableSavingsOptimization': enableSavingsOptimization,
      'automationAggressiveness': automationAggressiveness,
      'alertSensitivity': alertSensitivity,
    };
  }

  factory AIAutomationPreferences.fromMap(Map<String, dynamic> map) {
    return AIAutomationPreferences(
      enableBudgetReallocation: map['enableBudgetReallocation'] ?? true,
      enableSpendingAlerts: map['enableSpendingAlerts'] ?? true,
      enableGoalRecommendations: map['enableGoalRecommendations'] ?? true,
      enableExpenseClassification: map['enableExpenseClassification'] ?? true,
      enableSavingsOptimization: map['enableSavingsOptimization'] ?? true,
      automationAggressiveness:
          (map['automationAggressiveness'] ?? 0.5).toDouble(),
      alertSensitivity: (map['alertSensitivity'] ?? 0.5).toDouble(),
    );
  }
}

/// User's spending category preferences
class CategoryPreferences extends Equatable {
  final Map<String, CategoryPriority> categoryPriorities;
  final Map<String, double> categoryLimits; // Percentage of income
  final List<String> flexibleCategories; // Can be reduced if needed

  const CategoryPreferences({
    this.categoryPriorities = const {},
    this.categoryLimits = const {},
    this.flexibleCategories = const [],
  });

  @override
  List<Object?> get props =>
      [categoryPriorities, categoryLimits, flexibleCategories];

  CategoryPreferences copyWith({
    Map<String, CategoryPriority>? categoryPriorities,
    Map<String, double>? categoryLimits,
    List<String>? flexibleCategories,
  }) {
    return CategoryPreferences(
      categoryPriorities: categoryPriorities ?? this.categoryPriorities,
      categoryLimits: categoryLimits ?? this.categoryLimits,
      flexibleCategories: flexibleCategories ?? this.flexibleCategories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryPriorities':
          categoryPriorities.map((k, v) => MapEntry(k, v.name)),
      'categoryLimits': categoryLimits,
      'flexibleCategories': flexibleCategories,
    };
  }

  factory CategoryPreferences.fromMap(Map<String, dynamic> map) {
    return CategoryPreferences(
      categoryPriorities: (map['categoryPriorities'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(
                  k,
                  CategoryPriority.values.firstWhere(
                    (priority) => priority.name == v,
                    orElse: () => CategoryPriority.important,
                  ))) ??
          {},
      categoryLimits: Map<String, double>.from(map['categoryLimits'] ?? {}),
      flexibleCategories: List<String>.from(map['flexibleCategories'] ?? []),
    );
  }
}

/// Comprehensive user behavior profile
class UserBehaviorProfile extends Equatable {
  final String id;
  final String userId;
  final FinancialGoalType primaryFinancialGoal;
  final IncomeStability incomeStability;
  final SpendingMentality spendingMentality;
  final RiskAppetite riskAppetite;
  final double monthlyIncome;
  final double emergencyFundTarget; // In months of expenses
  final AIAutomationPreferences aiPreferences;
  final CategoryPreferences categoryPreferences;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isComplete;

  const UserBehaviorProfile({
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
    required this.createdAt,
    required this.updatedAt,
    required this.isComplete,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        primaryFinancialGoal,
        incomeStability,
        spendingMentality,
        riskAppetite,
        monthlyIncome,
        emergencyFundTarget,
        aiPreferences,
        categoryPreferences,
        createdAt,
        updatedAt,
        isComplete,
      ];

  UserBehaviorProfile copyWith({
    String? id,
    String? userId,
    FinancialGoalType? primaryFinancialGoal,
    IncomeStability? incomeStability,
    SpendingMentality? spendingMentality,
    RiskAppetite? riskAppetite,
    double? monthlyIncome,
    double? emergencyFundTarget,
    AIAutomationPreferences? aiPreferences,
    CategoryPreferences? categoryPreferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isComplete,
  }) {
    return UserBehaviorProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      primaryFinancialGoal: primaryFinancialGoal ?? this.primaryFinancialGoal,
      incomeStability: incomeStability ?? this.incomeStability,
      spendingMentality: spendingMentality ?? this.spendingMentality,
      riskAppetite: riskAppetite ?? this.riskAppetite,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      emergencyFundTarget: emergencyFundTarget ?? this.emergencyFundTarget,
      aiPreferences: aiPreferences ?? this.aiPreferences,
      categoryPreferences: categoryPreferences ?? this.categoryPreferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'primaryFinancialGoal': primaryFinancialGoal.name,
      'incomeStability': incomeStability.name,
      'spendingMentality': spendingMentality.name,
      'riskAppetite': riskAppetite.name,
      'monthlyIncome': monthlyIncome,
      'emergencyFundTarget': emergencyFundTarget,
      'aiPreferences': aiPreferences.toMap(),
      'categoryPreferences': categoryPreferences.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isComplete': isComplete,
    };
  }

  factory UserBehaviorProfile.fromMap(Map<String, dynamic> map) {
    return UserBehaviorProfile(
      id: map['id'],
      userId: map['userId'],
      primaryFinancialGoal: FinancialGoalType.values.firstWhere(
        (goal) => goal.name == map['primaryFinancialGoal'],
        orElse: () => FinancialGoalType.balancedGrowth,
      ),
      incomeStability: IncomeStability.values.firstWhere(
        (stability) => stability.name == map['incomeStability'],
        orElse: () => IncomeStability.stable,
      ),
      spendingMentality: SpendingMentality.values.firstWhere(
        (mentality) => mentality.name == map['spendingMentality'],
        orElse: () => SpendingMentality.balanced,
      ),
      riskAppetite: RiskAppetite.values.firstWhere(
        (risk) => risk.name == map['riskAppetite'],
        orElse: () => RiskAppetite.medium,
      ),
      monthlyIncome: (map['monthlyIncome'] ?? 0.0).toDouble(),
      emergencyFundTarget: (map['emergencyFundTarget'] ?? 3.0).toDouble(),
      aiPreferences:
          AIAutomationPreferences.fromMap(map['aiPreferences'] ?? {}),
      categoryPreferences:
          CategoryPreferences.fromMap(map['categoryPreferences'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isComplete: map['isComplete'] ?? false,
    );
  }

  /// Create a new incomplete profile
  factory UserBehaviorProfile.createNew(String userId) {
    final now = DateTime.now();
    return UserBehaviorProfile(
      id: '', // Will be generated by repository
      userId: userId,
      primaryFinancialGoal: FinancialGoalType.balancedGrowth,
      incomeStability: IncomeStability.stable,
      spendingMentality: SpendingMentality.balanced,
      riskAppetite: RiskAppetite.medium,
      monthlyIncome: 0.0,
      emergencyFundTarget: 3.0,
      aiPreferences: const AIAutomationPreferences(),
      categoryPreferences: const CategoryPreferences(),
      createdAt: now,
      updatedAt: now,
      isComplete: false,
    );
  }
}
