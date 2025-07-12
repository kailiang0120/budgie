// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
mixin _$AnalysisResultDaoMixin on DatabaseAccessor<AppDatabase> {
  $AnalysisResultsTable get analysisResults => attachedDatabase.analysisResults;
}
mixin _$AppSettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AppSettingsTable get appSettings => attachedDatabase.appSettings;
}
mixin _$ExchangeRatesDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExchangeRatesTable get exchangeRates => attachedDatabase.exchangeRates;
}
mixin _$UserProfilesDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserProfilesTable get userProfiles => attachedDatabase.userProfiles;
}
mixin _$BudgetsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BudgetsTable get budgets => attachedDatabase.budgets;
}
mixin _$ExpensesDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExpensesTable get expenses => attachedDatabase.expenses;
}
mixin _$FinancialGoalsDaoMixin on DatabaseAccessor<AppDatabase> {
  $FinancialGoalsTable get financialGoals => attachedDatabase.financialGoals;
}
mixin _$GoalHistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $GoalHistoryTable get goalHistory => attachedDatabase.goalHistory;
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remarkMeta = const VerificationMeta('remark');
  @override
  late final GeneratedColumn<String> remark = GeneratedColumn<String>(
      'remark', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('MYR'));
  static const VerificationMeta _recurringDetailsJsonMeta =
      const VerificationMeta('recurringDetailsJson');
  @override
  late final GeneratedColumn<String> recurringDetailsJson =
      GeneratedColumn<String>('recurring_details_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        remark,
        amount,
        date,
        category,
        method,
        description,
        currency,
        recurringDetailsJson,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(Insertable<Expense> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('remark')) {
      context.handle(_remarkMeta,
          remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta));
    } else if (isInserting) {
      context.missing(_remarkMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('recurring_details_json')) {
      context.handle(
          _recurringDetailsJsonMeta,
          recurringDetailsJson.isAcceptableOrUnknown(
              data['recurring_details_json']!, _recurringDetailsJsonMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      remark: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remark'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      recurringDetailsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}recurring_details_json']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final String id;
  final String remark;
  final double amount;
  final DateTime date;
  final String category;
  final String method;
  final String? description;
  final String currency;
  final String? recurringDetailsJson;
  final DateTime updatedAt;
  const Expense(
      {required this.id,
      required this.remark,
      required this.amount,
      required this.date,
      required this.category,
      required this.method,
      this.description,
      required this.currency,
      this.recurringDetailsJson,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['remark'] = Variable<String>(remark);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<DateTime>(date);
    map['category'] = Variable<String>(category);
    map['method'] = Variable<String>(method);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || recurringDetailsJson != null) {
      map['recurring_details_json'] = Variable<String>(recurringDetailsJson);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      remark: Value(remark),
      amount: Value(amount),
      date: Value(date),
      category: Value(category),
      method: Value(method),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      currency: Value(currency),
      recurringDetailsJson: recurringDetailsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringDetailsJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<String>(json['id']),
      remark: serializer.fromJson<String>(json['remark']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      category: serializer.fromJson<String>(json['category']),
      method: serializer.fromJson<String>(json['method']),
      description: serializer.fromJson<String?>(json['description']),
      currency: serializer.fromJson<String>(json['currency']),
      recurringDetailsJson:
          serializer.fromJson<String?>(json['recurringDetailsJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'remark': serializer.toJson<String>(remark),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<DateTime>(date),
      'category': serializer.toJson<String>(category),
      'method': serializer.toJson<String>(method),
      'description': serializer.toJson<String?>(description),
      'currency': serializer.toJson<String>(currency),
      'recurringDetailsJson': serializer.toJson<String?>(recurringDetailsJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Expense copyWith(
          {String? id,
          String? remark,
          double? amount,
          DateTime? date,
          String? category,
          String? method,
          Value<String?> description = const Value.absent(),
          String? currency,
          Value<String?> recurringDetailsJson = const Value.absent(),
          DateTime? updatedAt}) =>
      Expense(
        id: id ?? this.id,
        remark: remark ?? this.remark,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        category: category ?? this.category,
        method: method ?? this.method,
        description: description.present ? description.value : this.description,
        currency: currency ?? this.currency,
        recurringDetailsJson: recurringDetailsJson.present
            ? recurringDetailsJson.value
            : this.recurringDetailsJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      remark: data.remark.present ? data.remark.value : this.remark,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      category: data.category.present ? data.category.value : this.category,
      method: data.method.present ? data.method.value : this.method,
      description:
          data.description.present ? data.description.value : this.description,
      currency: data.currency.present ? data.currency.value : this.currency,
      recurringDetailsJson: data.recurringDetailsJson.present
          ? data.recurringDetailsJson.value
          : this.recurringDetailsJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('remark: $remark, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('method: $method, ')
          ..write('description: $description, ')
          ..write('currency: $currency, ')
          ..write('recurringDetailsJson: $recurringDetailsJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, remark, amount, date, category, method,
      description, currency, recurringDetailsJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.remark == this.remark &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.category == this.category &&
          other.method == this.method &&
          other.description == this.description &&
          other.currency == this.currency &&
          other.recurringDetailsJson == this.recurringDetailsJson &&
          other.updatedAt == this.updatedAt);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<String> id;
  final Value<String> remark;
  final Value<double> amount;
  final Value<DateTime> date;
  final Value<String> category;
  final Value<String> method;
  final Value<String?> description;
  final Value<String> currency;
  final Value<String?> recurringDetailsJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.remark = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.category = const Value.absent(),
    this.method = const Value.absent(),
    this.description = const Value.absent(),
    this.currency = const Value.absent(),
    this.recurringDetailsJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required String remark,
    required double amount,
    required DateTime date,
    required String category,
    required String method,
    this.description = const Value.absent(),
    this.currency = const Value.absent(),
    this.recurringDetailsJson = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        remark = Value(remark),
        amount = Value(amount),
        date = Value(date),
        category = Value(category),
        method = Value(method),
        updatedAt = Value(updatedAt);
  static Insertable<Expense> custom({
    Expression<String>? id,
    Expression<String>? remark,
    Expression<double>? amount,
    Expression<DateTime>? date,
    Expression<String>? category,
    Expression<String>? method,
    Expression<String>? description,
    Expression<String>? currency,
    Expression<String>? recurringDetailsJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remark != null) 'remark': remark,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (category != null) 'category': category,
      if (method != null) 'method': method,
      if (description != null) 'description': description,
      if (currency != null) 'currency': currency,
      if (recurringDetailsJson != null)
        'recurring_details_json': recurringDetailsJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith(
      {Value<String>? id,
      Value<String>? remark,
      Value<double>? amount,
      Value<DateTime>? date,
      Value<String>? category,
      Value<String>? method,
      Value<String?>? description,
      Value<String>? currency,
      Value<String?>? recurringDetailsJson,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ExpensesCompanion(
      id: id ?? this.id,
      remark: remark ?? this.remark,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      method: method ?? this.method,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      recurringDetailsJson: recurringDetailsJson ?? this.recurringDetailsJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (recurringDetailsJson.present) {
      map['recurring_details_json'] =
          Variable<String>(recurringDetailsJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('remark: $remark, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('method: $method, ')
          ..write('description: $description, ')
          ..write('currency: $currency, ')
          ..write('recurringDetailsJson: $recurringDetailsJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _monthIdMeta =
      const VerificationMeta('monthId');
  @override
  late final GeneratedColumn<String> monthId = GeneratedColumn<String>(
      'month_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
      'total', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _leftMeta = const VerificationMeta('left');
  @override
  late final GeneratedColumn<double> left = GeneratedColumn<double>(
      'left', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _categoriesJsonMeta =
      const VerificationMeta('categoriesJson');
  @override
  late final GeneratedColumn<String> categoriesJson = GeneratedColumn<String>(
      'categories_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _savingMeta = const VerificationMeta('saving');
  @override
  late final GeneratedColumn<double> saving = GeneratedColumn<double>(
      'saving', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('MYR'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [monthId, total, left, categoriesJson, saving, currency, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(Insertable<Budget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('month_id')) {
      context.handle(_monthIdMeta,
          monthId.isAcceptableOrUnknown(data['month_id']!, _monthIdMeta));
    } else if (isInserting) {
      context.missing(_monthIdMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('left')) {
      context.handle(
          _leftMeta, left.isAcceptableOrUnknown(data['left']!, _leftMeta));
    } else if (isInserting) {
      context.missing(_leftMeta);
    }
    if (data.containsKey('categories_json')) {
      context.handle(
          _categoriesJsonMeta,
          categoriesJson.isAcceptableOrUnknown(
              data['categories_json']!, _categoriesJsonMeta));
    } else if (isInserting) {
      context.missing(_categoriesJsonMeta);
    }
    if (data.containsKey('saving')) {
      context.handle(_savingMeta,
          saving.isAcceptableOrUnknown(data['saving']!, _savingMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {monthId};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      monthId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}month_id'])!,
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total'])!,
      left: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}left'])!,
      categoriesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}categories_json'])!,
      saving: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}saving'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final String monthId;
  final double total;
  final double left;
  final String categoriesJson;
  final double saving;
  final String currency;
  final DateTime updatedAt;
  const Budget(
      {required this.monthId,
      required this.total,
      required this.left,
      required this.categoriesJson,
      required this.saving,
      required this.currency,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['month_id'] = Variable<String>(monthId);
    map['total'] = Variable<double>(total);
    map['left'] = Variable<double>(left);
    map['categories_json'] = Variable<String>(categoriesJson);
    map['saving'] = Variable<double>(saving);
    map['currency'] = Variable<String>(currency);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      monthId: Value(monthId),
      total: Value(total),
      left: Value(left),
      categoriesJson: Value(categoriesJson),
      saving: Value(saving),
      currency: Value(currency),
      updatedAt: Value(updatedAt),
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      monthId: serializer.fromJson<String>(json['monthId']),
      total: serializer.fromJson<double>(json['total']),
      left: serializer.fromJson<double>(json['left']),
      categoriesJson: serializer.fromJson<String>(json['categoriesJson']),
      saving: serializer.fromJson<double>(json['saving']),
      currency: serializer.fromJson<String>(json['currency']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'monthId': serializer.toJson<String>(monthId),
      'total': serializer.toJson<double>(total),
      'left': serializer.toJson<double>(left),
      'categoriesJson': serializer.toJson<String>(categoriesJson),
      'saving': serializer.toJson<double>(saving),
      'currency': serializer.toJson<String>(currency),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Budget copyWith(
          {String? monthId,
          double? total,
          double? left,
          String? categoriesJson,
          double? saving,
          String? currency,
          DateTime? updatedAt}) =>
      Budget(
        monthId: monthId ?? this.monthId,
        total: total ?? this.total,
        left: left ?? this.left,
        categoriesJson: categoriesJson ?? this.categoriesJson,
        saving: saving ?? this.saving,
        currency: currency ?? this.currency,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      monthId: data.monthId.present ? data.monthId.value : this.monthId,
      total: data.total.present ? data.total.value : this.total,
      left: data.left.present ? data.left.value : this.left,
      categoriesJson: data.categoriesJson.present
          ? data.categoriesJson.value
          : this.categoriesJson,
      saving: data.saving.present ? data.saving.value : this.saving,
      currency: data.currency.present ? data.currency.value : this.currency,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('monthId: $monthId, ')
          ..write('total: $total, ')
          ..write('left: $left, ')
          ..write('categoriesJson: $categoriesJson, ')
          ..write('saving: $saving, ')
          ..write('currency: $currency, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      monthId, total, left, categoriesJson, saving, currency, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.monthId == this.monthId &&
          other.total == this.total &&
          other.left == this.left &&
          other.categoriesJson == this.categoriesJson &&
          other.saving == this.saving &&
          other.currency == this.currency &&
          other.updatedAt == this.updatedAt);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<String> monthId;
  final Value<double> total;
  final Value<double> left;
  final Value<String> categoriesJson;
  final Value<double> saving;
  final Value<String> currency;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.monthId = const Value.absent(),
    this.total = const Value.absent(),
    this.left = const Value.absent(),
    this.categoriesJson = const Value.absent(),
    this.saving = const Value.absent(),
    this.currency = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String monthId,
    required double total,
    required double left,
    required String categoriesJson,
    this.saving = const Value.absent(),
    this.currency = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : monthId = Value(monthId),
        total = Value(total),
        left = Value(left),
        categoriesJson = Value(categoriesJson),
        updatedAt = Value(updatedAt);
  static Insertable<Budget> custom({
    Expression<String>? monthId,
    Expression<double>? total,
    Expression<double>? left,
    Expression<String>? categoriesJson,
    Expression<double>? saving,
    Expression<String>? currency,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (monthId != null) 'month_id': monthId,
      if (total != null) 'total': total,
      if (left != null) 'left': left,
      if (categoriesJson != null) 'categories_json': categoriesJson,
      if (saving != null) 'saving': saving,
      if (currency != null) 'currency': currency,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith(
      {Value<String>? monthId,
      Value<double>? total,
      Value<double>? left,
      Value<String>? categoriesJson,
      Value<double>? saving,
      Value<String>? currency,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return BudgetsCompanion(
      monthId: monthId ?? this.monthId,
      total: total ?? this.total,
      left: left ?? this.left,
      categoriesJson: categoriesJson ?? this.categoriesJson,
      saving: saving ?? this.saving,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (monthId.present) {
      map['month_id'] = Variable<String>(monthId.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (left.present) {
      map['left'] = Variable<double>(left.value);
    }
    if (categoriesJson.present) {
      map['categories_json'] = Variable<String>(categoriesJson.value);
    }
    if (saving.present) {
      map['saving'] = Variable<double>(saving.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('monthId: $monthId, ')
          ..write('total: $total, ')
          ..write('left: $left, ')
          ..write('categoriesJson: $categoriesJson, ')
          ..write('saving: $saving, ')
          ..write('currency: $currency, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
      'theme', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('light'));
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('MYR'));
  static const VerificationMeta _allowNotificationMeta =
      const VerificationMeta('allowNotification');
  @override
  late final GeneratedColumn<bool> allowNotification = GeneratedColumn<bool>(
      'allow_notification', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("allow_notification" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _autoBudgetMeta =
      const VerificationMeta('autoBudget');
  @override
  late final GeneratedColumn<bool> autoBudget = GeneratedColumn<bool>(
      'auto_budget', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("auto_budget" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _improveAccuracyMeta =
      const VerificationMeta('improveAccuracy');
  @override
  late final GeneratedColumn<bool> improveAccuracy = GeneratedColumn<bool>(
      'improve_accuracy', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("improve_accuracy" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncEnabledMeta =
      const VerificationMeta('syncEnabled');
  @override
  late final GeneratedColumn<bool> syncEnabled = GeneratedColumn<bool>(
      'sync_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("sync_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        theme,
        currency,
        allowNotification,
        autoBudget,
        improveAccuracy,
        syncEnabled,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('theme')) {
      context.handle(
          _themeMeta, theme.isAcceptableOrUnknown(data['theme']!, _themeMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('allow_notification')) {
      context.handle(
          _allowNotificationMeta,
          allowNotification.isAcceptableOrUnknown(
              data['allow_notification']!, _allowNotificationMeta));
    }
    if (data.containsKey('auto_budget')) {
      context.handle(
          _autoBudgetMeta,
          autoBudget.isAcceptableOrUnknown(
              data['auto_budget']!, _autoBudgetMeta));
    }
    if (data.containsKey('improve_accuracy')) {
      context.handle(
          _improveAccuracyMeta,
          improveAccuracy.isAcceptableOrUnknown(
              data['improve_accuracy']!, _improveAccuracyMeta));
    }
    if (data.containsKey('sync_enabled')) {
      context.handle(
          _syncEnabledMeta,
          syncEnabled.isAcceptableOrUnknown(
              data['sync_enabled']!, _syncEnabledMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      theme: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      allowNotification: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}allow_notification'])!,
      autoBudget: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}auto_budget'])!,
      improveAccuracy: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}improve_accuracy'])!,
      syncEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}sync_enabled'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String theme;
  final String currency;
  final bool allowNotification;
  final bool autoBudget;
  final bool improveAccuracy;
  final bool syncEnabled;
  final DateTime updatedAt;
  const AppSetting(
      {required this.id,
      required this.theme,
      required this.currency,
      required this.allowNotification,
      required this.autoBudget,
      required this.improveAccuracy,
      required this.syncEnabled,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['theme'] = Variable<String>(theme);
    map['currency'] = Variable<String>(currency);
    map['allow_notification'] = Variable<bool>(allowNotification);
    map['auto_budget'] = Variable<bool>(autoBudget);
    map['improve_accuracy'] = Variable<bool>(improveAccuracy);
    map['sync_enabled'] = Variable<bool>(syncEnabled);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      theme: Value(theme),
      currency: Value(currency),
      allowNotification: Value(allowNotification),
      autoBudget: Value(autoBudget),
      improveAccuracy: Value(improveAccuracy),
      syncEnabled: Value(syncEnabled),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      theme: serializer.fromJson<String>(json['theme']),
      currency: serializer.fromJson<String>(json['currency']),
      allowNotification: serializer.fromJson<bool>(json['allowNotification']),
      autoBudget: serializer.fromJson<bool>(json['autoBudget']),
      improveAccuracy: serializer.fromJson<bool>(json['improveAccuracy']),
      syncEnabled: serializer.fromJson<bool>(json['syncEnabled']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'theme': serializer.toJson<String>(theme),
      'currency': serializer.toJson<String>(currency),
      'allowNotification': serializer.toJson<bool>(allowNotification),
      'autoBudget': serializer.toJson<bool>(autoBudget),
      'improveAccuracy': serializer.toJson<bool>(improveAccuracy),
      'syncEnabled': serializer.toJson<bool>(syncEnabled),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith(
          {int? id,
          String? theme,
          String? currency,
          bool? allowNotification,
          bool? autoBudget,
          bool? improveAccuracy,
          bool? syncEnabled,
          DateTime? updatedAt}) =>
      AppSetting(
        id: id ?? this.id,
        theme: theme ?? this.theme,
        currency: currency ?? this.currency,
        allowNotification: allowNotification ?? this.allowNotification,
        autoBudget: autoBudget ?? this.autoBudget,
        improveAccuracy: improveAccuracy ?? this.improveAccuracy,
        syncEnabled: syncEnabled ?? this.syncEnabled,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      theme: data.theme.present ? data.theme.value : this.theme,
      currency: data.currency.present ? data.currency.value : this.currency,
      allowNotification: data.allowNotification.present
          ? data.allowNotification.value
          : this.allowNotification,
      autoBudget:
          data.autoBudget.present ? data.autoBudget.value : this.autoBudget,
      improveAccuracy: data.improveAccuracy.present
          ? data.improveAccuracy.value
          : this.improveAccuracy,
      syncEnabled:
          data.syncEnabled.present ? data.syncEnabled.value : this.syncEnabled,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('theme: $theme, ')
          ..write('currency: $currency, ')
          ..write('allowNotification: $allowNotification, ')
          ..write('autoBudget: $autoBudget, ')
          ..write('improveAccuracy: $improveAccuracy, ')
          ..write('syncEnabled: $syncEnabled, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, theme, currency, allowNotification,
      autoBudget, improveAccuracy, syncEnabled, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.theme == this.theme &&
          other.currency == this.currency &&
          other.allowNotification == this.allowNotification &&
          other.autoBudget == this.autoBudget &&
          other.improveAccuracy == this.improveAccuracy &&
          other.syncEnabled == this.syncEnabled &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> theme;
  final Value<String> currency;
  final Value<bool> allowNotification;
  final Value<bool> autoBudget;
  final Value<bool> improveAccuracy;
  final Value<bool> syncEnabled;
  final Value<DateTime> updatedAt;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.theme = const Value.absent(),
    this.currency = const Value.absent(),
    this.allowNotification = const Value.absent(),
    this.autoBudget = const Value.absent(),
    this.improveAccuracy = const Value.absent(),
    this.syncEnabled = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.theme = const Value.absent(),
    this.currency = const Value.absent(),
    this.allowNotification = const Value.absent(),
    this.autoBudget = const Value.absent(),
    this.improveAccuracy = const Value.absent(),
    this.syncEnabled = const Value.absent(),
    required DateTime updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? theme,
    Expression<String>? currency,
    Expression<bool>? allowNotification,
    Expression<bool>? autoBudget,
    Expression<bool>? improveAccuracy,
    Expression<bool>? syncEnabled,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (theme != null) 'theme': theme,
      if (currency != null) 'currency': currency,
      if (allowNotification != null) 'allow_notification': allowNotification,
      if (autoBudget != null) 'auto_budget': autoBudget,
      if (improveAccuracy != null) 'improve_accuracy': improveAccuracy,
      if (syncEnabled != null) 'sync_enabled': syncEnabled,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<int>? id,
      Value<String>? theme,
      Value<String>? currency,
      Value<bool>? allowNotification,
      Value<bool>? autoBudget,
      Value<bool>? improveAccuracy,
      Value<bool>? syncEnabled,
      Value<DateTime>? updatedAt}) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      theme: theme ?? this.theme,
      currency: currency ?? this.currency,
      allowNotification: allowNotification ?? this.allowNotification,
      autoBudget: autoBudget ?? this.autoBudget,
      improveAccuracy: improveAccuracy ?? this.improveAccuracy,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (allowNotification.present) {
      map['allow_notification'] = Variable<bool>(allowNotification.value);
    }
    if (autoBudget.present) {
      map['auto_budget'] = Variable<bool>(autoBudget.value);
    }
    if (improveAccuracy.present) {
      map['improve_accuracy'] = Variable<bool>(improveAccuracy.value);
    }
    if (syncEnabled.present) {
      map['sync_enabled'] = Variable<bool>(syncEnabled.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('theme: $theme, ')
          ..write('currency: $currency, ')
          ..write('allowNotification: $allowNotification, ')
          ..write('autoBudget: $autoBudget, ')
          ..write('improveAccuracy: $improveAccuracy, ')
          ..write('syncEnabled: $syncEnabled, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ExchangeRatesTable extends ExchangeRates
    with TableInfo<$ExchangeRatesTable, ExchangeRate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExchangeRatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _baseCurrencyMeta =
      const VerificationMeta('baseCurrency');
  @override
  late final GeneratedColumn<String> baseCurrency = GeneratedColumn<String>(
      'base_currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ratesJsonMeta =
      const VerificationMeta('ratesJson');
  @override
  late final GeneratedColumn<String> ratesJson = GeneratedColumn<String>(
      'rates_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [baseCurrency, ratesJson, timestamp, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exchange_rates';
  @override
  VerificationContext validateIntegrity(Insertable<ExchangeRate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('base_currency')) {
      context.handle(
          _baseCurrencyMeta,
          baseCurrency.isAcceptableOrUnknown(
              data['base_currency']!, _baseCurrencyMeta));
    } else if (isInserting) {
      context.missing(_baseCurrencyMeta);
    }
    if (data.containsKey('rates_json')) {
      context.handle(_ratesJsonMeta,
          ratesJson.isAcceptableOrUnknown(data['rates_json']!, _ratesJsonMeta));
    } else if (isInserting) {
      context.missing(_ratesJsonMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {baseCurrency};
  @override
  ExchangeRate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExchangeRate(
      baseCurrency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base_currency'])!,
      ratesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rates_json'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ExchangeRatesTable createAlias(String alias) {
    return $ExchangeRatesTable(attachedDatabase, alias);
  }
}

class ExchangeRate extends DataClass implements Insertable<ExchangeRate> {
  final String baseCurrency;
  final String ratesJson;
  final DateTime timestamp;
  final DateTime updatedAt;
  const ExchangeRate(
      {required this.baseCurrency,
      required this.ratesJson,
      required this.timestamp,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['base_currency'] = Variable<String>(baseCurrency);
    map['rates_json'] = Variable<String>(ratesJson);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ExchangeRatesCompanion toCompanion(bool nullToAbsent) {
    return ExchangeRatesCompanion(
      baseCurrency: Value(baseCurrency),
      ratesJson: Value(ratesJson),
      timestamp: Value(timestamp),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExchangeRate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExchangeRate(
      baseCurrency: serializer.fromJson<String>(json['baseCurrency']),
      ratesJson: serializer.fromJson<String>(json['ratesJson']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'baseCurrency': serializer.toJson<String>(baseCurrency),
      'ratesJson': serializer.toJson<String>(ratesJson),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ExchangeRate copyWith(
          {String? baseCurrency,
          String? ratesJson,
          DateTime? timestamp,
          DateTime? updatedAt}) =>
      ExchangeRate(
        baseCurrency: baseCurrency ?? this.baseCurrency,
        ratesJson: ratesJson ?? this.ratesJson,
        timestamp: timestamp ?? this.timestamp,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ExchangeRate copyWithCompanion(ExchangeRatesCompanion data) {
    return ExchangeRate(
      baseCurrency: data.baseCurrency.present
          ? data.baseCurrency.value
          : this.baseCurrency,
      ratesJson: data.ratesJson.present ? data.ratesJson.value : this.ratesJson,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRate(')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('ratesJson: $ratesJson, ')
          ..write('timestamp: $timestamp, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(baseCurrency, ratesJson, timestamp, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeRate &&
          other.baseCurrency == this.baseCurrency &&
          other.ratesJson == this.ratesJson &&
          other.timestamp == this.timestamp &&
          other.updatedAt == this.updatedAt);
}

class ExchangeRatesCompanion extends UpdateCompanion<ExchangeRate> {
  final Value<String> baseCurrency;
  final Value<String> ratesJson;
  final Value<DateTime> timestamp;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ExchangeRatesCompanion({
    this.baseCurrency = const Value.absent(),
    this.ratesJson = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExchangeRatesCompanion.insert({
    required String baseCurrency,
    required String ratesJson,
    required DateTime timestamp,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : baseCurrency = Value(baseCurrency),
        ratesJson = Value(ratesJson),
        timestamp = Value(timestamp),
        updatedAt = Value(updatedAt);
  static Insertable<ExchangeRate> custom({
    Expression<String>? baseCurrency,
    Expression<String>? ratesJson,
    Expression<DateTime>? timestamp,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (baseCurrency != null) 'base_currency': baseCurrency,
      if (ratesJson != null) 'rates_json': ratesJson,
      if (timestamp != null) 'timestamp': timestamp,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExchangeRatesCompanion copyWith(
      {Value<String>? baseCurrency,
      Value<String>? ratesJson,
      Value<DateTime>? timestamp,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ExchangeRatesCompanion(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      ratesJson: ratesJson ?? this.ratesJson,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (baseCurrency.present) {
      map['base_currency'] = Variable<String>(baseCurrency.value);
    }
    if (ratesJson.present) {
      map['rates_json'] = Variable<String>(ratesJson.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRatesCompanion(')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('ratesJson: $ratesJson, ')
          ..write('timestamp: $timestamp, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinancialGoalsTable extends FinancialGoals
    with TableInfo<$FinancialGoalsTable, FinancialGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinancialGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetAmountMeta =
      const VerificationMeta('targetAmount');
  @override
  late final GeneratedColumn<double> targetAmount = GeneratedColumn<double>(
      'target_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currentAmountMeta =
      const VerificationMeta('currentAmount');
  @override
  late final GeneratedColumn<double> currentAmount = GeneratedColumn<double>(
      'current_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _deadlineMeta =
      const VerificationMeta('deadline');
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
      'deadline', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _iconNameMeta =
      const VerificationMeta('iconName');
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
      'icon_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorValueMeta =
      const VerificationMeta('colorValue');
  @override
  late final GeneratedColumn<String> colorValue = GeneratedColumn<String>(
      'color_value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        targetAmount,
        currentAmount,
        deadline,
        iconName,
        colorValue,
        isCompleted,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'financial_goals';
  @override
  VerificationContext validateIntegrity(Insertable<FinancialGoal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
          _targetAmountMeta,
          targetAmount.isAcceptableOrUnknown(
              data['target_amount']!, _targetAmountMeta));
    } else if (isInserting) {
      context.missing(_targetAmountMeta);
    }
    if (data.containsKey('current_amount')) {
      context.handle(
          _currentAmountMeta,
          currentAmount.isAcceptableOrUnknown(
              data['current_amount']!, _currentAmountMeta));
    } else if (isInserting) {
      context.missing(_currentAmountMeta);
    }
    if (data.containsKey('deadline')) {
      context.handle(_deadlineMeta,
          deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta));
    } else if (isInserting) {
      context.missing(_deadlineMeta);
    }
    if (data.containsKey('icon_name')) {
      context.handle(_iconNameMeta,
          iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta));
    } else if (isInserting) {
      context.missing(_iconNameMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
          _colorValueMeta,
          colorValue.isAcceptableOrUnknown(
              data['color_value']!, _colorValueMeta));
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinancialGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinancialGoal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      targetAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_amount'])!,
      currentAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}current_amount'])!,
      deadline: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deadline'])!,
      iconName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_name'])!,
      colorValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_value'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $FinancialGoalsTable createAlias(String alias) {
    return $FinancialGoalsTable(attachedDatabase, alias);
  }
}

class FinancialGoal extends DataClass implements Insertable<FinancialGoal> {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String iconName;
  final String colorValue;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FinancialGoal(
      {required this.id,
      required this.title,
      required this.targetAmount,
      required this.currentAmount,
      required this.deadline,
      required this.iconName,
      required this.colorValue,
      required this.isCompleted,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['target_amount'] = Variable<double>(targetAmount);
    map['current_amount'] = Variable<double>(currentAmount);
    map['deadline'] = Variable<DateTime>(deadline);
    map['icon_name'] = Variable<String>(iconName);
    map['color_value'] = Variable<String>(colorValue);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FinancialGoalsCompanion toCompanion(bool nullToAbsent) {
    return FinancialGoalsCompanion(
      id: Value(id),
      title: Value(title),
      targetAmount: Value(targetAmount),
      currentAmount: Value(currentAmount),
      deadline: Value(deadline),
      iconName: Value(iconName),
      colorValue: Value(colorValue),
      isCompleted: Value(isCompleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FinancialGoal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinancialGoal(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      targetAmount: serializer.fromJson<double>(json['targetAmount']),
      currentAmount: serializer.fromJson<double>(json['currentAmount']),
      deadline: serializer.fromJson<DateTime>(json['deadline']),
      iconName: serializer.fromJson<String>(json['iconName']),
      colorValue: serializer.fromJson<String>(json['colorValue']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'targetAmount': serializer.toJson<double>(targetAmount),
      'currentAmount': serializer.toJson<double>(currentAmount),
      'deadline': serializer.toJson<DateTime>(deadline),
      'iconName': serializer.toJson<String>(iconName),
      'colorValue': serializer.toJson<String>(colorValue),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FinancialGoal copyWith(
          {String? id,
          String? title,
          double? targetAmount,
          double? currentAmount,
          DateTime? deadline,
          String? iconName,
          String? colorValue,
          bool? isCompleted,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      FinancialGoal(
        id: id ?? this.id,
        title: title ?? this.title,
        targetAmount: targetAmount ?? this.targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        deadline: deadline ?? this.deadline,
        iconName: iconName ?? this.iconName,
        colorValue: colorValue ?? this.colorValue,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  FinancialGoal copyWithCompanion(FinancialGoalsCompanion data) {
    return FinancialGoal(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      currentAmount: data.currentAmount.present
          ? data.currentAmount.value
          : this.currentAmount,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      colorValue:
          data.colorValue.present ? data.colorValue.value : this.colorValue,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinancialGoal(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('currentAmount: $currentAmount, ')
          ..write('deadline: $deadline, ')
          ..write('iconName: $iconName, ')
          ..write('colorValue: $colorValue, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, targetAmount, currentAmount,
      deadline, iconName, colorValue, isCompleted, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialGoal &&
          other.id == this.id &&
          other.title == this.title &&
          other.targetAmount == this.targetAmount &&
          other.currentAmount == this.currentAmount &&
          other.deadline == this.deadline &&
          other.iconName == this.iconName &&
          other.colorValue == this.colorValue &&
          other.isCompleted == this.isCompleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FinancialGoalsCompanion extends UpdateCompanion<FinancialGoal> {
  final Value<String> id;
  final Value<String> title;
  final Value<double> targetAmount;
  final Value<double> currentAmount;
  final Value<DateTime> deadline;
  final Value<String> iconName;
  final Value<String> colorValue;
  final Value<bool> isCompleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FinancialGoalsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.currentAmount = const Value.absent(),
    this.deadline = const Value.absent(),
    this.iconName = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinancialGoalsCompanion.insert({
    required String id,
    required String title,
    required double targetAmount,
    required double currentAmount,
    required DateTime deadline,
    required String iconName,
    required String colorValue,
    this.isCompleted = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        targetAmount = Value(targetAmount),
        currentAmount = Value(currentAmount),
        deadline = Value(deadline),
        iconName = Value(iconName),
        colorValue = Value(colorValue),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<FinancialGoal> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<double>? targetAmount,
    Expression<double>? currentAmount,
    Expression<DateTime>? deadline,
    Expression<String>? iconName,
    Expression<String>? colorValue,
    Expression<bool>? isCompleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (currentAmount != null) 'current_amount': currentAmount,
      if (deadline != null) 'deadline': deadline,
      if (iconName != null) 'icon_name': iconName,
      if (colorValue != null) 'color_value': colorValue,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinancialGoalsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<double>? targetAmount,
      Value<double>? currentAmount,
      Value<DateTime>? deadline,
      Value<String>? iconName,
      Value<String>? colorValue,
      Value<bool>? isCompleted,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return FinancialGoalsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<double>(targetAmount.value);
    }
    if (currentAmount.present) {
      map['current_amount'] = Variable<double>(currentAmount.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<String>(colorValue.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinancialGoalsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('currentAmount: $currentAmount, ')
          ..write('deadline: $deadline, ')
          ..write('iconName: $iconName, ')
          ..write('colorValue: $colorValue, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalHistoryTable extends GoalHistory
    with TableInfo<$GoalHistoryTable, GoalHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
      'goal_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetAmountMeta =
      const VerificationMeta('targetAmount');
  @override
  late final GeneratedColumn<double> targetAmount = GeneratedColumn<double>(
      'target_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _finalAmountMeta =
      const VerificationMeta('finalAmount');
  @override
  late final GeneratedColumn<double> finalAmount = GeneratedColumn<double>(
      'final_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _createdDateMeta =
      const VerificationMeta('createdDate');
  @override
  late final GeneratedColumn<DateTime> createdDate = GeneratedColumn<DateTime>(
      'created_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _completedDateMeta =
      const VerificationMeta('completedDate');
  @override
  late final GeneratedColumn<DateTime> completedDate =
      GeneratedColumn<DateTime>('completed_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _iconNameMeta =
      const VerificationMeta('iconName');
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
      'icon_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorValueMeta =
      const VerificationMeta('colorValue');
  @override
  late final GeneratedColumn<String> colorValue = GeneratedColumn<String>(
      'color_value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        goalId,
        title,
        targetAmount,
        finalAmount,
        createdDate,
        completedDate,
        iconName,
        colorValue,
        notes,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goal_history';
  @override
  VerificationContext validateIntegrity(Insertable<GoalHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(_goalIdMeta,
          goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta));
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
          _targetAmountMeta,
          targetAmount.isAcceptableOrUnknown(
              data['target_amount']!, _targetAmountMeta));
    } else if (isInserting) {
      context.missing(_targetAmountMeta);
    }
    if (data.containsKey('final_amount')) {
      context.handle(
          _finalAmountMeta,
          finalAmount.isAcceptableOrUnknown(
              data['final_amount']!, _finalAmountMeta));
    } else if (isInserting) {
      context.missing(_finalAmountMeta);
    }
    if (data.containsKey('created_date')) {
      context.handle(
          _createdDateMeta,
          createdDate.isAcceptableOrUnknown(
              data['created_date']!, _createdDateMeta));
    } else if (isInserting) {
      context.missing(_createdDateMeta);
    }
    if (data.containsKey('completed_date')) {
      context.handle(
          _completedDateMeta,
          completedDate.isAcceptableOrUnknown(
              data['completed_date']!, _completedDateMeta));
    } else if (isInserting) {
      context.missing(_completedDateMeta);
    }
    if (data.containsKey('icon_name')) {
      context.handle(_iconNameMeta,
          iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta));
    } else if (isInserting) {
      context.missing(_iconNameMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
          _colorValueMeta,
          colorValue.isAcceptableOrUnknown(
              data['color_value']!, _colorValueMeta));
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      goalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}goal_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      targetAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_amount'])!,
      finalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}final_amount'])!,
      createdDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_date'])!,
      completedDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}completed_date'])!,
      iconName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_name'])!,
      colorValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_value'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $GoalHistoryTable createAlias(String alias) {
    return $GoalHistoryTable(attachedDatabase, alias);
  }
}

class GoalHistoryData extends DataClass implements Insertable<GoalHistoryData> {
  final String id;
  final String goalId;
  final String title;
  final double targetAmount;
  final double finalAmount;
  final DateTime createdDate;
  final DateTime completedDate;
  final String iconName;
  final String colorValue;
  final String? notes;
  final DateTime updatedAt;
  const GoalHistoryData(
      {required this.id,
      required this.goalId,
      required this.title,
      required this.targetAmount,
      required this.finalAmount,
      required this.createdDate,
      required this.completedDate,
      required this.iconName,
      required this.colorValue,
      this.notes,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['title'] = Variable<String>(title);
    map['target_amount'] = Variable<double>(targetAmount);
    map['final_amount'] = Variable<double>(finalAmount);
    map['created_date'] = Variable<DateTime>(createdDate);
    map['completed_date'] = Variable<DateTime>(completedDate);
    map['icon_name'] = Variable<String>(iconName);
    map['color_value'] = Variable<String>(colorValue);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GoalHistoryCompanion toCompanion(bool nullToAbsent) {
    return GoalHistoryCompanion(
      id: Value(id),
      goalId: Value(goalId),
      title: Value(title),
      targetAmount: Value(targetAmount),
      finalAmount: Value(finalAmount),
      createdDate: Value(createdDate),
      completedDate: Value(completedDate),
      iconName: Value(iconName),
      colorValue: Value(colorValue),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      updatedAt: Value(updatedAt),
    );
  }

  factory GoalHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalHistoryData(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      title: serializer.fromJson<String>(json['title']),
      targetAmount: serializer.fromJson<double>(json['targetAmount']),
      finalAmount: serializer.fromJson<double>(json['finalAmount']),
      createdDate: serializer.fromJson<DateTime>(json['createdDate']),
      completedDate: serializer.fromJson<DateTime>(json['completedDate']),
      iconName: serializer.fromJson<String>(json['iconName']),
      colorValue: serializer.fromJson<String>(json['colorValue']),
      notes: serializer.fromJson<String?>(json['notes']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'title': serializer.toJson<String>(title),
      'targetAmount': serializer.toJson<double>(targetAmount),
      'finalAmount': serializer.toJson<double>(finalAmount),
      'createdDate': serializer.toJson<DateTime>(createdDate),
      'completedDate': serializer.toJson<DateTime>(completedDate),
      'iconName': serializer.toJson<String>(iconName),
      'colorValue': serializer.toJson<String>(colorValue),
      'notes': serializer.toJson<String?>(notes),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  GoalHistoryData copyWith(
          {String? id,
          String? goalId,
          String? title,
          double? targetAmount,
          double? finalAmount,
          DateTime? createdDate,
          DateTime? completedDate,
          String? iconName,
          String? colorValue,
          Value<String?> notes = const Value.absent(),
          DateTime? updatedAt}) =>
      GoalHistoryData(
        id: id ?? this.id,
        goalId: goalId ?? this.goalId,
        title: title ?? this.title,
        targetAmount: targetAmount ?? this.targetAmount,
        finalAmount: finalAmount ?? this.finalAmount,
        createdDate: createdDate ?? this.createdDate,
        completedDate: completedDate ?? this.completedDate,
        iconName: iconName ?? this.iconName,
        colorValue: colorValue ?? this.colorValue,
        notes: notes.present ? notes.value : this.notes,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  GoalHistoryData copyWithCompanion(GoalHistoryCompanion data) {
    return GoalHistoryData(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      title: data.title.present ? data.title.value : this.title,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      finalAmount:
          data.finalAmount.present ? data.finalAmount.value : this.finalAmount,
      createdDate:
          data.createdDate.present ? data.createdDate.value : this.createdDate,
      completedDate: data.completedDate.present
          ? data.completedDate.value
          : this.completedDate,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      colorValue:
          data.colorValue.present ? data.colorValue.value : this.colorValue,
      notes: data.notes.present ? data.notes.value : this.notes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalHistoryData(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('title: $title, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('finalAmount: $finalAmount, ')
          ..write('createdDate: $createdDate, ')
          ..write('completedDate: $completedDate, ')
          ..write('iconName: $iconName, ')
          ..write('colorValue: $colorValue, ')
          ..write('notes: $notes, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, goalId, title, targetAmount, finalAmount,
      createdDate, completedDate, iconName, colorValue, notes, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalHistoryData &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.title == this.title &&
          other.targetAmount == this.targetAmount &&
          other.finalAmount == this.finalAmount &&
          other.createdDate == this.createdDate &&
          other.completedDate == this.completedDate &&
          other.iconName == this.iconName &&
          other.colorValue == this.colorValue &&
          other.notes == this.notes &&
          other.updatedAt == this.updatedAt);
}

class GoalHistoryCompanion extends UpdateCompanion<GoalHistoryData> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<String> title;
  final Value<double> targetAmount;
  final Value<double> finalAmount;
  final Value<DateTime> createdDate;
  final Value<DateTime> completedDate;
  final Value<String> iconName;
  final Value<String> colorValue;
  final Value<String?> notes;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const GoalHistoryCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.title = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.finalAmount = const Value.absent(),
    this.createdDate = const Value.absent(),
    this.completedDate = const Value.absent(),
    this.iconName = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.notes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalHistoryCompanion.insert({
    required String id,
    required String goalId,
    required String title,
    required double targetAmount,
    required double finalAmount,
    required DateTime createdDate,
    required DateTime completedDate,
    required String iconName,
    required String colorValue,
    this.notes = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        goalId = Value(goalId),
        title = Value(title),
        targetAmount = Value(targetAmount),
        finalAmount = Value(finalAmount),
        createdDate = Value(createdDate),
        completedDate = Value(completedDate),
        iconName = Value(iconName),
        colorValue = Value(colorValue),
        updatedAt = Value(updatedAt);
  static Insertable<GoalHistoryData> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? title,
    Expression<double>? targetAmount,
    Expression<double>? finalAmount,
    Expression<DateTime>? createdDate,
    Expression<DateTime>? completedDate,
    Expression<String>? iconName,
    Expression<String>? colorValue,
    Expression<String>? notes,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (title != null) 'title': title,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (finalAmount != null) 'final_amount': finalAmount,
      if (createdDate != null) 'created_date': createdDate,
      if (completedDate != null) 'completed_date': completedDate,
      if (iconName != null) 'icon_name': iconName,
      if (colorValue != null) 'color_value': colorValue,
      if (notes != null) 'notes': notes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalHistoryCompanion copyWith(
      {Value<String>? id,
      Value<String>? goalId,
      Value<String>? title,
      Value<double>? targetAmount,
      Value<double>? finalAmount,
      Value<DateTime>? createdDate,
      Value<DateTime>? completedDate,
      Value<String>? iconName,
      Value<String>? colorValue,
      Value<String?>? notes,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return GoalHistoryCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      createdDate: createdDate ?? this.createdDate,
      completedDate: completedDate ?? this.completedDate,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<double>(targetAmount.value);
    }
    if (finalAmount.present) {
      map['final_amount'] = Variable<double>(finalAmount.value);
    }
    if (createdDate.present) {
      map['created_date'] = Variable<DateTime>(createdDate.value);
    }
    if (completedDate.present) {
      map['completed_date'] = Variable<DateTime>(completedDate.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<String>(colorValue.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalHistoryCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('title: $title, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('finalAmount: $finalAmount, ')
          ..write('createdDate: $createdDate, ')
          ..write('completedDate: $completedDate, ')
          ..write('iconName: $iconName, ')
          ..write('colorValue: $colorValue, ')
          ..write('notes: $notes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _incomeStabilityMeta =
      const VerificationMeta('incomeStability');
  @override
  late final GeneratedColumn<String> incomeStability = GeneratedColumn<String>(
      'income_stability', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _spendingMentalityMeta =
      const VerificationMeta('spendingMentality');
  @override
  late final GeneratedColumn<String> spendingMentality =
      GeneratedColumn<String>('spending_mentality', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _riskAppetiteMeta =
      const VerificationMeta('riskAppetite');
  @override
  late final GeneratedColumn<String> riskAppetite = GeneratedColumn<String>(
      'risk_appetite', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _monthlyIncomeMeta =
      const VerificationMeta('monthlyIncome');
  @override
  late final GeneratedColumn<double> monthlyIncome = GeneratedColumn<double>(
      'monthly_income', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _emergencyFundTargetMeta =
      const VerificationMeta('emergencyFundTarget');
  @override
  late final GeneratedColumn<double> emergencyFundTarget =
      GeneratedColumn<double>('emergency_fund_target', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _financialLiteracyMeta =
      const VerificationMeta('financialLiteracy');
  @override
  late final GeneratedColumn<String> financialLiteracy =
      GeneratedColumn<String>('financial_literacy', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _dataConsentAcceptedAtMeta =
      const VerificationMeta('dataConsentAcceptedAt');
  @override
  late final GeneratedColumn<DateTime> dataConsentAcceptedAt =
      GeneratedColumn<DateTime>('data_consent_accepted_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isCompleteMeta =
      const VerificationMeta('isComplete');
  @override
  late final GeneratedColumn<bool> isComplete = GeneratedColumn<bool>(
      'is_complete', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_complete" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        incomeStability,
        spendingMentality,
        riskAppetite,
        monthlyIncome,
        emergencyFundTarget,
        financialLiteracy,
        createdAt,
        updatedAt,
        dataConsentAcceptedAt,
        isComplete
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<UserProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('income_stability')) {
      context.handle(
          _incomeStabilityMeta,
          incomeStability.isAcceptableOrUnknown(
              data['income_stability']!, _incomeStabilityMeta));
    } else if (isInserting) {
      context.missing(_incomeStabilityMeta);
    }
    if (data.containsKey('spending_mentality')) {
      context.handle(
          _spendingMentalityMeta,
          spendingMentality.isAcceptableOrUnknown(
              data['spending_mentality']!, _spendingMentalityMeta));
    } else if (isInserting) {
      context.missing(_spendingMentalityMeta);
    }
    if (data.containsKey('risk_appetite')) {
      context.handle(
          _riskAppetiteMeta,
          riskAppetite.isAcceptableOrUnknown(
              data['risk_appetite']!, _riskAppetiteMeta));
    } else if (isInserting) {
      context.missing(_riskAppetiteMeta);
    }
    if (data.containsKey('monthly_income')) {
      context.handle(
          _monthlyIncomeMeta,
          monthlyIncome.isAcceptableOrUnknown(
              data['monthly_income']!, _monthlyIncomeMeta));
    } else if (isInserting) {
      context.missing(_monthlyIncomeMeta);
    }
    if (data.containsKey('emergency_fund_target')) {
      context.handle(
          _emergencyFundTargetMeta,
          emergencyFundTarget.isAcceptableOrUnknown(
              data['emergency_fund_target']!, _emergencyFundTargetMeta));
    } else if (isInserting) {
      context.missing(_emergencyFundTargetMeta);
    }
    if (data.containsKey('financial_literacy')) {
      context.handle(
          _financialLiteracyMeta,
          financialLiteracy.isAcceptableOrUnknown(
              data['financial_literacy']!, _financialLiteracyMeta));
    } else if (isInserting) {
      context.missing(_financialLiteracyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('data_consent_accepted_at')) {
      context.handle(
          _dataConsentAcceptedAtMeta,
          dataConsentAcceptedAt.isAcceptableOrUnknown(
              data['data_consent_accepted_at']!, _dataConsentAcceptedAtMeta));
    }
    if (data.containsKey('is_complete')) {
      context.handle(
          _isCompleteMeta,
          isComplete.isAcceptableOrUnknown(
              data['is_complete']!, _isCompleteMeta));
    } else if (isInserting) {
      context.missing(_isCompleteMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      incomeStability: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}income_stability'])!,
      spendingMentality: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}spending_mentality'])!,
      riskAppetite: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}risk_appetite'])!,
      monthlyIncome: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}monthly_income'])!,
      emergencyFundTarget: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}emergency_fund_target'])!,
      financialLiteracy: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}financial_literacy'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      dataConsentAcceptedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}data_consent_accepted_at']),
      isComplete: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_complete'])!,
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfile extends DataClass implements Insertable<UserProfile> {
  final String id;
  final String userId;
  final String incomeStability;
  final String spendingMentality;
  final String riskAppetite;
  final double monthlyIncome;
  final double emergencyFundTarget;
  final String financialLiteracy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dataConsentAcceptedAt;
  final bool isComplete;
  const UserProfile(
      {required this.id,
      required this.userId,
      required this.incomeStability,
      required this.spendingMentality,
      required this.riskAppetite,
      required this.monthlyIncome,
      required this.emergencyFundTarget,
      required this.financialLiteracy,
      required this.createdAt,
      required this.updatedAt,
      this.dataConsentAcceptedAt,
      required this.isComplete});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['income_stability'] = Variable<String>(incomeStability);
    map['spending_mentality'] = Variable<String>(spendingMentality);
    map['risk_appetite'] = Variable<String>(riskAppetite);
    map['monthly_income'] = Variable<double>(monthlyIncome);
    map['emergency_fund_target'] = Variable<double>(emergencyFundTarget);
    map['financial_literacy'] = Variable<String>(financialLiteracy);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || dataConsentAcceptedAt != null) {
      map['data_consent_accepted_at'] =
          Variable<DateTime>(dataConsentAcceptedAt);
    }
    map['is_complete'] = Variable<bool>(isComplete);
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      userId: Value(userId),
      incomeStability: Value(incomeStability),
      spendingMentality: Value(spendingMentality),
      riskAppetite: Value(riskAppetite),
      monthlyIncome: Value(monthlyIncome),
      emergencyFundTarget: Value(emergencyFundTarget),
      financialLiteracy: Value(financialLiteracy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      dataConsentAcceptedAt: dataConsentAcceptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dataConsentAcceptedAt),
      isComplete: Value(isComplete),
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfile(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      incomeStability: serializer.fromJson<String>(json['incomeStability']),
      spendingMentality: serializer.fromJson<String>(json['spendingMentality']),
      riskAppetite: serializer.fromJson<String>(json['riskAppetite']),
      monthlyIncome: serializer.fromJson<double>(json['monthlyIncome']),
      emergencyFundTarget:
          serializer.fromJson<double>(json['emergencyFundTarget']),
      financialLiteracy: serializer.fromJson<String>(json['financialLiteracy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      dataConsentAcceptedAt:
          serializer.fromJson<DateTime?>(json['dataConsentAcceptedAt']),
      isComplete: serializer.fromJson<bool>(json['isComplete']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'incomeStability': serializer.toJson<String>(incomeStability),
      'spendingMentality': serializer.toJson<String>(spendingMentality),
      'riskAppetite': serializer.toJson<String>(riskAppetite),
      'monthlyIncome': serializer.toJson<double>(monthlyIncome),
      'emergencyFundTarget': serializer.toJson<double>(emergencyFundTarget),
      'financialLiteracy': serializer.toJson<String>(financialLiteracy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'dataConsentAcceptedAt':
          serializer.toJson<DateTime?>(dataConsentAcceptedAt),
      'isComplete': serializer.toJson<bool>(isComplete),
    };
  }

  UserProfile copyWith(
          {String? id,
          String? userId,
          String? incomeStability,
          String? spendingMentality,
          String? riskAppetite,
          double? monthlyIncome,
          double? emergencyFundTarget,
          String? financialLiteracy,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> dataConsentAcceptedAt = const Value.absent(),
          bool? isComplete}) =>
      UserProfile(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        incomeStability: incomeStability ?? this.incomeStability,
        spendingMentality: spendingMentality ?? this.spendingMentality,
        riskAppetite: riskAppetite ?? this.riskAppetite,
        monthlyIncome: monthlyIncome ?? this.monthlyIncome,
        emergencyFundTarget: emergencyFundTarget ?? this.emergencyFundTarget,
        financialLiteracy: financialLiteracy ?? this.financialLiteracy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        dataConsentAcceptedAt: dataConsentAcceptedAt.present
            ? dataConsentAcceptedAt.value
            : this.dataConsentAcceptedAt,
        isComplete: isComplete ?? this.isComplete,
      );
  UserProfile copyWithCompanion(UserProfilesCompanion data) {
    return UserProfile(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      incomeStability: data.incomeStability.present
          ? data.incomeStability.value
          : this.incomeStability,
      spendingMentality: data.spendingMentality.present
          ? data.spendingMentality.value
          : this.spendingMentality,
      riskAppetite: data.riskAppetite.present
          ? data.riskAppetite.value
          : this.riskAppetite,
      monthlyIncome: data.monthlyIncome.present
          ? data.monthlyIncome.value
          : this.monthlyIncome,
      emergencyFundTarget: data.emergencyFundTarget.present
          ? data.emergencyFundTarget.value
          : this.emergencyFundTarget,
      financialLiteracy: data.financialLiteracy.present
          ? data.financialLiteracy.value
          : this.financialLiteracy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      dataConsentAcceptedAt: data.dataConsentAcceptedAt.present
          ? data.dataConsentAcceptedAt.value
          : this.dataConsentAcceptedAt,
      isComplete:
          data.isComplete.present ? data.isComplete.value : this.isComplete,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfile(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('incomeStability: $incomeStability, ')
          ..write('spendingMentality: $spendingMentality, ')
          ..write('riskAppetite: $riskAppetite, ')
          ..write('monthlyIncome: $monthlyIncome, ')
          ..write('emergencyFundTarget: $emergencyFundTarget, ')
          ..write('financialLiteracy: $financialLiteracy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dataConsentAcceptedAt: $dataConsentAcceptedAt, ')
          ..write('isComplete: $isComplete')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      incomeStability,
      spendingMentality,
      riskAppetite,
      monthlyIncome,
      emergencyFundTarget,
      financialLiteracy,
      createdAt,
      updatedAt,
      dataConsentAcceptedAt,
      isComplete);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfile &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.incomeStability == this.incomeStability &&
          other.spendingMentality == this.spendingMentality &&
          other.riskAppetite == this.riskAppetite &&
          other.monthlyIncome == this.monthlyIncome &&
          other.emergencyFundTarget == this.emergencyFundTarget &&
          other.financialLiteracy == this.financialLiteracy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.dataConsentAcceptedAt == this.dataConsentAcceptedAt &&
          other.isComplete == this.isComplete);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfile> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> incomeStability;
  final Value<String> spendingMentality;
  final Value<String> riskAppetite;
  final Value<double> monthlyIncome;
  final Value<double> emergencyFundTarget;
  final Value<String> financialLiteracy;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> dataConsentAcceptedAt;
  final Value<bool> isComplete;
  final Value<int> rowid;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.incomeStability = const Value.absent(),
    this.spendingMentality = const Value.absent(),
    this.riskAppetite = const Value.absent(),
    this.monthlyIncome = const Value.absent(),
    this.emergencyFundTarget = const Value.absent(),
    this.financialLiteracy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dataConsentAcceptedAt = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    required String id,
    required String userId,
    required String incomeStability,
    required String spendingMentality,
    required String riskAppetite,
    required double monthlyIncome,
    required double emergencyFundTarget,
    required String financialLiteracy,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.dataConsentAcceptedAt = const Value.absent(),
    required bool isComplete,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        incomeStability = Value(incomeStability),
        spendingMentality = Value(spendingMentality),
        riskAppetite = Value(riskAppetite),
        monthlyIncome = Value(monthlyIncome),
        emergencyFundTarget = Value(emergencyFundTarget),
        financialLiteracy = Value(financialLiteracy),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        isComplete = Value(isComplete);
  static Insertable<UserProfile> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? incomeStability,
    Expression<String>? spendingMentality,
    Expression<String>? riskAppetite,
    Expression<double>? monthlyIncome,
    Expression<double>? emergencyFundTarget,
    Expression<String>? financialLiteracy,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? dataConsentAcceptedAt,
    Expression<bool>? isComplete,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (incomeStability != null) 'income_stability': incomeStability,
      if (spendingMentality != null) 'spending_mentality': spendingMentality,
      if (riskAppetite != null) 'risk_appetite': riskAppetite,
      if (monthlyIncome != null) 'monthly_income': monthlyIncome,
      if (emergencyFundTarget != null)
        'emergency_fund_target': emergencyFundTarget,
      if (financialLiteracy != null) 'financial_literacy': financialLiteracy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (dataConsentAcceptedAt != null)
        'data_consent_accepted_at': dataConsentAcceptedAt,
      if (isComplete != null) 'is_complete': isComplete,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? incomeStability,
      Value<String>? spendingMentality,
      Value<String>? riskAppetite,
      Value<double>? monthlyIncome,
      Value<double>? emergencyFundTarget,
      Value<String>? financialLiteracy,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? dataConsentAcceptedAt,
      Value<bool>? isComplete,
      Value<int>? rowid}) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      incomeStability: incomeStability ?? this.incomeStability,
      spendingMentality: spendingMentality ?? this.spendingMentality,
      riskAppetite: riskAppetite ?? this.riskAppetite,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      emergencyFundTarget: emergencyFundTarget ?? this.emergencyFundTarget,
      financialLiteracy: financialLiteracy ?? this.financialLiteracy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dataConsentAcceptedAt:
          dataConsentAcceptedAt ?? this.dataConsentAcceptedAt,
      isComplete: isComplete ?? this.isComplete,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (incomeStability.present) {
      map['income_stability'] = Variable<String>(incomeStability.value);
    }
    if (spendingMentality.present) {
      map['spending_mentality'] = Variable<String>(spendingMentality.value);
    }
    if (riskAppetite.present) {
      map['risk_appetite'] = Variable<String>(riskAppetite.value);
    }
    if (monthlyIncome.present) {
      map['monthly_income'] = Variable<double>(monthlyIncome.value);
    }
    if (emergencyFundTarget.present) {
      map['emergency_fund_target'] =
          Variable<double>(emergencyFundTarget.value);
    }
    if (financialLiteracy.present) {
      map['financial_literacy'] = Variable<String>(financialLiteracy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (dataConsentAcceptedAt.present) {
      map['data_consent_accepted_at'] =
          Variable<DateTime>(dataConsentAcceptedAt.value);
    }
    if (isComplete.present) {
      map['is_complete'] = Variable<bool>(isComplete.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('incomeStability: $incomeStability, ')
          ..write('spendingMentality: $spendingMentality, ')
          ..write('riskAppetite: $riskAppetite, ')
          ..write('monthlyIncome: $monthlyIncome, ')
          ..write('emergencyFundTarget: $emergencyFundTarget, ')
          ..write('financialLiteracy: $financialLiteracy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dataConsentAcceptedAt: $dataConsentAcceptedAt, ')
          ..write('isComplete: $isComplete, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnalysisResultsTable extends AnalysisResults
    with TableInfo<$AnalysisResultsTable, AnalysisResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnalysisResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _analysisDataMeta =
      const VerificationMeta('analysisData');
  @override
  late final GeneratedColumn<String> analysisData = GeneratedColumn<String>(
      'analysis_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, userId, analysisData, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'analysis_results';
  @override
  VerificationContext validateIntegrity(Insertable<AnalysisResult> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('analysis_data')) {
      context.handle(
          _analysisDataMeta,
          analysisData.isAcceptableOrUnknown(
              data['analysis_data']!, _analysisDataMeta));
    } else if (isInserting) {
      context.missing(_analysisDataMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnalysisResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnalysisResult(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      analysisData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}analysis_data'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AnalysisResultsTable createAlias(String alias) {
    return $AnalysisResultsTable(attachedDatabase, alias);
  }
}

class AnalysisResult extends DataClass implements Insertable<AnalysisResult> {
  /// A unique identifier for each analysis record.
  final String id;

  /// The ID of the user this analysis belongs to.
  final String userId;

  /// The full analysis response, stored as a serialized JSON string.
  final String analysisData;

  /// The timestamp when the analysis was performed and stored.
  final DateTime createdAt;
  const AnalysisResult(
      {required this.id,
      required this.userId,
      required this.analysisData,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['analysis_data'] = Variable<String>(analysisData);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AnalysisResultsCompanion toCompanion(bool nullToAbsent) {
    return AnalysisResultsCompanion(
      id: Value(id),
      userId: Value(userId),
      analysisData: Value(analysisData),
      createdAt: Value(createdAt),
    );
  }

  factory AnalysisResult.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnalysisResult(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      analysisData: serializer.fromJson<String>(json['analysisData']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'analysisData': serializer.toJson<String>(analysisData),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AnalysisResult copyWith(
          {String? id,
          String? userId,
          String? analysisData,
          DateTime? createdAt}) =>
      AnalysisResult(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        analysisData: analysisData ?? this.analysisData,
        createdAt: createdAt ?? this.createdAt,
      );
  AnalysisResult copyWithCompanion(AnalysisResultsCompanion data) {
    return AnalysisResult(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      analysisData: data.analysisData.present
          ? data.analysisData.value
          : this.analysisData,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnalysisResult(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('analysisData: $analysisData, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, analysisData, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnalysisResult &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.analysisData == this.analysisData &&
          other.createdAt == this.createdAt);
}

class AnalysisResultsCompanion extends UpdateCompanion<AnalysisResult> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> analysisData;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AnalysisResultsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.analysisData = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnalysisResultsCompanion.insert({
    required String id,
    required String userId,
    required String analysisData,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        analysisData = Value(analysisData),
        createdAt = Value(createdAt);
  static Insertable<AnalysisResult> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? analysisData,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (analysisData != null) 'analysis_data': analysisData,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnalysisResultsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? analysisData,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AnalysisResultsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      analysisData: analysisData ?? this.analysisData,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (analysisData.present) {
      map['analysis_data'] = Variable<String>(analysisData.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnalysisResultsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('analysisData: $analysisData, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $ExchangeRatesTable exchangeRates = $ExchangeRatesTable(this);
  late final $FinancialGoalsTable financialGoals = $FinancialGoalsTable(this);
  late final $GoalHistoryTable goalHistory = $GoalHistoryTable(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  late final $AnalysisResultsTable analysisResults =
      $AnalysisResultsTable(this);
  late final AnalysisResultDao analysisResultDao =
      AnalysisResultDao(this as AppDatabase);
  late final AppSettingsDao appSettingsDao =
      AppSettingsDao(this as AppDatabase);
  late final ExchangeRatesDao exchangeRatesDao =
      ExchangeRatesDao(this as AppDatabase);
  late final UserProfilesDao userProfilesDao =
      UserProfilesDao(this as AppDatabase);
  late final BudgetsDao budgetsDao = BudgetsDao(this as AppDatabase);
  late final ExpensesDao expensesDao = ExpensesDao(this as AppDatabase);
  late final FinancialGoalsDao financialGoalsDao =
      FinancialGoalsDao(this as AppDatabase);
  late final GoalHistoryDao goalHistoryDao =
      GoalHistoryDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        expenses,
        budgets,
        appSettings,
        exchangeRates,
        financialGoals,
        goalHistory,
        userProfiles,
        analysisResults
      ];
}

typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  required String id,
  required String remark,
  required double amount,
  required DateTime date,
  required String category,
  required String method,
  Value<String?> description,
  Value<String> currency,
  Value<String?> recurringDetailsJson,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<String> id,
  Value<String> remark,
  Value<double> amount,
  Value<DateTime> date,
  Value<String> category,
  Value<String> method,
  Value<String?> description,
  Value<String> currency,
  Value<String?> recurringDetailsJson,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remark => $composableBuilder(
      column: $table.remark, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurringDetailsJson => $composableBuilder(
      column: $table.recurringDetailsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remark => $composableBuilder(
      column: $table.remark, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurringDetailsJson => $composableBuilder(
      column: $table.recurringDetailsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remark =>
      $composableBuilder(column: $table.remark, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get recurringDetailsJson => $composableBuilder(
      column: $table.recurringDetailsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ExpensesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableAnnotationComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder,
    (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
    Expense,
    PrefetchHooks Function()> {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> remark = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> recurringDetailsJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpensesCompanion(
            id: id,
            remark: remark,
            amount: amount,
            date: date,
            category: category,
            method: method,
            description: description,
            currency: currency,
            recurringDetailsJson: recurringDetailsJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String remark,
            required double amount,
            required DateTime date,
            required String category,
            required String method,
            Value<String?> description = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> recurringDetailsJson = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpensesCompanion.insert(
            id: id,
            remark: remark,
            amount: amount,
            date: date,
            category: category,
            method: method,
            description: description,
            currency: currency,
            recurringDetailsJson: recurringDetailsJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExpensesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableAnnotationComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder,
    (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
    Expense,
    PrefetchHooks Function()>;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  required String monthId,
  required double total,
  required double left,
  required String categoriesJson,
  Value<double> saving,
  Value<String> currency,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<String> monthId,
  Value<double> total,
  Value<double> left,
  Value<String> categoriesJson,
  Value<double> saving,
  Value<String> currency,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get monthId => $composableBuilder(
      column: $table.monthId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get left => $composableBuilder(
      column: $table.left, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoriesJson => $composableBuilder(
      column: $table.categoriesJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get saving => $composableBuilder(
      column: $table.saving, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get monthId => $composableBuilder(
      column: $table.monthId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get left => $composableBuilder(
      column: $table.left, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoriesJson => $composableBuilder(
      column: $table.categoriesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get saving => $composableBuilder(
      column: $table.saving, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get monthId =>
      $composableBuilder(column: $table.monthId, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<double> get left =>
      $composableBuilder(column: $table.left, builder: (column) => column);

  GeneratedColumn<String> get categoriesJson => $composableBuilder(
      column: $table.categoriesJson, builder: (column) => column);

  GeneratedColumn<double> get saving =>
      $composableBuilder(column: $table.saving, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BudgetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableAnnotationComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder,
    (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
    Budget,
    PrefetchHooks Function()> {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> monthId = const Value.absent(),
            Value<double> total = const Value.absent(),
            Value<double> left = const Value.absent(),
            Value<String> categoriesJson = const Value.absent(),
            Value<double> saving = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion(
            monthId: monthId,
            total: total,
            left: left,
            categoriesJson: categoriesJson,
            saving: saving,
            currency: currency,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String monthId,
            required double total,
            required double left,
            required String categoriesJson,
            Value<double> saving = const Value.absent(),
            Value<String> currency = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion.insert(
            monthId: monthId,
            total: total,
            left: left,
            categoriesJson: categoriesJson,
            saving: saving,
            currency: currency,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BudgetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableAnnotationComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder,
    (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
    Budget,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> id,
  Value<String> theme,
  Value<String> currency,
  Value<bool> allowNotification,
  Value<bool> autoBudget,
  Value<bool> improveAccuracy,
  Value<bool> syncEnabled,
  required DateTime updatedAt,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> id,
  Value<String> theme,
  Value<String> currency,
  Value<bool> allowNotification,
  Value<bool> autoBudget,
  Value<bool> improveAccuracy,
  Value<bool> syncEnabled,
  Value<DateTime> updatedAt,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get theme => $composableBuilder(
      column: $table.theme, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get allowNotification => $composableBuilder(
      column: $table.allowNotification,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get autoBudget => $composableBuilder(
      column: $table.autoBudget, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get improveAccuracy => $composableBuilder(
      column: $table.improveAccuracy,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get syncEnabled => $composableBuilder(
      column: $table.syncEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get theme => $composableBuilder(
      column: $table.theme, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get allowNotification => $composableBuilder(
      column: $table.allowNotification,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get autoBudget => $composableBuilder(
      column: $table.autoBudget, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get improveAccuracy => $composableBuilder(
      column: $table.improveAccuracy,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get syncEnabled => $composableBuilder(
      column: $table.syncEnabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<bool> get allowNotification => $composableBuilder(
      column: $table.allowNotification, builder: (column) => column);

  GeneratedColumn<bool> get autoBudget => $composableBuilder(
      column: $table.autoBudget, builder: (column) => column);

  GeneratedColumn<bool> get improveAccuracy => $composableBuilder(
      column: $table.improveAccuracy, builder: (column) => column);

  GeneratedColumn<bool> get syncEnabled => $composableBuilder(
      column: $table.syncEnabled, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> theme = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<bool> allowNotification = const Value.absent(),
            Value<bool> autoBudget = const Value.absent(),
            Value<bool> improveAccuracy = const Value.absent(),
            Value<bool> syncEnabled = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            id: id,
            theme: theme,
            currency: currency,
            allowNotification: allowNotification,
            autoBudget: autoBudget,
            improveAccuracy: improveAccuracy,
            syncEnabled: syncEnabled,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> theme = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<bool> allowNotification = const Value.absent(),
            Value<bool> autoBudget = const Value.absent(),
            Value<bool> improveAccuracy = const Value.absent(),
            Value<bool> syncEnabled = const Value.absent(),
            required DateTime updatedAt,
          }) =>
              AppSettingsCompanion.insert(
            id: id,
            theme: theme,
            currency: currency,
            allowNotification: allowNotification,
            autoBudget: autoBudget,
            improveAccuracy: improveAccuracy,
            syncEnabled: syncEnabled,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;
typedef $$ExchangeRatesTableCreateCompanionBuilder = ExchangeRatesCompanion
    Function({
  required String baseCurrency,
  required String ratesJson,
  required DateTime timestamp,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ExchangeRatesTableUpdateCompanionBuilder = ExchangeRatesCompanion
    Function({
  Value<String> baseCurrency,
  Value<String> ratesJson,
  Value<DateTime> timestamp,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ExchangeRatesTableFilterComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get baseCurrency => $composableBuilder(
      column: $table.baseCurrency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ratesJson => $composableBuilder(
      column: $table.ratesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ExchangeRatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get baseCurrency => $composableBuilder(
      column: $table.baseCurrency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ratesJson => $composableBuilder(
      column: $table.ratesJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ExchangeRatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get baseCurrency => $composableBuilder(
      column: $table.baseCurrency, builder: (column) => column);

  GeneratedColumn<String> get ratesJson =>
      $composableBuilder(column: $table.ratesJson, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ExchangeRatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExchangeRatesTable,
    ExchangeRate,
    $$ExchangeRatesTableFilterComposer,
    $$ExchangeRatesTableOrderingComposer,
    $$ExchangeRatesTableAnnotationComposer,
    $$ExchangeRatesTableCreateCompanionBuilder,
    $$ExchangeRatesTableUpdateCompanionBuilder,
    (
      ExchangeRate,
      BaseReferences<_$AppDatabase, $ExchangeRatesTable, ExchangeRate>
    ),
    ExchangeRate,
    PrefetchHooks Function()> {
  $$ExchangeRatesTableTableManager(_$AppDatabase db, $ExchangeRatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExchangeRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExchangeRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExchangeRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> baseCurrency = const Value.absent(),
            Value<String> ratesJson = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExchangeRatesCompanion(
            baseCurrency: baseCurrency,
            ratesJson: ratesJson,
            timestamp: timestamp,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String baseCurrency,
            required String ratesJson,
            required DateTime timestamp,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ExchangeRatesCompanion.insert(
            baseCurrency: baseCurrency,
            ratesJson: ratesJson,
            timestamp: timestamp,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExchangeRatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExchangeRatesTable,
    ExchangeRate,
    $$ExchangeRatesTableFilterComposer,
    $$ExchangeRatesTableOrderingComposer,
    $$ExchangeRatesTableAnnotationComposer,
    $$ExchangeRatesTableCreateCompanionBuilder,
    $$ExchangeRatesTableUpdateCompanionBuilder,
    (
      ExchangeRate,
      BaseReferences<_$AppDatabase, $ExchangeRatesTable, ExchangeRate>
    ),
    ExchangeRate,
    PrefetchHooks Function()>;
typedef $$FinancialGoalsTableCreateCompanionBuilder = FinancialGoalsCompanion
    Function({
  required String id,
  required String title,
  required double targetAmount,
  required double currentAmount,
  required DateTime deadline,
  required String iconName,
  required String colorValue,
  Value<bool> isCompleted,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$FinancialGoalsTableUpdateCompanionBuilder = FinancialGoalsCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<double> targetAmount,
  Value<double> currentAmount,
  Value<DateTime> deadline,
  Value<String> iconName,
  Value<String> colorValue,
  Value<bool> isCompleted,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$FinancialGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $FinancialGoalsTable> {
  $$FinancialGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get currentAmount => $composableBuilder(
      column: $table.currentAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deadline => $composableBuilder(
      column: $table.deadline, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconName => $composableBuilder(
      column: $table.iconName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$FinancialGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinancialGoalsTable> {
  $$FinancialGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get currentAmount => $composableBuilder(
      column: $table.currentAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deadline => $composableBuilder(
      column: $table.deadline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconName => $composableBuilder(
      column: $table.iconName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$FinancialGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinancialGoalsTable> {
  $$FinancialGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => column);

  GeneratedColumn<double> get currentAmount => $composableBuilder(
      column: $table.currentAmount, builder: (column) => column);

  GeneratedColumn<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<String> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FinancialGoalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FinancialGoalsTable,
    FinancialGoal,
    $$FinancialGoalsTableFilterComposer,
    $$FinancialGoalsTableOrderingComposer,
    $$FinancialGoalsTableAnnotationComposer,
    $$FinancialGoalsTableCreateCompanionBuilder,
    $$FinancialGoalsTableUpdateCompanionBuilder,
    (
      FinancialGoal,
      BaseReferences<_$AppDatabase, $FinancialGoalsTable, FinancialGoal>
    ),
    FinancialGoal,
    PrefetchHooks Function()> {
  $$FinancialGoalsTableTableManager(
      _$AppDatabase db, $FinancialGoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinancialGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinancialGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinancialGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<double> targetAmount = const Value.absent(),
            Value<double> currentAmount = const Value.absent(),
            Value<DateTime> deadline = const Value.absent(),
            Value<String> iconName = const Value.absent(),
            Value<String> colorValue = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FinancialGoalsCompanion(
            id: id,
            title: title,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            deadline: deadline,
            iconName: iconName,
            colorValue: colorValue,
            isCompleted: isCompleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required double targetAmount,
            required double currentAmount,
            required DateTime deadline,
            required String iconName,
            required String colorValue,
            Value<bool> isCompleted = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              FinancialGoalsCompanion.insert(
            id: id,
            title: title,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            deadline: deadline,
            iconName: iconName,
            colorValue: colorValue,
            isCompleted: isCompleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FinancialGoalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FinancialGoalsTable,
    FinancialGoal,
    $$FinancialGoalsTableFilterComposer,
    $$FinancialGoalsTableOrderingComposer,
    $$FinancialGoalsTableAnnotationComposer,
    $$FinancialGoalsTableCreateCompanionBuilder,
    $$FinancialGoalsTableUpdateCompanionBuilder,
    (
      FinancialGoal,
      BaseReferences<_$AppDatabase, $FinancialGoalsTable, FinancialGoal>
    ),
    FinancialGoal,
    PrefetchHooks Function()>;
typedef $$GoalHistoryTableCreateCompanionBuilder = GoalHistoryCompanion
    Function({
  required String id,
  required String goalId,
  required String title,
  required double targetAmount,
  required double finalAmount,
  required DateTime createdDate,
  required DateTime completedDate,
  required String iconName,
  required String colorValue,
  Value<String?> notes,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$GoalHistoryTableUpdateCompanionBuilder = GoalHistoryCompanion
    Function({
  Value<String> id,
  Value<String> goalId,
  Value<String> title,
  Value<double> targetAmount,
  Value<double> finalAmount,
  Value<DateTime> createdDate,
  Value<DateTime> completedDate,
  Value<String> iconName,
  Value<String> colorValue,
  Value<String?> notes,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$GoalHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $GoalHistoryTable> {
  $$GoalHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get goalId => $composableBuilder(
      column: $table.goalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get finalAmount => $composableBuilder(
      column: $table.finalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdDate => $composableBuilder(
      column: $table.createdDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedDate => $composableBuilder(
      column: $table.completedDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconName => $composableBuilder(
      column: $table.iconName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$GoalHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalHistoryTable> {
  $$GoalHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get goalId => $composableBuilder(
      column: $table.goalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get finalAmount => $composableBuilder(
      column: $table.finalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdDate => $composableBuilder(
      column: $table.createdDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedDate => $composableBuilder(
      column: $table.completedDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconName => $composableBuilder(
      column: $table.iconName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$GoalHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalHistoryTable> {
  $$GoalHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => column);

  GeneratedColumn<double> get finalAmount => $composableBuilder(
      column: $table.finalAmount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdDate => $composableBuilder(
      column: $table.createdDate, builder: (column) => column);

  GeneratedColumn<DateTime> get completedDate => $composableBuilder(
      column: $table.completedDate, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<String> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$GoalHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GoalHistoryTable,
    GoalHistoryData,
    $$GoalHistoryTableFilterComposer,
    $$GoalHistoryTableOrderingComposer,
    $$GoalHistoryTableAnnotationComposer,
    $$GoalHistoryTableCreateCompanionBuilder,
    $$GoalHistoryTableUpdateCompanionBuilder,
    (
      GoalHistoryData,
      BaseReferences<_$AppDatabase, $GoalHistoryTable, GoalHistoryData>
    ),
    GoalHistoryData,
    PrefetchHooks Function()> {
  $$GoalHistoryTableTableManager(_$AppDatabase db, $GoalHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> goalId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<double> targetAmount = const Value.absent(),
            Value<double> finalAmount = const Value.absent(),
            Value<DateTime> createdDate = const Value.absent(),
            Value<DateTime> completedDate = const Value.absent(),
            Value<String> iconName = const Value.absent(),
            Value<String> colorValue = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalHistoryCompanion(
            id: id,
            goalId: goalId,
            title: title,
            targetAmount: targetAmount,
            finalAmount: finalAmount,
            createdDate: createdDate,
            completedDate: completedDate,
            iconName: iconName,
            colorValue: colorValue,
            notes: notes,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String goalId,
            required String title,
            required double targetAmount,
            required double finalAmount,
            required DateTime createdDate,
            required DateTime completedDate,
            required String iconName,
            required String colorValue,
            Value<String?> notes = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalHistoryCompanion.insert(
            id: id,
            goalId: goalId,
            title: title,
            targetAmount: targetAmount,
            finalAmount: finalAmount,
            createdDate: createdDate,
            completedDate: completedDate,
            iconName: iconName,
            colorValue: colorValue,
            notes: notes,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GoalHistoryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GoalHistoryTable,
    GoalHistoryData,
    $$GoalHistoryTableFilterComposer,
    $$GoalHistoryTableOrderingComposer,
    $$GoalHistoryTableAnnotationComposer,
    $$GoalHistoryTableCreateCompanionBuilder,
    $$GoalHistoryTableUpdateCompanionBuilder,
    (
      GoalHistoryData,
      BaseReferences<_$AppDatabase, $GoalHistoryTable, GoalHistoryData>
    ),
    GoalHistoryData,
    PrefetchHooks Function()>;
typedef $$UserProfilesTableCreateCompanionBuilder = UserProfilesCompanion
    Function({
  required String id,
  required String userId,
  required String incomeStability,
  required String spendingMentality,
  required String riskAppetite,
  required double monthlyIncome,
  required double emergencyFundTarget,
  required String financialLiteracy,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> dataConsentAcceptedAt,
  required bool isComplete,
  Value<int> rowid,
});
typedef $$UserProfilesTableUpdateCompanionBuilder = UserProfilesCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> incomeStability,
  Value<String> spendingMentality,
  Value<String> riskAppetite,
  Value<double> monthlyIncome,
  Value<double> emergencyFundTarget,
  Value<String> financialLiteracy,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> dataConsentAcceptedAt,
  Value<bool> isComplete,
  Value<int> rowid,
});

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get incomeStability => $composableBuilder(
      column: $table.incomeStability,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get spendingMentality => $composableBuilder(
      column: $table.spendingMentality,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get riskAppetite => $composableBuilder(
      column: $table.riskAppetite, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get monthlyIncome => $composableBuilder(
      column: $table.monthlyIncome, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get emergencyFundTarget => $composableBuilder(
      column: $table.emergencyFundTarget,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get financialLiteracy => $composableBuilder(
      column: $table.financialLiteracy,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dataConsentAcceptedAt => $composableBuilder(
      column: $table.dataConsentAcceptedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isComplete => $composableBuilder(
      column: $table.isComplete, builder: (column) => ColumnFilters(column));
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get incomeStability => $composableBuilder(
      column: $table.incomeStability,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get spendingMentality => $composableBuilder(
      column: $table.spendingMentality,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get riskAppetite => $composableBuilder(
      column: $table.riskAppetite,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get monthlyIncome => $composableBuilder(
      column: $table.monthlyIncome,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get emergencyFundTarget => $composableBuilder(
      column: $table.emergencyFundTarget,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get financialLiteracy => $composableBuilder(
      column: $table.financialLiteracy,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dataConsentAcceptedAt => $composableBuilder(
      column: $table.dataConsentAcceptedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isComplete => $composableBuilder(
      column: $table.isComplete, builder: (column) => ColumnOrderings(column));
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get incomeStability => $composableBuilder(
      column: $table.incomeStability, builder: (column) => column);

  GeneratedColumn<String> get spendingMentality => $composableBuilder(
      column: $table.spendingMentality, builder: (column) => column);

  GeneratedColumn<String> get riskAppetite => $composableBuilder(
      column: $table.riskAppetite, builder: (column) => column);

  GeneratedColumn<double> get monthlyIncome => $composableBuilder(
      column: $table.monthlyIncome, builder: (column) => column);

  GeneratedColumn<double> get emergencyFundTarget => $composableBuilder(
      column: $table.emergencyFundTarget, builder: (column) => column);

  GeneratedColumn<String> get financialLiteracy => $composableBuilder(
      column: $table.financialLiteracy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get dataConsentAcceptedAt => $composableBuilder(
      column: $table.dataConsentAcceptedAt, builder: (column) => column);

  GeneratedColumn<bool> get isComplete => $composableBuilder(
      column: $table.isComplete, builder: (column) => column);
}

class $$UserProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserProfilesTable,
    UserProfile,
    $$UserProfilesTableFilterComposer,
    $$UserProfilesTableOrderingComposer,
    $$UserProfilesTableAnnotationComposer,
    $$UserProfilesTableCreateCompanionBuilder,
    $$UserProfilesTableUpdateCompanionBuilder,
    (
      UserProfile,
      BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>
    ),
    UserProfile,
    PrefetchHooks Function()> {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> incomeStability = const Value.absent(),
            Value<String> spendingMentality = const Value.absent(),
            Value<String> riskAppetite = const Value.absent(),
            Value<double> monthlyIncome = const Value.absent(),
            Value<double> emergencyFundTarget = const Value.absent(),
            Value<String> financialLiteracy = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> dataConsentAcceptedAt = const Value.absent(),
            Value<bool> isComplete = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserProfilesCompanion(
            id: id,
            userId: userId,
            incomeStability: incomeStability,
            spendingMentality: spendingMentality,
            riskAppetite: riskAppetite,
            monthlyIncome: monthlyIncome,
            emergencyFundTarget: emergencyFundTarget,
            financialLiteracy: financialLiteracy,
            createdAt: createdAt,
            updatedAt: updatedAt,
            dataConsentAcceptedAt: dataConsentAcceptedAt,
            isComplete: isComplete,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String incomeStability,
            required String spendingMentality,
            required String riskAppetite,
            required double monthlyIncome,
            required double emergencyFundTarget,
            required String financialLiteracy,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> dataConsentAcceptedAt = const Value.absent(),
            required bool isComplete,
            Value<int> rowid = const Value.absent(),
          }) =>
              UserProfilesCompanion.insert(
            id: id,
            userId: userId,
            incomeStability: incomeStability,
            spendingMentality: spendingMentality,
            riskAppetite: riskAppetite,
            monthlyIncome: monthlyIncome,
            emergencyFundTarget: emergencyFundTarget,
            financialLiteracy: financialLiteracy,
            createdAt: createdAt,
            updatedAt: updatedAt,
            dataConsentAcceptedAt: dataConsentAcceptedAt,
            isComplete: isComplete,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserProfilesTable,
    UserProfile,
    $$UserProfilesTableFilterComposer,
    $$UserProfilesTableOrderingComposer,
    $$UserProfilesTableAnnotationComposer,
    $$UserProfilesTableCreateCompanionBuilder,
    $$UserProfilesTableUpdateCompanionBuilder,
    (
      UserProfile,
      BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>
    ),
    UserProfile,
    PrefetchHooks Function()>;
typedef $$AnalysisResultsTableCreateCompanionBuilder = AnalysisResultsCompanion
    Function({
  required String id,
  required String userId,
  required String analysisData,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$AnalysisResultsTableUpdateCompanionBuilder = AnalysisResultsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> analysisData,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$AnalysisResultsTableFilterComposer
    extends Composer<_$AppDatabase, $AnalysisResultsTable> {
  $$AnalysisResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get analysisData => $composableBuilder(
      column: $table.analysisData, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AnalysisResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnalysisResultsTable> {
  $$AnalysisResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get analysisData => $composableBuilder(
      column: $table.analysisData,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AnalysisResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnalysisResultsTable> {
  $$AnalysisResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get analysisData => $composableBuilder(
      column: $table.analysisData, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AnalysisResultsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AnalysisResultsTable,
    AnalysisResult,
    $$AnalysisResultsTableFilterComposer,
    $$AnalysisResultsTableOrderingComposer,
    $$AnalysisResultsTableAnnotationComposer,
    $$AnalysisResultsTableCreateCompanionBuilder,
    $$AnalysisResultsTableUpdateCompanionBuilder,
    (
      AnalysisResult,
      BaseReferences<_$AppDatabase, $AnalysisResultsTable, AnalysisResult>
    ),
    AnalysisResult,
    PrefetchHooks Function()> {
  $$AnalysisResultsTableTableManager(
      _$AppDatabase db, $AnalysisResultsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnalysisResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnalysisResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnalysisResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> analysisData = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AnalysisResultsCompanion(
            id: id,
            userId: userId,
            analysisData: analysisData,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String analysisData,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AnalysisResultsCompanion.insert(
            id: id,
            userId: userId,
            analysisData: analysisData,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AnalysisResultsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AnalysisResultsTable,
    AnalysisResult,
    $$AnalysisResultsTableFilterComposer,
    $$AnalysisResultsTableOrderingComposer,
    $$AnalysisResultsTableAnnotationComposer,
    $$AnalysisResultsTableCreateCompanionBuilder,
    $$AnalysisResultsTableUpdateCompanionBuilder,
    (
      AnalysisResult,
      BaseReferences<_$AppDatabase, $AnalysisResultsTable, AnalysisResult>
    ),
    AnalysisResult,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$ExchangeRatesTableTableManager get exchangeRates =>
      $$ExchangeRatesTableTableManager(_db, _db.exchangeRates);
  $$FinancialGoalsTableTableManager get financialGoals =>
      $$FinancialGoalsTableTableManager(_db, _db.financialGoals);
  $$GoalHistoryTableTableManager get goalHistory =>
      $$GoalHistoryTableTableManager(_db, _db.goalHistory);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
  $$AnalysisResultsTableTableManager get analysisResults =>
      $$AnalysisResultsTableTableManager(_db, _db.analysisResults);
}
