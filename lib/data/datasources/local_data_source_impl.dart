import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../domain/entities/budget.dart' as domain;
import '../../domain/entities/expense.dart' as domain;
import '../../domain/entities/recurring_expense.dart' as domain;
import '../../domain/entities/user.dart' as domain;
import '../../domain/entities/category.dart';
import '../../domain/entities/budget_suggestion.dart' as domain;
import '../local/database/app_database.dart';
import 'local_data_source.dart';

/// Implementation of LocalDataSource using Drift database
class LocalDataSourceImpl implements LocalDataSource {
  final AppDatabase _database;
  final Uuid _uuid = const Uuid();
  final firebase_auth.FirebaseAuth _auth;

  LocalDataSourceImpl(this._database, {firebase_auth.FirebaseAuth? auth})
      : _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  // User operations
  @override
  Future<domain.User?> getUser(String userId) async {
    final userRow = await (_database.select(_database.users)
          ..where((tbl) => tbl.id.equals(userId)))
        .getSingleOrNull();

    if (userRow == null) {
      return null;
    }

    return domain.User(
      id: userRow.id,
      email: userRow.email,
      displayName: userRow.displayName,
      photoUrl: userRow.photoUrl,
      currency: userRow.currency,
      theme: userRow.theme,
    );
  }

  @override
  Future<void> saveUser(domain.User user) async {
    await _database.into(_database.users).insertOnConflictUpdate(
          UsersCompanion.insert(
            id: user.id,
            email: Value(user.email),
            displayName: Value(user.displayName),
            photoUrl: Value(user.photoUrl),
            currency: Value(user.currency),
            theme: Value(user.theme),
            lastModified: DateTime.now(),
            isSynced: const Value(false),
          ),
        );

    await addToSyncQueue('user', user.id, user.id, 'update');
  }

  // User Settings operations
  @override
  Future<Map<String, dynamic>?> getUserSettings(String userId) async {
    final userRow = await (_database.select(_database.users)
          ..where((tbl) => tbl.id.equals(userId)))
        .getSingleOrNull();

    if (userRow == null) {
      return null;
    }

    return {
      'currency': userRow.currency,
      'theme': userRow.theme,
      'settings': {
        'allowNotification': userRow.allowNotification,
        'autoBudget': userRow.autoBudget,
        'improveAccuracy': userRow.improveAccuracy,
      },
    };
  }

