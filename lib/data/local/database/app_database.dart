import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show debugPrint;

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
  TextColumn get incomeStability => text()();
  TextColumn get spendingMentality => text()();
  TextColumn get riskAppetite => text()();
  TextColumn get financialLiteracy => text()();
  TextColumn get financialPriority => text()();
  TextColumn get savingHabit => text()();
  TextColumn get financialStressLevel => text()();
  TextColumn get occupation => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get dataConsentAcceptedAt => dateTime().nullable()();
  BoolColumn get isComplete => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table to store spending behavior analysis results.
///
/// This table holds the serialized JSON response from the comprehensive
/// analysis endpoint. Storing the full response allows for historical review
/// and reprocessing without needing to call the API again.
@DataClassName('AnalysisResult')
class AnalysisResults extends Table {
  /// A unique identifier for each analysis record.
  TextColumn get id => text()();

  /// The ID of the user this analysis belongs to.
  TextColumn get userId => text()();

  /// The full analysis response, stored as a serialized JSON string.
  TextColumn get analysisData => text()();

  /// The timestamp when the analysis was performed and stored.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [AnalysisResults])
class AnalysisResultDao extends DatabaseAccessor<AppDatabase>
    with _$AnalysisResultDaoMixin {
  AnalysisResultDao(super.db);

  /// Saves a new analysis result to the database.
  Future<void> saveAnalysisResult(AnalysisResult result) =>
      into(analysisResults).insert(result);

  /// Retrieves the most recent analysis result for a given user.
  Future<AnalysisResult?> getLatestAnalysisResult(String userId) {
    return (select(analysisResults)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }
}

@DriftAccessor(tables: [ExchangeRates])
class ExchangeRatesDao extends DatabaseAccessor<AppDatabase>
    with _$ExchangeRatesDaoMixin {
  ExchangeRatesDao(super.db);
}

@DriftAccessor(tables: [UserProfiles])
class UserProfilesDao extends DatabaseAccessor<AppDatabase>
    with _$UserProfilesDaoMixin {
  UserProfilesDao(super.db);
}

@DriftAccessor(tables: [Budgets])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.db);
}

@DriftAccessor(tables: [Expenses])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {
  ExpensesDao(super.db);
}

@DriftAccessor(tables: [FinancialGoals])
class FinancialGoalsDao extends DatabaseAccessor<AppDatabase>
    with _$FinancialGoalsDaoMixin {
  FinancialGoalsDao(super.db);
}

