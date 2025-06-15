import 'dart:io';
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
  TextColumn get recurringExpenseId => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
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

/// Recurring expenses table definition
class RecurringExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get frequency => text()(); // 'oneTime', 'weekly', 'monthly'
  IntColumn get dayOfMonth => integer().nullable()(); // 1-31 for monthly
  TextColumn get dayOfWeek => text().nullable()(); // 'monday', 'tuesday', etc.
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastProcessedDate => dateTime().nullable()();
  TextColumn get expenseRemark => text()();
  RealColumn get expenseAmount => real()();
  TextColumn get expenseCategoryId => text()();
  TextColumn get expensePaymentMethod => text()();
  TextColumn get expenseCurrency => text().withDefault(const Constant('MYR'))();
  TextColumn get expenseDescription => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
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
  RecurringExpenses,
  Users,
  ExchangeRates,
  BudgetSuggestions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
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
          // Add recurring expense support
          await m.createTable(recurringExpenses);
          await m.addColumn(
              expenses, expenses.recurringExpenseId as GeneratedColumn<Object>);
        }
        if (from <= 3 && to >= 4) {
          // Add exchange rates table for currency conversion
          await m.createTable(exchangeRates);
        }
        if (from <= 4 && to >= 5) {
          // Add saving field to budgets table with a safe default
          // First, check if the column already exists
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
      },
    );
  }
}