  @override
  Future<void> saveUserSettings(
      String userId, Map<String, dynamic> settings) async {
    try {
      debugPrint('💾 LocalDataSource: Saving user settings for user: $userId');
      debugPrint('💾 LocalDataSource: Settings data: $settings');

      final settingsMap = settings['settings'] as Map<String, dynamic>? ?? {};

      final companion = UsersCompanion(
        id: Value(userId),
        currency: Value(settings['currency'] as String? ?? 'MYR'),
        theme: Value(settings['theme'] as String? ?? 'light'),
        // Handle both nested and root-level format
        allowNotification: Value(settingsMap['allowNotification'] as bool? ??
            settings['allowNotification'] as bool? ??
            false),
        autoBudget: Value(settingsMap['autoBudget'] as bool? ??
            settings['autoBudget'] as bool? ??
            false),
        improveAccuracy: Value(settingsMap['improveAccuracy'] as bool? ??
            settings['improveAccuracy'] as bool? ??
            false),
        lastModified: Value(DateTime.now()),
        isSynced: const Value(false),
      );

      debugPrint('💾 LocalDataSource: Created companion object with values:');
      debugPrint('  - currency: ${companion.currency.value}');
      debugPrint('  - theme: ${companion.theme.value}');
      debugPrint('  - allowNotification: ${companion.allowNotification.value}');
      debugPrint('  - autoBudget: ${companion.autoBudget.value}');
      debugPrint('  - improveAccuracy: ${companion.improveAccuracy.value}');

      await _database.into(_database.users).insertOnConflictUpdate(companion);
      debugPrint('💾 LocalDataSource: User settings saved to database');

      await addToSyncQueue('user_settings', userId, userId, 'update');
      debugPrint('💾 LocalDataSource: Added to sync queue');
    } catch (e, stackTrace) {
      debugPrint('❌ LocalDataSource: Error saving user settings: $e');
      debugPrint('❌ LocalDataSource: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> markUserSettingsAsSynced(String userId) async {
    await (_database.update(_database.users)
          ..where((tbl) => tbl.id.equals(userId)))
        .write(const UsersCompanion(isSynced: Value(true)));
  }

  // Expenses operations
  @override
  Future<List<domain.Expense>> getExpenses() async {
    final expenses = await (_database.select(_database.expenses)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();

    return expenses.map((row) {
      final category =
          CategoryExtension.fromId(row.category) ?? Category.others;
      final methodString = row.method;
      final paymentMethod = domain.PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.$methodString',
        orElse: () => domain.PaymentMethod.cash,
      );

      // Parse embedded recurring details from JSON
      domain.RecurringDetails? recurringDetails;
      if (row.recurringDetailsJson != null &&
          row.recurringDetailsJson!.isNotEmpty) {
        try {
          final jsonData =
              jsonDecode(row.recurringDetailsJson!) as Map<String, dynamic>;
          recurringDetails = domain.RecurringDetails.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing recurring details JSON: $e');
        }
      }

      return domain.Expense(
        id: row.id,
        remark: row.remark,
        amount: row.amount,
        date: row.date,
        category: category,
        method: paymentMethod,
        description: row.description,
        currency: row.currency,
        recurringDetails: recurringDetails,
      );
    }).toList();
  }

  @override
  Future<void> saveExpense(domain.Expense expense) async {
    final newId = expense.id.isEmpty ? _uuid.v4() : expense.id;
    final userId = await _getCurrentUserId();

    // Check if this is an offline expense (needs syncing)
    final needsSync = expense.id.isEmpty || expense.id.startsWith('offline_');

    // Serialize recurring details to JSON
    String? recurringDetailsJson;
    if (expense.recurringDetails != null) {
      recurringDetailsJson = jsonEncode(expense.recurringDetails!.toJson());
    }

    await _database.into(_database.expenses).insertOnConflictUpdate(
          ExpensesCompanion.insert(
            id: newId,
            userId: userId,
            remark: expense.remark,
            amount: expense.amount,
            date: expense.date,
            category: expense.category.id,
            method: expense.method.toString().split('.').last,
            description: Value(expense.description),
            currency: Value(expense.currency),
            recurringDetailsJson: Value(recurringDetailsJson),
            isSynced: Value(
                !needsSync), // Mark as synced if it has a proper Firebase ID
            lastModified: DateTime.now(),
          ),
        );

    // Only add to sync queue if it needs syncing
    if (needsSync) {
      await addToSyncQueue('expense', newId, userId, 'add');
    }
  }

  /// Save expense that is already synced from Firebase
  @override
  Future<void> saveSyncedExpense(domain.Expense expense) async {
    final userId = await _getCurrentUserId();

    // Serialize recurring details to JSON
    String? recurringDetailsJson;
    if (expense.recurringDetails != null) {
      recurringDetailsJson = jsonEncode(expense.recurringDetails!.toJson());
    }

    await _database.into(_database.expenses).insertOnConflictUpdate(
          ExpensesCompanion.insert(
            id: expense.id,
            userId: userId,
            remark: expense.remark,
            amount: expense.amount,
            date: expense.date,
            category: expense.category.id,
            method: expense.method.toString().split('.').last,
            description: Value(expense.description),
            currency: Value(expense.currency),
            recurringDetailsJson: Value(recurringDetailsJson),
            isSynced: const Value(true), // Already synced from Firebase
            lastModified: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> updateExpense(domain.Expense expense) async {
    final userId = await _getCurrentUserId();

    // Serialize recurring details to JSON
    String? recurringDetailsJson;
    if (expense.recurringDetails != null) {
      recurringDetailsJson = jsonEncode(expense.recurringDetails!.toJson());
    }

    await _database.update(_database.expenses).replace(
          ExpensesCompanion(
            id: Value(expense.id),
            userId: Value(userId),
            remark: Value(expense.remark),
            amount: Value(expense.amount),
            date: Value(expense.date),
            category: Value(expense.category.id),
            method: Value(expense.method.toString().split('.').last),
            description: Value(expense.description),
            currency: Value(expense.currency),
            recurringDetailsJson: Value(recurringDetailsJson),
            isSynced: const Value(false),
            lastModified: Value(DateTime.now()),
          ),
        );

    await addToSyncQueue('expense', expense.id, userId, 'update');
  }

  @override
  Future<void> deleteExpense(String id) async {
    final userId = await _getCurrentUserId();

    await (_database.delete(_database.expenses)
          ..where((tbl) => tbl.id.equals(id)))
        .go();

    await addToSyncQueue('expense', id, userId, 'delete');
  }

  @override
  Future<List<domain.Expense>> getUnsyncedExpenses() async {
    final expenses = await (_database.select(_database.expenses)
          ..where((tbl) => tbl.isSynced.equals(false)))
        .get();

    return expenses.map((row) {
      final category =
          CategoryExtension.fromId(row.category) ?? Category.others;
      final methodString = row.method;
      final paymentMethod = domain.PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.$methodString',
        orElse: () => domain.PaymentMethod.cash,
      );

      // Parse embedded recurring details from JSON
      domain.RecurringDetails? recurringDetails;
      if (row.recurringDetailsJson != null &&
          row.recurringDetailsJson!.isNotEmpty) {
        try {
          final jsonData =
              jsonDecode(row.recurringDetailsJson!) as Map<String, dynamic>;
          recurringDetails = domain.RecurringDetails.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing recurring details JSON: $e');
        }
      }

      return domain.Expense(
        id: row.id,
        remark: row.remark,
        amount: row.amount,
        date: row.date,
        category: category,
        method: paymentMethod,
        description: row.description,
        currency: row.currency,
        recurringDetails: recurringDetails,
      );
    }).toList();
  }

  @override
  Future<void> markExpenseAsSynced(String id) async {
    await (_database.update(_database.expenses)
          ..where((tbl) => tbl.id.equals(id)))
        .write(const ExpensesCompanion(isSynced: Value(true)));
  }

  // Budget operations
  @override
  Future<domain.Budget?> getBudget(String monthId, String userId) async {
    final budgetRow = await (_database.select(_database.budgets)
          ..where(
              (tbl) => tbl.monthId.equals(monthId) & tbl.userId.equals(userId)))
        .getSingleOrNull();

    if (budgetRow == null) {
      return null;
    }

    final Map<String, dynamic> categoriesMap =
        jsonDecode(budgetRow.categoriesJson);
    final Map<String, domain.CategoryBudget> categories = {};

    categoriesMap.forEach((key, value) {
      categories[key] =
          domain.CategoryBudget.fromMap(Map<String, dynamic>.from(value));
    });

    // Calculate total allocated to categories
    final totalAllocated = categories.values
        .fold(0.0, (sum, categoryBudget) => sum + categoryBudget.budget);

    // Calculate expected saving
    final expectedSaving = budgetRow.total - totalAllocated;

    // Check if saving field needs to be updated (for backward compatibility)
    bool needsUpdate = false;
    double actualSaving = budgetRow.saving;

    // If saving is 0 but we expect it to be different, or if it doesn't match calculation
    if ((budgetRow.saving == 0.0 && expectedSaving != 0.0) ||
        (budgetRow.saving != expectedSaving && expectedSaving >= 0)) {
      actualSaving = expectedSaving;
      needsUpdate = true;
    }

    // If we need to update the saving field in the database
    if (needsUpdate) {
      try {
        await (_database.update(_database.budgets)
              ..where((tbl) =>
                  tbl.monthId.equals(monthId) & tbl.userId.equals(userId)))
            .write(BudgetsCompanion(saving: Value(actualSaving)));
        print('Updated saving field for budget $monthId: $actualSaving');
      } catch (e) {
        print('Error updating saving field: $e');
        // Continue with calculated value even if database update fails
      }
    }

    return domain.Budget(
      total: budgetRow.total,
      left: budgetRow.left,
      categories: categories,
      saving: actualSaving,
    );
  }

  @override
  Future<void> saveBudget(String monthId, domain.Budget budget, String userId,
      {bool isSynced = false}) async {
    final categoriesJson = jsonEncode(budget.toMap()['categories']);

    await _database.into(_database.budgets).insertOnConflictUpdate(
          BudgetsCompanion.insert(
            monthId: monthId,
            userId: userId,
            total: budget.total,
            left: budget.left,
            categoriesJson: categoriesJson,
            saving: Value(budget.saving),
            lastModified: DateTime.now(),
            isSynced: Value(isSynced),
          ),
        );

    // Only add to sync queue if not marked as synced
    if (!isSynced) {
      // Check if there's already a pending sync operation for this budget
      final operations = await (_database.select(_database.syncQueue)
            ..where((tbl) =>
                tbl.entityType.equals('budget') &
                tbl.entityId.equals(monthId) &
                tbl.userId.equals(userId)))
          .get();

      // Only add to queue if no pending operation exists
      if (operations.isEmpty) {
        await addToSyncQueue('budget', monthId, userId, 'update');
      }
    }
  }

  @override
  Future<List<String>> getUnsyncedBudgetIds(String userId) async {
    final budgets = await (_database.select(_database.budgets)
          ..where(
              (tbl) => tbl.userId.equals(userId) & tbl.isSynced.equals(false)))
        .get();

    return budgets.map((b) => b.monthId).toList();
  }

  @override
  Future<void> markBudgetAsSynced(String monthId, String userId) async {
    await (_database.update(_database.budgets)
          ..where(
              (tbl) => tbl.monthId.equals(monthId) & tbl.userId.equals(userId)))
        .write(const BudgetsCompanion(isSynced: Value(true)));
  }

  // Budget suggestions operations
  @override
  Future<void> saveBudgetSuggestion(domain.BudgetSuggestion suggestion) async {
    await _database.into(_database.budgetSuggestions).insert(
          BudgetSuggestionsCompanion.insert(
            monthId: suggestion.monthId,
            userId: suggestion.userId,
            suggestions: suggestion.suggestions,
            timestamp: suggestion.timestamp,
            isRead: Value(suggestion.isRead),
          ),
        );
  }

  Future<domain.BudgetSuggestion?> getLatestBudgetSuggestion(
      String monthId, String userId) async {
    final query = _database.select(_database.budgetSuggestions)
      ..where((tbl) => tbl.monthId.equals(monthId) & tbl.userId.equals(userId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)])
      ..limit(1);

    final suggestion = await query.getSingleOrNull();

    if (suggestion == null) {
      return null;
    }

    return domain.BudgetSuggestion(
      id: suggestion.id,
      monthId: suggestion.monthId,
      userId: suggestion.userId,
      suggestions: suggestion.suggestions,
      timestamp: suggestion.timestamp,
      isRead: suggestion.isRead,
    );
  }

  @override
  Future<void> markBudgetSuggestionAsRead(int id) async {
    await (_database.update(_database.budgetSuggestions)
          ..where((tbl) => tbl.id.equals(id)))
        .write(const BudgetSuggestionsCompanion(isRead: Value(true)));
  }

  // Sync operations
  @override
  Future<void> addToSyncQueue(String entityType, String entityId, String userId,
      String operation) async {
    await _database.into(_database.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            userId: userId,
            operation: operation,
            timestamp: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> removeSyncOperation(int id) async {
    await (_database.delete(_database.syncQueue)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  @override
  Future<void> clearAllSyncOperations() async {
    await _database.delete(_database.syncQueue).go();
  }

  /// Helper method to get current user ID
  Future<String> _getCurrentUserId() async {
    // First try to get user from local database
    final users = await _database.select(_database.users).get();
    if (users.isNotEmpty) {
      return users.first.id;
    }

    // If no user in local database, try Firebase
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      // Save Firebase user to local database
      final user = domain.User(
        id: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        // Use default values
        currency: 'MYR',
        theme: 'light',
      );

      // Save user to local database (don't wait for completion)
      saveUser(user);

      return firebaseUser.uid;
    }

    // If no user found in either location, throw exception
    throw Exception('No user found in local database or Firebase');
  }

  /// Clear all budget sync operations for a specific user
  @override
  Future<void> clearAllBudgetSyncOperations(String userId) async {
    try {
      // Get all sync operations
      final operations = await (_database.select(_database.syncQueue)).get();

      // Filter for budget operations for this user
      final budgetOps = operations
          .where((op) => op.entityType == 'budget' && op.userId == userId);

      // Delete each operation
      for (final op in budgetOps) {
        await (_database.delete(_database.syncQueue)
              ..where((tbl) => tbl.id.equals(op.id)))
            .go();
      }

      // Mark all budgets as synced
      await (_database.update(_database.budgets)
            ..where((tbl) => tbl.userId.equals(userId)))
          .write(const BudgetsCompanion(isSynced: Value(true)));

      debugPrint('Cleared all budget sync operations for user $userId');
    } catch (e) {
      debugPrint('Error clearing budget sync operations: $e');
    }
  }

  // Clean up resources
  void dispose() {
    // Close the database connection
    _database.close();
  }

  // Budget suggestions operations
  @override
  Future<List<domain.BudgetSuggestion>> getBudgetSuggestions(
      String monthId, String userId) async {
    final suggestions = await (_database.select(_database.budgetSuggestions)
          ..where(
              (tbl) => tbl.monthId.equals(monthId) & tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .get();

    return suggestions
        .map((s) => domain.BudgetSuggestion(
              id: s.id,
              monthId: s.monthId,
              userId: s.userId,
              suggestions: s.suggestions,
              timestamp: s.timestamp,
              isRead: s.isRead,
            ))
        .toList();
  }

  @override
  Future<void> deleteBudgetSuggestion(int id) async {
    await (_database.delete(_database.budgetSuggestions)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  // Exchange rates operations
  @override
  Future<Map<String, double>?> getExchangeRates(
      String baseCurrency, String userId) async {
    try {
      // Get the exchange rates from the database
      final query = _database.select(_database.exchangeRates)
        ..where((tbl) =>
            tbl.baseCurrency.equals(baseCurrency) & tbl.userId.equals(userId));

      final ratesRow = await query.getSingleOrNull();

      if (ratesRow == null) {
        return null;
      }

      // Parse rates JSON into a Map
      final ratesMap = jsonDecode(ratesRow.ratesJson) as Map<String, dynamic>;

      // Convert dynamic values to double
      final doubleRatesMap = <String, double>{};
      ratesMap.forEach((key, value) {
        doubleRatesMap[key] = (value as num).toDouble();
      });

      return doubleRatesMap;
    } catch (e) {
      debugPrint('Error getting exchange rates from local database: $e');
      return null;
    }
  }

  @override
  Future<void> saveExchangeRates(String baseCurrency, String userId,
      Map<String, double> rates, DateTime timestamp) async {
    try {
      // Convert rates map to JSON string
      final ratesJson = jsonEncode(rates);

      // Insert or update the exchange rates
      await _database.into(_database.exchangeRates).insertOnConflictUpdate(
            ExchangeRatesCompanion.insert(
              baseCurrency: baseCurrency,
              userId: userId,
              ratesJson: ratesJson,
              timestamp: timestamp,
              lastModified: DateTime.now(),
            ),
          );

      debugPrint('Exchange rates saved for $baseCurrency');
    } catch (e) {
      debugPrint('Error saving exchange rates to local database: $e');
    }
  }

  @override
  Future<DateTime?> getExchangeRatesTimestamp(
      String baseCurrency, String userId) async {
    final ratesRow = await (_database.select(_database.exchangeRates)
          ..where((tbl) =>
              tbl.baseCurrency.equals(baseCurrency) &
              tbl.userId.equals(userId)))
        .getSingleOrNull();

    return ratesRow?.timestamp;
  }

  // Sync queue operations
  @override
  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final operations = await (_database.select(_database.syncQueue)
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();

    return operations
        .map((op) => {
              'id': op.id,
              'entityType': op.entityType,
              'entityId': op.entityId,
              'userId': op.userId,
              'operation': op.operation,
              'timestamp': op.timestamp,
            })
        .toList();
  }

  @override
  Future<void> removeSyncQueueItem(int id) async {
    await (_database.delete(_database.syncQueue)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  @override
  Future<void> clearSyncQueue() async {
    await _database.delete(_database.syncQueue).go();
  }
}
