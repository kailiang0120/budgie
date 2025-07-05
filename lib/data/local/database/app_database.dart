import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

// Import database tables
part 'app_database.g.dart';

/// Expenses table definition
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get remark => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get category => text()();
  TextColumn get method => text()();
  TextColumn get description => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('MYR'))();
  TextColumn get recurringDetailsJson =>
      text().nullable()(); // JSON field for embedded recurring details
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  // Custom indexes for frequently queried columns
  static const String indexDate =
      'CREATE INDEX IF NOT EXISTS expenses_date_idx ON expenses (date)';
}

/// Budgets table definition
class Budgets extends Table {
  TextColumn get monthId => text()();
  RealColumn get total => real()();
  RealColumn get left => real()();
  TextColumn get categoriesJson => text()();
  RealColumn get saving => real().withDefault(const Constant(0.0))();
  TextColumn get currency => text().withDefault(const Constant('MYR'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {monthId};
}

/// Financial goals table definition
class FinancialGoals extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount => real()();
  DateTimeColumn get deadline => dateTime()();
  TextColumn get iconName => text()();
  TextColumn get colorValue => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Goal history table definition
class GoalHistory extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text()();
  TextColumn get title => text()();
  RealColumn get targetAmount => real()();
  RealColumn get finalAmount => real()();
  DateTimeColumn get createdDate => dateTime()();
  DateTimeColumn get completedDate => dateTime()();
  TextColumn get iconName => text()();
  TextColumn get colorValue => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Settings table for app-wide settings
class AppSettings extends Table {
  // Use a single row for app settings with id=1
  IntColumn get id => integer().autoIncrement()();
  TextColumn get theme => text().withDefault(const Constant('light'))();
  TextColumn get currency => text().withDefault(const Constant('MYR'))();
  BoolColumn get allowNotification =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get autoBudget => boolean().withDefault(const Constant(false))();
  BoolColumn get improveAccuracy =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get syncEnabled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Exchange rates table for storing currency conversion rates
class ExchangeRates extends Table {
  TextColumn get baseCurrency => text()();
  TextColumn get ratesJson => text()();
  DateTimeColumn get timestamp => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {baseCurrency};
}

/// User profiles table for storing financial behavior profiles
class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get primaryFinancialGoal => text()();
  TextColumn get incomeStability => text()();
  TextColumn get spendingMentality => text()();
  TextColumn get riskAppetite => text()();
  RealColumn get monthlyIncome => real()();
  RealColumn get emergencyFundTarget => real()();
  TextColumn get aiPreferencesJson => text().named('ai_preferences')();
  TextColumn get categoryPreferencesJson =>
      text().named('category_preferences')();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isComplete => boolean()();

  @override
  Set<Column> get primaryKey => {id};
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
@DriftDatabase(
  tables: [
    Expenses,
    Budgets,
    AppSettings,
    ExchangeRates,
    FinancialGoals,
    GoalHistory,
    UserProfiles,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 13;

  /// Create performance indexes for better query performance
  Future<void> _createPerformanceIndexes() async {
    await customStatement(Expenses.indexDate);
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Create performance indexes
        await _createPerformanceIndexes();

        // Create default settings directly with SQL
        await customStatement('''
          INSERT INTO app_settings (
            theme,
            currency, 
            allow_notification, 
            auto_budget, 
            improve_accuracy, 
            sync_enabled,
            updated_at
          ) VALUES (
            'light',
            'MYR', 
            0, 
            0, 
            0, 
            0,
            ${DateTime.now().millisecondsSinceEpoch}
          )
        ''');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 12) {
          // Handle migration from previous versions

          // Add currency column to app_settings if it doesn't exist
          try {
            await customStatement(
                'ALTER TABLE app_settings ADD COLUMN currency TEXT NOT NULL DEFAULT \'MYR\'');
          } catch (e) {
            debugPrint('Error adding currency column to app_settings: $e');
          }

          // Create new tables without user ID if needed
          try {
            // Create new expenses table without user ID
            await customStatement('''
              CREATE TABLE IF NOT EXISTS expenses_new (
                id TEXT PRIMARY KEY NOT NULL,
                remark TEXT NOT NULL,
                amount REAL NOT NULL,
                date INTEGER NOT NULL,
                category TEXT NOT NULL,
                method TEXT NOT NULL,
                description TEXT,
                currency TEXT NOT NULL DEFAULT 'MYR',
                recurring_details_json TEXT,
                updated_at INTEGER NOT NULL
              )
            ''');

            // Copy data from old table to new table
            await customStatement('''
              INSERT INTO expenses_new 
              SELECT id, remark, amount, date, category, method, description, 
                     currency, recurring_details_json, last_modified
              FROM expenses
            ''');

            // Drop old table and rename new table
            await customStatement('DROP TABLE expenses');
            await customStatement(
                'ALTER TABLE expenses_new RENAME TO expenses');

            // Create index on date
            await customStatement(Expenses.indexDate);

            // Create new budgets table without user ID
            await customStatement('''
              CREATE TABLE IF NOT EXISTS budgets_new (
                month_id TEXT PRIMARY KEY NOT NULL,
                total REAL NOT NULL,
                left REAL NOT NULL,
                categories_json TEXT NOT NULL,
                saving REAL NOT NULL DEFAULT 0.0,
                currency TEXT NOT NULL DEFAULT 'MYR',
                updated_at INTEGER NOT NULL
              )
            ''');

            // Copy data from old table to new table, taking the first entry for each month_id
            await customStatement('''
              INSERT INTO budgets_new 
              SELECT month_id, total, left, categories_json, saving, currency, last_modified
              FROM budgets
              GROUP BY month_id
            ''');

            // Drop old table and rename new table
            await customStatement('DROP TABLE budgets');
            await customStatement('ALTER TABLE budgets_new RENAME TO budgets');

            // Create new exchange_rates table without user ID
            await customStatement('''
              CREATE TABLE IF NOT EXISTS exchange_rates_new (
                base_currency TEXT PRIMARY KEY NOT NULL,
                rates_json TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
              )
            ''');

            // Copy data from old table to new table
            await customStatement('''
              INSERT INTO exchange_rates_new 
              SELECT base_currency, rates_json, timestamp, last_modified
              FROM exchange_rates
              GROUP BY base_currency
            ''');

            // Drop old table and rename new table
            await customStatement('DROP TABLE exchange_rates');
            await customStatement(
                'ALTER TABLE exchange_rates_new RENAME TO exchange_rates');

            // Drop unused tables
            await customStatement('DROP TABLE IF EXISTS users');
            await customStatement('DROP TABLE IF EXISTS sync_queue');
          } catch (e) {
            debugPrint('Error during migration: $e');
          }
        }

        if (from < 13) {
          // Create financial goals tables
          try {
            await m.createTable(financialGoals);
            await m.createTable(goalHistory);
          } catch (e) {
            debugPrint('Error creating financial goals tables: $e');
          }
        }
      },
    );
  }

  // Get app settings
  Future<Map<String, dynamic>> getAppSettings() async {
    final result = await customSelect(
      'SELECT * FROM app_settings LIMIT 1',
    ).getSingleOrNull();

    if (result != null) {
      return result.data;
    }

    // Create default settings if none exist
    await customStatement('''
      INSERT INTO app_settings (
        theme,
        currency, 
        allow_notification, 
        auto_budget, 
        improve_accuracy, 
        sync_enabled,
        updated_at
      ) VALUES (
        'light',
        'MYR',
        0,
        0,
        0,
        0,
        ${DateTime.now().millisecondsSinceEpoch}
      )
    ''');

    final newResult = await customSelect(
      'SELECT * FROM app_settings LIMIT 1',
    ).getSingle();

    return newResult.data;
  }

  // Update app settings
  Future<void> updateAppSettings(Map<String, dynamic> settings) async {
    final settingsData = await getAppSettings();
    final id = settingsData['id'] as int;

    final updates = <String>[];
    final values = <String>[];

    settings.forEach((key, value) {
      updates.add('$key = ?');

      if (value is bool) {
        values.add(value ? '1' : '0');
      } else if (value is String) {
        values.add("'$value'");
      } else if (value is DateTime) {
        values.add('${value.millisecondsSinceEpoch}');
      } else if (value is int || value is double) {
        values.add('$value');
      }
    });

    // Add updated_at to the update
    updates.add('updated_at = ${DateTime.now().millisecondsSinceEpoch}');

    await customStatement(
        'UPDATE app_settings SET ${updates.join(', ')} WHERE id = $id');
  }

  /// Delete and recreate the budgets table
  Future<void> resetBudgetsTable() async {
    try {
      debugPrint('🗑️ AppDatabase: Deleting budgets table...');
      await customStatement('DROP TABLE IF EXISTS budgets');
      debugPrint('✅ AppDatabase: Budgets table deleted successfully');

      debugPrint('🔄 AppDatabase: Recreating budgets table...');
      await customStatement('''
        CREATE TABLE budgets (
          month_id TEXT PRIMARY KEY NOT NULL,
          total REAL NOT NULL,
          left REAL NOT NULL,
          categories_json TEXT NOT NULL,
          saving REAL NOT NULL DEFAULT 0.0,
          currency TEXT NOT NULL DEFAULT 'MYR',
          updated_at INTEGER NOT NULL
        )
      ''');
      debugPrint('✅ AppDatabase: Budgets table recreated successfully');
    } catch (e) {
      debugPrint('❌ AppDatabase: Error resetting budgets table: $e');
      rethrow;
    }
  }

  /// Financial goals methods
  Future<List<FinancialGoal>> getActiveGoals() {
    return (select(financialGoals)
          ..where((tbl) => tbl.isCompleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.deadline)]))
        .get();
  }

  Future<FinancialGoal?> getGoalById(String id) {
    return (select(financialGoals)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertGoal(FinancialGoalsCompanion goal) {
    return into(financialGoals).insert(goal);
  }

  Future<bool> updateGoal(FinancialGoalsCompanion goal) async {
    return update(financialGoals).replace(goal);
  }

  Future<int> deleteGoal(String id) {
    return (delete(financialGoals)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> countActiveGoals() async {
    final query = selectOnly(financialGoals)
      ..addColumns([financialGoals.id.count()])
      ..where(financialGoals.isCompleted.equals(false));

    final result = await query.getSingle();
    return result.read(financialGoals.id.count()) ?? 0;
  }

  Future<int> insertGoalHistory(GoalHistoryCompanion history) {
    return into(goalHistory).insert(history);
  }

  Future<List<GoalHistoryData>> getGoalHistory() {
    return (select(goalHistory)
          ..orderBy([(t) => OrderingTerm.desc(t.completedDate)]))
        .get();
  }
}
