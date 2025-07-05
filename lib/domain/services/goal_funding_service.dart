import '../entities/financial_goal.dart';

/// Service for calculating goal funding distribution
class GoalFundingService {
  /// Calculate how to distribute available savings across active goals
  ///
  /// The algorithm prioritizes goals based on urgency score which considers:
  /// - Time remaining until deadline (more urgent = higher priority)
  /// - Amount remaining to reach target (larger remaining = higher priority)
  /// - Current progress (lower progress = higher priority)
  Map<String, double> calculateFundingDistribution({
    required List<FinancialGoal> activeGoals,
    required double availableSavings,
  }) {
    if (activeGoals.isEmpty || availableSavings <= 0) {
      return {};
    }

    // Filter out completed goals
    final incompleteGoals =
        activeGoals.where((goal) => !goal.isCompleted).toList();

    if (incompleteGoals.isEmpty) {
      return {};
    }

    // Calculate urgency scores for each goal
    final goalScores = <String, double>{};
    double totalUrgencyScore = 0;

    for (final goal in incompleteGoals) {
      final urgencyScore = _calculateUrgencyScore(goal);
      goalScores[goal.id] = urgencyScore;
      totalUrgencyScore += urgencyScore;
    }

    // Distribute savings proportionally based on urgency scores
    final distribution = <String, double>{};
    double allocatedAmount = 0;

    for (final goal in incompleteGoals) {
      final score = goalScores[goal.id]!;
      final proportion = score / totalUrgencyScore;
      final allocation = availableSavings * proportion;

      // Don't allocate more than what's needed to complete the goal
      final maxNeeded = goal.amountRemaining;
      final finalAllocation = allocation > maxNeeded ? maxNeeded : allocation;

      distribution[goal.id] = finalAllocation;
      allocatedAmount += finalAllocation;
    }

    return distribution;
  }

  /// Calculate urgency score for a goal
  /// Higher score = more urgent = higher priority for funding
  double _calculateUrgencyScore(FinancialGoal goal) {
    // Base score factors
    const double maxDays = 365.0; // Normalize days remaining
    const double progressWeight = 0.3;
    const double timeWeight = 0.4;
    const double amountWeight = 0.3;

    // 1. Progress factor (lower progress = higher urgency)
    // Invert progress so that goals with less progress get higher scores
    final progressFactor = (1.0 - goal.progress) * progressWeight;

    // 2. Time factor (less time remaining = higher urgency)
    final daysRemaining = goal.daysRemaining.toDouble();
    final normalizedTimeRemaining = (daysRemaining / maxDays).clamp(0.0, 1.0);
    // Invert so that less time remaining = higher score
    final timeFactor = (1.0 - normalizedTimeRemaining) * timeWeight;

    // 3. Amount factor (larger remaining amount = higher urgency)
    // Normalize based on target amount to make it fair across different goal sizes
    final amountRemainingRatio = goal.amountRemaining / goal.targetAmount;
    final amountFactor = amountRemainingRatio * amountWeight;

    // Calculate final urgency score
    final urgencyScore = progressFactor + timeFactor + amountFactor;

    // Apply deadline penalty for overdue goals (boost their priority)
    if (goal.isOverdue) {
      return urgencyScore * 1.5; // 50% boost for overdue goals
    }

    return urgencyScore;
  }

  /// Calculate recommended monthly contribution for each goal
  /// to meet deadlines based on remaining time and amount
  Map<String, double> calculateRecommendedContributions(
    List<FinancialGoal> activeGoals,
  ) {
    final recommendations = <String, double>{};

    for (final goal in activeGoals) {
      if (goal.isCompleted) continue;

      final monthsRemaining = goal.daysRemaining / 30.0;

      if (monthsRemaining <= 0) {
        // Goal is overdue, recommend paying it all
        recommendations[goal.id] = goal.amountRemaining;
      } else {
        // Calculate monthly amount needed
        final monthlyContribution = goal.amountRemaining / monthsRemaining;
        recommendations[goal.id] = monthlyContribution;
      }
    }

    return recommendations;
  }

  /// Check if a funding amount would complete any goals
  List<FinancialGoal> getGoalsThatWouldComplete({
    required List<FinancialGoal> goals,
    required Map<String, double> fundingDistribution,
  }) {
    final completableGoals = <FinancialGoal>[];

    for (final goal in goals) {
      final funding = fundingDistribution[goal.id] ?? 0;
      if (funding > 0 && (goal.currentAmount + funding) >= goal.targetAmount) {
        completableGoals.add(goal);
      }
    }

    return completableGoals;
  }
}
