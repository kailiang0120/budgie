import 'package:flutter/material.dart';
import 'dart:async';
import '../../domain/entities/budget.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../core/errors/app_error.dart';
import '../../core/utils/performance_monitor.dart';
import '../../core/services/budget_calculation_service.dart';
import '../../core/services/currency_conversion_service.dart';
import '../../core/services/settings_service.dart';

class BudgetViewModel extends ChangeNotifier {
  final BudgetRepository _budgetRepository;
  final CurrencyConversionService _currencyConversionService;
  Budget? budget;
  bool isLoading = false;
  String? errorMessage;

  // Track last save time to prevent frequent updates
  DateTime? _lastSaveTime;
  Timer? _saveDebounceTimer;

  // Flag to track if a currency conversion is in progress
  bool _isConvertingCurrency = false;

  // Map to track pending budget saves by monthId
  final Map<String, Budget> _pendingSaves = {};

  BudgetViewModel({
    required BudgetRepository budgetRepository,
    CurrencyConversionService? currencyConversionService,
  })  : _budgetRepository = budgetRepository,
        _currencyConversionService =
            currencyConversionService ?? CurrencyConversionService();

  /// Load budget for a specific month and check if currency conversion is needed
  Future<void> loadBudget(String monthId, {bool checkCurrency = false}) async {
    // Set loading state without notifying
    isLoading = true;
    errorMessage = null;

    try {
      PerformanceMonitor.startTimer('load_budget');
      final loadedBudget = await _budgetRepository.getBudget(monthId);
      PerformanceMonitor.stopTimer('load_budget');

      if (loadedBudget != null) {
        // Simply use the budget as stored in Firebase, without automatic currency conversion
        // This prevents the repeated conversion issue
        if (budget != loadedBudget) {
          budget = loadedBudget;
          isLoading = false;
          notifyListeners();
        } else {
          // Just update loading state without notifying if budget didn't change
          isLoading = false;
        }

        // Log the currency for debugging
        final settingsService = SettingsService.instance;
        if (settingsService != null) {
          debugPrint('Budget loaded with currency: ${loadedBudget.currency}, '
              'User preferred currency: ${settingsService.currency}');

          // Check if currency conversion is needed
          if (checkCurrency &&
              loadedBudget.currency != settingsService.currency) {
            // Schedule the currency check for after this method completes
            Future.microtask(() => checkAndConvertBudgetCurrency(
                monthId, settingsService.currency));
          }
        }
      } else {
        // No budget found
        budget = null;
        isLoading = false;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      errorMessage = error.message;
      // 如果是认证错误，则清空预算数据
      if (error is AuthError) {
        budget = null;
      }
      isLoading = false;
      notifyListeners();
    }
  }

  /// Check if the budget's currency matches the target currency and convert if needed
  Future<void> checkAndConvertBudgetCurrency(
      String monthId, String targetCurrency) async {
    try {
      // If no budget or already in progress or currencies match, skip conversion
      if (budget == null ||
          _isConvertingCurrency ||
          budget!.currency == targetCurrency) {
        debugPrint(
            '🔄 Currency check - No conversion needed: ${budget?.currency ?? 'No budget'} -> $targetCurrency');
        return;
      }

      debugPrint('🔄 Currency check - STARTING conversion check');
      debugPrint(
          '🔄 Current budget currency: ${budget!.currency}, Target currency: $targetCurrency');
      debugPrint('🔄 Current budget total: ${budget!.total}');

      // If currencies differ, perform conversion
      if (budget!.currency != targetCurrency) {
        debugPrint(
            '🔄 Currency conversion NEEDED - converting ${budget!.currency} to $targetCurrency');
        // Delegate to the existing onCurrencyChanged method
        await onCurrencyChanged(targetCurrency);
        debugPrint(
            '🔄 After conversion - Budget currency: ${budget!.currency}, Budget total: ${budget!.total}');
      }
    } catch (e) {
      debugPrint('❌ Error checking/converting budget currency: $e');
      // Don't rethrow - this is a background operation
    }
  }

  /// Handle currency changes from settings
  Future<void> onCurrencyChanged(String newCurrency) async {
    // Check if we already have a budget to convert
    if (budget == null) {
      debugPrint('🔄 No budget to convert, skipping onCurrencyChanged');
      return; // No budget to convert
    }

    // Check if the currency is already the same
    if (budget!.currency == newCurrency) {
      debugPrint(
          '🔄 Budget currency already matches new currency: $newCurrency');
      return; // Already in the right currency
    }

    // Check if a conversion is already in progress
    if (_isConvertingCurrency) {
      debugPrint(
          '🔄 Currency conversion already in progress, skipping duplicate request');
      return; // Prevent duplicate conversions
    }

    try {
      // Set the conversion flag to prevent duplicate conversions
      _isConvertingCurrency = true;

      debugPrint(
          '🔄 Currency changed to $newCurrency - updating budget from ${budget!.currency}');
      debugPrint('🔄 Before conversion - Budget total: ${budget!.total}');
      isLoading = true;
      notifyListeners();

      // Convert the budget using our enhanced CurrencyConversionService
      final oldCurrency = budget!.currency;
      final oldBudget = budget!;

      // Create a new Budget object with converted values
      final newCategories = <String, CategoryBudget>{};

      // Convert each category budget
      for (final entry in oldBudget.categories.entries) {
        final categoryId = entry.key;
        final categoryBudget = entry.value;

        // Convert budget and left amounts
        final convertedBudget = await _currencyConversionService
            .convertCurrency(categoryBudget.budget, oldCurrency, newCurrency);

        final convertedLeft = await _currencyConversionService.convertCurrency(
            categoryBudget.left, oldCurrency, newCurrency);

        newCategories[categoryId] = CategoryBudget(
          budget: convertedBudget,
          left: convertedLeft,
        );

        debugPrint(
            '🔄 Converted category "$categoryId": Budget ${categoryBudget.budget} $oldCurrency → $convertedBudget $newCurrency');
      }

      // Convert total and left amounts
      final convertedTotal = await _currencyConversionService.convertCurrency(
          oldBudget.total, oldCurrency, newCurrency);

      final convertedLeft = await _currencyConversionService.convertCurrency(
          oldBudget.left, oldCurrency, newCurrency);

      // Create the new budget with converted values
      final convertedBudget = Budget(
        total: convertedTotal,
        left: convertedLeft,
        categories: newCategories,
        currency: newCurrency,
      );

      debugPrint(
          '🔄 Converted total budget: ${oldBudget.total} $oldCurrency → ${convertedBudget.total} $newCurrency');
      debugPrint(
          '🔄 Converted left budget: ${oldBudget.left} $oldCurrency → ${convertedBudget.left} $newCurrency');

      // Update the budget in memory
      budget = convertedBudget;

      // Get current month ID for saving
      final now = DateTime.now();
      final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Save the converted budget to Firebase
      debugPrint(
          '🔄 Saving converted budget to Firebase with currency: $newCurrency');
      await _budgetRepository.setBudget(monthId, convertedBudget);

      debugPrint(
          '✅ Budget successfully converted and saved with new currency: $newCurrency');
      debugPrint('✅ Final budget total: ${convertedBudget.total}');
    } catch (e) {
      debugPrint('❌ Error handling currency change: $e');
      errorMessage = 'Failed to update budget with new currency';
    } finally {
      // Reset the conversion flag
      _isConvertingCurrency = false;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveBudgetWithMonthId(String monthId, Budget newBudget) async {
    // Cancel any pending save for this month
    if (_saveDebounceTimer != null && _saveDebounceTimer!.isActive) {
      _saveDebounceTimer!.cancel();
    }

    // Store this budget in pending saves
    _pendingSaves[monthId] = newBudget;

    // Check if we should throttle this save
    final now = DateTime.now();
    if (_lastSaveTime != null && now.difference(_lastSaveTime!).inSeconds < 2) {
      // Debounce save requests that come too quickly
      debugPrint('Debouncing budget save for month: $monthId');
      _saveDebounceTimer = Timer(const Duration(seconds: 2), () {
        // After debounce period, check if this save is still needed
        if (_pendingSaves.containsKey(monthId)) {
          final budgetToSave = _pendingSaves.remove(monthId);
          if (budgetToSave != null) {
            _executeSaveBudget(monthId, budgetToSave);
          }
        }
      });
      return;
    }

    // Not throttled, execute immediately
    _pendingSaves.remove(monthId);
    await _executeSaveBudget(monthId, newBudget);
  }

  // This is an alias for backwards compatibility with existing code
  Future<void> saveBudget(String monthId, Budget newBudget) async {
    await saveBudgetWithMonthId(monthId, newBudget);
  }

  // Save budget without explicit month ID
  Future<void> saveBudgetWithoutMonthId(Budget newBudget) async {
    // Extract month ID from the budget's data (this needs to be provided elsewhere)
    // For now, use the current month as a fallback
    final now = DateTime.now();
    final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    await saveBudgetWithMonthId(monthId, newBudget);
  }

  // The actual save operation
  Future<void> _executeSaveBudget(String monthId, Budget newBudget) async {
    try {
      errorMessage = null;
      isLoading = true;
      notifyListeners();

      debugPrint('Executing budget save for month: $monthId');
      _lastSaveTime = DateTime.now();

      // We no longer automatically convert the currency when saving
      // This ensures we save the budget with the currency it was created with
      Budget budgetToSave = newBudget;

      await PerformanceMonitor.measureAsync('save_budget', () async {
        return await _budgetRepository.setBudget(monthId, budgetToSave);
      });

      budget = budgetToSave;
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 计算预算剩余金额（总额和各类别）
  ///
  /// [expenses] 当月支出列表
  Future<void> calculateBudgetRemaining(List<Expense> expenses) async {
    if (budget == null) return;

    try {
      errorMessage = null;
      isLoading = true;
      notifyListeners();

      // Convert expenses to budget currency if needed
      final convertedExpenses =
          await _convertExpensesToBudgetCurrency(expenses);

      // 使用预算计算服务计算剩余预算
      final updatedBudget =
          await PerformanceMonitor.measureAsync('calculate_budget', () async {
        return await BudgetCalculationService.calculateBudget(
            budget!, convertedExpenses);
      });

      // 更新预算数据
      budget = updatedBudget;
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Convert expenses to the same currency as the budget
  Future<List<Expense>> _convertExpensesToBudgetCurrency(
      List<Expense> expenses) async {
    if (budget == null || expenses.isEmpty) {
      return expenses;
    }

    final budgetCurrency = budget!.currency;
    final result = <Expense>[];

    debugPrint(
        '💰 Converting ${expenses.length} expenses to budget currency: $budgetCurrency');
    int convertedCount = 0;

    for (final expense in expenses) {
      if (expense.currency == budgetCurrency) {
        // No conversion needed
        result.add(expense);
      } else {
        try {
          // Convert expense amount to budget currency
          final convertedAmount =
              await _currencyConversionService.convertCurrency(
            expense.amount,
            expense.currency,
            budgetCurrency,
          );

          convertedCount++;
          if (convertedCount <= 3) {
            // Only log a few conversions to avoid log spam
            debugPrint(
                '💰 Converted expense: ${expense.amount} ${expense.currency} → $convertedAmount $budgetCurrency (${expense.remark})');
          }

          // Create a copy of the expense with the converted amount and budget currency
          // We also update the currency to ensure consistent calculations
          final convertedExpense = expense.copyWith(
            amount: convertedAmount,
            currency: budgetCurrency, // Store the converted currency
          );

          result.add(convertedExpense);
        } catch (e) {
          debugPrint('❌ Error converting expense currency: $e');
          // If conversion fails, use original expense
          result.add(expense);
        }
      }
    }

    if (convertedCount > 3) {
      debugPrint('💰 Converted $convertedCount expenses to $budgetCurrency');
    }

    return result;
  }

  @override
  void dispose() {
    // Cancel any pending timers
    if (_saveDebounceTimer != null) {
      _saveDebounceTimer!.cancel();
      _saveDebounceTimer = null;
    }
    _pendingSaves.clear();
    super.dispose();
  }
}
