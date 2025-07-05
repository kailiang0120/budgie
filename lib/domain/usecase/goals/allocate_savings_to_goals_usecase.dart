import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../entities/financial_goal.dart';
import '../../entities/expense.dart';
import '../../entities/category.dart' as domain_category;
import '../../repositories/goals_repository.dart';
import '../../repositories/budget_repository.dart';
import '../../repositories/expenses_repository.dart';
import '../../services/goal_funding_service.dart';

/// Use case for allocating available savings to financial goals
class AllocateSavingsToGoalsUseCase {
  final GoalsRepository _goalsRepository;
  final BudgetRepository _budgetRepository;
  final ExpensesRepository _expensesRepository;
  final GoalFundingService _fundingService;
  final Uuid _uuid = const Uuid();

  AllocateSavingsToGoalsUseCase({
    required GoalsRepository goalsRepository,
    required BudgetRepository budgetRepository,
    required ExpensesRepository expensesRepository,
    required GoalFundingService fundingService,
  })  : _goalsRepository = goalsRepository,
        _budgetRepository = budgetRepository,
        _expensesRepository = expensesRepository,
        _fundingService = fundingService;

  /// Execute the allocation of savings to goals
  /// Returns a map of goal IDs to the amount allocated to each
  Future<Map<String, double>> execute() async {
    try {
      debugPrint('🎯 AllocateSavingsUseCase: Starting savings allocation...');

      // Get active goals
      final activeGoals = await _goalsRepository.getActiveGoals();
      debugPrint(
          '🎯 AllocateSavingsUseCase: Found ${activeGoals.length} active goals');

      if (activeGoals.isEmpty) {
        debugPrint('🎯 AllocateSavingsUseCase: No active goals to fund');
        return {};
      }

      // Get last month's savings (budget left over)
      final lastMonthSavings = await _getLastMonthSavings();
      debugPrint(
          '🎯 AllocateSavingsUseCase: Last month savings: RM $lastMonthSavings');

      if (lastMonthSavings <= 0) {
        debugPrint(
            '🎯 AllocateSavingsUseCase: No savings available to allocate');
        return {};
      }

      // Calculate funding distribution
      final distribution = _fundingService.calculateFundingDistribution(
        activeGoals: activeGoals,
        availableSavings: lastMonthSavings,
      );

      debugPrint(
          '🎯 AllocateSavingsUseCase: Distribution calculated: $distribution');

      // Calculate total amount being allocated
      final totalAllocated =
          distribution.values.fold(0.0, (sum, amount) => sum + amount);

      // Apply the funding to each goal
      for (final entry in distribution.entries) {
        final goalId = entry.key;
        final amount = entry.value;

        if (amount > 0) {
          final goal = activeGoals.firstWhere((g) => g.id == goalId);
          final newAmount = goal.currentAmount + amount;

          // Update the goal with new amount
          final updatedGoal = goal.copyWithNewAmount(newAmount);
          await _goalsRepository.updateGoal(updatedGoal);

          debugPrint(
              '🎯 AllocateSavingsUseCase: Added RM $amount to goal "${goal.title}"');
        }
      }

      // Create expense entry for goal funding in "Others" category
      if (totalAllocated > 0) {
        await _createGoalFundingExpense(totalAllocated);
      }

      debugPrint(
          '🎯 AllocateSavingsUseCase: Savings allocation completed successfully');
      return distribution;
    } catch (e) {
      debugPrint('🎯 AllocateSavingsUseCase: Error allocating savings: $e');
      rethrow;
    }
  }

