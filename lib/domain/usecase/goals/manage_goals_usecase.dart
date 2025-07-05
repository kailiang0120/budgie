import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../entities/financial_goal.dart';
import '../../repositories/goals_repository.dart';

/// Use case for saving a financial goal
class SaveGoalUseCase {
  final GoalsRepository _goalsRepository;
  final _uuid = const Uuid();

  SaveGoalUseCase({
    required GoalsRepository goalsRepository,
  }) : _goalsRepository = goalsRepository;

  /// Execute the use case to save a goal
  /// Returns true if successful, false if the limit is reached
  Future<bool> execute(FinancialGoal goal) async {
    try {
      debugPrint('🎯 SaveGoalUseCase: Saving goal: ${goal.title}');

      // Generate ID if needed
      final goalToSave = goal.id.isEmpty
          ? FinancialGoal(
              id: _uuid.v4(),
              title: goal.title,
              targetAmount: goal.targetAmount,
              currentAmount: goal.currentAmount,
              deadline: goal.deadline,
              icon: goal.icon,
              isCompleted: goal.isCompleted,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          : goal;

      return await _goalsRepository.saveGoal(goalToSave);
    } catch (e) {
      debugPrint('🎯 SaveGoalUseCase: Error saving goal: $e');
      return false;
    }
  }
}

/// Use case for updating a financial goal
class UpdateGoalUseCase {
  final GoalsRepository _goalsRepository;

  UpdateGoalUseCase({
    required GoalsRepository goalsRepository,
  }) : _goalsRepository = goalsRepository;

  /// Execute the use case to update a goal
  Future<void> execute(FinancialGoal goal) async {
    try {
      debugPrint('🎯 UpdateGoalUseCase: Updating goal: ${goal.title}');

      // Ensure we have an ID
      if (goal.id.isEmpty) {
        throw Exception('Cannot update a goal without an ID');
      }

      await _goalsRepository.updateGoal(goal);
    } catch (e) {
      debugPrint('🎯 UpdateGoalUseCase: Error updating goal: $e');
      rethrow;
    }
  }
}

/// Use case for deleting a financial goal
class DeleteGoalUseCase {
  final GoalsRepository _goalsRepository;

  DeleteGoalUseCase({
    required GoalsRepository goalsRepository,
  }) : _goalsRepository = goalsRepository;

  /// Execute the use case to delete a goal
  Future<void> execute(String id) async {
    try {
      debugPrint('🎯 DeleteGoalUseCase: Deleting goal with ID: $id');
      await _goalsRepository.deleteGoal(id);
    } catch (e) {
      debugPrint('🎯 DeleteGoalUseCase: Error deleting goal: $e');
      rethrow;
    }
  }
}

/// Use case for completing a financial goal
class CompleteGoalUseCase {
  final GoalsRepository _goalsRepository;

  CompleteGoalUseCase({
    required GoalsRepository goalsRepository,
  }) : _goalsRepository = goalsRepository;

  /// Execute the use case to complete a goal
  Future<void> execute(String id, {String? notes}) async {
    try {
      debugPrint('🎯 CompleteGoalUseCase: Completing goal with ID: $id');
      await _goalsRepository.completeGoal(id, notes: notes);
    } catch (e) {
      debugPrint('🎯 CompleteGoalUseCase: Error completing goal: $e');
      rethrow;
    }
  }
}

/// Use case for checking if more goals can be added
class CanAddGoalUseCase {
  final GoalsRepository _goalsRepository;

  CanAddGoalUseCase({
    required GoalsRepository goalsRepository,
  }) : _goalsRepository = goalsRepository;

  /// Execute the use case to check if more goals can be added
  Future<bool> execute() async {
    try {
      return await _goalsRepository.canAddMoreGoals();
    } catch (e) {
      debugPrint(
          '🎯 CanAddGoalUseCase: Error checking if more goals can be added: $e');
      return false;
    }
  }
}