@DriftAccessor(tables: [GoalHistory])
class GoalHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$GoalHistoryDaoMixin {
  GoalHistoryDao(super.db);
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
    ExchangeRates,
    FinancialGoals,
    GoalHistory,
    UserProfiles,
    AnalysisResults,
  ],
  daos: [
    AnalysisResultDao,
    ExchangeRatesDao,
    UserProfilesDao,
    BudgetsDao,
    ExpensesDao,
    FinancialGoalsDao,
    GoalHistoryDao
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Add getters for all DAOs
  @override
  AnalysisResultDao get analysisResultDao => AnalysisResultDao(this);
  @override
  ExchangeRatesDao get exchangeRatesDao => ExchangeRatesDao(this);
  @override
  UserProfilesDao get userProfilesDao => UserProfilesDao(this);
  @override
  BudgetsDao get budgetsDao => BudgetsDao(this);
  @override
  ExpensesDao get expensesDao => ExpensesDao(this);
  @override
  FinancialGoalsDao get financialGoalsDao => FinancialGoalsDao(this);
  @override
  GoalHistoryDao get goalHistoryDao => GoalHistoryDao(this);

  @override
  int get schemaVersion => 18;

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
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 14) {
          await m.createTable(analysisResults);
        }
        if (from < 15) {
          // Migrate user profiles from AI preferences to financial literacy
          await customStatement('''
            ALTER TABLE user_profiles 
            ADD COLUMN financial_literacy TEXT DEFAULT 'intermediate'
          ''');

          await customStatement('''
            ALTER TABLE user_profiles 
            ADD COLUMN data_consent_accepted_at INTEGER
          ''');

          // Remove old AI preferences column if it exists
          try {
            await customStatement('''
              CREATE TABLE user_profiles_new (
                id TEXT PRIMARY KEY NOT NULL,
                user_id TEXT NOT NULL,
                primary_financial_goal TEXT NOT NULL,
                income_stability TEXT NOT NULL,
                spending_mentality TEXT NOT NULL,
                risk_appetite TEXT NOT NULL,
                monthly_income REAL NOT NULL,
                emergency_fund_target REAL NOT NULL,
                financial_literacy TEXT NOT NULL DEFAULT 'intermediate',
                category_preferences TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                data_consent_accepted_at INTEGER,
                is_complete INTEGER NOT NULL
              )
            ''');

            // Copy data from old table to new table, mapping AI preferences to default literacy
            await customStatement('''
              INSERT INTO user_profiles_new (
                id, user_id, primary_financial_goal, income_stability,
                spending_mentality, risk_appetite, monthly_income,
                emergency_fund_target, financial_literacy, category_preferences,
                created_at, updated_at, data_consent_accepted_at, is_complete
              )
              SELECT 
                id, user_id, primary_financial_goal, income_stability,
                spending_mentality, risk_appetite, monthly_income,
                emergency_fund_target, 'intermediate', category_preferences,
                created_at, updated_at, NULL, is_complete
              FROM user_profiles
            ''');

            // Drop old table and rename new table
            await customStatement('DROP TABLE user_profiles');
            await customStatement(
                'ALTER TABLE user_profiles_new RENAME TO user_profiles');
          } catch (e) {
            debugPrint('Error migrating user profiles schema: $e');
          }
        }
        if (from < 16) {
          // Remove unnecessary columns: primary_financial_goal and category_preferences
          try {
            await customStatement('''
              CREATE TABLE user_profiles_new (
                id TEXT PRIMARY KEY NOT NULL,
                user_id TEXT NOT NULL,
                income_stability TEXT NOT NULL,
                spending_mentality TEXT NOT NULL,
                risk_appetite TEXT NOT NULL,
                monthly_income REAL NOT NULL,
                emergency_fund_target REAL NOT NULL,
                financial_literacy TEXT NOT NULL DEFAULT 'intermediate',
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                data_consent_accepted_at INTEGER,
                is_complete INTEGER NOT NULL
              )
            ''');

            // Copy data from old table to new table, excluding removed columns
            await customStatement('''
              INSERT INTO user_profiles_new (
                id, user_id, income_stability, spending_mentality, 
                risk_appetite, monthly_income, emergency_fund_target, 
                financial_literacy, created_at, updated_at, 
                data_consent_accepted_at, is_complete
              )
              SELECT 
                id, user_id, income_stability, spending_mentality,
                risk_appetite, monthly_income, emergency_fund_target,
                financial_literacy, created_at, updated_at,
                data_consent_accepted_at, is_complete
              FROM user_profiles
            ''');

            // Drop old table and rename new table
            await customStatement('DROP TABLE user_profiles');
            await customStatement(
                'ALTER TABLE user_profiles_new RENAME TO user_profiles');
          } catch (e) {
            debugPrint(
                'Error removing unnecessary columns from user profiles: $e');
          }
        }
        if (from < 17) {
          // Migrate user_profiles to new schema (remove old fields, add new ones)
          try {
            await customStatement('''
              CREATE TABLE user_profiles_new (
                id TEXT PRIMARY KEY NOT NULL,
                user_id TEXT NOT NULL,
                income_stability TEXT NOT NULL,
                spending_mentality TEXT NOT NULL,
                risk_appetite TEXT NOT NULL,
                financial_literacy TEXT NOT NULL DEFAULT 'intermediate',
                financial_priority TEXT NOT NULL DEFAULT 'saving',
                saving_habit TEXT NOT NULL DEFAULT 'regular',
                financial_stress_level TEXT NOT NULL DEFAULT 'moderate',
                technology_adoption TEXT NOT NULL DEFAULT 'average',
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                data_consent_accepted_at INTEGER,
                is_complete INTEGER NOT NULL
              )
            ''');

            // Copy data from old table, set new fields to defaults
            await customStatement('''
              INSERT INTO user_profiles_new (
                id, user_id, income_stability, spending_mentality, risk_appetite,
                financial_literacy, financial_priority, saving_habit, financial_stress_level, technology_adoption,
                created_at, updated_at, data_consent_accepted_at, is_complete
              )
              SELECT
                id, user_id, income_stability, spending_mentality, risk_appetite,
                financial_literacy, 'saving', 'regular', 'moderate', 'average',
                created_at, updated_at, data_consent_accepted_at, is_complete
              FROM user_profiles
            ''');

            await customStatement('DROP TABLE user_profiles');
            await customStatement(
                'ALTER TABLE user_profiles_new RENAME TO user_profiles');
          } catch (e) {
            debugPrint(
                'Error migrating user profiles schema to v17: $e');
          }
        }
        if (from < 18) {
          // Migrate user_profiles to replace technologyAdoption with occupation
          try {
            await customStatement('''
              CREATE TABLE user_profiles_new (
                id TEXT PRIMARY KEY NOT NULL,
                user_id TEXT NOT NULL,
                income_stability TEXT NOT NULL,
                spending_mentality TEXT NOT NULL,
                risk_appetite TEXT NOT NULL,
                financial_literacy TEXT NOT NULL DEFAULT 'intermediate',
                financial_priority TEXT NOT NULL DEFAULT 'saving',
                saving_habit TEXT NOT NULL DEFAULT 'regular',
                financial_stress_level TEXT NOT NULL DEFAULT 'moderate',
                occupation TEXT NOT NULL DEFAULT 'employed',
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                data_consent_accepted_at INTEGER,
                is_complete INTEGER NOT NULL
              )
            ''');

            // Copy data from old table, mapping technology_adoption to occupation
            await customStatement('''
              INSERT INTO user_profiles_new (
                id, user_id, income_stability, spending_mentality, risk_appetite,
                financial_literacy, financial_priority, saving_habit, financial_stress_level, occupation,
                created_at, updated_at, data_consent_accepted_at, is_complete
              )
              SELECT
                id, user_id, income_stability, spending_mentality, risk_appetite,
                financial_literacy, financial_priority, saving_habit, financial_stress_level, 
                CASE 
                  WHEN technology_adoption = 'earlyAdopter' THEN 'employed'
                  WHEN technology_adoption = 'average' THEN 'employed'
                  WHEN technology_adoption = 'reluctant' THEN 'employed'
                  ELSE 'employed'
                END,
                created_at, updated_at, data_consent_accepted_at, is_complete
              FROM user_profiles
            ''');

            await customStatement('DROP TABLE user_profiles');
            await customStatement(
                'ALTER TABLE user_profiles_new RENAME TO user_profiles');
          } catch (e) {
            debugPrint(
                'Error migrating user profiles schema to v18: $e');
          }
        }
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
