import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../entities/expense.dart';
import '../../entities/category.dart' as domain_category;
import '../../entities/budget.dart' as domain;
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

      // Get available savings from all budget months
      final availableSavings = await _getAvailableSavings();
      debugPrint(
          '🎯 AllocateSavingsUseCase: Available savings: RM $availableSavings');

      if (availableSavings <= 0) {
        debugPrint(
            '🎯 AllocateSavingsUseCase: No savings available to allocate');
        return {};
      }

      // Calculate funding distribution
      final distribution = _fundingService.calculateFundingDistribution(
        activeGoals: activeGoals,
        availableSavings: availableSavings,
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

      // Create expense entries for goal funding and update budgets
      if (totalAllocated > 0) {
        await _createGoalFundingExpensesAndUpdateBudgets(totalAllocated);
      }

      debugPrint(
          '🎯 AllocateSavingsUseCase: Savings allocation completed successfully');
      return distribution;
    } catch (e) {
      debugPrint('🎯 AllocateSavingsUseCase: Error allocating savings: $e');
      rethrow;
    }
  }

  /// Get the savings amount from available budget months
  Future<double> _getAvailableSavings() async {
    try {
      // Get budgets from previous months only that have available savings
      final budgetsWithSavings =
          await _budgetRepository.getPreviousMonthBudgetsWithSavings();

      double totalSavings = 0.0;
      for (final budgetWithMonth in budgetsWithSavings) {
        // Use the saving field (unallocated budget) instead of left field
        totalSavings += budgetWithMonth.budget.saving;
      }

      debugPrint(
          '🎯 AllocateSavingsUseCase: Found ${budgetsWithSavings.length} previous months with savings, total: RM $totalSavings');
      return totalSavings;
    } catch (e) {
      debugPrint(
          '🎯 AllocateSavingsUseCase: Error getting available savings: $e');
      return 0;
    }
  }

  /// Get budgets with available savings for funding
  Future<List<BudgetWithMonth>> _getBudgetsWithSavings() async {
    try {
      return await _budgetRepository.getPreviousMonthBudgetsWithSavings();
    } catch (e) {
      debugPrint(
          '🎯 AllocateSavingsUseCase: Error getting budgets with savings: $e');
      return [];
    }
  }

  /// Preview the funding distribution without actually applying it
  Future<Map<String, double>> previewDistribution() async {
    try {
      final activeGoals = await _goalsRepository.getActiveGoals();
      final availableSavings = await _getAvailableSavings();

      if (activeGoals.isEmpty || availableSavings <= 0) {
        return {};
      }

      return _fundingService.calculateFundingDistribution(
        activeGoals: activeGoals,
        availableSavings: availableSavings,
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
      final availableSavings = await _getAvailableSavings();

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
      final availableSavings = await _getAvailableSavings();
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

      // Create expense entries for goal funding and update budgets
      if (totalAllocated > 0) {
        await _createGoalFundingExpensesAndUpdateBudgets(totalAllocated);
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
    return await _getAvailableSavings();
  }

  /// Create expense entries for goal funding and update budgets
  Future<void> _createGoalFundingExpensesAndUpdateBudgets(
      double totalAmount) async {
    try {
      // Get budgets with savings to distribute the expense across months
      final budgetsWithSavings = await _getBudgetsWithSavings();

      if (budgetsWithSavings.isEmpty) {
        debugPrint('🎯 AllocateSavingsUseCase: No budgets with savings found');
        return;
      }

      // Calculate total available savings
      double totalAvailableSavings = 0.0;
      for (final budgetWithMonth in budgetsWithSavings) {
        totalAvailableSavings += budgetWithMonth.budget.saving;
      }

      // Distribute expenses proportionally across months
      for (final budgetWithMonth in budgetsWithSavings) {
        final monthSavings = budgetWithMonth.budget.saving;
        final proportionalAmount =
            (monthSavings / totalAvailableSavings) * totalAmount;

        if (proportionalAmount > 0) {
          // Create expense on the last day of the savings month
          final expenseDate = _getLastDayOfMonth(budgetWithMonth.monthId);

          final expense = Expense(
            id: _uuid.v4(),
            remark: 'Goals funding',
            amount: double.parse(proportionalAmount.toStringAsFixed(2)),
            date: expenseDate,
            category: domain_category.Category.others,
            method: PaymentMethod.other,
            description: 'Automatic allocation of savings to financial goals',
            currency: 'MYR',
          );

          await _expensesRepository.addExpense(expense);

          // Update budget to reallocate the savings to "others" category
          await _reallocateBudgetToOthers(
              budgetWithMonth.monthId, proportionalAmount);

          debugPrint(
              '🎯 AllocateSavingsUseCase: Created goal funding expense of RM ${proportionalAmount.toStringAsFixed(2)} for month ${budgetWithMonth.monthId}');
        }
      }
    } catch (e) {
      debugPrint(
          '🎯 AllocateSavingsUseCase: Error creating goal funding expenses: $e');
      // Don't rethrow - goal funding should still succeed even if expense creation fails
    }
  }

  /// Get the last day of a month from monthId (format: YYYY-MM)
  DateTime _getLastDayOfMonth(String monthId) {
    final parts = monthId.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    // Get the first day of the next month, then subtract one day
    final nextMonth = DateTime(year, month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1));
  }

  /// Reallocate unallocated budget to "others" category
  Future<void> _reallocateBudgetToOthers(String monthId, double amount) async {
    try {
      final budget = await _budgetRepository.getBudget(monthId);
      if (budget == null) {
        debugPrint(
            '🎯 AllocateSavingsUseCase: Budget not found for month $monthId');
        return;
      }

      // Get or create "others" category budget
      final othersCategory = domain_category.Category.others;
      final currentOthersAmount =
          budget.categories[othersCategory.id]?.budget ?? 0.0;
      final newOthersAmount = currentOthersAmount + amount;

      // Update the budget
      final updatedCategories =
          Map<String, domain.CategoryBudget>.from(budget.categories);
      updatedCategories[othersCategory.id] = domain.CategoryBudget(
        budget: newOthersAmount,
        left: budget.categories[othersCategory.id]?.left ?? 0.0,
      );

      final updatedBudget = domain.Budget(
        total: budget.total,
        left: budget.left, // Keep left unchanged
        categories: updatedCategories,
        saving: budget.saving - amount, // Reduce the saving amount
        currency: budget.currency,
      );

      await _budgetRepository.setBudget(monthId, updatedBudget);
      debugPrint(
          '🎯 AllocateSavingsUseCase: Reallocated RM ${amount.toStringAsFixed(2)} to others category for month $monthId');
    } catch (e) {
      debugPrint(
          '🎯 AllocateSavingsUseCase: Error reallocating budget to others: $e');
    }
  }
}
