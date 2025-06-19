import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

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
import 'dart:async';

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
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _expensesSubscription;
  bool _isOffline = false;

  // Flag to prevent auto-reset of month filter when navigating between screens
  bool _persistFilter = true;

  // For date filtering
  DateTime _selectedMonth = DateTime.now();
  bool _isFiltering = false;
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
    // Check network connection status
    _isOffline = await _loadExpensesUseCase.isOffline;

    // Listen for network status changes with performance optimization
    final subscription =
        _connectivityService.connectionStatusStream.listen((isConnected) {
      final wasOffline = _isOffline;
      _isOffline = !isConnected;

      // Reload data when going from offline to online
      if (wasOffline && isConnected) {
        debugPrint(
            '🔄 ExpensesViewModel: Network connection restored, triggering sync and reload');
        // Trigger sync first
        _loadExpensesUseCase.triggerSync();
        // Then reload data
        _startExpensesStream();
      } else if (!wasOffline && !isConnected) {
        // Load local data when going from online to offline
        debugPrint(
            '🔄 ExpensesViewModel: Network connection lost, loading from local database');
        _loadExpensesFromLocalDatabase();
      }
    });
    trackSubscription(subscription);

    // Initial data load
    if (_isOffline) {
      debugPrint(
          '🔄 ExpensesViewModel: Starting in offline mode, loading from local database');
      _loadExpensesFromLocalDatabase();
    } else {
      debugPrint(
          '🔄 ExpensesViewModel: Starting in online mode, loading from server');
      _startExpensesStream();
    }
  }

  // Load expenses from local database
  Future<void> _loadExpensesFromLocalDatabase() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final localExpenses = await _loadExpensesUseCase.loadFromLocalDatabase();

      _expenses = localExpenses;

      // Apply default filtering for current month
      _isFiltering = true;
      // Use the current _selectedMonth instead of forcing to 'home' screen filter
      if (_selectedMonth == DateTime.now() || !_isFiltering) {
        _selectedMonth = DateTime.now();
      }
      _filterExpensesByMonth();

      _isLoading = false;
      notifyListenersThrottled('expenses_loaded');
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
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

      // Initialize filtered expenses as empty to prevent null access
      _filteredExpenses = [];

      _filterExpensesByMonth();
    } catch (e) {
      debugPrint('Error setting selected month: $e');
      _error = 'Failed to set selected month';
      // Use post frame callback to avoid build phase issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Get filter settings for a specific screen
  DateTime getScreenFilterDate(String screenKey) {
    return _screenFilters[screenKey] ?? DateTime.now();
  }

  /// Check if day filtering is enabled for a specific screen
  bool isDayFilteringForScreen(String screenKey) {
    return _screenDayFilters[screenKey] ?? false;
  }

  /// Manually set if the filter should be persisted between screen navigations
  void setPersistFilter(bool persist) {
    _persistFilter = persist;
  }

  /// Check if filter should be persisted
  bool get shouldPersistFilter => _persistFilter;

  void clearMonthFilter() {
    _isFiltering = false;
    notifyListeners();
  }

  void _filterExpensesByMonth() {
    if (!_isFiltering) return;

    // Use the filter use case for filtering
    _filteredExpenses = _filterExpensesUseCase.filterByMonth(
        _expenses, _selectedMonth,
        isDayFiltering: _isDayFiltering);

    // Schedule notification for next event loop to avoid build phase issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Force filtering by month (public method for external components)
  void forceFilterByMonth(DateTime month) {
    debugPrint('Forcing filter by month: ${month.toString()}');
    debugPrint('Previous selected month: ${_selectedMonth.toString()}');

    // Clear relevant cache to ensure fresh filtering
    _filterExpensesUseCase.clearCache();

    // Set filter parameters
    _selectedMonth = month;
    _isFiltering = true;
    _isDayFiltering = false;

    debugPrint('Set new selected month: ${_selectedMonth.toString()}');
    debugPrint(
        'Filtering enabled: $_isFiltering, Day filtering: $_isDayFiltering');

    // Perform filtering
    _filterExpensesByMonth();
  }

  void _startExpensesStream() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _handleError(AuthError.unauthenticated());
      return;
    }

    final userId = currentUser.uid;

    _expensesSubscription?.cancel(); // Cancel previous subscription if any

    // Use database layer filtering for current month data, add pagination
    const int pageSize = 50;
    Query expensesQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .limit(pageSize);

    _expensesSubscription = expensesQuery.snapshots().listen(
      (snapshot) {
        _processExpensesSnapshot(snapshot, userId, pageSize);
      },
      onError: (e, stackTrace) {
        // When handling exceptions, try to load data from local database
        debugPrint('Firestore stream error: $e, loading from local database');
        _loadExpensesFromLocalDatabase();
      },
    );
  }

  // Extract data processing logic to independent method for better code management
  void _processExpensesSnapshot(
      QuerySnapshot snapshot, String userId, int pageSize) {
    // Use compute for parallel processing to improve performance
    compute<List<QueryDocumentSnapshot>, List<Expense>>(
            LoadExpensesUseCase.processExpensesDocs, snapshot.docs)
        .then((processedExpenses) {
      _expenses = processedExpenses;

      // Clear expired cache
      _filterExpensesUseCase.clearCache();

      // Apply filtering based on current state
      if (!_isFiltering) {
        _isFiltering = true;
        _selectedMonth = DateTime.now();
        _isDayFiltering = false;
      }
      _filterExpensesByMonth();

      _isLoading = false;
      notifyListeners();
    }).catchError((e, stackTrace) {
      _handleError(e, stackTrace);
    });
  }

  void _handleError(dynamic e, [StackTrace? stackTrace]) {
    final appError = AppError.from(e, stackTrace);
    _error = appError.message;
    _isLoading = false;
    notifyListeners();
    appError.log();
  }

  // Get total expenses for the selected month by category with currency conversion
  Future<Map<String, double>> getCategoryTotals() async {
    final expensesToUse = _isFiltering ? _filteredExpenses : _expenses;
    return await _calculateExpenseTotalsUseCase
        .getCategoryTotals(expensesToUse);
  }

  // Get total expenses for the selected month with currency conversion
  Future<double> getTotalExpenses() async {
    final expensesToUse = _isFiltering ? _filteredExpenses : _expenses;
    return await _calculateExpenseTotalsUseCase.getTotalExpenses(expensesToUse);
  }

  Future<void> addExpense(Expense expense) async {
    try {
      // Add expense to database
      await _addExpenseUseCase.execute(expense);

      // Clear cache to ensure data consistency
      _filterExpensesUseCase.clearCache();

      // Offline mode support
      if (_isOffline) {
        await _loadExpensesFromLocalDatabase();
      }
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      rethrow; // Rethrow to allow UI to handle
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      // Update expense data
      await _updateExpenseUseCase.execute(expense);

      // Clear cache to ensure data consistency
      _filterExpensesUseCase.clearCache();

      // Force refresh data to ensure UI consistency
      await refreshData();
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      // Get the expense to delete for budget update
      final expenseToDelete = _expenses.firstWhere((e) => e.id == id);

      // Delete expense
      await _deleteExpenseUseCase.execute(id, expenseToDelete);

      // Clear cache
      _filterExpensesUseCase.clearCache();

      // Offline mode support
      if (_isOffline) {
        await _loadExpensesFromLocalDatabase();
      }
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      rethrow;
    }
  }

  // Get expenses for a specific month
  List<Expense> getExpensesForMonth(int year, int month) {
    return _filterExpensesUseCase.getExpensesForMonth(_expenses, year, month);
  }

  Future<void> refreshData() async {
    debugPrint('🔄 ExpensesViewModel: Manual data refresh requested');
    _isLoading = true;
    notifyListeners();

    try {
      // Check if we're online
      final isConnected = await _connectivityService.isConnected;

      if (isConnected) {
        // If online, trigger sync first
        await _loadExpensesUseCase.triggerSync();
        // Then reload data
        await _loadExpensesFromLocalDatabase();
      } else {
        // If offline, just reload from local database
        await _loadExpensesFromLocalDatabase();
      }
    } catch (e) {
      debugPrint('🔄 ExpensesViewModel: Error refreshing data: $e');
      _error = 'Failed to refresh data: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _expensesSubscription?.cancel(); // Cancel the stream subscription
    super.dispose();
  }
}
