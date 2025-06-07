import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart' as app_category;
import '../../domain/repositories/expenses_repository.dart';
import '../../core/errors/app_error.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/performance_monitor.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../core/services/budget_calculation_service.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/services/sync_service.dart';
import '../../di/injection_container.dart' as di;
import 'dart:async';

class ExpensesViewModel extends ChangeNotifier {
  final ExpensesRepository _expensesRepository;
  final BudgetRepository _budgetRepository;
  final ConnectivityService _connectivityService;
  final SettingsService _settingsService;
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _expensesSubscription;
  bool _isOffline = false;

  // Flag to prevent automatic budget updates on startup
  bool _isInitialLoad = true;

  // Flag to prevent auto-reset of month filter when navigating between screens
  bool _persistFilter = true;

  // Cache mechanism
  final Map<String, List<Expense>> _cache = {};

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
    required BudgetRepository budgetRepository,
    required ConnectivityService connectivityService,
    required SettingsService settingsService,
  })  : _expensesRepository = expensesRepository,
        _budgetRepository = budgetRepository,
        _connectivityService = connectivityService,
        _settingsService = settingsService {
    _init();
  }

  Future<void> _init() async {
    // Check network connection status
    _isOffline = !await _connectivityService.isConnected;

    // Listen for network status changes
    _connectivityService.connectionStatusStream.listen((isConnected) {
      final wasOffline = _isOffline;
      _isOffline = !isConnected;

      // Reload data when going from offline to online
      if (wasOffline && isConnected) {
        debugPrint(
            '🔄 ExpensesViewModel: Network connection restored, triggering sync and reload');
        // Trigger sync first
        _triggerSync();
        // Then reload data
        _startExpensesStream();
      } else if (!wasOffline && !isConnected) {
        // Load local data when going from online to offline
        debugPrint(
            '🔄 ExpensesViewModel: Network connection lost, loading from local database');
        _loadExpensesFromLocalDatabase();
      }
    });

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
      PerformanceMonitor.startTimer('load_local_expenses');
      final localExpenses = await _expensesRepository.getExpenses();

      _expenses = localExpenses;

      // Clear cache
      _cache.clear();

      // Apply default filtering for current month
      _isFiltering = true;
      _selectedMonth = _screenFilters['home'] ?? DateTime.now();
      _isDayFiltering = _screenDayFilters['home'] ?? false;
      _filterExpensesByMonth();

      // Set initial load flag to false after first load
      _isInitialLoad = false;

      _isLoading = false;
      PerformanceMonitor.stopTimer('load_local_expenses');
      notifyListeners();
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
      // _filterExpensesByMonth already calls notifyListeners
    } catch (e) {
      debugPrint('Error setting selected month: $e');
      _error = 'Failed to set selected month';
      // Use microtask to avoid build phase issues
      Future.microtask(() {
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

    PerformanceMonitor.startTimer('filter_expenses');

    final cacheKey = _isDayFiltering
        ? '${_selectedMonth.year}-${_selectedMonth.month}-${_selectedMonth.day}'
        : '${_selectedMonth.year}-${_selectedMonth.month}';

    // Use cached data if available
    if (_cache.containsKey(cacheKey)) {
      _filteredExpenses = _cache[cacheKey]!;
      PerformanceMonitor.stopTimer('filter_expenses', logResult: true);
      // Schedule notification for next event loop to avoid build phase issues
      Future.microtask(() {
        notifyListeners();
      });
      return;
    }

    // Filter synchronously to avoid state inconsistency
    try {
      if (_isDayFiltering) {
        // Filter by exact date (day level)
        _filteredExpenses = _expenses.where((expense) {
          return expense.date.year == _selectedMonth.year &&
              expense.date.month == _selectedMonth.month &&
              expense.date.day == _selectedMonth.day;
        }).toList();
      } else {
        // Filter by month only
        _filteredExpenses = _expenses.where((expense) {
          return expense.date.year == _selectedMonth.year &&
              expense.date.month == _selectedMonth.month;
        }).toList();
      }

      // Update cache
      _cache[cacheKey] = _filteredExpenses;
    } catch (e) {
      debugPrint('Error during expense filtering: $e');
      // Ensure valid list even if filtering fails
      _filteredExpenses = [];
    }

    PerformanceMonitor.stopTimer('filter_expenses');
    // Schedule notification for next event loop to avoid build phase issues
    Future.microtask(() {
      notifyListeners();
    });
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
    PerformanceMonitor.startTimer('load_expenses');

    // If month filter is already set, filter at database layer
    Query expensesQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .orderBy('date', descending: true);

    // Limit maximum data loading to optimize performance
    const int pageSize = 50;
    expensesQuery = expensesQuery.limit(pageSize);

    _expensesSubscription = expensesQuery.snapshots().listen(
      (snapshot) {
        _processExpensesSnapshot(snapshot, userId, pageSize);
      },
      onError: (e, stackTrace) {
        // When handling exceptions, try to load data from local database
        debugPrint('Firestore stream error: $e, loading from local database');
        _loadExpensesFromLocalDatabase();
        PerformanceMonitor.stopTimer('load_expenses');
      },
    );
  }

  // Extract data processing logic to independent method for better code management
  void _processExpensesSnapshot(
      QuerySnapshot snapshot, String userId, int pageSize) {
    // Use compute for parallel processing to improve performance
    compute<_ProcessParams, List<Expense>>(
        _processExpensesDocs,
        _ProcessParams(
          docs: snapshot.docs,
        )).then((processedExpenses) {
      _expenses = processedExpenses;

      // Clear expired cache
      _cache.clear();

      // Apply default filtering for current month when loading for the first time
      if (_isInitialLoad) {
        _isFiltering = true;
        _selectedMonth = _screenFilters['home'] ?? DateTime.now();
        _isDayFiltering = _screenDayFilters['home'] ?? false;
        _filterExpensesByMonth();
      }
      // Apply existing filter if active
      else if (_isFiltering) {
        _filterExpensesByMonth();
      }

      // Set initial load flag to false after first load
      _isInitialLoad = false;

      PerformanceMonitor.stopTimer('load_expenses');
      _isLoading = false;
      notifyListeners();
    }).catchError((e, stackTrace) {
      _handleError(e, stackTrace);
      PerformanceMonitor.stopTimer('load_expenses');
    });
  }

  // Static method for parallel document processing with enhanced null safety
  static List<Expense> _processExpensesDocs(_ProcessParams params) {
    return params.docs
        .map((doc) {
          final data = doc.data();
          if (data == null) {
            // Skip null documents
            return null;
          }

          final documentData = data as Map<String, dynamic>;

          // Handle potential null or missing data safely
          final amount = (documentData['amount'] as num?)?.toDouble() ?? 0.0;
          final timestamp = documentData['date'] as Timestamp?;
          final date = timestamp?.toDate() ?? DateTime.now();
          final categoryString = documentData['category'] as String?;
          final category = categoryString != null
              ? app_category.CategoryExtension.fromId(categoryString) ??
                  app_category.Category.others
              : app_category.Category.others;
          final methodString = documentData['method'] as String?;
          final method = PaymentMethod.values.firstWhere(
            (e) => e.toString().split('.').last == methodString,
            orElse: () => PaymentMethod.cash,
          );

          return Expense(
            id: doc.id,
            remark: documentData['remark'] as String? ?? '',
            amount: amount,
            date: date,
            category: category,
            method: method,
            description: documentData['description'] as String?,
            currency: documentData['currency'] as String? ?? 'MYR',
          );
        })
        .whereType<Expense>()
        .toList(); // Filter out null expenses
  }

  // 统一错误处理
  void _handleError(dynamic e, [StackTrace? stackTrace]) {
    final appError = AppError.from(e, stackTrace);
    _error = appError.message;
    _isLoading = false;
    notifyListeners();
    appError.log(); // 使用自定义的日志记录
  }

  // Get total expenses for the selected month by category - 优化使用compute函数
  Map<app_category.Category, double> getCategoryTotals() {
    final expensesToUse = _isFiltering ? _filteredExpenses : _expenses;

    if (expensesToUse.isEmpty) {
      return {};
    }

    return PerformanceMonitor.measure('calculate_category_totals', () {
      final Map<app_category.Category, double> result = {};

      for (var expense in expensesToUse) {
        result[expense.category] =
            (result[expense.category] ?? 0) + expense.amount;
      }

      return result;
    });
  }

  // Get total expenses for the selected month - 优化计算
  double getTotalExpenses() {
    final expensesToUse = _isFiltering ? _filteredExpenses : _expenses;

    if (expensesToUse.isEmpty) {
      return 0.0;
    }

    return PerformanceMonitor.measure('calculate_total_expenses', () {
      return expensesToUse.fold<double>(
          0.0, (sum, expense) => sum + expense.amount);
    });
  }

  // 根据日期获取对应的月份ID
  String _getMonthIdFromDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  // 在支出更改后更新预算数据
  Future<void> _updateBudgetAfterExpenseChange(Expense expense) async {
    // Skip budget updates during initial load to prevent unnecessary syncing
    if (_isInitialLoad) {
      debugPrint(
          'Skipping budget update during initial load for expense: ${expense.id}');
      return;
    }

    // Skip updates if we're not on the expense's month
    if (_isFiltering &&
        (_selectedMonth.year != expense.date.year ||
            _selectedMonth.month != expense.date.month)) {
      debugPrint(
          'Skipping budget update for expense: ${expense.id} - not in currently selected month');
      return;
    }

    try {
      debugPrint(
          'Expense change detected: ${expense.id}. Checking if budget update is needed...');
      // 获取该支出所属月份的ID
      final monthId = _getMonthIdFromDate(expense.date);

      // 获取该月的预算
      final currentBudget = await _budgetRepository.getBudget(monthId);
      if (currentBudget == null) {
        debugPrint(
            'No budget found for month $monthId. Cannot update after expense change.');
        return; // 如果没有预算数据，则不需要更新
      }

      // 获取该月的所有支出
      final monthExpenses =
          getExpensesForMonth(expense.date.year, expense.date.month);

      // 计算新的预算剩余金额
      final updatedBudget = await BudgetCalculationService.calculateBudget(
          currentBudget, monthExpenses);

      // 只有当预算真正发生变化时才保存
      if (currentBudget != updatedBudget) {
        await _budgetRepository.setBudget(monthId, updatedBudget);
        debugPrint(
            'Budget updated for month $monthId after expense change because it changed.');
      } else {
        debugPrint(
            'Budget for month $monthId did not change after expense calculation. No update sent.');
      }
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      debugPrint(
          'Error updating budget after expense change: ${error.message}');
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      // 添加支出到数据库
      await PerformanceMonitor.measureAsync('add_expense', () async {
        return await _expensesRepository.addExpense(expense);
      });

      // 清除缓存以确保数据一致性
      _cache.clear();

      // 离线模式下，手动刷新数据
      if (_isOffline) {
        await _loadExpensesFromLocalDatabase();
      }

      // 更新相关月份的预算
      await _updateBudgetAfterExpenseChange(expense);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      rethrow; // Rethrow to allow UI to handle
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      // 更新支出数据
      await PerformanceMonitor.measureAsync('update_expense', () async {
        return await _expensesRepository.updateExpense(expense);
      });

      // 清除缓存以确保数据一致性
      _cache.clear();

      // 离线模式下，手动刷新数据
      if (_isOffline) {
        await _loadExpensesFromLocalDatabase();
      }

      // 更新当前月份的预算
      await _updateBudgetAfterExpenseChange(expense);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      // 获取要删除的支出，以便后续更新相关月份的预算
      final expenseToDelete = _expenses.firstWhere((e) => e.id == id);

      // 删除支出
      await PerformanceMonitor.measureAsync('delete_expense', () async {
        return await _expensesRepository.deleteExpense(id);
      });

      // Only clear cache for the affected month to preserve performance
      final monthKey =
          '${expenseToDelete.date.year}-${expenseToDelete.date.month}';
      _cache.remove(monthKey);

      // 离线模式下，手动刷新数据
      if (_isOffline) {
        await _loadExpensesFromLocalDatabase();
      }

      // 更新相关月份的预算
      await _updateBudgetAfterExpenseChange(expenseToDelete);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      rethrow;
    }
  }

  // Get expenses for a specific month
  List<Expense> getExpensesForMonth(int year, int month) {
    return PerformanceMonitor.measure('get_expenses_for_month', () {
      return _expenses.where((expense) {
        return expense.date.year == year && expense.date.month == month;
      }).toList();
    });
  }

  // 手动刷新数据（可从UI调用）
  Future<void> refreshData() async {
    debugPrint('🔄 ExpensesViewModel: Manual data refresh requested');
    _isLoading = true;
    notifyListeners();

    try {
      // Check if we're online
      final isConnected = await _connectivityService.isConnected;

      if (isConnected) {
        // If online, trigger sync first
        await _triggerSync();
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

  // Explicitly update budget for a specific month (for use in analytics screen)
  Future<void> updateBudgetForMonth(int year, int month) async {
    try {
      final monthId = '$year-${month.toString().padLeft(2, '0')}';
      debugPrint('Explicitly updating budget for month: $monthId');

      // Get the current user ID
      final userId = await _getCurrentUserId();
      if (userId == null) {
        debugPrint('No user ID available, cannot update budget');
        return;
      }

      // Get the budget for this month
      final currentBudget = await _budgetRepository.getBudget(monthId);
      if (currentBudget == null) {
        debugPrint('No budget found for month $monthId. Nothing to update.');
        return;
      }

      // Get expenses for this month
      final monthExpenses = getExpensesForMonth(year, month);

      // Calculate new budget
      final updatedBudget = await BudgetCalculationService.calculateBudget(
          currentBudget, monthExpenses);

      // Only save if changed
      if (currentBudget != updatedBudget) {
        await _budgetRepository.setBudget(monthId, updatedBudget);
        debugPrint('Budget for month $monthId updated explicitly.');
      } else {
        debugPrint('Budget for month $monthId already up to date.');

        // Even if budget hasn't changed, clear any pending sync operations
        // to prevent continuous updates
        final syncService = di.sl<SyncService>();
        await syncService.manualClearBudgetSyncForMonth(monthId);
      }
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      debugPrint('Error updating budget explicitly: ${error.message}');
    }
  }

  // Helper method to get current user ID
  Future<String?> _getCurrentUserId() async {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      return null;
    }
  }

  // Trigger data synchronization
  Future<void> _triggerSync() async {
    try {
      debugPrint('🔄 ExpensesViewModel: Triggering data synchronization');
      final syncService = di.sl<SyncService>();
      await syncService.syncData(fullSync: true);
      debugPrint('🔄 ExpensesViewModel: Data synchronization completed');
    } catch (e) {
      debugPrint('🔄 ExpensesViewModel: Error during data synchronization: $e');
    }
  }

  @override
  void dispose() {
    _expensesSubscription?.cancel(); // Cancel the stream subscription
    super.dispose();
  }
}

// 处理参数类，用于compute函数
class _ProcessParams {
  final List<QueryDocumentSnapshot> docs;

  _ProcessParams({
    required this.docs,
  });
}
