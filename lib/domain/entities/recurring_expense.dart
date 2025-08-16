/// Recurring frequency options
enum RecurringFrequency {
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

/// Recurring details entity for expenses with recurring status
/// This will be stored as an embedded field within the expense document
class RecurringDetails {
  /// Frequency of recurrence (weekly or monthly only)
  final RecurringFrequency frequency;

  /// Day of month for monthly recurring (1-31)
  /// If the day doesn't exist in a month, it will use the last day of that month
  final int? dayOfMonth;

  /// Day of week for weekly recurring
  final DayOfWeek? dayOfWeek;

  /// Optional end date for the recurring expense
  final DateTime? endDate;
  
  /// Last processed date - tracks when this recurring expense was last processed
  /// This prevents duplicate expense creation
  final DateTime? lastProcessedDate;

  RecurringDetails({
    required this.frequency,
    this.dayOfMonth,
    this.dayOfWeek,
    this.endDate,
    this.lastProcessedDate,
  }) : assert(
            (frequency == RecurringFrequency.weekly && dayOfWeek != null) ||
                (frequency == RecurringFrequency.monthly && dayOfMonth != null),
            'Weekly frequency requires dayOfWeek, monthly frequency requires dayOfMonth');

  /// Creates a copy of this RecurringDetails with the given fields replaced
  RecurringDetails copyWith({
    RecurringFrequency? frequency,
    int? dayOfMonth,
    DayOfWeek? dayOfWeek,
    DateTime? endDate,
    DateTime? lastProcessedDate,
  }) {
    return RecurringDetails(
      frequency: frequency ?? this.frequency,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      endDate: endDate ?? this.endDate,
      lastProcessedDate: lastProcessedDate ?? this.lastProcessedDate,
    );
  }

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.displayName,
      'dayOfMonth': dayOfMonth,
      'dayOfWeek': dayOfWeek?.displayName,
      'endDate': endDate?.toIso8601String(),
      'lastProcessedDate': lastProcessedDate?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory RecurringDetails.fromJson(Map<String, dynamic> json) {
    return RecurringDetails(
      frequency: RecurringFrequencyExtension.fromDisplayName(
              json['frequency'] as String) ??
          RecurringFrequencyExtension.fromId(json['frequency'] as String) ??
          RecurringFrequency.monthly,
      dayOfMonth: json['dayOfMonth'] as int?,
      dayOfWeek: json['dayOfWeek'] != null
          ? DayOfWeekExtension.fromDisplayName(json['dayOfWeek'] as String) ??
              DayOfWeekExtension.fromId(json['dayOfWeek'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      lastProcessedDate: json['lastProcessedDate'] != null
          ? DateTime.parse(json['lastProcessedDate'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringDetails &&
          runtimeType == other.runtimeType &&
          frequency == other.frequency &&
          dayOfMonth == other.dayOfMonth &&
          dayOfWeek == other.dayOfWeek &&
          endDate == other.endDate &&
          lastProcessedDate == other.lastProcessedDate;

  @override
  int get hashCode =>
      frequency.hashCode ^
      dayOfMonth.hashCode ^
      dayOfWeek.hashCode ^
      endDate.hashCode ^
      lastProcessedDate.hashCode;

  @override
  String toString() {
    return 'RecurringDetails{frequency: $frequency, dayOfMonth: $dayOfMonth, dayOfWeek: $dayOfWeek, endDate: $endDate, lastProcessedDate: $lastProcessedDate}';
  }
}

/// Extension methods for RecurringFrequency
extension RecurringFrequencyExtension on RecurringFrequency {
  String get id {
    return toString().split('.').last;
  }

  String get displayName {
    switch (this) {
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

  static RecurringFrequency? fromDisplayName(String displayName) {
    try {
      return RecurringFrequency.values.firstWhere(
        (frequency) => frequency.displayName == displayName,
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

  static DayOfWeek? fromDisplayName(String displayName) {
    try {
      return DayOfWeek.values.firstWhere(
        (day) => day.displayName == displayName,
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
