import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../domain/entities/budget.dart' as domain;
import '../../domain/entities/expense.dart' as domain;
import '../../domain/entities/recurring_expense.dart' as domain;
import '../../domain/entities/category.dart';

import '../local/database/app_database.dart';
import 'local_data_source.dart';

/// Implementation of LocalDataSource using Drift database
class LocalDataSourceImpl implements LocalDataSource {
  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  LocalDataSourceImpl(this._database);

  // App Settings operations
  @override
  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final settingsRow = await (_database.select(_database.appSettings)
            ..where((tbl) => tbl.id.equals(1)))
          .getSingleOrNull();

      if (settingsRow == null) {
        // Create default settings if none exist using raw SQL
        await _database.customStatement('''
          INSERT INTO app_settings (
            theme, 
            currency,
            allow_notification, 
            auto_budget, 
            improve_accuracy, 
            updated_at
          ) VALUES (
            'light',
            'MYR',
            0, 
            0, 
            0, 
            ${DateTime.now().millisecondsSinceEpoch}
          )
        ''');

        // Return default settings as map
        return {
          'theme': 'light',
          'currency': 'MYR',
          'allow_notification': false,
          'auto_budget': false,
          'improve_accuracy': false,
        };
      }

      // Convert row to map
      return {
        'id': settingsRow.id,
        'theme': settingsRow.theme,
        'currency': settingsRow.currency,
        'allow_notification': settingsRow.allowNotification,
        'auto_budget': settingsRow.autoBudget,
        'improve_accuracy': settingsRow.improveAccuracy,
        'updated_at': settingsRow.updatedAt.millisecondsSinceEpoch,
      };
    } catch (e) {
      debugPrint('Error getting app settings: $e');
      // Return default settings if any error occurs
      return {
        'theme': 'light',
        'currency': 'MYR',
        'allow_notification': false,
        'auto_budget': false,
        'improve_accuracy': false,
      };
    }
  }

  @override
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    final existingSettings = await (_database.select(_database.appSettings)
          ..where((tbl) => tbl.id.equals(1)))
        .getSingleOrNull();

    final companion = AppSettingsCompanion(
      id: Value(existingSettings?.id ?? 1),
      theme: Value(settings['theme'] as String? ?? 'light'),
      currency: Value(settings['currency'] as String? ?? 'MYR'),
      allowNotification:
          Value(settings['allow_notification'] as bool? ?? false),
      autoBudget: Value(settings['auto_budget'] as bool? ?? false),
      improveAccuracy: Value(settings['improve_accuracy'] as bool? ?? false),
      updatedAt: Value(DateTime.now()),
    );

    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(companion);
  }

  @override
  Future<String> getAppTheme() async {
    final settings = await getAppSettings();
    return settings['theme'] as String? ?? 'light';
  }

  @override
  Future<void> updateAppTheme(String theme) async {
    final settings = await getAppSettings();
    settings['theme'] = theme;
    await saveAppSettings(settings);
  }

  @override
  Future<String> getAppCurrency() async {
    final settings = await getAppSettings();
    return settings['currency'] as String? ?? 'MYR';
  }

  @override
  Future<void> updateAppCurrency(String currency) async {
    final settings = await getAppSettings();
    settings['currency'] = currency;
    await saveAppSettings(settings);
  }

  @override
  Future<bool> getNotificationsEnabled() async {
    final settings = await getAppSettings();
    return settings['allow_notification'] as bool? ?? false;
  }

  @override
  Future<void> updateNotificationsEnabled(bool enabled) async {
    final settings = await getAppSettings();
    settings['allow_notification'] = enabled;
    await saveAppSettings(settings);
  }

  @override
  Future<bool> getAutoBudgetEnabled() async {
    final settings = await getAppSettings();
    return settings['auto_budget'] as bool? ?? false;
  }

  @override
  Future<void> updateAutoBudgetEnabled(bool enabled) async {
    final settings = await getAppSettings();
    settings['auto_budget'] = enabled;
    await saveAppSettings(settings);
  }

  @override
  Future<bool> getImproveAccuracyEnabled() async {
    final settings = await getAppSettings();
    return settings['improve_accuracy'] as bool? ?? false;
  }

  @override
  Future<void> updateImproveAccuracyEnabled(bool enabled) async {
    final settings = await getAppSettings();
    settings['improve_accuracy'] = enabled;
    await saveAppSettings(settings);
  }

  @override
  Future<bool> getSyncEnabled() async {
    final settings = await getAppSettings();
    return settings['sync_enabled'] as bool? ?? false;
  }

  @override
  Future<void> updateSyncEnabled(bool enabled) async {
    final settings = await getAppSettings();
    settings['sync_enabled'] = enabled;
    await saveAppSettings(settings);
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
      if (row.recurringDetailsJson?.isNotEmpty ?? false) {
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

    // Serialize recurring details to JSON
    String? recurringDetailsJson;
    if (expense.recurringDetails != null) {
      recurringDetailsJson = jsonEncode(expense.recurringDetails!.toJson());
    }

    await _database.into(_database.expenses).insertOnConflictUpdate(
          ExpensesCompanion.insert(
            id: newId,
            remark: expense.remark,
            amount: expense.amount,
            date: expense.date,
            category: expense.category.id,
            method: expense.method.toString().split('.').last,
            description: Value(expense.description),
            currency: Value(expense.currency),
            recurringDetailsJson: Value(recurringDetailsJson),
            updatedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> updateExpense(domain.Expense expense) async {
    // Serialize recurring details to JSON
    String? recurringDetailsJson;
    if (expense.recurringDetails != null) {
      recurringDetailsJson = jsonEncode(expense.recurringDetails!.toJson());
    }

    await _database.update(_database.expenses).replace(
          ExpensesCompanion(
            id: Value(expense.id),
            remark: Value(expense.remark),
            amount: Value(expense.amount),
            date: Value(expense.date),
            category: Value(expense.category.id),
            method: Value(expense.method.toString().split('.').last),
            description: Value(expense.description),
            currency: Value(expense.currency),
            recurringDetailsJson: Value(recurringDetailsJson),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  @override
  Future<void> deleteExpense(String id) async {
    await (_database.delete(_database.expenses)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  // Budget operations
  @override
  Future<domain.Budget?> getBudget(String monthId) async {
    try {
      debugPrint('📊 LocalDataSource: Getting budget for month: $monthId');

      // Add null check for monthId
      if (monthId.isEmpty) {
        debugPrint('📊 LocalDataSource: Month ID is empty');
        return null;
      }

      final budgetRow = await (_database.select(_database.budgets)
            ..where((tbl) => tbl.monthId.equals(monthId)))
          .getSingleOrNull();

      if (budgetRow == null) {
        debugPrint('📊 LocalDataSource: No budget found for month: $monthId');
        return null;
      }

      // Add null check for categoriesJson
      final Map<String, dynamic> categoriesMap =
          budgetRow.categoriesJson.isNotEmpty
              ? jsonDecode(budgetRow.categoriesJson) as Map<String, dynamic>
              : {};

      final Map<String, domain.CategoryBudget> categories = {};

      categoriesMap.forEach((key, value) {
        if (value != null) {
          try {
            categories[key] =
                domain.CategoryBudget.fromMap(Map<String, dynamic>.from(value));
          } catch (e) {
            debugPrint('📊 LocalDataSource: Error parsing category budget: $e');
          }
        }
      });

      final budget = domain.Budget(
        total: budgetRow.total,
        left: budgetRow.left,
        categories: categories,
        saving: budgetRow.saving,
        currency: budgetRow.currency,
      );

      debugPrint(
          '📊 LocalDataSource: Budget found with total: ${budget.total}, left: ${budget.left}, currency: ${budget.currency}');
      return budget;
    } catch (e) {
      debugPrint('📊 LocalDataSource: Error getting budget: $e');
      return null;
    }
  }

  @override
  Future<void> saveBudget(String monthId, domain.Budget budget) async {
    try {
      debugPrint('📊 LocalDataSource: Saving budget for month: $monthId');
      debugPrint(
          '📊 LocalDataSource: Budget total: ${budget.total}, left: ${budget.left}, currency: ${budget.currency}');

      final categoriesJson = jsonEncode(budget.toMap()['categories']);

      await _database.into(_database.budgets).insertOnConflictUpdate(
            BudgetsCompanion.insert(
              monthId: monthId,
              total: budget.total,
              left: budget.left,
              categoriesJson: categoriesJson,
              saving: Value(budget.saving),
              currency: Value(budget.currency),
              updatedAt: DateTime.now(),
            ),
          );

      debugPrint('📊 LocalDataSource: Budget saved successfully');

      // Verify the save worked by reading it back
      final savedRow = await (_database.select(_database.budgets)
            ..where((tbl) => tbl.monthId.equals(monthId)))
          .getSingleOrNull();

      debugPrint(
          '📊 LocalDataSource: Verified budget row exists: ${savedRow != null}');
      if (savedRow != null) {
        debugPrint(
            '📊 LocalDataSource: Saved budget total: ${savedRow.total}, left: ${savedRow.left}, currency: ${savedRow.currency}');
      }
    } catch (e) {
      debugPrint('📊 LocalDataSource: Error saving budget: $e');
      throw Exception('Failed to save budget: $e');
    }
  }

  @override
  Future<void> deleteBudget(String monthId) async {
    try {
      debugPrint('📊 LocalDataSource: Deleting budget for month: $monthId');

      // Delete the budget from the database using a delete query
      await (_database.delete(_database.budgets)
            ..where((tbl) => tbl.monthId.equals(monthId)))
          .go();

      debugPrint('📊 LocalDataSource: Budget deleted successfully');
    } catch (e) {
      debugPrint('📊 LocalDataSource: Error deleting budget: $e');
      throw Exception('Failed to delete budget: $e');
    }
  }

  // Exchange rates operations
  @override
  Future<Map<String, double>?> getExchangeRates(String baseCurrency) async {
    try {
      // Get the exchange rates from the database
      final query = _database.select(_database.exchangeRates)
        ..where((tbl) => tbl.baseCurrency.equals(baseCurrency));

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
  Future<void> saveExchangeRates(String baseCurrency, Map<String, double> rates,
      DateTime timestamp) async {
    try {
      // Convert rates map to JSON string
      final ratesJson = jsonEncode(rates);

      // Insert or update the exchange rates
      await _database.into(_database.exchangeRates).insertOnConflictUpdate(
            ExchangeRatesCompanion.insert(
              baseCurrency: baseCurrency,
              ratesJson: ratesJson,
              timestamp: timestamp,
              updatedAt: DateTime.now(),
            ),
          );
    } catch (e) {
      debugPrint('Error saving exchange rates to local database: $e');
    }
  }

  @override
  Future<DateTime?> getExchangeRatesTimestamp(String baseCurrency) async {
    final ratesRow = await (_database.select(_database.exchangeRates)
          ..where((tbl) => tbl.baseCurrency.equals(baseCurrency)))
        .getSingleOrNull();

    return ratesRow?.timestamp;
  }
}
