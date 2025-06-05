/// Recurring frequency options
enum RecurringFrequency {
  oneTime,
  weekly,
  monthly,
}

/// Day of week for weekly recurring
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

/// Recurring expense configuration entity
class RecurringExpense {
  /// Unique identifier for the recurring expense
  final String id;

  /// Frequency of recurrence
  final RecurringFrequency frequency;

  /// Day of month for monthly recurring (1-31)
  /// If the day doesn't exist in a month, it will use the last day of that month
  final int? dayOfMonth;

  /// Day of week for weekly recurring
  final DayOfWeek? dayOfWeek;

  /// Start date for the recurring pattern
  final DateTime startDate;

  /// End date for the recurring pattern (null means indefinite)
  final DateTime? endDate;

  /// Whether this recurring expense is active
  final bool isActive;

  /// Date when this recurring expense was last processed
  final DateTime? lastProcessedDate;

  /// The base expense template
  final String expenseRemark;
  final double expenseAmount;
  final String expenseCategoryId;
  final String expensePaymentMethod;
  final String expenseCurrency;
  final String? expenseDescription;

  RecurringExpense({
    required this.id,
    required this.frequency,
    this.dayOfMonth,
    this.dayOfWeek,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.lastProcessedDate,
    required this.expenseRemark,
    required this.expenseAmount,
    required this.expenseCategoryId,
    required this.expensePaymentMethod,
    required this.expenseCurrency,
    this.expenseDescription,
  });

  /// Creates a copy of this RecurringExpense with the given fields replaced
  RecurringExpense copyWith({
    String? id,
    RecurringFrequency? frequency,
    int? dayOfMonth,
    DayOfWeek? dayOfWeek,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? lastProcessedDate,
    String? expenseRemark,
    double? expenseAmount,
    String? expenseCategoryId,
    String? expensePaymentMethod,
    String? expenseCurrency,
    String? expenseDescription,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
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
    );
  }
}

/// Extension methods for RecurringFrequency
extension RecurringFrequencyExtension on RecurringFrequency {
  String get id {
    return toString().split('.').last;
  }

  String get displayName {
    switch (this) {
      case RecurringFrequency.oneTime:
        return 'One-time';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
    }
  }

  static RecurringFrequency? fromId(String id) {
    try {
      return RecurringFrequency.values.firstWhere(
        (frequency) => frequency.id == id,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Extension methods for DayOfWeek
extension DayOfWeekExtension on DayOfWeek {
  String get id {
    return toString().split('.').last;
  }

  String get displayName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Monday';
      case DayOfWeek.tuesday:
        return 'Tuesday';
      case DayOfWeek.wednesday:
        return 'Wednesday';
      case DayOfWeek.thursday:
        return 'Thursday';
      case DayOfWeek.friday:
        return 'Friday';
      case DayOfWeek.saturday:
        return 'Saturday';
      case DayOfWeek.sunday:
        return 'Sunday';
    }
  }

  /// Convert to DateTime weekday (1 = Monday, 7 = Sunday)
  int get weekday {
    switch (this) {
      case DayOfWeek.monday:
        return 1;
      case DayOfWeek.tuesday:
        return 2;
      case DayOfWeek.wednesday:
        return 3;
      case DayOfWeek.thursday:
        return 4;
      case DayOfWeek.friday:
        return 5;
      case DayOfWeek.saturday:
        return 6;
      case DayOfWeek.sunday:
        return 7;
    }
  }

  static DayOfWeek? fromId(String id) {
    try {
      return DayOfWeek.values.firstWhere(
        (day) => day.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  static DayOfWeek fromWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return DayOfWeek.monday;
      case 2:
        return DayOfWeek.tuesday;
      case 3:
        return DayOfWeek.wednesday;
      case 4:
        return DayOfWeek.thursday;
      case 5:
        return DayOfWeek.friday;
      case 6:
        return DayOfWeek.saturday;
      case 7:
        return DayOfWeek.sunday;
      default:
        return DayOfWeek.monday;
    }
  }
}
