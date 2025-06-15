// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
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
  static const VerificationMeta _recurringExpenseIdMeta =
      const VerificationMeta('recurringExpenseId');
  @override
  late final GeneratedColumn<String> recurringExpenseId =
      GeneratedColumn<String>('recurring_expense_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        remark,
        amount,
        date,
        category,
        method,
        description,
        currency,
        recurringExpenseId,
        isSynced,
        lastModified
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
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
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
    if (data.containsKey('recurring_expense_id')) {
      context.handle(
          _recurringExpenseIdMeta,
          recurringExpenseId.isAcceptableOrUnknown(
              data['recurring_expense_id']!, _recurringExpenseIdMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedMeta);
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
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
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
      recurringExpenseId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}recurring_expense_id']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      lastModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final String id;
  final String userId;
  final String remark;
  final double amount;
  final DateTime date;
  final String category;
  final String method;
  final String? description;
  final String currency;
  final String? recurringExpenseId;
  final bool isSynced;
  final DateTime lastModified;
  const Expense(
      {required this.id,
      required this.userId,
      required this.remark,
      required this.amount,
      required this.date,
      required this.category,
      required this.method,
      this.description,
      required this.currency,
      this.recurringExpenseId,
      required this.isSynced,
      required this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['remark'] = Variable<String>(remark);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<DateTime>(date);
    map['category'] = Variable<String>(category);
    map['method'] = Variable<String>(method);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || recurringExpenseId != null) {
      map['recurring_expense_id'] = Variable<String>(recurringExpenseId);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      userId: Value(userId),
      remark: Value(remark),
      amount: Value(amount),
      date: Value(date),
      category: Value(category),
      method: Value(method),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      currency: Value(currency),
      recurringExpenseId: recurringExpenseId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringExpenseId),
      isSynced: Value(isSynced),
      lastModified: Value(lastModified),
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      remark: serializer.fromJson<String>(json['remark']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      category: serializer.fromJson<String>(json['category']),
      method: serializer.fromJson<String>(json['method']),
      description: serializer.fromJson<String?>(json['description']),
      currency: serializer.fromJson<String>(json['currency']),
      recurringExpenseId:
          serializer.fromJson<String?>(json['recurringExpenseId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'remark': serializer.toJson<String>(remark),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<DateTime>(date),
      'category': serializer.toJson<String>(category),
      'method': serializer.toJson<String>(method),
      'description': serializer.toJson<String?>(description),
      'currency': serializer.toJson<String>(currency),
      'recurringExpenseId': serializer.toJson<String?>(recurringExpenseId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  Expense copyWith(
          {String? id,
          String? userId,
          String? remark,
          double? amount,
          DateTime? date,
          String? category,
          String? method,
          Value<String?> description = const Value.absent(),
          String? currency,
          Value<String?> recurringExpenseId = const Value.absent(),
          bool? isSynced,
          DateTime? lastModified}) =>
      Expense(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        remark: remark ?? this.remark,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        category: category ?? this.category,
        method: method ?? this.method,
        description: description.present ? description.value : this.description,
        currency: currency ?? this.currency,
        recurringExpenseId: recurringExpenseId.present
            ? recurringExpenseId.value
            : this.recurringExpenseId,
        isSynced: isSynced ?? this.isSynced,
        lastModified: lastModified ?? this.lastModified,
      );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      remark: data.remark.present ? data.remark.value : this.remark,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      category: data.category.present ? data.category.value : this.category,
      method: data.method.present ? data.method.value : this.method,
      description:
          data.description.present ? data.description.value : this.description,
      currency: data.currency.present ? data.currency.value : this.currency,
      recurringExpenseId: data.recurringExpenseId.present
          ? data.recurringExpenseId.value
          : this.recurringExpenseId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('remark: $remark, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('method: $method, ')
          ..write('description: $description, ')
          ..write('currency: $currency, ')
          ..write('recurringExpenseId: $recurringExpenseId, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      remark,
      amount,
      date,
      category,
      method,
      description,
      currency,
      recurringExpenseId,
      isSynced,
      lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.remark == this.remark &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.category == this.category &&
          other.method == this.method &&
          other.description == this.description &&
          other.currency == this.currency &&
          other.recurringExpenseId == this.recurringExpenseId &&
          other.isSynced == this.isSynced &&
          other.lastModified == this.lastModified);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> remark;
  final Value<double> amount;
  final Value<DateTime> date;
  final Value<String> category;
  final Value<String> method;
  final Value<String?> description;
  final Value<String> currency;
  final Value<String?> recurringExpenseId;
  final Value<bool> isSynced;
  final Value<DateTime> lastModified;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.remark = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.category = const Value.absent(),
    this.method = const Value.absent(),
    this.description = const Value.absent(),
    this.currency = const Value.absent(),
    this.recurringExpenseId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required String userId,
    required String remark,
    required double amount,
    required DateTime date,
    required String category,
    required String method,
    this.description = const Value.absent(),
    this.currency = const Value.absent(),
    this.recurringExpenseId = const Value.absent(),
    this.isSynced = const Value.absent(),
    required DateTime lastModified,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        remark = Value(remark),
        amount = Value(amount),
        date = Value(date),
        category = Value(category),
        method = Value(method),
        lastModified = Value(lastModified);
  static Insertable<Expense> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? remark,
    Expression<double>? amount,
    Expression<DateTime>? date,
    Expression<String>? category,
    Expression<String>? method,
    Expression<String>? description,
    Expression<String>? currency,
    Expression<String>? recurringExpenseId,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (remark != null) 'remark': remark,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (category != null) 'category': category,
      if (method != null) 'method': method,
      if (description != null) 'description': description,
      if (currency != null) 'currency': currency,
      if (recurringExpenseId != null)
        'recurring_expense_id': recurringExpenseId,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? remark,
      Value<double>? amount,
      Value<DateTime>? date,
      Value<String>? category,
      Value<String>? method,
      Value<String?>? description,
      Value<String>? currency,
      Value<String?>? recurringExpenseId,
      Value<bool>? isSynced,
      Value<DateTime>? lastModified,
      Value<int>? rowid}) {
    return ExpensesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      remark: remark ?? this.remark,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      method: method ?? this.method,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      recurringExpenseId: recurringExpenseId ?? this.recurringExpenseId,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
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
    if (recurringExpenseId.present) {
      map['recurring_expense_id'] = Variable<String>(recurringExpenseId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
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
          ..write('userId: $userId, ')
          ..write('remark: $remark, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('method: $method, ')
          ..write('description: $description, ')
          ..write('currency: $currency, ')
          ..write('recurringExpenseId: $recurringExpenseId, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified, ')
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
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
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        monthId,
        userId,
        total,
        left,
        categoriesJson,
        saving,
        isSynced,
        lastModified
      ];
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
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
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
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {monthId, userId};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      monthId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}month_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total'])!,
      left: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}left'])!,
      categoriesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}categories_json'])!,
      saving: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}saving'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      lastModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final String monthId;
  final String userId;
  final double total;
  final double left;
  final String categoriesJson;
  final double saving;
  final bool isSynced;
  final DateTime lastModified;
  const Budget(
      {required this.monthId,
      required this.userId,
      required this.total,
      required this.left,
      required this.categoriesJson,
      required this.saving,
      required this.isSynced,
      required this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['month_id'] = Variable<String>(monthId);
    map['user_id'] = Variable<String>(userId);
    map['total'] = Variable<double>(total);
    map['left'] = Variable<double>(left);
    map['categories_json'] = Variable<String>(categoriesJson);
    map['saving'] = Variable<double>(saving);
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      monthId: Value(monthId),
      userId: Value(userId),
      total: Value(total),
      left: Value(left),
      categoriesJson: Value(categoriesJson),
      saving: Value(saving),
      isSynced: Value(isSynced),
      lastModified: Value(lastModified),
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      monthId: serializer.fromJson<String>(json['monthId']),
      userId: serializer.fromJson<String>(json['userId']),
      total: serializer.fromJson<double>(json['total']),
      left: serializer.fromJson<double>(json['left']),
      categoriesJson: serializer.fromJson<String>(json['categoriesJson']),
      saving: serializer.fromJson<double>(json['saving']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'monthId': serializer.toJson<String>(monthId),
      'userId': serializer.toJson<String>(userId),
      'total': serializer.toJson<double>(total),
      'left': serializer.toJson<double>(left),
      'categoriesJson': serializer.toJson<String>(categoriesJson),
      'saving': serializer.toJson<double>(saving),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  Budget copyWith(
          {String? monthId,
          String? userId,
          double? total,
          double? left,
          String? categoriesJson,
          double? saving,
          bool? isSynced,
          DateTime? lastModified}) =>
      Budget(
        monthId: monthId ?? this.monthId,
        userId: userId ?? this.userId,
        total: total ?? this.total,
        left: left ?? this.left,
        categoriesJson: categoriesJson ?? this.categoriesJson,
        saving: saving ?? this.saving,
        isSynced: isSynced ?? this.isSynced,
        lastModified: lastModified ?? this.lastModified,
      );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      monthId: data.monthId.present ? data.monthId.value : this.monthId,
      userId: data.userId.present ? data.userId.value : this.userId,
      total: data.total.present ? data.total.value : this.total,
      left: data.left.present ? data.left.value : this.left,
      categoriesJson: data.categoriesJson.present
          ? data.categoriesJson.value
          : this.categoriesJson,
      saving: data.saving.present ? data.saving.value : this.saving,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('monthId: $monthId, ')
          ..write('userId: $userId, ')
          ..write('total: $total, ')
          ..write('left: $left, ')
          ..write('categoriesJson: $categoriesJson, ')
          ..write('saving: $saving, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(monthId, userId, total, left, categoriesJson,
      saving, isSynced, lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.monthId == this.monthId &&
          other.userId == this.userId &&
          other.total == this.total &&
          other.left == this.left &&
          other.categoriesJson == this.categoriesJson &&
          other.saving == this.saving &&
          other.isSynced == this.isSynced &&
          other.lastModified == this.lastModified);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<String> monthId;
  final Value<String> userId;
  final Value<double> total;
  final Value<double> left;
  final Value<String> categoriesJson;
  final Value<double> saving;
  final Value<bool> isSynced;
  final Value<DateTime> lastModified;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.monthId = const Value.absent(),
    this.userId = const Value.absent(),
    this.total = const Value.absent(),
    this.left = const Value.absent(),
    this.categoriesJson = const Value.absent(),
    this.saving = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String monthId,
    required String userId,
    required double total,
    required double left,
    required String categoriesJson,
    this.saving = const Value.absent(),
    this.isSynced = const Value.absent(),
    required DateTime lastModified,
    this.rowid = const Value.absent(),
  })  : monthId = Value(monthId),
        userId = Value(userId),
        total = Value(total),
        left = Value(left),
        categoriesJson = Value(categoriesJson),
        lastModified = Value(lastModified);
  static Insertable<Budget> custom({
    Expression<String>? monthId,
    Expression<String>? userId,
    Expression<double>? total,
    Expression<double>? left,
    Expression<String>? categoriesJson,
    Expression<double>? saving,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (monthId != null) 'month_id': monthId,
      if (userId != null) 'user_id': userId,
      if (total != null) 'total': total,
      if (left != null) 'left': left,
      if (categoriesJson != null) 'categories_json': categoriesJson,
      if (saving != null) 'saving': saving,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith(
      {Value<String>? monthId,
      Value<String>? userId,
      Value<double>? total,
      Value<double>? left,
      Value<String>? categoriesJson,
      Value<double>? saving,
      Value<bool>? isSynced,
      Value<DateTime>? lastModified,
      Value<int>? rowid}) {
    return BudgetsCompanion(
      monthId: monthId ?? this.monthId,
      userId: userId ?? this.userId,
      total: total ?? this.total,
      left: left ?? this.left,
      categoriesJson: categoriesJson ?? this.categoriesJson,
      saving: saving ?? this.saving,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (monthId.present) {
      map['month_id'] = Variable<String>(monthId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
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
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
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
          ..write('userId: $userId, ')
          ..write('total: $total, ')
          ..write('left: $left, ')
          ..write('categoriesJson: $categoriesJson, ')
          ..write('saving: $saving, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, entityType, entityId, userId, operation, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String entityType;
  final String entityId;
  final String userId;
  final String operation;
  final DateTime timestamp;
  const SyncQueueData(
      {required this.id,
      required this.entityType,
      required this.entityId,
      required this.userId,
      required this.operation,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['user_id'] = Variable<String>(userId);
    map['operation'] = Variable<String>(operation);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      userId: Value(userId),
      operation: Value(operation),
      timestamp: Value(timestamp),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      userId: serializer.fromJson<String>(json['userId']),
      operation: serializer.fromJson<String>(json['operation']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'userId': serializer.toJson<String>(userId),
      'operation': serializer.toJson<String>(operation),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  SyncQueueData copyWith(
          {int? id,
          String? entityType,
          String? entityId,
          String? userId,
          String? operation,
          DateTime? timestamp}) =>
      SyncQueueData(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        userId: userId ?? this.userId,
        operation: operation ?? this.operation,
        timestamp: timestamp ?? this.timestamp,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      userId: data.userId.present ? data.userId.value : this.userId,
      operation: data.operation.present ? data.operation.value : this.operation,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('userId: $userId, ')
          ..write('operation: $operation, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entityType, entityId, userId, operation, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.userId == this.userId &&
          other.operation == this.operation &&
          other.timestamp == this.timestamp);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> userId;
  final Value<String> operation;
  final Value<DateTime> timestamp;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.userId = const Value.absent(),
    this.operation = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityId,
    required String userId,
    required String operation,
    required DateTime timestamp,
  })  : entityType = Value(entityType),
        entityId = Value(entityId),
        userId = Value(userId),
        operation = Value(operation),
        timestamp = Value(timestamp);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? userId,
    Expression<String>? operation,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (userId != null) 'user_id': userId,
      if (operation != null) 'operation': operation,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? userId,
      Value<String>? operation,
      Value<DateTime>? timestamp}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      userId: userId ?? this.userId,
      operation: operation ?? this.operation,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('userId: $userId, ')
          ..write('operation: $operation, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $RecurringExpensesTable extends RecurringExpenses
    with TableInfo<$RecurringExpensesTable, RecurringExpense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringExpensesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _frequencyMeta =
      const VerificationMeta('frequency');
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
      'frequency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dayOfMonthMeta =
      const VerificationMeta('dayOfMonth');
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
      'day_of_month', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dayOfWeekMeta =
      const VerificationMeta('dayOfWeek');
  @override
  late final GeneratedColumn<String> dayOfWeek = GeneratedColumn<String>(
      'day_of_week', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _lastProcessedDateMeta =
      const VerificationMeta('lastProcessedDate');
  @override
  late final GeneratedColumn<DateTime> lastProcessedDate =
      GeneratedColumn<DateTime>('last_processed_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _expenseRemarkMeta =
      const VerificationMeta('expenseRemark');
  @override
  late final GeneratedColumn<String> expenseRemark = GeneratedColumn<String>(
      'expense_remark', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expenseAmountMeta =
      const VerificationMeta('expenseAmount');
  @override
  late final GeneratedColumn<double> expenseAmount = GeneratedColumn<double>(
      'expense_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _expenseCategoryIdMeta =
      const VerificationMeta('expenseCategoryId');
  @override
  late final GeneratedColumn<String> expenseCategoryId =
      GeneratedColumn<String>('expense_category_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expensePaymentMethodMeta =
      const VerificationMeta('expensePaymentMethod');
  @override
  late final GeneratedColumn<String> expensePaymentMethod =
      GeneratedColumn<String>('expense_payment_method', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expenseCurrencyMeta =
      const VerificationMeta('expenseCurrency');
  @override
  late final GeneratedColumn<String> expenseCurrency = GeneratedColumn<String>(
      'expense_currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('MYR'));
  static const VerificationMeta _expenseDescriptionMeta =
      const VerificationMeta('expenseDescription');
  @override
  late final GeneratedColumn<String> expenseDescription =
      GeneratedColumn<String>('expense_description', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        frequency,
        dayOfMonth,
        dayOfWeek,
        startDate,
        endDate,
        isActive,
        lastProcessedDate,
        expenseRemark,
        expenseAmount,
        expenseCategoryId,
        expensePaymentMethod,
        expenseCurrency,
        expenseDescription,
        isSynced,
        lastModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_expenses';
  @override
  VerificationContext validateIntegrity(Insertable<RecurringExpense> instance,
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
    if (data.containsKey('frequency')) {
      context.handle(_frequencyMeta,
          frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta));
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
          _dayOfMonthMeta,
          dayOfMonth.isAcceptableOrUnknown(
              data['day_of_month']!, _dayOfMonthMeta));
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
          _dayOfWeekMeta,
          dayOfWeek.isAcceptableOrUnknown(
              data['day_of_week']!, _dayOfWeekMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('last_processed_date')) {
      context.handle(
          _lastProcessedDateMeta,
          lastProcessedDate.isAcceptableOrUnknown(
              data['last_processed_date']!, _lastProcessedDateMeta));
    }
    if (data.containsKey('expense_remark')) {
      context.handle(
          _expenseRemarkMeta,
          expenseRemark.isAcceptableOrUnknown(
              data['expense_remark']!, _expenseRemarkMeta));
    } else if (isInserting) {
      context.missing(_expenseRemarkMeta);
    }
    if (data.containsKey('expense_amount')) {
      context.handle(
          _expenseAmountMeta,
          expenseAmount.isAcceptableOrUnknown(
              data['expense_amount']!, _expenseAmountMeta));
    } else if (isInserting) {
      context.missing(_expenseAmountMeta);
    }
    if (data.containsKey('expense_category_id')) {
      context.handle(
          _expenseCategoryIdMeta,
          expenseCategoryId.isAcceptableOrUnknown(
              data['expense_category_id']!, _expenseCategoryIdMeta));
    } else if (isInserting) {
      context.missing(_expenseCategoryIdMeta);
    }
    if (data.containsKey('expense_payment_method')) {
      context.handle(
          _expensePaymentMethodMeta,
          expensePaymentMethod.isAcceptableOrUnknown(
              data['expense_payment_method']!, _expensePaymentMethodMeta));
    } else if (isInserting) {
      context.missing(_expensePaymentMethodMeta);
    }
    if (data.containsKey('expense_currency')) {
      context.handle(
          _expenseCurrencyMeta,
          expenseCurrency.isAcceptableOrUnknown(
              data['expense_currency']!, _expenseCurrencyMeta));
    }
    if (data.containsKey('expense_description')) {
      context.handle(
          _expenseDescriptionMeta,
          expenseDescription.isAcceptableOrUnknown(
              data['expense_description']!, _expenseDescriptionMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringExpense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringExpense(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      frequency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frequency'])!,
      dayOfMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_of_month']),
      dayOfWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day_of_week']),
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      lastProcessedDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_processed_date']),
      expenseRemark: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}expense_remark'])!,
      expenseAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}expense_amount'])!,
      expenseCategoryId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}expense_category_id'])!,
      expensePaymentMethod: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}expense_payment_method'])!,
      expenseCurrency: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}expense_currency'])!,
      expenseDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}expense_description']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      lastModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $RecurringExpensesTable createAlias(String alias) {
    return $RecurringExpensesTable(attachedDatabase, alias);
  }
}

class RecurringExpense extends DataClass
    implements Insertable<RecurringExpense> {
  final String id;
  final String userId;
  final String frequency;
  final int? dayOfMonth;
  final String? dayOfWeek;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime? lastProcessedDate;
  final String expenseRemark;
  final double expenseAmount;
  final String expenseCategoryId;
  final String expensePaymentMethod;
  final String expenseCurrency;
  final String? expenseDescription;
  final bool isSynced;
  final DateTime lastModified;
  const RecurringExpense(
      {required this.id,
      required this.userId,
      required this.frequency,
      this.dayOfMonth,
      this.dayOfWeek,
      required this.startDate,
      this.endDate,
      required this.isActive,
      this.lastProcessedDate,
      required this.expenseRemark,
      required this.expenseAmount,
      required this.expenseCategoryId,
      required this.expensePaymentMethod,
      required this.expenseCurrency,
      this.expenseDescription,
      required this.isSynced,
      required this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['frequency'] = Variable<String>(frequency);
    if (!nullToAbsent || dayOfMonth != null) {
      map['day_of_month'] = Variable<int>(dayOfMonth);
    }
    if (!nullToAbsent || dayOfWeek != null) {
      map['day_of_week'] = Variable<String>(dayOfWeek);
    }
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || lastProcessedDate != null) {
      map['last_processed_date'] = Variable<DateTime>(lastProcessedDate);
    }
    map['expense_remark'] = Variable<String>(expenseRemark);
    map['expense_amount'] = Variable<double>(expenseAmount);
    map['expense_category_id'] = Variable<String>(expenseCategoryId);
    map['expense_payment_method'] = Variable<String>(expensePaymentMethod);
    map['expense_currency'] = Variable<String>(expenseCurrency);
    if (!nullToAbsent || expenseDescription != null) {
      map['expense_description'] = Variable<String>(expenseDescription);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  RecurringExpensesCompanion toCompanion(bool nullToAbsent) {
    return RecurringExpensesCompanion(
      id: Value(id),
      userId: Value(userId),
      frequency: Value(frequency),
      dayOfMonth: dayOfMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(dayOfMonth),
      dayOfWeek: dayOfWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(dayOfWeek),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      isActive: Value(isActive),
      lastProcessedDate: lastProcessedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastProcessedDate),
      expenseRemark: Value(expenseRemark),
      expenseAmount: Value(expenseAmount),
      expenseCategoryId: Value(expenseCategoryId),
      expensePaymentMethod: Value(expensePaymentMethod),
      expenseCurrency: Value(expenseCurrency),
      expenseDescription: expenseDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(expenseDescription),
      isSynced: Value(isSynced),
      lastModified: Value(lastModified),
    );
  }

  factory RecurringExpense.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringExpense(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      frequency: serializer.fromJson<String>(json['frequency']),
      dayOfMonth: serializer.fromJson<int?>(json['dayOfMonth']),
      dayOfWeek: serializer.fromJson<String?>(json['dayOfWeek']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      lastProcessedDate:
          serializer.fromJson<DateTime?>(json['lastProcessedDate']),
      expenseRemark: serializer.fromJson<String>(json['expenseRemark']),
      expenseAmount: serializer.fromJson<double>(json['expenseAmount']),
      expenseCategoryId: serializer.fromJson<String>(json['expenseCategoryId']),
      expensePaymentMethod:
          serializer.fromJson<String>(json['expensePaymentMethod']),
      expenseCurrency: serializer.fromJson<String>(json['expenseCurrency']),
      expenseDescription:
          serializer.fromJson<String?>(json['expenseDescription']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'frequency': serializer.toJson<String>(frequency),
      'dayOfMonth': serializer.toJson<int?>(dayOfMonth),
      'dayOfWeek': serializer.toJson<String?>(dayOfWeek),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'isActive': serializer.toJson<bool>(isActive),
      'lastProcessedDate': serializer.toJson<DateTime?>(lastProcessedDate),
      'expenseRemark': serializer.toJson<String>(expenseRemark),
      'expenseAmount': serializer.toJson<double>(expenseAmount),
      'expenseCategoryId': serializer.toJson<String>(expenseCategoryId),
      'expensePaymentMethod': serializer.toJson<String>(expensePaymentMethod),
      'expenseCurrency': serializer.toJson<String>(expenseCurrency),
      'expenseDescription': serializer.toJson<String?>(expenseDescription),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  RecurringExpense copyWith(
          {String? id,
          String? userId,
          String? frequency,
          Value<int?> dayOfMonth = const Value.absent(),
          Value<String?> dayOfWeek = const Value.absent(),
          DateTime? startDate,
          Value<DateTime?> endDate = const Value.absent(),
          bool? isActive,
          Value<DateTime?> lastProcessedDate = const Value.absent(),
          String? expenseRemark,
          double? expenseAmount,
          String? expenseCategoryId,
          String? expensePaymentMethod,
          String? expenseCurrency,
          Value<String?> expenseDescription = const Value.absent(),
          bool? isSynced,
          DateTime? lastModified}) =>
      RecurringExpense(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        frequency: frequency ?? this.frequency,
        dayOfMonth: dayOfMonth.present ? dayOfMonth.value : this.dayOfMonth,
        dayOfWeek: dayOfWeek.present ? dayOfWeek.value : this.dayOfWeek,
        startDate: startDate ?? this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        isActive: isActive ?? this.isActive,
        lastProcessedDate: lastProcessedDate.present
            ? lastProcessedDate.value
            : this.lastProcessedDate,
        expenseRemark: expenseRemark ?? this.expenseRemark,
        expenseAmount: expenseAmount ?? this.expenseAmount,
        expenseCategoryId: expenseCategoryId ?? this.expenseCategoryId,
        expensePaymentMethod: expensePaymentMethod ?? this.expensePaymentMethod,
        expenseCurrency: expenseCurrency ?? this.expenseCurrency,
        expenseDescription: expenseDescription.present
            ? expenseDescription.value
            : this.expenseDescription,
        isSynced: isSynced ?? this.isSynced,
        lastModified: lastModified ?? this.lastModified,
      );
  RecurringExpense copyWithCompanion(RecurringExpensesCompanion data) {
    return RecurringExpense(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      dayOfMonth:
          data.dayOfMonth.present ? data.dayOfMonth.value : this.dayOfMonth,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      lastProcessedDate: data.lastProcessedDate.present
          ? data.lastProcessedDate.value
          : this.lastProcessedDate,
      expenseRemark: data.expenseRemark.present
          ? data.expenseRemark.value
          : this.expenseRemark,
      expenseAmount: data.expenseAmount.present
          ? data.expenseAmount.value
          : this.expenseAmount,
      expenseCategoryId: data.expenseCategoryId.present
          ? data.expenseCategoryId.value
          : this.expenseCategoryId,
      expensePaymentMethod: data.expensePaymentMethod.present
          ? data.expensePaymentMethod.value
          : this.expensePaymentMethod,
      expenseCurrency: data.expenseCurrency.present
          ? data.expenseCurrency.value
          : this.expenseCurrency,
      expenseDescription: data.expenseDescription.present
          ? data.expenseDescription.value
          : this.expenseDescription,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringExpense(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('frequency: $frequency, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('isActive: $isActive, ')
          ..write('lastProcessedDate: $lastProcessedDate, ')
          ..write('expenseRemark: $expenseRemark, ')
          ..write('expenseAmount: $expenseAmount, ')
          ..write('expenseCategoryId: $expenseCategoryId, ')
          ..write('expensePaymentMethod: $expensePaymentMethod, ')
          ..write('expenseCurrency: $expenseCurrency, ')
          ..write('expenseDescription: $expenseDescription, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      frequency,
      dayOfMonth,
      dayOfWeek,
      startDate,
      endDate,
      isActive,
      lastProcessedDate,
      expenseRemark,
      expenseAmount,
      expenseCategoryId,
      expensePaymentMethod,
      expenseCurrency,
      expenseDescription,
      isSynced,
      lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringExpense &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.frequency == this.frequency &&
          other.dayOfMonth == this.dayOfMonth &&
          other.dayOfWeek == this.dayOfWeek &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.isActive == this.isActive &&
          other.lastProcessedDate == this.lastProcessedDate &&
          other.expenseRemark == this.expenseRemark &&
          other.expenseAmount == this.expenseAmount &&
          other.expenseCategoryId == this.expenseCategoryId &&
          other.expensePaymentMethod == this.expensePaymentMethod &&
          other.expenseCurrency == this.expenseCurrency &&
          other.expenseDescription == this.expenseDescription &&
          other.isSynced == this.isSynced &&
          other.lastModified == this.lastModified);
}

class RecurringExpensesCompanion extends UpdateCompanion<RecurringExpense> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> frequency;
  final Value<int?> dayOfMonth;
  final Value<String?> dayOfWeek;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<bool> isActive;
  final Value<DateTime?> lastProcessedDate;
  final Value<String> expenseRemark;
  final Value<double> expenseAmount;
  final Value<String> expenseCategoryId;
  final Value<String> expensePaymentMethod;
  final Value<String> expenseCurrency;
  final Value<String?> expenseDescription;
  final Value<bool> isSynced;
  final Value<DateTime> lastModified;
  final Value<int> rowid;
  const RecurringExpensesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.frequency = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.lastProcessedDate = const Value.absent(),
    this.expenseRemark = const Value.absent(),
    this.expenseAmount = const Value.absent(),
    this.expenseCategoryId = const Value.absent(),
    this.expensePaymentMethod = const Value.absent(),
    this.expenseCurrency = const Value.absent(),
    this.expenseDescription = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringExpensesCompanion.insert({
    required String id,
    required String userId,
    required String frequency,
    this.dayOfMonth = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.lastProcessedDate = const Value.absent(),
    required String expenseRemark,
    required double expenseAmount,
    required String expenseCategoryId,
    required String expensePaymentMethod,
    this.expenseCurrency = const Value.absent(),
    this.expenseDescription = const Value.absent(),
    this.isSynced = const Value.absent(),
    required DateTime lastModified,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        frequency = Value(frequency),
        startDate = Value(startDate),
        expenseRemark = Value(expenseRemark),
        expenseAmount = Value(expenseAmount),
        expenseCategoryId = Value(expenseCategoryId),
        expensePaymentMethod = Value(expensePaymentMethod),
        lastModified = Value(lastModified);
  static Insertable<RecurringExpense> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? frequency,
    Expression<int>? dayOfMonth,
    Expression<String>? dayOfWeek,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<bool>? isActive,
    Expression<DateTime>? lastProcessedDate,
    Expression<String>? expenseRemark,
    Expression<double>? expenseAmount,
    Expression<String>? expenseCategoryId,
    Expression<String>? expensePaymentMethod,
    Expression<String>? expenseCurrency,
    Expression<String>? expenseDescription,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (frequency != null) 'frequency': frequency,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (isActive != null) 'is_active': isActive,
      if (lastProcessedDate != null) 'last_processed_date': lastProcessedDate,
      if (expenseRemark != null) 'expense_remark': expenseRemark,
      if (expenseAmount != null) 'expense_amount': expenseAmount,
      if (expenseCategoryId != null) 'expense_category_id': expenseCategoryId,
      if (expensePaymentMethod != null)
        'expense_payment_method': expensePaymentMethod,
      if (expenseCurrency != null) 'expense_currency': expenseCurrency,
      if (expenseDescription != null) 'expense_description': expenseDescription,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringExpensesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? frequency,
      Value<int?>? dayOfMonth,
      Value<String?>? dayOfWeek,
      Value<DateTime>? startDate,
      Value<DateTime?>? endDate,
      Value<bool>? isActive,
      Value<DateTime?>? lastProcessedDate,
      Value<String>? expenseRemark,
      Value<double>? expenseAmount,
      Value<String>? expenseCategoryId,
      Value<String>? expensePaymentMethod,
      Value<String>? expenseCurrency,
      Value<String?>? expenseDescription,
      Value<bool>? isSynced,
      Value<DateTime>? lastModified,
      Value<int>? rowid}) {
    return RecurringExpensesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      frequency: frequency ?? this.frequency,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      lastProcessedDate: lastProcessedDate ?? this.lastProcessedDate,
      expenseRemark: expenseRemark ?? this.expenseRemark,
      expenseAmount: expenseAmount ?? this.expenseAmount,
      expenseCategoryId: expenseCategoryId ?? this.expenseCategoryId,
      expensePaymentMethod: expensePaymentMethod ?? this.expensePaymentMethod,
      expenseCurrency: expenseCurrency ?? this.expenseCurrency,
      expenseDescription: expenseDescription ?? this.expenseDescription,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
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
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<String>(dayOfWeek.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (lastProcessedDate.present) {
      map['last_processed_date'] = Variable<DateTime>(lastProcessedDate.value);
    }
    if (expenseRemark.present) {
      map['expense_remark'] = Variable<String>(expenseRemark.value);
    }
    if (expenseAmount.present) {
      map['expense_amount'] = Variable<double>(expenseAmount.value);
    }
    if (expenseCategoryId.present) {
      map['expense_category_id'] = Variable<String>(expenseCategoryId.value);
    }
    if (expensePaymentMethod.present) {
      map['expense_payment_method'] =
          Variable<String>(expensePaymentMethod.value);
    }
    if (expenseCurrency.present) {
      map['expense_currency'] = Variable<String>(expenseCurrency.value);
    }
    if (expenseDescription.present) {
      map['expense_description'] = Variable<String>(expenseDescription.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringExpensesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('frequency: $frequency, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('isActive: $isActive, ')
          ..write('lastProcessedDate: $lastProcessedDate, ')
          ..write('expenseRemark: $expenseRemark, ')
          ..write('expenseAmount: $expenseAmount, ')
          ..write('expenseCategoryId: $expenseCategoryId, ')
          ..write('expensePaymentMethod: $expensePaymentMethod, ')
          ..write('expenseCurrency: $expenseCurrency, ')
          ..write('expenseDescription: $expenseDescription, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoUrlMeta =
      const VerificationMeta('photoUrl');
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
      'photo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('MYR'));
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
      'theme', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('light'));
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
  static const VerificationMeta _automaticRebalanceSuggestionsMeta =
      const VerificationMeta('automaticRebalanceSuggestions');
  @override
  late final GeneratedColumn<bool> automaticRebalanceSuggestions =
      GeneratedColumn<bool>(
          'automatic_rebalance_suggestions', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("automatic_rebalance_suggestions" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        email,
        displayName,
        photoUrl,
        currency,
        theme,
        allowNotification,
        autoBudget,
        improveAccuracy,
        automaticRebalanceSuggestions,
        lastModified,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('photo_url')) {
      context.handle(_photoUrlMeta,
          photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('theme')) {
      context.handle(
          _themeMeta, theme.isAcceptableOrUnknown(data['theme']!, _themeMeta));
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
    if (data.containsKey('automatic_rebalance_suggestions')) {
      context.handle(
          _automaticRebalanceSuggestionsMeta,
          automaticRebalanceSuggestions.isAcceptableOrUnknown(
              data['automatic_rebalance_suggestions']!,
              _automaticRebalanceSuggestionsMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name']),
      photoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_url']),
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      theme: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme'])!,
      allowNotification: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}allow_notification'])!,
      autoBudget: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}auto_budget'])!,
      improveAccuracy: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}improve_accuracy'])!,
      automaticRebalanceSuggestions: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}automatic_rebalance_suggestions'])!,
      lastModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String currency;
  final String theme;
  final bool allowNotification;
  final bool autoBudget;
  final bool improveAccuracy;
  final bool automaticRebalanceSuggestions;
  final DateTime lastModified;
  final bool isSynced;
  const User(
      {required this.id,
      this.email,
      this.displayName,
      this.photoUrl,
      required this.currency,
      required this.theme,
      required this.allowNotification,
      required this.autoBudget,
      required this.improveAccuracy,
      required this.automaticRebalanceSuggestions,
      required this.lastModified,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    map['currency'] = Variable<String>(currency);
    map['theme'] = Variable<String>(theme);
    map['allow_notification'] = Variable<bool>(allowNotification);
    map['auto_budget'] = Variable<bool>(autoBudget);
    map['improve_accuracy'] = Variable<bool>(improveAccuracy);
    map['automatic_rebalance_suggestions'] =
        Variable<bool>(automaticRebalanceSuggestions);
    map['last_modified'] = Variable<DateTime>(lastModified);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      currency: Value(currency),
      theme: Value(theme),
      allowNotification: Value(allowNotification),
      autoBudget: Value(autoBudget),
      improveAccuracy: Value(improveAccuracy),
      automaticRebalanceSuggestions: Value(automaticRebalanceSuggestions),
      lastModified: Value(lastModified),
      isSynced: Value(isSynced),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String?>(json['email']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      currency: serializer.fromJson<String>(json['currency']),
      theme: serializer.fromJson<String>(json['theme']),
      allowNotification: serializer.fromJson<bool>(json['allowNotification']),
      autoBudget: serializer.fromJson<bool>(json['autoBudget']),
      improveAccuracy: serializer.fromJson<bool>(json['improveAccuracy']),
      automaticRebalanceSuggestions:
          serializer.fromJson<bool>(json['automaticRebalanceSuggestions']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String?>(email),
      'displayName': serializer.toJson<String?>(displayName),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'currency': serializer.toJson<String>(currency),
      'theme': serializer.toJson<String>(theme),
      'allowNotification': serializer.toJson<bool>(allowNotification),
      'autoBudget': serializer.toJson<bool>(autoBudget),
      'improveAccuracy': serializer.toJson<bool>(improveAccuracy),
      'automaticRebalanceSuggestions':
          serializer.toJson<bool>(automaticRebalanceSuggestions),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  User copyWith(
          {String? id,
          Value<String?> email = const Value.absent(),
          Value<String?> displayName = const Value.absent(),
          Value<String?> photoUrl = const Value.absent(),
          String? currency,
          String? theme,
          bool? allowNotification,
          bool? autoBudget,
          bool? improveAccuracy,
          bool? automaticRebalanceSuggestions,
          DateTime? lastModified,
          bool? isSynced}) =>
      User(
        id: id ?? this.id,
        email: email.present ? email.value : this.email,
        displayName: displayName.present ? displayName.value : this.displayName,
        photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
        currency: currency ?? this.currency,
        theme: theme ?? this.theme,
        allowNotification: allowNotification ?? this.allowNotification,
        autoBudget: autoBudget ?? this.autoBudget,
        improveAccuracy: improveAccuracy ?? this.improveAccuracy,
        automaticRebalanceSuggestions:
            automaticRebalanceSuggestions ?? this.automaticRebalanceSuggestions,
        lastModified: lastModified ?? this.lastModified,
        isSynced: isSynced ?? this.isSynced,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      currency: data.currency.present ? data.currency.value : this.currency,
      theme: data.theme.present ? data.theme.value : this.theme,
      allowNotification: data.allowNotification.present
          ? data.allowNotification.value
          : this.allowNotification,
      autoBudget:
          data.autoBudget.present ? data.autoBudget.value : this.autoBudget,
      improveAccuracy: data.improveAccuracy.present
          ? data.improveAccuracy.value
          : this.improveAccuracy,
      automaticRebalanceSuggestions: data.automaticRebalanceSuggestions.present
          ? data.automaticRebalanceSuggestions.value
          : this.automaticRebalanceSuggestions,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('currency: $currency, ')
          ..write('theme: $theme, ')
          ..write('allowNotification: $allowNotification, ')
          ..write('autoBudget: $autoBudget, ')
          ..write('improveAccuracy: $improveAccuracy, ')
          ..write(
              'automaticRebalanceSuggestions: $automaticRebalanceSuggestions, ')
          ..write('lastModified: $lastModified, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      email,
      displayName,
      photoUrl,
      currency,
      theme,
      allowNotification,
      autoBudget,
      improveAccuracy,
      automaticRebalanceSuggestions,
      lastModified,
      isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.photoUrl == this.photoUrl &&
          other.currency == this.currency &&
          other.theme == this.theme &&
          other.allowNotification == this.allowNotification &&
          other.autoBudget == this.autoBudget &&
          other.improveAccuracy == this.improveAccuracy &&
          other.automaticRebalanceSuggestions ==
              this.automaticRebalanceSuggestions &&
          other.lastModified == this.lastModified &&
          other.isSynced == this.isSynced);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String?> email;
  final Value<String?> displayName;
  final Value<String?> photoUrl;
  final Value<String> currency;
  final Value<String> theme;
  final Value<bool> allowNotification;
  final Value<bool> autoBudget;
  final Value<bool> improveAccuracy;
  final Value<bool> automaticRebalanceSuggestions;
  final Value<DateTime> lastModified;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.currency = const Value.absent(),
    this.theme = const Value.absent(),
    this.allowNotification = const Value.absent(),
    this.autoBudget = const Value.absent(),
    this.improveAccuracy = const Value.absent(),
    this.automaticRebalanceSuggestions = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.currency = const Value.absent(),
    this.theme = const Value.absent(),
    this.allowNotification = const Value.absent(),
    this.autoBudget = const Value.absent(),
    this.improveAccuracy = const Value.absent(),
    this.automaticRebalanceSuggestions = const Value.absent(),
    required DateTime lastModified,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        lastModified = Value(lastModified);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<String>? photoUrl,
    Expression<String>? currency,
    Expression<String>? theme,
    Expression<bool>? allowNotification,
    Expression<bool>? autoBudget,
    Expression<bool>? improveAccuracy,
    Expression<bool>? automaticRebalanceSuggestions,
    Expression<DateTime>? lastModified,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (currency != null) 'currency': currency,
      if (theme != null) 'theme': theme,
      if (allowNotification != null) 'allow_notification': allowNotification,
      if (autoBudget != null) 'auto_budget': autoBudget,
      if (improveAccuracy != null) 'improve_accuracy': improveAccuracy,
      if (automaticRebalanceSuggestions != null)
        'automatic_rebalance_suggestions': automaticRebalanceSuggestions,
      if (lastModified != null) 'last_modified': lastModified,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? id,
      Value<String?>? email,
      Value<String?>? displayName,
      Value<String?>? photoUrl,
      Value<String>? currency,
      Value<String>? theme,
      Value<bool>? allowNotification,
      Value<bool>? autoBudget,
      Value<bool>? improveAccuracy,
      Value<bool>? automaticRebalanceSuggestions,
      Value<DateTime>? lastModified,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return UsersCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      currency: currency ?? this.currency,
      theme: theme ?? this.theme,
      allowNotification: allowNotification ?? this.allowNotification,
      autoBudget: autoBudget ?? this.autoBudget,
      improveAccuracy: improveAccuracy ?? this.improveAccuracy,
      automaticRebalanceSuggestions:
          automaticRebalanceSuggestions ?? this.automaticRebalanceSuggestions,
      lastModified: lastModified ?? this.lastModified,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
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
    if (automaticRebalanceSuggestions.present) {
      map['automatic_rebalance_suggestions'] =
          Variable<bool>(automaticRebalanceSuggestions.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('currency: $currency, ')
          ..write('theme: $theme, ')
          ..write('allowNotification: $allowNotification, ')
          ..write('autoBudget: $autoBudget, ')
          ..write('improveAccuracy: $improveAccuracy, ')
          ..write(
              'automaticRebalanceSuggestions: $automaticRebalanceSuggestions, ')
          ..write('lastModified: $lastModified, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
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
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [baseCurrency, userId, ratesJson, timestamp, lastModified];
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
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
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
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {baseCurrency, userId};
  @override
  ExchangeRate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExchangeRate(
      baseCurrency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base_currency'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      ratesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rates_json'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      lastModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $ExchangeRatesTable createAlias(String alias) {
    return $ExchangeRatesTable(attachedDatabase, alias);
  }
}

class ExchangeRate extends DataClass implements Insertable<ExchangeRate> {
  final String baseCurrency;
  final String userId;
  final String ratesJson;
  final DateTime timestamp;
  final DateTime lastModified;
  const ExchangeRate(
      {required this.baseCurrency,
      required this.userId,
      required this.ratesJson,
      required this.timestamp,
      required this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['base_currency'] = Variable<String>(baseCurrency);
    map['user_id'] = Variable<String>(userId);
    map['rates_json'] = Variable<String>(ratesJson);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  ExchangeRatesCompanion toCompanion(bool nullToAbsent) {
    return ExchangeRatesCompanion(
      baseCurrency: Value(baseCurrency),
      userId: Value(userId),
      ratesJson: Value(ratesJson),
      timestamp: Value(timestamp),
      lastModified: Value(lastModified),
    );
  }

  factory ExchangeRate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExchangeRate(
      baseCurrency: serializer.fromJson<String>(json['baseCurrency']),
      userId: serializer.fromJson<String>(json['userId']),
      ratesJson: serializer.fromJson<String>(json['ratesJson']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'baseCurrency': serializer.toJson<String>(baseCurrency),
      'userId': serializer.toJson<String>(userId),
      'ratesJson': serializer.toJson<String>(ratesJson),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  ExchangeRate copyWith(
          {String? baseCurrency,
          String? userId,
          String? ratesJson,
          DateTime? timestamp,
          DateTime? lastModified}) =>
      ExchangeRate(
        baseCurrency: baseCurrency ?? this.baseCurrency,
        userId: userId ?? this.userId,
        ratesJson: ratesJson ?? this.ratesJson,
        timestamp: timestamp ?? this.timestamp,
        lastModified: lastModified ?? this.lastModified,
      );
  ExchangeRate copyWithCompanion(ExchangeRatesCompanion data) {
    return ExchangeRate(
      baseCurrency: data.baseCurrency.present
          ? data.baseCurrency.value
          : this.baseCurrency,
      userId: data.userId.present ? data.userId.value : this.userId,
      ratesJson: data.ratesJson.present ? data.ratesJson.value : this.ratesJson,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRate(')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('userId: $userId, ')
          ..write('ratesJson: $ratesJson, ')
          ..write('timestamp: $timestamp, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(baseCurrency, userId, ratesJson, timestamp, lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeRate &&
          other.baseCurrency == this.baseCurrency &&
          other.userId == this.userId &&
          other.ratesJson == this.ratesJson &&
          other.timestamp == this.timestamp &&
          other.lastModified == this.lastModified);
}

class ExchangeRatesCompanion extends UpdateCompanion<ExchangeRate> {
  final Value<String> baseCurrency;
  final Value<String> userId;
  final Value<String> ratesJson;
  final Value<DateTime> timestamp;
  final Value<DateTime> lastModified;
  final Value<int> rowid;
  const ExchangeRatesCompanion({
    this.baseCurrency = const Value.absent(),
    this.userId = const Value.absent(),
    this.ratesJson = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExchangeRatesCompanion.insert({
    required String baseCurrency,
    required String userId,
    required String ratesJson,
    required DateTime timestamp,
    required DateTime lastModified,
    this.rowid = const Value.absent(),
  })  : baseCurrency = Value(baseCurrency),
        userId = Value(userId),
        ratesJson = Value(ratesJson),
        timestamp = Value(timestamp),
        lastModified = Value(lastModified);
  static Insertable<ExchangeRate> custom({
    Expression<String>? baseCurrency,
    Expression<String>? userId,
    Expression<String>? ratesJson,
    Expression<DateTime>? timestamp,
    Expression<DateTime>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (baseCurrency != null) 'base_currency': baseCurrency,
      if (userId != null) 'user_id': userId,
      if (ratesJson != null) 'rates_json': ratesJson,
      if (timestamp != null) 'timestamp': timestamp,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExchangeRatesCompanion copyWith(
      {Value<String>? baseCurrency,
      Value<String>? userId,
      Value<String>? ratesJson,
      Value<DateTime>? timestamp,
      Value<DateTime>? lastModified,
      Value<int>? rowid}) {
    return ExchangeRatesCompanion(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      userId: userId ?? this.userId,
      ratesJson: ratesJson ?? this.ratesJson,
      timestamp: timestamp ?? this.timestamp,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (baseCurrency.present) {
      map['base_currency'] = Variable<String>(baseCurrency.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (ratesJson.present) {
      map['rates_json'] = Variable<String>(ratesJson.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
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
          ..write('userId: $userId, ')
          ..write('ratesJson: $ratesJson, ')
          ..write('timestamp: $timestamp, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetSuggestionsTable extends BudgetSuggestions
    with TableInfo<$BudgetSuggestionsTable, BudgetSuggestion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetSuggestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _monthIdMeta =
      const VerificationMeta('monthId');
  @override
  late final GeneratedColumn<String> monthId = GeneratedColumn<String>(
      'month_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _suggestionsMeta =
      const VerificationMeta('suggestions');
  @override
  late final GeneratedColumn<String> suggestions = GeneratedColumn<String>(
      'suggestions', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, monthId, userId, suggestions, timestamp, isRead];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_suggestions';
  @override
  VerificationContext validateIntegrity(Insertable<BudgetSuggestion> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month_id')) {
      context.handle(_monthIdMeta,
          monthId.isAcceptableOrUnknown(data['month_id']!, _monthIdMeta));
    } else if (isInserting) {
      context.missing(_monthIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('suggestions')) {
      context.handle(
          _suggestionsMeta,
          suggestions.isAcceptableOrUnknown(
              data['suggestions']!, _suggestionsMeta));
    } else if (isInserting) {
      context.missing(_suggestionsMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetSuggestion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetSuggestion(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      monthId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}month_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      suggestions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}suggestions'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
    );
  }

  @override
  $BudgetSuggestionsTable createAlias(String alias) {
    return $BudgetSuggestionsTable(attachedDatabase, alias);
  }
}

class BudgetSuggestion extends DataClass
    implements Insertable<BudgetSuggestion> {
  final int id;
  final String monthId;
  final String userId;
  final String suggestions;
  final DateTime timestamp;
  final bool isRead;
  const BudgetSuggestion(
      {required this.id,
      required this.monthId,
      required this.userId,
      required this.suggestions,
      required this.timestamp,
      required this.isRead});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month_id'] = Variable<String>(monthId);
    map['user_id'] = Variable<String>(userId);
    map['suggestions'] = Variable<String>(suggestions);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['is_read'] = Variable<bool>(isRead);
    return map;
  }

  BudgetSuggestionsCompanion toCompanion(bool nullToAbsent) {
    return BudgetSuggestionsCompanion(
      id: Value(id),
      monthId: Value(monthId),
      userId: Value(userId),
      suggestions: Value(suggestions),
      timestamp: Value(timestamp),
      isRead: Value(isRead),
    );
  }

  factory BudgetSuggestion.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetSuggestion(
      id: serializer.fromJson<int>(json['id']),
      monthId: serializer.fromJson<String>(json['monthId']),
      userId: serializer.fromJson<String>(json['userId']),
      suggestions: serializer.fromJson<String>(json['suggestions']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      isRead: serializer.fromJson<bool>(json['isRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'monthId': serializer.toJson<String>(monthId),
      'userId': serializer.toJson<String>(userId),
      'suggestions': serializer.toJson<String>(suggestions),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'isRead': serializer.toJson<bool>(isRead),
    };
  }

  BudgetSuggestion copyWith(
          {int? id,
          String? monthId,
          String? userId,
          String? suggestions,
          DateTime? timestamp,
          bool? isRead}) =>
      BudgetSuggestion(
        id: id ?? this.id,
        monthId: monthId ?? this.monthId,
        userId: userId ?? this.userId,
        suggestions: suggestions ?? this.suggestions,
        timestamp: timestamp ?? this.timestamp,
        isRead: isRead ?? this.isRead,
      );
  BudgetSuggestion copyWithCompanion(BudgetSuggestionsCompanion data) {
    return BudgetSuggestion(
      id: data.id.present ? data.id.value : this.id,
      monthId: data.monthId.present ? data.monthId.value : this.monthId,
      userId: data.userId.present ? data.userId.value : this.userId,
      suggestions:
          data.suggestions.present ? data.suggestions.value : this.suggestions,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetSuggestion(')
          ..write('id: $id, ')
          ..write('monthId: $monthId, ')
          ..write('userId: $userId, ')
          ..write('suggestions: $suggestions, ')
          ..write('timestamp: $timestamp, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, monthId, userId, suggestions, timestamp, isRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetSuggestion &&
          other.id == this.id &&
          other.monthId == this.monthId &&
          other.userId == this.userId &&
          other.suggestions == this.suggestions &&
          other.timestamp == this.timestamp &&
          other.isRead == this.isRead);
}

class BudgetSuggestionsCompanion extends UpdateCompanion<BudgetSuggestion> {
  final Value<int> id;
  final Value<String> monthId;
  final Value<String> userId;
  final Value<String> suggestions;
  final Value<DateTime> timestamp;
  final Value<bool> isRead;
  const BudgetSuggestionsCompanion({
    this.id = const Value.absent(),
    this.monthId = const Value.absent(),
    this.userId = const Value.absent(),
    this.suggestions = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isRead = const Value.absent(),
  });
  BudgetSuggestionsCompanion.insert({
    this.id = const Value.absent(),
    required String monthId,
    required String userId,
    required String suggestions,
    required DateTime timestamp,
    this.isRead = const Value.absent(),
  })  : monthId = Value(monthId),
        userId = Value(userId),
        suggestions = Value(suggestions),
        timestamp = Value(timestamp);
  static Insertable<BudgetSuggestion> custom({
    Expression<int>? id,
    Expression<String>? monthId,
    Expression<String>? userId,
    Expression<String>? suggestions,
    Expression<DateTime>? timestamp,
    Expression<bool>? isRead,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monthId != null) 'month_id': monthId,
      if (userId != null) 'user_id': userId,
      if (suggestions != null) 'suggestions': suggestions,
      if (timestamp != null) 'timestamp': timestamp,
      if (isRead != null) 'is_read': isRead,
    });
  }

  BudgetSuggestionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? monthId,
      Value<String>? userId,
      Value<String>? suggestions,
      Value<DateTime>? timestamp,
      Value<bool>? isRead}) {
    return BudgetSuggestionsCompanion(
      id: id ?? this.id,
      monthId: monthId ?? this.monthId,
      userId: userId ?? this.userId,
      suggestions: suggestions ?? this.suggestions,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (monthId.present) {
      map['month_id'] = Variable<String>(monthId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (suggestions.present) {
      map['suggestions'] = Variable<String>(suggestions.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetSuggestionsCompanion(')
          ..write('id: $id, ')
          ..write('monthId: $monthId, ')
          ..write('userId: $userId, ')
          ..write('suggestions: $suggestions, ')
          ..write('timestamp: $timestamp, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $RecurringExpensesTable recurringExpenses =
      $RecurringExpensesTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $ExchangeRatesTable exchangeRates = $ExchangeRatesTable(this);
  late final $BudgetSuggestionsTable budgetSuggestions =
      $BudgetSuggestionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        expenses,
        budgets,
        syncQueue,
        recurringExpenses,
        users,
        exchangeRates,
        budgetSuggestions
      ];
}

typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  required String id,
  required String userId,
  required String remark,
  required double amount,
  required DateTime date,
  required String category,
  required String method,
  Value<String?> description,
  Value<String> currency,
  Value<String?> recurringExpenseId,
  Value<bool> isSynced,
  required DateTime lastModified,
  Value<int> rowid,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> remark,
  Value<double> amount,
  Value<DateTime> date,
  Value<String> category,
  Value<String> method,
  Value<String?> description,
  Value<String> currency,
  Value<String?> recurringExpenseId,
  Value<bool> isSynced,
  Value<DateTime> lastModified,
  Value<int> rowid,
});

class $$ExpensesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder> {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ExpensesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ExpensesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> remark = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> recurringExpenseId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpensesCompanion(
            id: id,
            userId: userId,
            remark: remark,
            amount: amount,
            date: date,
            category: category,
            method: method,
            description: description,
            currency: currency,
            recurringExpenseId: recurringExpenseId,
            isSynced: isSynced,
            lastModified: lastModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String remark,
            required double amount,
            required DateTime date,
            required String category,
            required String method,
            Value<String?> description = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> recurringExpenseId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            required DateTime lastModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpensesCompanion.insert(
            id: id,
            userId: userId,
            remark: remark,
            amount: amount,
            date: date,
            category: category,
            method: method,
            description: description,
            currency: currency,
            recurringExpenseId: recurringExpenseId,
            isSynced: isSynced,
            lastModified: lastModified,
            rowid: rowid,
          ),
        ));
}

class $$ExpensesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get remark => $state.composableBuilder(
      column: $state.table.remark,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get method => $state.composableBuilder(
      column: $state.table.method,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get currency => $state.composableBuilder(
      column: $state.table.currency,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get recurringExpenseId => $state.composableBuilder(
      column: $state.table.recurringExpenseId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastModified => $state.composableBuilder(
      column: $state.table.lastModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$ExpensesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get remark => $state.composableBuilder(
      column: $state.table.remark,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get method => $state.composableBuilder(
      column: $state.table.method,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get currency => $state.composableBuilder(
      column: $state.table.currency,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get recurringExpenseId => $state.composableBuilder(
      column: $state.table.recurringExpenseId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastModified => $state.composableBuilder(
      column: $state.table.lastModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  required String monthId,
  required String userId,
  required double total,
  required double left,
  required String categoriesJson,
  Value<double> saving,
  Value<bool> isSynced,
  required DateTime lastModified,
  Value<int> rowid,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<String> monthId,
  Value<String> userId,
  Value<double> total,
  Value<double> left,
  Value<String> categoriesJson,
  Value<double> saving,
  Value<bool> isSynced,
  Value<DateTime> lastModified,
  Value<int> rowid,
});

class $$BudgetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder> {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BudgetsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BudgetsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> monthId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<double> total = const Value.absent(),
            Value<double> left = const Value.absent(),
            Value<String> categoriesJson = const Value.absent(),
            Value<double> saving = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion(
            monthId: monthId,
            userId: userId,
            total: total,
            left: left,
            categoriesJson: categoriesJson,
            saving: saving,
            isSynced: isSynced,
            lastModified: lastModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String monthId,
            required String userId,
            required double total,
            required double left,
            required String categoriesJson,
            Value<double> saving = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            required DateTime lastModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion.insert(
            monthId: monthId,
            userId: userId,
            total: total,
            left: left,
            categoriesJson: categoriesJson,
            saving: saving,
            isSynced: isSynced,
            lastModified: lastModified,
            rowid: rowid,
          ),
        ));
}

class $$BudgetsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer(super.$state);
  ColumnFilters<String> get monthId => $state.composableBuilder(
      column: $state.table.monthId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get total => $state.composableBuilder(
      column: $state.table.total,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get left => $state.composableBuilder(
      column: $state.table.left,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get categoriesJson => $state.composableBuilder(
      column: $state.table.categoriesJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get saving => $state.composableBuilder(
      column: $state.table.saving,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastModified => $state.composableBuilder(
      column: $state.table.lastModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$BudgetsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get monthId => $state.composableBuilder(
      column: $state.table.monthId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get total => $state.composableBuilder(
      column: $state.table.total,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get left => $state.composableBuilder(
      column: $state.table.left,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get categoriesJson => $state.composableBuilder(
      column: $state.table.categoriesJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get saving => $state.composableBuilder(
      column: $state.table.saving,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastModified => $state.composableBuilder(
      column: $state.table.lastModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String entityType,
  required String entityId,
  required String userId,
  required String operation,
  required DateTime timestamp,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> userId,
  Value<String> operation,
  Value<DateTime> timestamp,
});

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SyncQueueTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SyncQueueTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            entityType: entityType,
            entityId: entityId,
            userId: userId,
            operation: operation,
            timestamp: timestamp,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String entityType,
            required String entityId,
            required String userId,
            required String operation,
            required DateTime timestamp,
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            userId: userId,
            operation: operation,
            timestamp: timestamp,
          ),
        ));
}

class $$SyncQueueTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get entityType => $state.composableBuilder(
      column: $state.table.entityType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get entityId => $state.composableBuilder(
      column: $state.table.entityId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get operation => $state.composableBuilder(
      column: $state.table.operation,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SyncQueueTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get entityType => $state.composableBuilder(
      column: $state.table.entityType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get entityId => $state.composableBuilder(
      column: $state.table.entityId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get operation => $state.composableBuilder(
      column: $state.table.operation,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$RecurringExpensesTableCreateCompanionBuilder
    = RecurringExpensesCompanion Function({
  required String id,
  required String userId,
  required String frequency,
  Value<int?> dayOfMonth,
  Value<String?> dayOfWeek,
  required DateTime startDate,
  Value<DateTime?> endDate,
  Value<bool> isActive,
  Value<DateTime?> lastProcessedDate,
  required String expenseRemark,
  required double expenseAmount,
  required String expenseCategoryId,
  required String expensePaymentMethod,
  Value<String> expenseCurrency,
  Value<String?> expenseDescription,
  Value<bool> isSynced,
  required DateTime lastModified,
  Value<int> rowid,
});
typedef $$RecurringExpensesTableUpdateCompanionBuilder
    = RecurringExpensesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> frequency,
  Value<int?> dayOfMonth,
  Value<String?> dayOfWeek,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<bool> isActive,
  Value<DateTime?> lastProcessedDate,
  Value<String> expenseRemark,
  Value<double> expenseAmount,
  Value<String> expenseCategoryId,
  Value<String> expensePaymentMethod,
  Value<String> expenseCurrency,
  Value<String?> expenseDescription,
  Value<bool> isSynced,
  Value<DateTime> lastModified,
  Value<int> rowid,
});

class $$RecurringExpensesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecurringExpensesTable,
    RecurringExpense,
    $$RecurringExpensesTableFilterComposer,
    $$RecurringExpensesTableOrderingComposer,
    $$RecurringExpensesTableCreateCompanionBuilder,
    $$RecurringExpensesTableUpdateCompanionBuilder> {
  $$RecurringExpensesTableTableManager(
      _$AppDatabase db, $RecurringExpensesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$RecurringExpensesTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$RecurringExpensesTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> frequency = const Value.absent(),
            Value<int?> dayOfMonth = const Value.absent(),
            Value<String?> dayOfWeek = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime?> lastProcessedDate = const Value.absent(),
            Value<String> expenseRemark = const Value.absent(),
            Value<double> expenseAmount = const Value.absent(),
            Value<String> expenseCategoryId = const Value.absent(),
            Value<String> expensePaymentMethod = const Value.absent(),
            Value<String> expenseCurrency = const Value.absent(),
            Value<String?> expenseDescription = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurringExpensesCompanion(
            id: id,
            userId: userId,
            frequency: frequency,
            dayOfMonth: dayOfMonth,
            dayOfWeek: dayOfWeek,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            lastProcessedDate: lastProcessedDate,
            expenseRemark: expenseRemark,
            expenseAmount: expenseAmount,
            expenseCategoryId: expenseCategoryId,
            expensePaymentMethod: expensePaymentMethod,
            expenseCurrency: expenseCurrency,
            expenseDescription: expenseDescription,
            isSynced: isSynced,
            lastModified: lastModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String frequency,
            Value<int?> dayOfMonth = const Value.absent(),
            Value<String?> dayOfWeek = const Value.absent(),
            required DateTime startDate,
            Value<DateTime?> endDate = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime?> lastProcessedDate = const Value.absent(),
            required String expenseRemark,
            required double expenseAmount,
            required String expenseCategoryId,
            required String expensePaymentMethod,
            Value<String> expenseCurrency = const Value.absent(),
            Value<String?> expenseDescription = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            required DateTime lastModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurringExpensesCompanion.insert(
            id: id,
            userId: userId,
            frequency: frequency,
            dayOfMonth: dayOfMonth,
            dayOfWeek: dayOfWeek,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            lastProcessedDate: lastProcessedDate,
            expenseRemark: expenseRemark,
            expenseAmount: expenseAmount,
            expenseCategoryId: expenseCategoryId,
            expensePaymentMethod: expensePaymentMethod,
            expenseCurrency: expenseCurrency,
            expenseDescription: expenseDescription,
            isSynced: isSynced,
            lastModified: lastModified,
            rowid: rowid,
          ),
        ));
}

class $$RecurringExpensesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $RecurringExpensesTable> {
  $$RecurringExpensesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get frequency => $state.composableBuilder(
      column: $state.table.frequency,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get dayOfMonth => $state.composableBuilder(
      column: $state.table.dayOfMonth,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get dayOfWeek => $state.composableBuilder(
      column: $state.table.dayOfWeek,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get startDate => $state.composableBuilder(
      column: $state.table.startDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get endDate => $state.composableBuilder(
      column: $state.table.endDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastProcessedDate => $state.composableBuilder(
      column: $state.table.lastProcessedDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get expenseRemark => $state.composableBuilder(
      column: $state.table.expenseRemark,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get expenseAmount => $state.composableBuilder(
      column: $state.table.expenseAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get expenseCategoryId => $state.composableBuilder(
      column: $state.table.expenseCategoryId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get expensePaymentMethod => $state.composableBuilder(
      column: $state.table.expensePaymentMethod,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get expenseCurrency => $state.composableBuilder(
      column: $state.table.expenseCurrency,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get expenseDescription => $state.composableBuilder(
      column: $state.table.expenseDescription,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastModified => $state.composableBuilder(
      column: $state.table.lastModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$RecurringExpensesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $RecurringExpensesTable> {
  $$RecurringExpensesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get frequency => $state.composableBuilder(
      column: $state.table.frequency,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get dayOfMonth => $state.composableBuilder(
      column: $state.table.dayOfMonth,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get dayOfWeek => $state.composableBuilder(
      column: $state.table.dayOfWeek,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get startDate => $state.composableBuilder(
      column: $state.table.startDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get endDate => $state.composableBuilder(
      column: $state.table.endDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastProcessedDate => $state.composableBuilder(
      column: $state.table.lastProcessedDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get expenseRemark => $state.composableBuilder(
      column: $state.table.expenseRemark,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get expenseAmount => $state.composableBuilder(
      column: $state.table.expenseAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get expenseCategoryId => $state.composableBuilder(
      column: $state.table.expenseCategoryId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get expensePaymentMethod => $state.composableBuilder(
      column: $state.table.expensePaymentMethod,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get expenseCurrency => $state.composableBuilder(
      column: $state.table.expenseCurrency,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get expenseDescription => $state.composableBuilder(
      column: $state.table.expenseDescription,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastModified => $state.composableBuilder(
      column: $state.table.lastModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  Value<String?> email,
  Value<String?> displayName,
  Value<String?> photoUrl,
  Value<String> currency,
  Value<String> theme,
  Value<bool> allowNotification,
  Value<bool> autoBudget,
  Value<bool> improveAccuracy,
  Value<bool> automaticRebalanceSuggestions,
  required DateTime lastModified,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String?> email,
  Value<String?> displayName,
  Value<String?> photoUrl,
  Value<String> currency,
  Value<String> theme,
  Value<bool> allowNotification,
  Value<bool> autoBudget,
  Value<bool> improveAccuracy,
  Value<bool> automaticRebalanceSuggestions,
  Value<DateTime> lastModified,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$UsersTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$UsersTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<String?> photoUrl = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> theme = const Value.absent(),
            Value<bool> allowNotification = const Value.absent(),
            Value<bool> autoBudget = const Value.absent(),
            Value<bool> improveAccuracy = const Value.absent(),
            Value<bool> automaticRebalanceSuggestions = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            email: email,
            displayName: displayName,
            photoUrl: photoUrl,
            currency: currency,
            theme: theme,
            allowNotification: allowNotification,
            autoBudget: autoBudget,
            improveAccuracy: improveAccuracy,
            automaticRebalanceSuggestions: automaticRebalanceSuggestions,
            lastModified: lastModified,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> email = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<String?> photoUrl = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> theme = const Value.absent(),
            Value<bool> allowNotification = const Value.absent(),
            Value<bool> autoBudget = const Value.absent(),
            Value<bool> improveAccuracy = const Value.absent(),
            Value<bool> automaticRebalanceSuggestions = const Value.absent(),
            required DateTime lastModified,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            email: email,
            displayName: displayName,
            photoUrl: photoUrl,
            currency: currency,
            theme: theme,
            allowNotification: allowNotification,
            autoBudget: autoBudget,
            improveAccuracy: improveAccuracy,
            automaticRebalanceSuggestions: automaticRebalanceSuggestions,
            lastModified: lastModified,
            isSynced: isSynced,
            rowid: rowid,
          ),
        ));
}

class $$UsersTableFilterComposer
    extends FilterComposer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get displayName => $state.composableBuilder(
      column: $state.table.displayName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get photoUrl => $state.composableBuilder(
      column: $state.table.photoUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get currency => $state.composableBuilder(
      column: $state.table.currency,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get theme => $state.composableBuilder(
      column: $state.table.theme,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get allowNotification => $state.composableBuilder(
      column: $state.table.allowNotification,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get autoBudget => $state.composableBuilder(
      column: $state.table.autoBudget,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get improveAccuracy => $state.composableBuilder(
      column: $state.table.improveAccuracy,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get automaticRebalanceSuggestions => $state
      .composableBuilder(
          column: $state.table.automaticRebalanceSuggestions,
          builder: (column, joinBuilders) =>
              ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastModified => $state.composableBuilder(
      column: $state.table.lastModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$UsersTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get displayName => $state.composableBuilder(
      column: $state.table.displayName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get photoUrl => $state.composableBuilder(
      column: $state.table.photoUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get currency => $state.composableBuilder(
      column: $state.table.currency,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get theme => $state.composableBuilder(
      column: $state.table.theme,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get allowNotification => $state.composableBuilder(
      column: $state.table.allowNotification,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get autoBudget => $state.composableBuilder(
      column: $state.table.autoBudget,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get improveAccuracy => $state.composableBuilder(
      column: $state.table.improveAccuracy,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get automaticRebalanceSuggestions =>
      $state.composableBuilder(
          column: $state.table.automaticRebalanceSuggestions,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastModified => $state.composableBuilder(
      column: $state.table.lastModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$ExchangeRatesTableCreateCompanionBuilder = ExchangeRatesCompanion
    Function({
  required String baseCurrency,
  required String userId,
  required String ratesJson,
  required DateTime timestamp,
  required DateTime lastModified,
  Value<int> rowid,
});
typedef $$ExchangeRatesTableUpdateCompanionBuilder = ExchangeRatesCompanion
    Function({
  Value<String> baseCurrency,
  Value<String> userId,
  Value<String> ratesJson,
  Value<DateTime> timestamp,
  Value<DateTime> lastModified,
  Value<int> rowid,
});

class $$ExchangeRatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExchangeRatesTable,
    ExchangeRate,
    $$ExchangeRatesTableFilterComposer,
    $$ExchangeRatesTableOrderingComposer,
    $$ExchangeRatesTableCreateCompanionBuilder,
    $$ExchangeRatesTableUpdateCompanionBuilder> {
  $$ExchangeRatesTableTableManager(_$AppDatabase db, $ExchangeRatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ExchangeRatesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ExchangeRatesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> baseCurrency = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> ratesJson = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExchangeRatesCompanion(
            baseCurrency: baseCurrency,
            userId: userId,
            ratesJson: ratesJson,
            timestamp: timestamp,
            lastModified: lastModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String baseCurrency,
            required String userId,
            required String ratesJson,
            required DateTime timestamp,
            required DateTime lastModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              ExchangeRatesCompanion.insert(
            baseCurrency: baseCurrency,
            userId: userId,
            ratesJson: ratesJson,
            timestamp: timestamp,
            lastModified: lastModified,
            rowid: rowid,
          ),
        ));
}

class $$ExchangeRatesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableFilterComposer(super.$state);
  ColumnFilters<String> get baseCurrency => $state.composableBuilder(
      column: $state.table.baseCurrency,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get ratesJson => $state.composableBuilder(
      column: $state.table.ratesJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastModified => $state.composableBuilder(
      column: $state.table.lastModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$ExchangeRatesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get baseCurrency => $state.composableBuilder(
      column: $state.table.baseCurrency,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get ratesJson => $state.composableBuilder(
      column: $state.table.ratesJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastModified => $state.composableBuilder(
      column: $state.table.lastModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$BudgetSuggestionsTableCreateCompanionBuilder
    = BudgetSuggestionsCompanion Function({
  Value<int> id,
  required String monthId,
  required String userId,
  required String suggestions,
  required DateTime timestamp,
  Value<bool> isRead,
});
typedef $$BudgetSuggestionsTableUpdateCompanionBuilder
    = BudgetSuggestionsCompanion Function({
  Value<int> id,
  Value<String> monthId,
  Value<String> userId,
  Value<String> suggestions,
  Value<DateTime> timestamp,
  Value<bool> isRead,
});

class $$BudgetSuggestionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BudgetSuggestionsTable,
    BudgetSuggestion,
    $$BudgetSuggestionsTableFilterComposer,
    $$BudgetSuggestionsTableOrderingComposer,
    $$BudgetSuggestionsTableCreateCompanionBuilder,
    $$BudgetSuggestionsTableUpdateCompanionBuilder> {
  $$BudgetSuggestionsTableTableManager(
      _$AppDatabase db, $BudgetSuggestionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BudgetSuggestionsTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$BudgetSuggestionsTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> monthId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> suggestions = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
          }) =>
              BudgetSuggestionsCompanion(
            id: id,
            monthId: monthId,
            userId: userId,
            suggestions: suggestions,
            timestamp: timestamp,
            isRead: isRead,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String monthId,
            required String userId,
            required String suggestions,
            required DateTime timestamp,
            Value<bool> isRead = const Value.absent(),
          }) =>
              BudgetSuggestionsCompanion.insert(
            id: id,
            monthId: monthId,
            userId: userId,
            suggestions: suggestions,
            timestamp: timestamp,
            isRead: isRead,
          ),
        ));
}

class $$BudgetSuggestionsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BudgetSuggestionsTable> {
  $$BudgetSuggestionsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get monthId => $state.composableBuilder(
      column: $state.table.monthId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get suggestions => $state.composableBuilder(
      column: $state.table.suggestions,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isRead => $state.composableBuilder(
      column: $state.table.isRead,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$BudgetSuggestionsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BudgetSuggestionsTable> {
  $$BudgetSuggestionsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get monthId => $state.composableBuilder(
      column: $state.table.monthId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get suggestions => $state.composableBuilder(
      column: $state.table.suggestions,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isRead => $state.composableBuilder(
      column: $state.table.isRead,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$RecurringExpensesTableTableManager get recurringExpenses =>
      $$RecurringExpensesTableTableManager(_db, _db.recurringExpenses);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$ExchangeRatesTableTableManager get exchangeRates =>
      $$ExchangeRatesTableTableManager(_db, _db.exchangeRates);
  $$BudgetSuggestionsTableTableManager get budgetSuggestions =>
      $$BudgetSuggestionsTableTableManager(_db, _db.budgetSuggestions);
}
