import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../datasources/local_data_source.dart';
import '../../../domain/repositories/expenses_repository.dart';
import '../../../domain/repositories/budget_repository.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/user.dart' as domain;
import '../network/connectivity_service.dart';
import '../errors/app_error.dart';

/// Service responsible for synchronizing local data with Firebase
class SyncService {
  final LocalDataSource _localDataSource;
  final ExpensesRepository _expensesRepository;
  final BudgetRepository _budgetRepository;
  final ConnectivityService _connectivityService;
  final firebase_auth.FirebaseAuth _auth;
  Timer? _syncTimer;
  bool _isSyncing = false;

  // Track when we last synced to prevent too frequent syncs
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(minutes: 5));

  // Stream controller to broadcast sync status
  final StreamController<bool> _syncStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get syncStatus => _syncStatusController.stream;

  SyncService({
    required LocalDataSource localDataSource,
    required ExpensesRepository expensesRepository,
    required BudgetRepository budgetRepository,
    required ConnectivityService connectivityService,
    firebase_auth.FirebaseAuth? auth,
  })  : _localDataSource = localDataSource,
        _expensesRepository = expensesRepository,
        _budgetRepository = budgetRepository,
        _connectivityService = connectivityService,
        _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  /// Initialize the sync service
  Future<void> initialize({bool startPeriodicSync = false}) async {
    debugPrint('Initializing SyncService...');

    // Listen for connectivity changes and auto-sync when connection is restored
    _connectivityService.connectionStatusStream.listen((isConnected) async {
      if (isConnected) {
        debugPrint('Connection restored - triggering data sync');
        // Delay sync slightly to ensure connection is stable
        await Future.delayed(const Duration(seconds: 1));
        syncData(fullSync: true);
      } else {
        debugPrint(
            'Connection lost - sync will be performed when connection is restored');
      }
    });

    // Check if we have connection now, and if so, perform initial sync
    final isConnected = await _connectivityService.isConnected;
    if (isConnected) {
      debugPrint('Initial connection available - performing first sync');
      // Delay to ensure app is fully initialized
      Future.delayed(const Duration(seconds: 3), () {
        syncData(fullSync: true);
      });
    }

    // Only start periodic sync if explicitly requested
    if (startPeriodicSync) {
      _startPeriodicSync();
    }

    debugPrint('SyncService initialized successfully');
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
    debugPrint('Started periodic sync timer (every 15 minutes)');
  }

  /// Manually trigger data synchronization
  Future<void> syncData(
      {bool skipBudgets = false, bool fullSync = false}) async {
    // Prevent multiple syncs from running simultaneously
    if (_isSyncing) {
      debugPrint('Sync already in progress, skipping new request');
      return;
    }

    try {
      _isSyncing = true;
      _syncStatusController.add(true); // Broadcast sync started

      // Don't sync more than once every 5 seconds unless it's a full sync
      final now = DateTime.now();
      if (!fullSync && now.difference(_lastSyncTime).inSeconds < 5) {
        debugPrint('Sync requested too soon after previous sync, skipping...');
        _isSyncing = false;
        _syncStatusController.add(false);
        return;
      }

      _lastSyncTime = now;

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No user logged in, skipping sync');
        _isSyncing = false;
        _syncStatusController.add(false);
        return;
      }

      final userId = currentUser.uid;
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        debugPrint('No network connection, skipping sync');
        _isSyncing = false;
        _syncStatusController.add(false);
        return;
      }

      debugPrint('Starting data synchronization for user: $userId');

      // 1. Sync expenses first
      await _syncExpenses(userId);

      // 2. Sync budgets (unless skipped)
      if (!skipBudgets) {
        await _syncBudgets(userId);
      }

      // 3. Sync user settings
      await _syncUserSettings(userId);

      // 4. Process any remaining operations from the queue
      await _processPendingOperations(userId, skipBudgets);

      debugPrint('Data synchronization completed successfully');
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false); // Broadcast sync ended
    }
  }

  /// Sync all unsynced expenses
  Future<void> _syncExpenses(String userId) async {
    try {
      debugPrint('Syncing expenses...');
      final unsyncedExpenses = await _localDataSource.getUnsyncedExpenses();
      debugPrint('Found ${unsyncedExpenses.length} unsynced expenses');

      for (final expense in unsyncedExpenses) {
        if (expense.id.startsWith('offline_')) {
          // This is an offline-created expense, add to Firebase
          debugPrint('Syncing offline expense: ${expense.id}');

          // Add to Firebase to get a proper ID
          final docRef = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('expenses')
              .add({
            'remark': expense.remark,
            'amount': expense.amount,
            'date': Timestamp.fromDate(expense.date),
            'category': expense.category.id,
            'method': expense.method.toString().split('.').last,
            'description': expense.description,
            'currency': expense.currency,
            'recurringExpenseId': expense.recurringExpenseId,
          });

          debugPrint('Firebase save successful with ID: ${docRef.id}');

          // Create expense with Firebase-generated ID
          final expenseWithFirebaseId = expense.copyWith(id: docRef.id);

          // Delete old offline record
          await _localDataSource.deleteExpense(expense.id);

          // Save with new Firebase ID as synced
          await _localDataSource.saveSyncedExpense(expenseWithFirebaseId);

          debugPrint(
              'Synced offline expense ${expense.id} to Firebase with ID: ${docRef.id}');
        } else {
          // This is an existing expense that was updated offline
          debugPrint('Syncing updated expense: ${expense.id}');

          // Update the expense in Firebase
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('expenses')
              .doc(expense.id)
              .update({
            'remark': expense.remark,
            'amount': expense.amount,
            'date': Timestamp.fromDate(expense.date),
            'category': expense.category.id,
            'method': expense.method.toString().split('.').last,
            'description': expense.description,
            'currency': expense.currency,
            'recurringExpenseId': expense.recurringExpenseId,
          });

          // Mark as synced
          await _localDataSource.markExpenseAsSynced(expense.id);
          debugPrint('Expense updated in Firebase: ${expense.id}');
        }
      }

      debugPrint('Expense sync completed');
    } catch (e) {
      debugPrint('Error syncing expenses: $e');
      rethrow;
    }
  }

  /// Sync all unsynced budgets
  Future<void> _syncBudgets(String userId) async {
    try {
      debugPrint('Syncing budgets...');
      final unsyncedBudgetIds =
          await _localDataSource.getUnsyncedBudgetIds(userId);
      debugPrint('Found ${unsyncedBudgetIds.length} unsynced budgets');

      for (final monthId in unsyncedBudgetIds) {
        final localBudget = await _localDataSource.getBudget(monthId, userId);
        if (localBudget != null) {
          debugPrint('Syncing budget for month: $monthId');

          // Set the budget in Firebase
          await _budgetRepository.setBudget(monthId, localBudget);

          // Mark as synced
          await _localDataSource.markBudgetAsSynced(monthId, userId);
          debugPrint('Budget synced for month: $monthId');
        }
      }

      debugPrint('Budget sync completed');
    } catch (e) {
      debugPrint('Error syncing budgets: $e');
      rethrow;
    }
  }

  /// Sync user settings
  Future<void> _syncUserSettings(String userId) async {
    try {
      debugPrint('Syncing user settings...');
      final settings = await _localDataSource.getUserSettings(userId);

      if (settings != null) {
        // Check if settings need syncing (not marked as synced)
        final userData = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Only add non-null values
        if (settings['currency'] != null) {
          userData['currency'] = settings['currency'];
        }
        if (settings['theme'] != null) {
          userData['theme'] = settings['theme'];
        }

        // Handle nested settings
        final Map<String, dynamic> settingsMap = {};
        if (settings.containsKey('settings') && settings['settings'] is Map) {
          final nestedSettings = settings['settings'] as Map<String, dynamic>;
          if (nestedSettings['allowNotification'] != null) {
            settingsMap['allowNotification'] =
                nestedSettings['allowNotification'];
          }
          if (nestedSettings['autoBudget'] != null) {
            settingsMap['autoBudget'] = nestedSettings['autoBudget'];
          }
          if (nestedSettings['improveAccuracy'] != null) {
            settingsMap['improveAccuracy'] = nestedSettings['improveAccuracy'];
          }
        }

        // Also check for root-level settings (backward compatibility)
        if (settings['allowNotification'] != null) {
          settingsMap['allowNotification'] = settings['allowNotification'];
        }
        if (settings['autoBudget'] != null) {
          settingsMap['autoBudget'] = settings['autoBudget'];
        }
        if (settings['improveAccuracy'] != null) {
          settingsMap['improveAccuracy'] = settings['improveAccuracy'];
        }

        if (settingsMap.isNotEmpty) {
          userData['settings'] = settingsMap;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set(userData, SetOptions(merge: true));

        await _localDataSource.markUserSettingsAsSynced(userId);
        debugPrint('User settings synced successfully');
      }
    } catch (e) {
      debugPrint('Error syncing user settings: $e');
    }
  }

  /// Process any remaining operations from the sync queue
  Future<void> _processPendingOperations(
      String userId, bool skipBudgets) async {
    try {
      debugPrint('Processing pending operations from queue...');

      // Get all pending operations from queue
      final pendingOperations =
          await _localDataSource.getPendingSyncOperations();
      debugPrint('Found ${pendingOperations.length} pending operations');

      // Process operations in chronological order
      for (final operation in pendingOperations) {
        final entityType = operation['entityType'] as String;
        final entityId = operation['entityId'] as String;
        final opUserId = operation['userId'] as String;
        final operationType = operation['operation'] as String;
        final syncId = operation['id'] as int;

        // Verify operation belongs to current user
        if (opUserId != userId) {
          await _localDataSource.clearSyncOperation(syncId);
          continue;
        }

        // Skip budget operations if requested
        if (skipBudgets && entityType == 'budget') {
          debugPrint(
              'Skipping budget sync operation: $syncId (skipBudgets=true)');
          continue;
        }

        try {
          // Handle sync based on entity type and operation type
          switch (entityType) {
            case 'expense':
              await _syncExpense(entityId, operationType, userId);
              break;
            case 'budget':
              if (!skipBudgets) {
                await _syncBudget(entityId, userId, operationType);
              }
              break;
            case 'user_settings':
              await _syncUserSettings(userId);
              break;
            case 'recurring_expense':
              // TODO: Implement recurring expense sync
              break;
          }

          // Mark operation as completed
          await _localDataSource.clearSyncOperation(syncId);
        } catch (e) {
          debugPrint('Error processing operation $syncId: $e');
          // If network error, stop sync process
          if (e is NetworkError) {
            break;
          }
          // For other errors, continue with next operation
        }
      }

      debugPrint('Finished processing pending operations');
    } catch (e) {
      debugPrint('Error processing pending operations: $e');
    }
  }

  /// Sync individual expense record
  Future<void> _syncExpense(
      String expenseId, String operation, String userId) async {
    try {
      switch (operation) {
        case 'add':
        case 'update':
          final expenses = await _localDataSource.getUnsyncedExpenses();

          Expense? expense;
          try {
            expense = expenses.firstWhere((e) => e.id == expenseId);
          } catch (e) {
            debugPrint('Expense with ID $expenseId not found for sync');
            return;
          }

          if (operation == 'add') {
            // For offline expenses, add to Firebase and update local ID
            if (expense.id.startsWith('offline_')) {
              // Add to Firebase
              final docRef = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('expenses')
                  .add({
                'remark': expense.remark,
                'amount': expense.amount,
                'date': Timestamp.fromDate(expense.date),
                'category': expense.category.id,
                'method': expense.method.toString().split('.').last,
                'description': expense.description,
                'currency': expense.currency,
                'recurringExpenseId': expense.recurringExpenseId,
              });

              debugPrint('Firebase save successful with ID: ${docRef.id}');

              // Update local record with Firebase ID
              final expenseWithFirebaseId = expense.copyWith(id: docRef.id);

              // Delete old offline record
              await _localDataSource.deleteExpense(expense.id);

              // Save with new Firebase ID as synced
              await _localDataSource.saveSyncedExpense(expenseWithFirebaseId);

              debugPrint(
                  'Synced offline expense ${expense.id} to Firebase with ID: ${docRef.id}');
            } else {
              // Regular add operation
              await _expensesRepository.addExpense(expense);
              await _localDataSource.markExpenseAsSynced(expenseId);
              debugPrint('Synced regular expense: $expenseId');
            }
          } else {
            // Update operation
            await _expensesRepository.updateExpense(expense);
            await _localDataSource.markExpenseAsSynced(expenseId);
          }
          break;

        case 'delete':
          await _expensesRepository.deleteExpense(expenseId);
          break;
      }
    } catch (e) {
      if (e is NetworkError) {
        rethrow;
      }
      // Log other errors but continue processing
      debugPrint('Expense sync error: $e');
    }
  }

  /// Sync individual budget with proper null safety
  Future<void> _syncBudget(
      String monthId, String userId, String operation) async {
    try {
      if (operation == 'update') {
        final localBudget = await _localDataSource.getBudget(monthId, userId);
        if (localBudget != null) {
          // Get the current budget from Firebase to compare
          final firebaseBudget = await _budgetRepository.getBudget(monthId);

          // Only update if the budgets are different
          if (firebaseBudget == null || localBudget != firebaseBudget) {
            debugPrint(
                'Budget for month $monthId needs syncing - updating Firebase');
            await _budgetRepository.setBudget(monthId, localBudget);
            await _localDataSource.markBudgetAsSynced(monthId, userId);
            debugPrint('Budget for month $monthId synced to Firebase');
          } else {
            debugPrint(
                'Budget for month $monthId is already in sync - skipping update');
            // Still mark as synced since it's already up to date
            await _localDataSource.markBudgetAsSynced(monthId, userId);
          }
        } else {
          debugPrint('Budget for month $monthId not found for sync');
        }
      }
    } catch (e) {
      if (e is NetworkError) {
        rethrow;
      }
      debugPrint('Budget sync error: $e');
    }
  }

  /// Initialize local data when user logs in
  Future<void> initializeLocalDataOnLogin(String userId) async {
    try {
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        debugPrint('No connection available for data initialization');
        return; // Don't initialize when offline
      }

      debugPrint('Initializing local data for user: $userId');

      // Get remote expense data and store locally
      final expenses = await _expensesRepository.getExpenses();
      for (final expense in expenses) {
        await _localDataSource.saveExpense(expense);
        await _localDataSource.markExpenseAsSynced(expense.id);
      }
      debugPrint('Initialized ${expenses.length} expenses from Firebase');

      // Get current month budget
      final currentMonthId = _getCurrentMonthId();
      final budget = await _budgetRepository.getBudget(currentMonthId);
      if (budget != null) {
        await _localDataSource.saveBudget(currentMonthId, budget, userId,
            isSynced: true);
        await _localDataSource.markBudgetAsSynced(currentMonthId, userId);
        debugPrint('Initialized budget for current month: $currentMonthId');
      }

      debugPrint('Local data initialization completed');
    } catch (e) {
      debugPrint('Local data initialization error: $e');
    }
  }

  /// Helper method: Get current month ID (format: YYYY-MM)
  String _getCurrentMonthId() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Dispose resources
  void dispose() {
    if (_syncTimer != null) {
      _syncTimer!.cancel();
      _syncTimer = null;
      debugPrint('Sync timer cancelled');
    }
    _syncStatusController.close();
  }

  /// Clear pending budget sync operations for a specific user
  Future<void> clearPendingBudgetSyncs(String userId) async {
    try {
      debugPrint('Clearing pending budget sync operations for user: $userId');

      // Use the direct method in LocalDataSource
      await _localDataSource.clearAllBudgetSyncOperations(userId);

      debugPrint('Finished clearing pending budget sync operations');
    } catch (e) {
      debugPrint('Error clearing pending budget syncs: $e');
    }
  }

  /// Clear sync operations for a specific month's budget
  Future<void> clearBudgetSyncForMonth(String monthId, String userId) async {
    try {
      debugPrint('Clearing sync operations for budget month: $monthId');

      // Get all pending operations from queue
      final pendingOperations =
          await _localDataSource.getPendingSyncOperations();

      // Find and clear budget operations for this specific month
      for (final operation in pendingOperations) {
        final entityType = operation['entityType'] as String;
        final entityId = operation['entityId'] as String;
        final opUserId = operation['userId'] as String;
        final syncId = operation['id'] as int;

        // Only clear budget operations for this month and user
        if (entityType == 'budget' &&
            entityId == monthId &&
            opUserId == userId) {
          await _localDataSource.clearSyncOperation(syncId);
          debugPrint(
              'Cleared budget sync operation for month $monthId: $syncId');
        }
      }

      // Also mark the budget as synced in the database
      await _localDataSource.markBudgetAsSynced(monthId, userId);

      debugPrint(
          'Finished clearing sync operations for budget month: $monthId');
    } catch (e) {
      debugPrint('Error clearing budget sync for month: $e');
    }
  }

  /// Manually clear budget sync operations for a specific month
  Future<void> manualClearBudgetSyncForMonth(String monthId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final userId = currentUser.uid;
    debugPrint('Manually clearing budget sync for month: $monthId');

    try {
      // Get pending operations
      final operations = await _localDataSource.getPendingSyncOperations();

      // Find and clear budget operations for this month
      for (final operation in operations) {
        if (operation['entityType'] == 'budget' &&
            operation['entityId'] == monthId &&
            operation['userId'] == userId) {
          final syncId = operation['id'] as int;
          await _localDataSource.clearSyncOperation(syncId);
          debugPrint(
              'Cleared budget sync operation for month $monthId: $syncId');
        }
      }

      // Mark budget as synced in database
      await _localDataSource.markBudgetAsSynced(monthId, userId);
      debugPrint('Marked budget for month $monthId as synced');
    } catch (e) {
      debugPrint('Error clearing budget sync for month $monthId: $e');
    }
  }

  /// Force a full sync of all data
  Future<void> forceFullSync() async {
    debugPrint('Force full sync requested');
    await syncData(fullSync: true, skipBudgets: false);
  }

  /// Get a user from the local database
  Future<domain.User?> getLocalUser(String userId) async {
    try {
      debugPrint('Getting user from local database: $userId');
      return await _localDataSource.getUser(userId);
    } catch (e) {
      debugPrint('Error getting user from local database: $e');
      return null;
    }
  }
}
