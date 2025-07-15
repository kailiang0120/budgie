import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/financial_goal.dart';
import '../../domain/usecase/goals/get_goals_usecase.dart';
import '../../domain/usecase/goals/manage_goals_usecase.dart';
import '../../domain/usecase/goals/allocate_savings_to_goals_usecase.dart';

/// ViewModel for financial goals
class GoalsViewModel extends ChangeNotifier {
  final GetGoalsUseCase _getGoalsUseCase;
  final GetGoalHistoryUseCase _getGoalHistoryUseCase;
  final GetGoalByIdUseCase _getGoalByIdUseCase;
  final SaveGoalUseCase _saveGoalUseCase;
  final UpdateGoalUseCase _updateGoalUseCase;
  final DeleteGoalUseCase _deleteGoalUseCase;
  final CompleteGoalUseCase _completeGoalUseCase;
  final CanAddGoalUseCase _canAddGoalUseCase;
  final AllocateSavingsToGoalsUseCase _allocateSavingsUseCase;

  final _uuid = const Uuid();

  List<FinancialGoal> _goals = [];
  List<GoalHistory> _goalHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  double _availableSavings = 0.0;
  bool _isFundingGoals = false;

  GoalsViewModel({
    required GetGoalsUseCase getGoalsUseCase,
    required GetGoalHistoryUseCase getGoalHistoryUseCase,
    required GetGoalByIdUseCase getGoalByIdUseCase,
    required SaveGoalUseCase saveGoalUseCase,
    required UpdateGoalUseCase updateGoalUseCase,
    required DeleteGoalUseCase deleteGoalUseCase,
    required CompleteGoalUseCase completeGoalUseCase,
    required CanAddGoalUseCase canAddGoalUseCase,
    required AllocateSavingsToGoalsUseCase allocateSavingsUseCase,
  })  : _getGoalsUseCase = getGoalsUseCase,
        _getGoalHistoryUseCase = getGoalHistoryUseCase,
        _getGoalByIdUseCase = getGoalByIdUseCase,
        _saveGoalUseCase = saveGoalUseCase,
        _updateGoalUseCase = updateGoalUseCase,
        _deleteGoalUseCase = deleteGoalUseCase,
        _completeGoalUseCase = completeGoalUseCase,
        _canAddGoalUseCase = canAddGoalUseCase,
        _allocateSavingsUseCase = allocateSavingsUseCase;

  // Getters
  List<FinancialGoal> get goals => _goals;
  List<GoalHistory> get goalHistory => _goalHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasGoals => _goals.isNotEmpty;
  bool get hasHistory => _goalHistory.isNotEmpty;
  double get availableSavings => _availableSavings;
  bool get isFundingGoals => _isFundingGoals;
  bool get hasSavingsToAllocate => _availableSavings > 0;

  // Initialize the view model
  Future<void> init() async {
    await loadGoals();
    await loadGoalHistory();
    await loadAvailableSavings();
  }

