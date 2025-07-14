import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../../domain/entities/financial_goal.dart' as domain;
import '../../domain/repositories/goals_repository.dart';
import '../datasources/local_data_source.dart';
import '../local/database/app_database.dart';

/// Implementation of GoalsRepository with local storage
class GoalsRepositoryImpl implements GoalsRepository {
  final LocalDataSource _localDataSource;
  final AppDatabase _database;
  final _uuid = const Uuid();

  GoalsRepositoryImpl({
    required LocalDataSource localDataSource,
    required AppDatabase database,
  })  : _localDataSource = localDataSource,
        _database = database;

  @override
  Future<List<domain.FinancialGoal>> getActiveGoals() async {
    try {
      debugPrint('🎯 GoalsRepository: Getting active goals');
      final goals = await _database.getActiveGoals();
      return goals.map(_mapToFinancialGoal).toList();
    } catch (e) {
      debugPrint('🎯 GoalsRepository: Error getting active goals: $e');
      return [];
    }
  }

  @override
  Future<domain.FinancialGoal?> getGoalById(String id) async {
    try {
      debugPrint('🎯 GoalsRepository: Getting goal by ID: $id');
      final goal = await _database.getGoalById(id);
      if (goal != null) {
        return _mapToFinancialGoal(goal);
      }
      return null;
    } catch (e) {
      debugPrint('🎯 GoalsRepository: Error getting goal by ID: $e');
      return null;
    }
  }

  @override
  Future<bool> saveGoal(domain.FinancialGoal goal) async {
    try {
      debugPrint('🎯 GoalsRepository: Saving goal: ${goal.title}');

      // Check if we can add more goals
      final canAdd = await canAddMoreGoals();
      if (!canAdd) {
        debugPrint('🎯 GoalsRepository: Cannot add more goals. Limit reached.');
        return false;
      }

      // Convert domain entity to database model
      final goalData = FinancialGoalsCompanion(
        id: Value(goal.id),
        title: Value(goal.title),
        targetAmount: Value(goal.targetAmount),
        currentAmount: Value(goal.currentAmount),
        deadline: Value(goal.deadline),
        iconName: Value(goal.icon.name),
        colorValue: Value(goal.icon.color.value.toString()),
        isCompleted: Value(goal.isCompleted),
        createdAt: Value(goal.createdAt),
        updatedAt: Value(DateTime.now()),
      );

      await _database.insertGoal(goalData);
      return true;
    } catch (e) {
      debugPrint('🎯 GoalsRepository: Error saving goal: $e');
      return false;
    }
  }

  @override
  Future<void> updateGoal(domain.FinancialGoal goal) async {
    try {
      debugPrint('🎯 GoalsRepository: Updating goal: ${goal.title}');

      // Convert domain entity to database model
      final goalData = FinancialGoalsCompanion(
        id: Value(goal.id),
        title: Value(goal.title),
        targetAmount: Value(goal.targetAmount),
        currentAmount: Value(goal.currentAmount),
        deadline: Value(goal.deadline),
        iconName: Value(goal.icon.name),
        colorValue: Value(goal.icon.color.value.toString()),
        isCompleted: Value(goal.isCompleted),
        createdAt: Value(goal.createdAt),
        updatedAt: Value(DateTime.now()),
      );

      await _database.updateGoal(goalData);
    } catch (e) {
      debugPrint('🎯 GoalsRepository: Error updating goal: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    try {
      debugPrint('🎯 GoalsRepository: Deleting goal with ID: $id');
      await _database.deleteGoal(id);
    } catch (e) {
      debugPrint('🎯 GoalsRepository: Error deleting goal: $e');
      rethrow;
    }
  }

  @override
  Future<void> completeGoal(String id, {String? notes}) async {
    try {
      debugPrint('🎯 GoalsRepository: Completing goal with ID: $id');

      // Get the goal to complete
      final goal = await getGoalById(id);
      if (goal == null) {
        throw Exception('Goal not found');
      }

      // Create history record
      final history = GoalHistoryCompanion(
        id: Value(_uuid.v4()),
        goalId: Value(goal.id),
        title: Value(goal.title),
        targetAmount: Value(goal.targetAmount),
        finalAmount: Value(goal.currentAmount),
        createdDate: Value(goal.createdAt),
        completedDate: Value(DateTime.now()),
        iconName: Value(goal.icon.name),
        colorValue: Value(goal.icon.color.value.toString()),
        notes: Value(notes),
        updatedAt: Value(DateTime.now()),
      );

      // Add to history and delete the goal
      await _database.transaction(() async {
        await _database.insertGoalHistory(history);
        await _database.deleteGoal(id);
      });
    } catch (e) {
      debugPrint('🎯 GoalsRepository: Error completing goal: $e');
      rethrow;
    }
  }

  @override
  Future<List<domain.GoalHistory>> getGoalHistory() async {
    try {
      debugPrint('🎯 GoalsRepository: Getting goal history');
      final history = await _database.getGoalHistory();
      return history.map(_mapToGoalHistory).toList();
    } catch (e) {
      debugPrint('🎯 GoalsRepository: Error getting goal history: $e');
      return [];
    }
  }

  @override
  Future<int> countActiveGoals() async {
    try {
      return await _database.countActiveGoals();
    } catch (e) {
      debugPrint('🎯 GoalsRepository: Error counting active goals: $e');
      return 0;
    }
  }

  @override
  Future<bool> canAddMoreGoals() async {
    try {
      final count = await countActiveGoals();
      return count < 3;
    } catch (e) {
      debugPrint(
          '🎯 GoalsRepository: Error checking if more goals can be added: $e');
      return false;
    }
  }

  // Helper methods to map between domain entities and database models
  domain.FinancialGoal _mapToFinancialGoal(FinancialGoal data) {
    return domain.FinancialGoal(
      id: data.id,
      title: data.title,
      targetAmount: data.targetAmount,
      currentAmount: data.currentAmount,
      deadline: data.deadline,
      icon: domain.GoalIcon.fromNameAndColor(
        data.iconName,
        data.colorValue,
      ),
      isCompleted: data.isCompleted,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  domain.GoalHistory _mapToGoalHistory(GoalHistoryData data) {
    return domain.GoalHistory(
      id: data.id,
      goalId: data.goalId,
      title: data.title,
      targetAmount: data.targetAmount,
      finalAmount: data.finalAmount,
      createdDate: data.createdDate,
      completedDate: data.completedDate,
      icon: domain.GoalIcon.fromNameAndColor(
        data.iconName,
        data.colorValue,
      ),
      notes: data.notes,
      updatedAt: data.updatedAt,
    );
  }
}
