import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/user_behavior_profile.dart';
import '../../domain/repositories/user_behavior_repository.dart';
import '../../domain/usecase/goals/get_goals_usecase.dart';
import '../../domain/usecase/goals/manage_goals_usecase.dart';
import '../../domain/usecase/goals/allocate_savings_to_goals_usecase.dart';
import '../../data/infrastructure/services/notification_service.dart';

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
  final UserBehaviorRepository _userBehaviorRepository;
  final NotificationService _notificationService;

  static const String _defaultUserId = 'guest_user';

  final _uuid = const Uuid();

  List<FinancialGoal> _goals = [];
  List<GoalHistory> _goalHistory = [];
  bool _isGoalsLoading = false;
  bool _isHistoryLoading = false;
  bool _isMutating = false;
  String? _errorMessage;
  double _availableSavings = 0.0;
  bool _isFundingGoals = false;
  UserBehaviorProfile? _behaviorProfile;
  List<GoalRecommendation> _goalRecommendations = [];
  final Set<String> _notifiedGoalIds = <String>{};
  bool _initialized = false;

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
    required UserBehaviorRepository userBehaviorRepository,
    required NotificationService notificationService,
  })  : _getGoalsUseCase = getGoalsUseCase,
        _getGoalHistoryUseCase = getGoalHistoryUseCase,
        _getGoalByIdUseCase = getGoalByIdUseCase,
        _saveGoalUseCase = saveGoalUseCase,
        _updateGoalUseCase = updateGoalUseCase,
        _deleteGoalUseCase = deleteGoalUseCase,
        _completeGoalUseCase = completeGoalUseCase,
        _canAddGoalUseCase = canAddGoalUseCase,
        _allocateSavingsUseCase = allocateSavingsUseCase,
        _userBehaviorRepository = userBehaviorRepository,
        _notificationService = notificationService;

  // Getters
  List<FinancialGoal> get goals => _goals;
  List<GoalHistory> get goalHistory => _goalHistory;
  bool get isLoading => _isGoalsLoading || _isMutating;
  bool get isGoalsLoading => _isGoalsLoading;
  bool get isHistoryLoading => _isHistoryLoading;
  bool get isMutating => _isMutating;
  String? get errorMessage => _errorMessage;
  bool get hasGoals => _goals.isNotEmpty;
  bool get hasHistory => _goalHistory.isNotEmpty;
  double get availableSavings => _availableSavings;
  bool get isFundingGoals => _isFundingGoals;
  bool get hasSavingsToAllocate => _availableSavings > 0;
  UserBehaviorProfile? get behaviorProfile => _behaviorProfile;
  List<GoalRecommendation> get goalRecommendations =>
      List.unmodifiable(_goalRecommendations);

  // Initialize the view model
  Future<void> init({bool force = false}) async {
  if (_isGoalsLoading || _isMutating) {
      return;
    }

    if (!force && _initialized) {
      await _loadBehaviorProfile();
      await loadAvailableSavings(notify: false);
      _refreshGoalRecommendations(notify: true);
      await _scheduleGoalReminders();
      return;
    }

    await _loadBehaviorProfile();
    await loadGoals();
    await loadGoalHistory();
    _refreshGoalRecommendations(notify: true);
    await _scheduleGoalReminders();
    _initialized = true;
  }

  // Load available savings
  Future<void> loadAvailableSavings({bool notify = true}) async {
    try {
      _availableSavings = await _allocateSavingsUseCase.getAvailableSavings();
      if (notify) {
        _refreshGoalRecommendations();
        notifyListeners();
      }
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
    _setGoalsLoading(true);
    _clearError();

    try {
      _goals = await _getGoalsUseCase.execute();
      await loadAvailableSavings(notify: false);
      _refreshGoalRecommendations();
      await _scheduleGoalReminders();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load goals: $e');
    } finally {
      _setGoalsLoading(false);
    }
  }

  // Load goal history
  Future<void> loadGoalHistory() async {
    _setHistoryLoading(true);
    _clearError();

    try {
      _goalHistory = await _getGoalHistoryUseCase.execute();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load goal history: $e');
    } finally {
      _setHistoryLoading(false);
    }
  }

  Future<void> _loadBehaviorProfile() async {
    try {
      _behaviorProfile =
          await _userBehaviorRepository.getUserBehaviorProfile(_defaultUserId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to load behavior profile: $e');
      }
    }
  }

  void _refreshGoalRecommendations({bool notify = false}) {
    final profile = _behaviorProfile;
    final List<GoalRecommendation> recommendations = [];

    if (profile != null) {
      final emergency = _buildEmergencyFundRecommendation(profile);
      if (emergency != null) {
        recommendations.add(emergency);
      }

      final investment = _buildInvestmentRecommendation(profile);
      if (investment != null) {
        recommendations.add(investment);
      }

      final debt = _buildDebtReductionRecommendation(profile);
      if (debt != null) {
        recommendations.add(debt);
      }

      if (recommendations.isEmpty) {
        final savingsBoost = _buildSavingsHabitRecommendation(profile);
        if (savingsBoost != null) {
          recommendations.add(savingsBoost);
        }
      }
    } else if (_goals.isEmpty) {
      recommendations.add(GoalRecommendation(
        id: 'starter-savings',
        title: 'Starter Savings Goal',
        description:
            'Set aside a small starter fund to build momentum for your savings journey.',
        suggestedAmount: 1000,
        suggestedDuration: const Duration(days: 90),
        icon: GoalIcon(
          icon: Icons.savings,
          name: 'savings',
          color: Colors.blueAccent,
        ),
        rationale:
            'Create your first goal so Budgie can help you stay accountable.',
      ));
    }

    _goalRecommendations = recommendations.take(3).toList();

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _scheduleGoalReminders() async {
    if (_goals.isEmpty) {
      return;
    }

    for (final goal in _goals) {
      if (goal.isCompleted) {
        continue;
      }

      final daysRemaining = goal.daysRemaining;
      if (daysRemaining < 0 || daysRemaining > 7) {
        continue;
      }

      if (_notifiedGoalIds.contains(goal.id)) {
        continue;
      }

      final success = await _notificationService.sendReminderNotification(
        title: 'Goal reminder',
        message: daysRemaining == 0
            ? '"${goal.title}" is due today. You are ${goal.progressPercentage}% of the way there!'
            : '"${goal.title}" is due in $daysRemaining day${daysRemaining == 1 ? '' : 's'}. You are ${goal.progressPercentage}% complete.',
        payload: 'goal:${goal.id}',
      );

      if (success) {
        _notifiedGoalIds.add(goal.id);
      }
    }
  }

  GoalRecommendation? _buildEmergencyFundRecommendation(
      UserBehaviorProfile profile) {
    if (_hasGoalWithKeyword('emergency')) {
      return null;
    }

    int baseMonths;
    switch (profile.incomeStability) {
      case IncomeStability.irregular:
        baseMonths = 6;
        break;
      case IncomeStability.variable:
        baseMonths = 4;
        break;
      case IncomeStability.stable:
        baseMonths = 3;
        break;
    }

    if (profile.financialStressLevel == FinancialStressLevel.high) {
      baseMonths += 1;
    }

    if (profile.savingHabit == SavingHabit.never) {
      baseMonths = (baseMonths / 2).ceil();
    }

    final months = baseMonths.clamp(2, 6);
    final amount = (months * 1200).toDouble();

    return GoalRecommendation(
      id: 'emergency-fund',
      title: 'Emergency Fund Boost',
      description:
          'Build a reserve covering $months months of essential expenses to steady your ${profile.incomeStability.displayName.toLowerCase()} income.',
      suggestedAmount: amount,
      suggestedDuration: Duration(days: months * 30),
      icon: GoalIcon(
        icon: Icons.emergency,
        name: 'emergency',
        color: Colors.deepOrangeAccent,
      ),
      rationale:
          'Recommended because your financial stress level is ${profile.financialStressLevel.displayName.toLowerCase()} and your saving habit is ${profile.savingHabit.displayName.toLowerCase()}.',
    );
  }

  GoalRecommendation? _buildInvestmentRecommendation(
      UserBehaviorProfile profile) {
    final isInvestmentFocused =
        profile.financialPriority == FinancialPriority.investing ||
            profile.riskAppetite == RiskAppetite.high;
    if (!isInvestmentFocused) {
      return null;
    }

    if (_hasGoalWithKeyword('invest')) {
      return null;
    }

    final target = profile.riskAppetite == RiskAppetite.high ? 8000 : 5000;
    final months = profile.financialLiteracyLevel.index >=
            FinancialLiteracyLevel.intermediate.index
        ? 6
        : 9;

    return GoalRecommendation(
      id: 'investment-boost',
      title: 'Investment Booster',
      description:
          'Set aside capital for future investments that match your ${profile.riskAppetite.displayName.toLowerCase()} risk appetite.',
      suggestedAmount: target.toDouble(),
      suggestedDuration: Duration(days: months * 30),
      icon: GoalIcon(
        icon: Icons.trending_up,
        name: 'investment',
        color: Colors.teal,
      ),
      rationale:
          'Suggested because you prioritise investing and are comfortable with ${profile.riskAppetite.displayName.toLowerCase()} risk.',
    );
  }

  GoalRecommendation? _buildDebtReductionRecommendation(
      UserBehaviorProfile profile) {
    if (profile.financialPriority != FinancialPriority.debtRepayment &&
        profile.financialStressLevel == FinancialStressLevel.low) {
      return null;
    }

    if (_hasGoalWithKeyword('debt') || _hasGoalWithKeyword('loan')) {
      return null;
    }

    final amount = profile.financialStressLevel == FinancialStressLevel.high
        ? 4000.0
        : 2500.0;
    final months =
        profile.financialStressLevel == FinancialStressLevel.high ? 4 : 6;

    return GoalRecommendation(
      id: 'debt-relief',
      title: 'Debt Fast-Track',
      description:
          'Allocate a focused lump sum to knock out high-interest debt and reduce stress.',
      suggestedAmount: amount,
      suggestedDuration: Duration(days: months * 30),
      icon: GoalIcon(
        icon: Icons.credit_score,
        name: 'debt',
        color: Colors.redAccent,
      ),
      rationale:
          'Recommended because your priority leans toward debt repayment or you reported elevated financial stress.',
    );
  }

  GoalRecommendation? _buildSavingsHabitRecommendation(
      UserBehaviorProfile profile) {
    if (profile.savingHabit == SavingHabit.regular &&
        profile.financialStressLevel == FinancialStressLevel.low) {
      return null;
    }

    if (_hasGoalWithKeyword('savings') || _hasGoalWithKeyword('buffer')) {
      return null;
    }

    return GoalRecommendation(
      id: 'habit-builder',
      title: 'Monthly Savings Habit',
      description:
          'Automate small monthly contributions to reinforce consistent saving behaviour.',
      suggestedAmount: 1200.0,
      suggestedDuration: const Duration(days: 120),
      icon: GoalIcon(
        icon: Icons.auto_graph,
        name: 'habit',
        color: Colors.indigoAccent,
      ),
      rationale:
          'Designed to strengthen your savings habit based on your current responses.',
    );
  }

  bool _hasGoalWithKeyword(String keyword) {
    final lower = keyword.toLowerCase();
    return _goals.any((goal) => goal.title.toLowerCase().contains(lower));
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
    _setMutating(true);
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
      _setMutating(false);
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
    }
  }

  // Update an existing goal
  Future<void> updateGoal(FinancialGoal goal) async {
    _setMutating(true);
    _clearError();

    try {
      await _updateGoalUseCase.execute(goal);
      await loadGoals();
    } catch (e) {
      _setError('Failed to update goal: $e');
    } finally {
      _setMutating(false);
    }
  }

  // Update the current amount of a goal
  Future<void> updateGoalAmount(String goalId, double newAmount) async {
    _setMutating(true);
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
      _setMutating(false);
    }
  }

  // Delete a goal
  Future<void> deleteGoal(String id) async {
    _setMutating(true);
    _clearError();

    try {
      await _deleteGoalUseCase.execute(id);
      await loadGoals();
    } catch (e) {
      _setError('Failed to delete goal: $e');
    } finally {
      _setMutating(false);
    }
  }

  // Complete a goal
  Future<void> completeGoal(String id, {String? notes}) async {
    _setMutating(true);
    _clearError();

    try {
      await _completeGoalUseCase.execute(id, notes: notes);
      await loadGoals();
      await loadGoalHistory();
    } catch (e) {
      _setError('Failed to complete goal: $e');
    } finally {
      _setMutating(false);
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
  void _setGoalsLoading(bool loading) {
    if (_isGoalsLoading == loading) {
      return;
    }
    _isGoalsLoading = loading;
    notifyListeners();
  }

  void _setHistoryLoading(bool loading) {
    if (_isHistoryLoading == loading) {
      return;
    }
    _isHistoryLoading = loading;
    notifyListeners();
  }

  void _setMutating(bool loading) {
    if (_isMutating == loading) {
      return;
    }
    _isMutating = loading;
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

class GoalRecommendation {
  final String id;
  final String title;
  final String description;
  final double suggestedAmount;
  final Duration suggestedDuration;
  final GoalIcon icon;
  final String rationale;

  const GoalRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.suggestedAmount,
    required this.suggestedDuration,
    required this.icon,
    required this.rationale,
  });

  DateTime get suggestedDeadline => DateTime.now().add(suggestedDuration);
}
