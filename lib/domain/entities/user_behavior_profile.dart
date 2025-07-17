import 'package:equatable/equatable.dart';

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

/// Enumeration for financial literacy level
enum FinancialLiteracyLevel {
  beginner('Beginner', 'New to personal finance and investing concepts'),
  intermediate(
      'Intermediate', 'Some knowledge of budgeting and basic investments'),
  advanced('Advanced',
      'Well-versed in financial planning and investment strategies'),
  expert('Expert',
      'Deep understanding of complex financial instruments and strategies');

  const FinancialLiteracyLevel(this.displayName, this.description);
  final String displayName;
  final String description;
}

enum FinancialPriority {
  saving,
  spending,
  investing,
  debtRepayment,
  other,
}

enum SavingHabit {
  regular,
  occasional,
  rarely,
  never,
}

enum FinancialStressLevel {
  low,
  moderate,
  high,
}

enum TechnologyAdoption {
  earlyAdopter,
  average,
  reluctant,
}

/// Comprehensive user behavior profile
class UserBehaviorProfile extends Equatable {
  final String id;
  final String userId;
  final IncomeStability incomeStability;
  final SpendingMentality spendingMentality;
  final RiskAppetite riskAppetite;
  final FinancialLiteracyLevel financialLiteracyLevel;
  final FinancialPriority financialPriority;
  final SavingHabit savingHabit;
  final FinancialStressLevel financialStressLevel;
  final TechnologyAdoption technologyAdoption;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dataConsentAcceptedAt; // Track when user accepted data usage
  final bool isComplete;

  const UserBehaviorProfile({
    required this.id,
    required this.userId,
    required this.incomeStability,
    required this.spendingMentality,
    required this.riskAppetite,
    required this.financialLiteracyLevel,
    required this.financialPriority,
    required this.savingHabit,
    required this.financialStressLevel,
    required this.technologyAdoption,
    required this.createdAt,
    required this.updatedAt,
    this.dataConsentAcceptedAt,
    required this.isComplete,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        incomeStability,
        spendingMentality,
        riskAppetite,
        financialLiteracyLevel,
        financialPriority,
        savingHabit,
        financialStressLevel,
        technologyAdoption,
        createdAt,
        updatedAt,
        dataConsentAcceptedAt,
        isComplete,
      ];

  UserBehaviorProfile copyWith({
    String? id,
    String? userId,
    IncomeStability? incomeStability,
    SpendingMentality? spendingMentality,
    RiskAppetite? riskAppetite,
    FinancialLiteracyLevel? financialLiteracyLevel,
    FinancialPriority? financialPriority,
    SavingHabit? savingHabit,
    FinancialStressLevel? financialStressLevel,
    TechnologyAdoption? technologyAdoption,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dataConsentAcceptedAt,
    bool? isComplete,
  }) {
    return UserBehaviorProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      incomeStability: incomeStability ?? this.incomeStability,
      spendingMentality: spendingMentality ?? this.spendingMentality,
      riskAppetite: riskAppetite ?? this.riskAppetite,
      financialLiteracyLevel:
          financialLiteracyLevel ?? this.financialLiteracyLevel,
      financialPriority: financialPriority ?? this.financialPriority,
      savingHabit: savingHabit ?? this.savingHabit,
      financialStressLevel: financialStressLevel ?? this.financialStressLevel,
      technologyAdoption: technologyAdoption ?? this.technologyAdoption,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dataConsentAcceptedAt:
          dataConsentAcceptedAt ?? this.dataConsentAcceptedAt,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'incomeStability': incomeStability.name,
      'spendingMentality': spendingMentality.name,
      'riskAppetite': riskAppetite.name,
      'financialLiteracyLevel': financialLiteracyLevel.name,
      'financialPriority': financialPriority.name,
      'savingHabit': savingHabit.name,
      'financialStressLevel': financialStressLevel.name,
      'technologyAdoption': technologyAdoption.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'dataConsentAcceptedAt': dataConsentAcceptedAt?.toIso8601String(),
      'isComplete': isComplete,
    };
  }

  factory UserBehaviorProfile.fromMap(Map<String, dynamic> map) {
    return UserBehaviorProfile(
      id: map['id'],
      userId: map['userId'],
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
      financialLiteracyLevel: FinancialLiteracyLevel.values.firstWhere(
        (level) => level.name == map['financialLiteracyLevel'],
        orElse: () => FinancialLiteracyLevel.intermediate,
      ),
      financialPriority: FinancialPriority.values.firstWhere(
        (priority) => priority.name == map['financialPriority'],
        orElse: () => FinancialPriority.saving,
      ),
      savingHabit: SavingHabit.values.firstWhere(
        (habit) => habit.name == map['savingHabit'],
        orElse: () => SavingHabit.regular,
      ),
      financialStressLevel: FinancialStressLevel.values.firstWhere(
        (level) => level.name == map['financialStressLevel'],
        orElse: () => FinancialStressLevel.moderate,
      ),
      technologyAdoption: TechnologyAdoption.values.firstWhere(
        (adoption) => adoption.name == map['technologyAdoption'],
        orElse: () => TechnologyAdoption.average,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      dataConsentAcceptedAt: map['dataConsentAcceptedAt'] != null
          ? DateTime.parse(map['dataConsentAcceptedAt'])
          : null,
      isComplete: map['isComplete'] ?? false,
    );
  }

  /// Create a new incomplete profile
  factory UserBehaviorProfile.createNew(String userId) {
    final now = DateTime.now();
    return UserBehaviorProfile(
      id: '', // Will be generated by repository
      userId: userId,
      incomeStability: IncomeStability.stable,
      spendingMentality: SpendingMentality.balanced,
      riskAppetite: RiskAppetite.medium,
      financialLiteracyLevel: FinancialLiteracyLevel.intermediate,
      financialPriority: FinancialPriority.saving,
      savingHabit: SavingHabit.regular,
      financialStressLevel: FinancialStressLevel.moderate,
      technologyAdoption: TechnologyAdoption.average,
      createdAt: now,
      updatedAt: now,
      dataConsentAcceptedAt: null,
      isComplete: false,
    );
  }

  /// Check if user has consented to data usage
  bool get hasDataConsent => dataConsentAcceptedAt != null;

  /// Get appropriate advice complexity based on financial literacy
  String get adviceComplexityLevel {
    switch (financialLiteracyLevel) {
      case FinancialLiteracyLevel.beginner:
        return 'simple';
      case FinancialLiteracyLevel.intermediate:
        return 'moderate';
      case FinancialLiteracyLevel.advanced:
        return 'detailed';
      case FinancialLiteracyLevel.expert:
        return 'comprehensive';
    }
  }

  /// Get personalized advice tone based on literacy level
  String get adviceTone {
    switch (financialLiteracyLevel) {
      case FinancialLiteracyLevel.beginner:
        return 'educational and encouraging';
      case FinancialLiteracyLevel.intermediate:
        return 'informative and supportive';
      case FinancialLiteracyLevel.advanced:
        return 'detailed and analytical';
      case FinancialLiteracyLevel.expert:
        return 'technical and comprehensive';
    }
  }
}
