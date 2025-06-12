import 'dart:async';
import '../../entities/budget.dart';
import '../../repositories/budget_repository.dart';
import '../../../data/infrastructure/errors/app_error.dart';
import '../../../data/infrastructure/monitoring/performance_monitor.dart';

/// Use case for saving budget with debouncing
class SaveBudgetUseCase {
  final BudgetRepository _budgetRepository;

  // Track last save time to prevent frequent updates
  DateTime? _lastSaveTime;
  Timer? _saveDebounceTimer;

  // Map to track pending budget saves by monthId
  final Map<String, Budget> _pendingSaves = {};

  SaveBudgetUseCase({
    required BudgetRepository budgetRepository,
  }) : _budgetRepository = budgetRepository;

  /// Execute the save budget use case with debouncing
  Future<void> execute(String monthId, Budget budget) async {
    // Cancel any pending save for this month
    if (_saveDebounceTimer != null && _saveDebounceTimer!.isActive) {
      _saveDebounceTimer!.cancel();
    }

    // Store this budget in pending saves
    _pendingSaves[monthId] = budget;

    // Check if we should throttle this save
    final now = DateTime.now();
    if (_lastSaveTime != null && now.difference(_lastSaveTime!).inSeconds < 2) {
      // Debounce save requests that come too quickly
      print('Debouncing budget save for month: $monthId');
      _saveDebounceTimer = Timer(const Duration(seconds: 2), () {
        // After debounce period, check if this save is still needed
        if (_pendingSaves.containsKey(monthId)) {
          final budgetToSave = _pendingSaves.remove(monthId);
          if (budgetToSave != null) {
            _executeSave(monthId, budgetToSave);
          }
        }
      });
      return;
    }

    // Not throttled, execute immediately
    _pendingSaves.remove(monthId);
    await _executeSave(monthId, budget);
  }

  /// The actual save operation
  Future<void> _executeSave(String monthId, Budget budget) async {
    try {
      print('Executing budget save for month: $monthId');
      _lastSaveTime = DateTime.now();

      await PerformanceMonitor.measureAsync('save_budget', () async {
        return await _budgetRepository.setBudget(monthId, budget);
      });
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    // Cancel any pending timers
    if (_saveDebounceTimer != null) {
      _saveDebounceTimer!.cancel();
      _saveDebounceTimer = null;
    }
    _pendingSaves.clear();
  }
}