  // Load available savings
  Future<void> loadAvailableSavings() async {
    try {
      _availableSavings = await _allocateSavingsUseCase.getAvailableSavings();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading available savings: $e');
      }
    }
  }

  // Allocate savings to goals
  Future<bool> allocateSavingsToGoals() async {
    _setFundingLoading(true);
    _clearError();

    try {
      final distribution = await _allocateSavingsUseCase.execute();

      if (distribution.isNotEmpty) {
        // Reload goals to reflect updated amounts
        await loadGoals();
        await loadAvailableSavings();

        if (kDebugMode) {
          debugPrint(
              '🎯 GoalsViewModel: Successfully allocated savings to ${distribution.length} goals');
        }
        return true;
      } else {
        _setError('No savings available to allocate or no active goals');
        return false;
      }
    } catch (e) {
      _setError('Failed to allocate savings: $e');
      return false;
    } finally {
      _setFundingLoading(false);
    }
  }

  // Preview funding distribution
  Future<Map<String, double>> previewFundingDistribution() async {
    try {
      return await _allocateSavingsUseCase.previewDistribution();
    } catch (e) {
      _setError('Failed to preview funding distribution: $e');
      return {};
    }
  }

  // Preview custom funding distribution with specific amount
  Future<Map<String, double>> previewCustomFundingDistribution(
      double amount) async {
    try {
      return await _allocateSavingsUseCase.previewCustomDistribution(amount);
    } catch (e) {
      _setError('Failed to preview custom funding distribution: $e');
      return {};
    }
  }

  // Allocate custom savings amount to goals
  Future<bool> allocateCustomSavingsToGoals(double amount) async {
    _setFundingLoading(true);
    _clearError();

    try {
      final distribution = await _allocateSavingsUseCase.executeCustom(amount);

      if (distribution.isNotEmpty) {
        // Reload goals to reflect updated amounts
        await loadGoals();
        await loadAvailableSavings();

        if (kDebugMode) {
          debugPrint(
              '🎯 GoalsViewModel: Successfully allocated custom amount $amount to ${distribution.length} goals');
        }
        return true;
      } else {
        _setError('No savings available to allocate or no active goals');
        return false;
      }
    } catch (e) {
      _setError('Failed to allocate custom savings: $e');
      return false;
    } finally {
      _setFundingLoading(false);
    }
  }

  // Load active goals
  Future<void> loadGoals() async {
    _setLoading(true);
    _clearError();

    try {
      _goals = await _getGoalsUseCase.execute();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load goals: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load goal history
  Future<void> loadGoalHistory() async {
    _setLoading(true);
    _clearError();

    try {
      _goalHistory = await _getGoalHistoryUseCase.execute();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load goal history: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get a goal by ID
  Future<FinancialGoal?> getGoalById(String id) async {
    try {
      return await _getGoalByIdUseCase.execute(id);
    } catch (e) {
      _setError('Failed to get goal: $e');
      return null;
    }
  }

  // Save a new goal
  Future<bool> saveGoal(FinancialGoal goal) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _saveGoalUseCase.execute(goal);

      if (result) {
        await loadGoals();
      } else {
        _setError('Cannot add more goals. Maximum limit reached.');
      }

      return result;
    } catch (e) {
      _setError('Failed to save goal: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Save a new goal with individual parameters
  Future<bool> createGoal({
    required String title,
    required double targetAmount,
    required DateTime deadline,
    required GoalIcon icon,
    double currentAmount = 0.0,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final goal = FinancialGoal(
        id: _uuid.v4(),
        title: title,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        deadline: deadline,
        icon: icon,
      );

      return await saveGoal(goal);
    } catch (e) {
      _setError('Failed to create goal: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing goal
  Future<void> updateGoal(FinancialGoal goal) async {
    _setLoading(true);
    _clearError();

    try {
      await _updateGoalUseCase.execute(goal);
      await loadGoals();
    } catch (e) {
      _setError('Failed to update goal: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update the current amount of a goal
  Future<void> updateGoalAmount(String goalId, double newAmount) async {
    _setLoading(true);
    _clearError();

    try {
      final goal = await _getGoalByIdUseCase.execute(goalId);

      if (goal != null) {
        final updatedGoal = goal.copyWithNewAmount(newAmount);
        await _updateGoalUseCase.execute(updatedGoal);
        await loadGoals();
      } else {
        _setError('Goal not found');
      }
    } catch (e) {
      _setError('Failed to update goal amount: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete a goal
  Future<void> deleteGoal(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _deleteGoalUseCase.execute(id);
      await loadGoals();
    } catch (e) {
      _setError('Failed to delete goal: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Complete a goal
  Future<void> completeGoal(String id, {String? notes}) async {
    _setLoading(true);
    _clearError();

    try {
      await _completeGoalUseCase.execute(id, notes: notes);
      await loadGoals();
      await loadGoalHistory();
    } catch (e) {
      _setError('Failed to complete goal: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Check if more goals can be added
  Future<bool> canAddMoreGoals() async {
    try {
      return await _canAddGoalUseCase.execute();
    } catch (e) {
      _setError('Failed to check if more goals can be added: $e');
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setFundingLoading(bool loading) {
    _isFundingGoals = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    if (kDebugMode) {
      debugPrint('GoalsViewModel Error: $message');
    }
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
