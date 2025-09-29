import 'package:flutter/foundation.dart';

import '../../domain/entities/expense.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../../data/infrastructure/errors/app_error.dart';
import '../../data/infrastructure/services/settings_service.dart';
import '../../data/infrastructure/network/connectivity_service.dart';
import '../../domain/usecase/expense/add_expense_usecase.dart';
import '../../domain/usecase/expense/update_expense_usecase.dart';
import '../../domain/usecase/expense/delete_expense_usecase.dart';
import '../../domain/usecase/expense/load_expenses_usecase.dart';
import '../../domain/usecase/expense/filter_expenses_usecase.dart';
import '../../domain/usecase/expense/calculate_expense_totals_usecase.dart';
import '../utils/performance_utils.dart';
import '../widgets/date_picker_button.dart';
import 'dart:async';

/// Filter modes for expenses (import from date_picker_button)
typedef FilterMode = DateFilterMode;

class ExpensesViewModel extends ChangeNotifier
    with PerformanceOptimizedViewModel {
  final ExpensesRepository _expensesRepository;
  final ConnectivityService _connectivityService;
  final SettingsService _settingsService;
  final AddExpenseUseCase _addExpenseUseCase;
  final UpdateExpenseUseCase _updateExpenseUseCase;
  final DeleteExpenseUseCase _deleteExpenseUseCase;
  final LoadExpensesUseCase _loadExpensesUseCase;
  final FilterExpensesUseCase _filterExpensesUseCase;
  final CalculateExpenseTotalsUseCase _calculateExpenseTotalsUseCase;

  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = false;
  String? _error;
  bool _isOffline = false;
  Future<void>? _ongoingLoad;

  // Flag to prevent auto-reset of month filter when navigating between screens
  bool _persistFilter = true;

  // For date filtering
  DateTime _selectedMonth = DateTime.now();
  bool _isFiltering = true;
  bool _isDayFiltering = false; // New flag for day-level filtering

  // Screen-specific filters
  final Map<String, DateTime> _screenFilters = {
    'home': DateTime.now(),
    'analytics': DateTime.now(),
  };
  final Map<String, bool> _screenDayFilters = {
    'home': false,
    'analytics': false,
  };

  // Current filter mode (day, month, or year)
  FilterMode _filterMode = DateFilterMode.month;

  static const Map<String, Map<String, double>> _fallbackConversionRates = {
    'MYR': {'USD': 0.21, 'EUR': 0.19, 'GBP': 0.17},
    'USD': {'MYR': 4.73, 'EUR': 0.92, 'GBP': 0.79},
    'EUR': {'MYR': 5.26, 'USD': 1.09, 'GBP': 0.86},
    'GBP': {'MYR': 6.12, 'USD': 1.26, 'EUR': 1.16},
  };

  ExpensesViewModel({
    required ExpensesRepository expensesRepository,
    required ConnectivityService connectivityService,
    required SettingsService settingsService,
    required AddExpenseUseCase addExpenseUseCase,
    required UpdateExpenseUseCase updateExpenseUseCase,
    required DeleteExpenseUseCase deleteExpenseUseCase,
    required LoadExpensesUseCase loadExpensesUseCase,
    required FilterExpensesUseCase filterExpensesUseCase,
    required CalculateExpenseTotalsUseCase calculateExpenseTotalsUseCase,
  })  : _expensesRepository = expensesRepository,
        _connectivityService = connectivityService,
        _settingsService = settingsService,
        _addExpenseUseCase = addExpenseUseCase,
        _updateExpenseUseCase = updateExpenseUseCase,
        _deleteExpenseUseCase = deleteExpenseUseCase,
        _loadExpensesUseCase = loadExpensesUseCase,
        _filterExpensesUseCase = filterExpensesUseCase,
        _calculateExpenseTotalsUseCase = calculateExpenseTotalsUseCase {
    _init();
  }

  Future<void> _init() async {
    // Listen for network status changes with performance optimization
    final subscription =
        _connectivityService.connectionStatusStream.listen((isConnected) {
      final wasOffline = _isOffline;
      _isOffline = !isConnected;

      // Only reload data when going from offline to online to avoid redundant operations
      if (wasOffline && isConnected && _settingsService.syncEnabled) {
        if (kDebugMode) {
          debugPrint(
              '🔄 ExpensesViewModel: Network connection restored, triggering sync and reload');
        }
        // Trigger sync first, then reload data
        _loadExpensesUseCase.execute();
        _loadExpensesFromLocalDatabase();
      } else if (!wasOffline && !isConnected) {
        // Load local data when going from online to offline
        if (kDebugMode) {
          debugPrint(
              '🔄 ExpensesViewModel: Network connection lost, loading from local database');
        }
        _loadExpensesFromLocalDatabase();
      }
    });
    trackSubscription(subscription);

    // Initial data load
    _loadExpensesFromLocalDatabase();
  }

  // Load expenses from local database
  Future<void> _loadExpensesFromLocalDatabase({bool force = false}) async {
    if (_ongoingLoad != null) {
      if (!force) {
        return await _ongoingLoad!;
      }
      await _ongoingLoad;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final loadFuture = _loadExpensesWithRetry();
    _ongoingLoad = loadFuture;

    try {
      await loadFuture;
    } finally {
      _ongoingLoad = null;
    }
  }

  /// Load expenses with retry mechanism
  Future<void> _loadExpensesWithRetry({int maxRetries = 3}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (kDebugMode) {
          debugPrint(
              '🔄 ExpensesViewModel: Loading expenses attempt ${attempt + 1}/$maxRetries');
        }

        final localExpenses = await _expensesRepository.getExpenses();

        _expenses = localExpenses;
        _filterExpensesUseCase.clearCache();

        if (_isFiltering) {
          _filterExpensesByMonth();
        } else {
          _filteredExpenses = _expenses;
        }

        _isLoading = false;
        notifyListenersThrottled('expenses_loaded');

        if (kDebugMode) {
          debugPrint(
              '✅ ExpensesViewModel: Successfully loaded ${_expenses.length} expenses');
        }
        return;
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('⚠️ ExpensesViewModel: Attempt ${attempt + 1} failed: $e');
        }

        if (attempt >= maxRetries - 1) {
          _handleError(e, stackTrace);
          return;
        }

        final delay = Duration(milliseconds: 500 * (attempt + 1));
        if (kDebugMode) {
          debugPrint(
              '🔄 ExpensesViewModel: Retrying in ${delay.inMilliseconds}ms...');
        }
        await Future.delayed(delay);
      }
    }
  }

  List<Expense> get expenses => _isFiltering ? _filteredExpenses : _expenses;
  List<Expense> get filteredExpenses => _filteredExpenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOffline => _isOffline;
  DateTime get selectedMonth => _selectedMonth;
  bool get isFiltering => _isFiltering;

  // Access current user settings
  String get currentCurrency => _settingsService.currency;
  bool get allowNotification => _settingsService.allowNotification;
  bool get autoBudget => _settingsService.autoBudget;
  bool get syncEnabled => _settingsService.syncEnabled;

  /// Set selected month with screen context
  void setSelectedMonth(DateTime month,
      {bool filterByDay = false,
      String screenKey = 'default',
      bool persist = true}) {
    try {
      // Store filter settings for the specific screen
      _screenFilters[screenKey] = month;
      _screenDayFilters[screenKey] = filterByDay;

      if (filterByDay) {
        // For day filtering, use exact date
        if (_selectedMonth == month && _isDayFiltering) {
          return; // No change needed
        }

        _selectedMonth = month;
        _isFiltering = true;
        _isDayFiltering = true;
        _persistFilter = persist;
      } else {
        // For month filtering, standardize to first day of month
        final normalizedMonth = DateTime(month.year, month.month, 1);

        if (_selectedMonth.year == normalizedMonth.year &&
            _selectedMonth.month == normalizedMonth.month &&
            !_isDayFiltering) {
          return; // No change needed
        }

        _selectedMonth = normalizedMonth;
        _isFiltering = true;
        _isDayFiltering = false;
        _persistFilter = persist;
      }

      _filterExpensesByMonth();
      notifyListenersThrottled('month_filter_changed');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting selected month: $e');
      }
    }
  }

  /// Restore screen-specific filter
  void restoreScreenFilter(String screenKey) {
    if (!_persistFilter) {
      return; // Skip if filter persistence is disabled
    }

    final savedMonth = _screenFilters[screenKey];
    final isDayFilter = _screenDayFilters[screenKey] ?? false;

    if (savedMonth != null) {
      setSelectedMonth(savedMonth,
          filterByDay: isDayFilter, screenKey: screenKey);
    }
  }

  /// Reset month filter to show all expenses
  void resetMonthFilter() {
    _isFiltering = false;
    _isDayFiltering = false;
    _filteredExpenses = _expenses;
    notifyListenersThrottled('filter_reset');
  }

  /// Filter expenses by the selected period (day, month, or year)
  void _filterExpensesByMonth() {
    if (!_isFiltering) {
      _filteredExpenses = _expenses;
      return;
    }

    switch (_filterMode) {
      case DateFilterMode.day:
        // Day-level filtering: exact date
        _filteredExpenses = _filterExpensesUseCase
            .filterByMonth(_expenses, _selectedMonth, isDayFiltering: true);
        break;
      case DateFilterMode.month:
        // Month-level filtering: first day of month is normalized in setSelectedMonth
        _filteredExpenses = _filterExpensesUseCase
            .filterByMonth(_expenses, _selectedMonth, isDayFiltering: false);
        break;
      case DateFilterMode.year:
        // Year-level filtering: include all expenses in the selected year
        _filteredExpenses = _expenses
            .where((expense) => expense.date.year == _selectedMonth.year)
            .toList();
        break;
    }
  }

  /// Add a new expense
  Future<void> addExpense(Expense expense) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _addExpenseUseCase.execute(expense);

      // Refresh the expenses list
      await _loadExpensesFromLocalDatabase(force: true);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
    }
  }

  /// Update an existing expense
  Future<void> updateExpense(Expense expense) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _updateExpenseUseCase.execute(expense);

      // Refresh the expenses list
      await _loadExpensesFromLocalDatabase(force: true);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId, DateTime expenseDate) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _deleteExpenseUseCase.execute(expenseId, expenseDate);

      // Refresh the expenses list
      await _loadExpensesFromLocalDatabase(force: true);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
    }
  }

  /// Calculate expense totals for a specific month
  Future<Map<String, double>> calculateMonthlyTotals(
      int year, int month) async {
    try {
      final monthDate = DateTime(year, month, 1);
      final monthExpenses =
          _filterExpensesUseCase.filterByMonth(_expenses, monthDate);
      final total =
          await _calculateExpenseTotalsUseCase.getTotalExpenses(monthExpenses);
      return {'total': total};
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      return {};
    }
  }

  /// Calculate expense totals by category for a specific month
  Future<Map<String, double>> calculateCategoryTotals(
      int year, int month) async {
    try {
      final monthDate = DateTime(year, month, 1);
      final monthExpenses =
          _filterExpensesUseCase.filterByMonth(_expenses, monthDate);
      return await _calculateExpenseTotalsUseCase
          .getCategoryTotals(monthExpenses);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      return {};
    }
  }

  /// Calculate expense totals for the current day
  Future<double> calculateDailyTotal(DateTime day) async {
    try {
      final dayExpenses = _filterExpensesUseCase.filterByMonth(_expenses, day,
          isDayFiltering: true);
      final totals =
          await _calculateExpenseTotalsUseCase.getTotalExpenses(dayExpenses);
      return totals;
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      return 0.0;
    }
  }

  /// Calculate daily spending pattern for a month (returns map of day -> amount)
  Future<Map<int, double>> calculateDailySpendingPattern(
      DateTime selectedMonth) async {
    try {
      final Map<int, double> dailyTotals = {};

      // Get the number of days in the selected month
      final daysInMonth =
          DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

      // Initialize all days with 0
      for (int day = 1; day <= daysInMonth; day++) {
        dailyTotals[day] = 0.0;
      }

      // Filter expenses for the selected month
      final monthExpenses =
          _filterExpensesUseCase.filterByMonth(_expenses, selectedMonth);

      // Group expenses by day and calculate totals
      for (final expense in monthExpenses) {
        final day = expense.date.day;

        // Convert currency if needed
        double convertedAmount = expense.amount;
        if (expense.currency != currentCurrency) {
          // Use approximate conversion for display purposes
          convertedAmount = _convertCurrency(
              expense.amount, expense.currency, currentCurrency);
        }

        dailyTotals[day] = (dailyTotals[day] ?? 0.0) + convertedAmount;
      }

      return dailyTotals;
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      return {};
    }
  }

  /// Simple currency conversion helper (can be enhanced with real-time rates)
  double _convertCurrency(
      double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) {
      return amount;
    }

    final rate = _fallbackConversionRates[fromCurrency]?[toCurrency];

    if (rate == null) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ ExpensesViewModel: Missing conversion rate for $fromCurrency -> $toCurrency, returning original amount');
      }
      return amount;
    }

    return amount * rate;
  }

  /// Calculate yearly spending totals by month
  Future<Map<int, double>> calculateYearlySpendingPattern(int year) async {
    try {
      final Map<int, double> monthlyTotals = {};

      // Initialize all months with 0
      for (int month = 1; month <= 12; month++) {
        monthlyTotals[month] = 0.0;
      }

      // Filter expenses for the selected year
      final yearExpenses =
          _expenses.where((expense) => expense.date.year == year).toList();

      // Group expenses by month and calculate totals
      for (final expense in yearExpenses) {
        final month = expense.date.month;

        // Convert currency if needed
        double convertedAmount = expense.amount;
        if (expense.currency != currentCurrency) {
          convertedAmount = _convertCurrency(
              expense.amount, expense.currency, currentCurrency);
        }

        monthlyTotals[month] = (monthlyTotals[month] ?? 0.0) + convertedAmount;
      }

      return monthlyTotals;
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      return {};
    }
  }

  /// Set filter mode and date
  void setFilterMode(FilterMode mode, DateTime date,
      {String screenKey = 'default'}) {
    try {
      // Update the filter mode
      _filterMode = mode;

      // Store the filter mode info in screen filters for consistency
      _screenDayFilters[screenKey] = (mode == DateFilterMode.day);
      _screenFilters[screenKey] = date;

      switch (mode) {
        case DateFilterMode.day:
          // For day filtering, use exact date
          _selectedMonth = date;
          _isFiltering = true;
          _isDayFiltering = true;
          break;
        case DateFilterMode.month:
          // For month filtering, standardize to first day of month
          final normalizedMonth = DateTime(date.year, date.month, 1);
          _selectedMonth = normalizedMonth;
          _isFiltering = true;
          _isDayFiltering = false;
          break;
        case DateFilterMode.year:
          // For year filtering, store the year in _selectedMonth
          final yearDate = DateTime(date.year, 1, 1);
          _selectedMonth = yearDate;
          _isFiltering = true;
          _isDayFiltering = false;
          break;
      }

      // Apply the filter immediately
      _filterExpensesByMonth();
      notifyListenersThrottled('filter_mode_changed');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting filter mode: $e');
      }
    }
  }

  /// Get current filter mode for a screen
  FilterMode getFilterMode(String screenKey) {
    final isDayFilter = _screenDayFilters[screenKey] ?? false;
    if (isDayFilter) return DateFilterMode.day;
    // If no screen-specific setting, return the current global filter mode
    return _filterMode;
  }

  /// Handle errors
  void _handleError(Object e, StackTrace? stackTrace) {
    final error = AppError.from(e, stackTrace ?? StackTrace.current);
    error.log();
    _error = error.message;
    _isLoading = false;
    notifyListeners();
  }

  /// Get the filter date for a specific screen
  DateTime getScreenFilterDate(String screenKey) {
    return _screenFilters[screenKey] ?? DateTime.now();
  }

  /// Check if day filtering is enabled for a specific screen
  bool isDayFilteringForScreen(String screenKey) {
    return _screenDayFilters[screenKey] ?? false;
  }

  /// Get expenses for a specific month
  List<Expense> getExpensesForMonth(int year, int month) {
    final monthDate = DateTime(year, month, 1);
    return _filterExpensesUseCase.filterByMonth(_expenses, monthDate);
  }

  /// Get category totals for the current filter
  Future<Map<String, double>> getCategoryTotals() async {
    try {
      return await _calculateExpenseTotalsUseCase
          .getCategoryTotals(_filteredExpenses);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      return {};
    }
  }

  /// Refresh all data
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clear any cached filter data
      _filterExpensesUseCase.clearCache();

      // Load fresh data from database
      await _loadExpensesFromLocalDatabase(force: true);

      // Reapply current filter if active
      if (_isFiltering) {
        _filterExpensesByMonth();
      }

      if (kDebugMode) {
        debugPrint(
            'ExpensesViewModel: Data refreshed successfully, ${_expenses.length} expenses loaded');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ExpensesViewModel: Error refreshing data: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
