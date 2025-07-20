import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../domain/repositories/expenses_repository.dart';
import '../../../domain/repositories/budget_repository.dart';
import '../network/connectivity_service.dart';
import '../services/settings_service.dart';

/// Service responsible for synchronizing local data with Firebase
class SyncService {
  final ExpensesRepository _expensesRepository;
  final BudgetRepository _budgetRepository;
  final ConnectivityService _connectivityService;
  final SettingsService _settingsService;
  Timer? _syncTimer;
  bool _isSyncing = false;

  // Track when we last synced to prevent too frequent syncs
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(minutes: 5));

  // Stream controller to broadcast sync status
  final StreamController<bool> _syncStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get syncStatus => _syncStatusController.stream;

  SyncService({
    required ExpensesRepository expensesRepository,
    required BudgetRepository budgetRepository,
    required ConnectivityService connectivityService,
    required SettingsService settingsService,
  })  : _expensesRepository = expensesRepository,
        _budgetRepository = budgetRepository,
        _connectivityService = connectivityService,
        _settingsService = settingsService;

  /// Initialize the sync service
  Future<void> initialize({bool startPeriodicSync = false}) async {
    if (kDebugMode) {
      debugPrint('Initializing SyncService...');
    }

    // Listen for connectivity changes and auto-sync when connection is restored
    _connectivityService.connectionStatusStream.listen((isConnected) async {
      if (isConnected) {
        if (kDebugMode) {
          debugPrint('Connection restored - triggering data sync');
        }
        // Delay sync slightly to ensure connection is stable
        await Future.delayed(const Duration(seconds: 1));
        syncData(fullSync: true);
      } else {
        if (kDebugMode) {
          debugPrint(
              'Connection lost - sync will be performed when connection is restored');
        }
      }
    });

    // Check if we have connection now, and if so, perform initial sync
    final isConnected = await _connectivityService.isConnected;
    if (isConnected) {
      if (kDebugMode) {
        debugPrint('Initial connection available - performing first sync');
      }
      // Delay to ensure app is fully initialized
      Future.delayed(const Duration(seconds: 3), () {
        syncData(fullSync: true);
      });
    }

    // Only start periodic sync if explicitly requested
    if (startPeriodicSync) {
      _startPeriodicSync();
    }

    if (kDebugMode) {
      debugPrint('SyncService initialized successfully');
    }
  }

  /// Start periodic synchronization timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      final isConnected = await _connectivityService.isConnected;
      if (isConnected) {
        syncData(skipBudgets: false);
      }
    });
    if (kDebugMode) {
      debugPrint('Started periodic sync timer (every 15 minutes)');
    }
  }

  /// Check if sync is enabled
  Future<bool> isSyncEnabled() async {
    try {
      return _settingsService.syncEnabled;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking sync enabled status: $e');
      }
      return false;
    }
  }

  /// Set sync enabled/disabled state
  Future<void> setSyncEnabled(bool enabled) async {
    try {
      await _settingsService.updateSyncSetting(enabled);
      if (kDebugMode) {
        debugPrint('Sync ${enabled ? 'enabled' : 'disabled'} setting saved');
      }

      // If enabling sync, trigger a sync
      if (enabled) {
        // Use microtask to avoid blocking UI
        Future.microtask(() => syncData(fullSync: true));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting sync enabled status: $e');
      }
    }
  }

  /// Manually trigger data synchronization
  Future<void> syncData(
      {bool skipBudgets = false, bool fullSync = false}) async {
    // First check if sync is enabled
    final syncEnabled = await isSyncEnabled();
    if (!syncEnabled) {
      if (kDebugMode) {
        debugPrint('Sync is disabled in settings, skipping sync operation');
      }
      return;
    }

    // Prevent multiple syncs from running simultaneously
    if (_isSyncing) {
      if (kDebugMode) {
        debugPrint('Sync already in progress, skipping new request');
      }
      return;
    }

    try {
      _isSyncing = true;
      _syncStatusController.add(true); // Broadcast sync started

      // Don't sync more than once every 5 seconds unless it's a full sync
      final now = DateTime.now();
      if (!fullSync && now.difference(_lastSyncTime).inSeconds < 5) {
        if (kDebugMode) {
          debugPrint(
              'Sync requested too soon after previous sync, skipping...');
        }
        _isSyncing = false;
        _syncStatusController.add(false);
        return;
      }

      _lastSyncTime = now;

      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        if (kDebugMode) {
          debugPrint('No network connection, skipping sync');
        }
        _isSyncing = false;
        _syncStatusController.add(false);
        return;
      }

      if (kDebugMode) {
        debugPrint('Starting data synchronization');
      }

      // 1. Sync expenses first
      await _syncExpenses();

      // 2. Sync budgets (unless skipped)
      if (!skipBudgets) {
        await _syncBudgets();
      }

      if (kDebugMode) {
        debugPrint('Data synchronization completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync error: $e');
      }
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false); // Broadcast sync ended
    }
  }

  /// Force a full synchronization
  Future<void> forceFullSync() async {
    await syncData(fullSync: true);
  }

  /// Sync expenses between local database and Firebase
  Future<void> _syncExpenses() async {
    try {
      if (kDebugMode) {
        debugPrint('Syncing expenses...');
      }

      // Get local expenses
      final expenses = await _expensesRepository.getExpenses();
      if (kDebugMode) {
        debugPrint('Found ${expenses.length} expenses in local database');
      }

      // In a real app, we would sync with Firebase here

      if (kDebugMode) {
        debugPrint('Expenses sync completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error syncing expenses: $e');
      }
    }
  }

  /// Sync budgets between local database and Firebase
  Future<void> _syncBudgets() async {
    try {
      if (kDebugMode) {
        debugPrint('Syncing budgets...');
      }

      // Get current month ID
      final now = DateTime.now();
      final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Get local budget
      final budget = await _budgetRepository.getBudget(monthId);
      if (budget != null) {
        if (kDebugMode) {
          debugPrint('Found budget for month $monthId in local database');
        }
      } else {
        if (kDebugMode) {
          debugPrint('No budget found for month $monthId');
        }
      }

      // In a real app, we would sync with Firebase here

      if (kDebugMode) {
        debugPrint('Budget sync completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error syncing budgets: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
    if (kDebugMode) {
      debugPrint('SyncService disposed');
    }
  }
}