  /// Get the savings amount from last month's budget
  Future<double> _getLastMonthSavings() async {
    try {
      // Get last month's date
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1);
      final monthId =
          '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}';

      // Get last month's budget
      final budget = await _budgetRepository.getBudget(monthId);

      if (budget != null) {
        // Return the amount left in the budget (savings)
        return budget.left > 0 ? budget.left : 0;
      }

      return 0;
    } catch (e) {
      debugPrint(
          '🎯 AllocateSavingsUseCase: Error getting last month savings: $e');
      return 0;
    }
  }

  /// Preview the funding distribution without actually applying it
  Future<Map<String, double>> previewDistribution() async {
    try {
      final activeGoals = await _goalsRepository.getActiveGoals();
      final lastMonthSavings = await _getLastMonthSavings();

      if (activeGoals.isEmpty || lastMonthSavings <= 0) {
        return {};
      }

      return _fundingService.calculateFundingDistribution(
        activeGoals: activeGoals,
        availableSavings: lastMonthSavings,
      );
    } catch (e) {
      debugPrint(
          '🎯 AllocateSavingsUseCase: Error previewing distribution: $e');
      return {};
    }
  }

  /// Preview custom funding distribution with specified amount
  Future<Map<String, double>> previewCustomDistribution(
      double customAmount) async {
    try {
      final activeGoals = await _goalsRepository.getActiveGoals();
      final availableSavings = await _getLastMonthSavings();

      if (activeGoals.isEmpty ||
          customAmount <= 0 ||
          customAmount > availableSavings) {
        return {};
      }

      return _fundingService.calculateFundingDistribution(
        activeGoals: activeGoals,
        availableSavings: customAmount,
      );
    } catch (e) {
      debugPrint(
          '🎯 AllocateSavingsUseCase: Error previewing custom distribution: $e');
      return {};
    }
  }

  /// Execute custom allocation with specific amount
  Future<Map<String, double>> executeCustom(double customAmount) async {
    try {
      debugPrint(
          '🎯 AllocateSavingsUseCase: Starting custom savings allocation of RM $customAmount...');

      // Get active goals
      final activeGoals = await _goalsRepository.getActiveGoals();
      debugPrint(
          '🎯 AllocateSavingsUseCase: Found ${activeGoals.length} active goals');

      if (activeGoals.isEmpty) {
        debugPrint('🎯 AllocateSavingsUseCase: No active goals to fund');
        return {};
      }

      // Validate custom amount against available savings
      final availableSavings = await _getLastMonthSavings();
      if (customAmount <= 0 || customAmount > availableSavings) {
        debugPrint(
            '🎯 AllocateSavingsUseCase: Invalid custom amount: RM $customAmount (available: RM $availableSavings)');
        return {};
      }

      // Calculate funding distribution with custom amount
      final distribution = _fundingService.calculateFundingDistribution(
        activeGoals: activeGoals,
        availableSavings: customAmount,
      );

      debugPrint(
          '🎯 AllocateSavingsUseCase: Custom distribution calculated: $distribution');

      // Calculate total amount being allocated
      final totalAllocated =
          distribution.values.fold(0.0, (sum, amount) => sum + amount);

      // Apply the funding to each goal
      for (final entry in distribution.entries) {
        final goalId = entry.key;
        final amount = entry.value;

        if (amount > 0) {
          final goal = activeGoals.firstWhere((g) => g.id == goalId);
          final newAmount = goal.currentAmount + amount;

          // Update the goal with new amount
          final updatedGoal = goal.copyWithNewAmount(newAmount);
          await _goalsRepository.updateGoal(updatedGoal);

          debugPrint(
              '🎯 AllocateSavingsUseCase: Added RM $amount to goal "${goal.title}"');
        }
      }

      // Create expense entry for goal funding in "Others" category
      if (totalAllocated > 0) {
        await _createGoalFundingExpense(totalAllocated);
      }

      debugPrint(
          '🎯 AllocateSavingsUseCase: Custom savings allocation completed successfully');
      return distribution;
    } catch (e) {
      debugPrint(
          '🎯 AllocateSavingsUseCase: Error allocating custom savings: $e');
      rethrow;
    }
  }

  /// Get available savings amount without allocating
  Future<double> getAvailableSavings() async {
    return await _getLastMonthSavings();
  }

  /// Create an expense entry for goal funding
  Future<void> _createGoalFundingExpense(double amount) async {
    try {
      final expense = Expense(
        id: _uuid.v4(),
        remark: 'Goals funding',
        amount: amount,
        date: DateTime.now(),
        category: domain_category.Category.others,
        method: PaymentMethod.other,
        description: 'Automatic allocation of savings to financial goals',
        currency: 'MYR',
      );

      await _expensesRepository.addExpense(expense);
      debugPrint(
          '🎯 AllocateSavingsUseCase: Created goal funding expense of RM $amount');
    } catch (e) {
      debugPrint(
          '🎯 AllocateSavingsUseCase: Error creating goal funding expense: $e');
      // Don't rethrow - goal funding should still succeed even if expense creation fails
    }
  }
}
