import 'dart:io';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Import database tables
part 'app_database.g.dart';

/// Expenses table definition
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get remark => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get category => text()();
  TextColumn get method => text()();
  TextColumn get description => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('MYR'))();
  TextColumn get recurringDetailsJson =>
      text().nullable()(); // JSON field for embedded recurring details
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  // Add indexes for performance optimization
  @override
  List<Set<Column>> get uniqueKeys => [];

  // Custom indexes for frequently queried columns
  static const String indexUserId =
      'CREATE INDEX IF NOT EXISTS expenses_user_id_idx ON expenses (user_id)';
  static const String indexDate =
      'CREATE INDEX IF NOT EXISTS expenses_date_idx ON expenses (date)';
  static const String indexUserDate =
      'CREATE INDEX IF NOT EXISTS expenses_user_date_idx ON expenses (user_id, date)';
  static const String indexSyncStatus =
      'CREATE INDEX IF NOT EXISTS expenses_sync_idx ON expenses (is_synced)';
}

/// Budgets table definition
class Budgets extends Table {
  TextColumn get monthId => text()();
  TextColumn get userId => text()();
  RealColumn get total => real()();
  RealColumn get left => real()();
  TextColumn get categoriesJson => text()();
  RealColumn get saving => real().withDefault(const Constant(0.0))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();

  @override
  Set<Column> get primaryKey => {monthId, userId};

  // Custom indexes for performance optimization
  static const String indexUserId =
      'CREATE INDEX IF NOT EXISTS budgets_user_id_idx ON budgets (user_id)';
  static const String indexSyncStatus =
      'CREATE INDEX IF NOT EXISTS budgets_sync_idx ON budgets (is_synced)';
}

/// Sync queue table for tracking operations that need to be synchronized
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType =>
      text()(); // 'expense', 'budget', or 'user_settings'
  TextColumn get entityId => text()();
  TextColumn get userId => text()();
  TextColumn get operation => text()(); // 'add', 'update', 'delete'
  DateTimeColumn get timestamp => dateTime()();
}

/// Exchange rates table for storing currency conversion rates
class ExchangeRates extends Table {
  TextColumn get baseCurrency => text()();
  TextColumn get userId => text()();
  TextColumn get ratesJson => text()();
  DateTimeColumn get timestamp => dateTime()();
  DateTimeColumn get lastModified => dateTime()();

  @override
  Set<Column> get primaryKey => {baseCurrency, userId};
}

/// Users table for storing user information and settings
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().nullable()();
  TextColumn get displayName => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('MYR'))();
  TextColumn get theme => text().withDefault(const Constant('light'))();
  BoolColumn get allowNotification =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get autoBudget => boolean().withDefault(const Constant(false))();
  BoolColumn get improveAccuracy =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get automaticRebalanceSuggestions =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Budget suggestions table for storing AI-generated recommendations
class BudgetSuggestions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get monthId => text()();
  TextColumn get userId => text()();
  TextColumn get suggestions => text()(); // Stores the raw text from the AI
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
}

/// Create database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'budgie.sqlite'));
    return NativeDatabase(file);
  });
}

/// Main application database
@DriftDatabase(tables: [
  Expenses,
  Budgets,
  SyncQueue,
  Users,
  ExchangeRates,
  BudgetSuggestions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 9;

  /// Create performance indexes for better query performance
  Future<void> _createPerformanceIndexes() async {
    await customStatement(Expenses.indexUserId);
    await customStatement(Expenses.indexDate);
    await customStatement(Expenses.indexUserDate);
    await customStatement(Expenses.indexSyncStatus);
    await customStatement(Budgets.indexUserId);
    await customStatement(Budgets.indexSyncStatus);
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Create performance indexes
        await _createPerformanceIndexes();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1 && to >= 2) {
          // Add new settings columns to Users table
          await m.addColumn(
              users, users.allowNotification as GeneratedColumn<Object>);
          await m.addColumn(users, users.autoBudget as GeneratedColumn<Object>);
          await m.addColumn(
              users, users.improveAccuracy as GeneratedColumn<Object>);
        }
        if (from <= 2 && to >= 3) {
          // Skip old recurring expense structure - no longer used
          // This migration step is kept for compatibility but does nothing
        }
        if (from <= 3 && to >= 4) {
          // Add exchange rates table for currency conversion
          await m.createTable(exchangeRates);
        }
        if (from <= 4 && to >= 5) {
          // Add saving field to budgets table with a safe default
          final tableInfo =
              await m.database.customSelect('PRAGMA table_info(budgets)').get();
          final hasSavingColumn =
              tableInfo.any((row) => row.data['name'] == 'saving');

          if (!hasSavingColumn) {
            await m.addColumn(
                budgets, budgets.saving as GeneratedColumn<Object>);
          }
        }
        if (from <= 5 && to >= 6) {
          // Add table for budget suggestions and new user setting
          await m.createTable(budgetSuggestions);
          final tableInfo =
              await m.database.customSelect('PRAGMA table_info(users)').get();
          final hasColumn = tableInfo.any(
              (row) => row.data['name'] == 'automatic_rebalance_suggestions');
          if (!hasColumn) {
            await m.addColumn(users,
                users.automaticRebalanceSuggestions as GeneratedColumn<Object>);
          }
        }
        if (from <= 6 && to >= 7) {
          // Legacy migration - add isRecurring column (will be removed in v9)
          await m.addColumn(expenses,
              expenses.recurringDetailsJson as GeneratedColumn<Object>);
        }
        if (from <= 7 && to >= 8) {
          // Legacy migration for endDate - no longer needed
        }
        if (from <= 8 && to >= 9) {
          // Migrate from subcollection structure to embedded recurring details
          try {
            // Add recurringDetailsJson column if not exists
            final tableInfo = await m.database
                .customSelect('PRAGMA table_info(expenses)')
                .get();
            final hasRecurringDetailsJson = tableInfo
                .any((row) => row.data['name'] == 'recurring_details_json');

            if (!hasRecurringDetailsJson) {
              await m.addColumn(expenses,
                  expenses.recurringDetailsJson as GeneratedColumn<Object>);
            }

            // Migrate data from recurring_details table to embedded JSON field
            final recurringDetailsData = await m.database
                .customSelect('SELECT * FROM recurring_details')
                .get();

            for (final recurringDetail in recurringDetailsData) {
              final expenseId = recurringDetail.data['expense_id'] as String;
              final recurringDetailsJson = {
                'frequency': recurringDetail.data['frequency'],
                'dayOfMonth': recurringDetail.data['day_of_month'],
                'dayOfWeek': recurringDetail.data['day_of_week'],
                'endDate': recurringDetail.data['end_date']?.toString(),
              };

              await m.database.customUpdate(
                'UPDATE expenses SET recurring_details_json = ? WHERE id = ?',
                variables: [
                  Variable.withString(jsonEncode(recurringDetailsJson)),
                  Variable.withString(expenseId),
                ],
              );
            }

            // Drop the old recurring_details table
            await m.database
                .customStatement('DROP TABLE IF EXISTS recurring_details');

            // Remove isRecurring column as it's now computed from recurringDetails
            // Note: SQLite doesn't support dropping columns directly, so we leave it for backward compatibility
          } catch (e) {
            // If migration fails, continue - this is not critical
            print('Recurring details migration warning: $e');
          }
        }
      },
    );
  }
}
