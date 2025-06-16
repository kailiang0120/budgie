import 'category.dart';
import 'constants.dart';
import 'recurring_expense.dart';

/// Available payment methods for expenses
enum PaymentMethod {
  card,
  cash,
  eWallet,
  bankTransfer,
  other,
}

/// Expense entity representing a financial expense record
class Expense {
  /// Unique identifier for the expense
  final String id;

  /// Brief description or title of the expense
  final String remark;

  /// Amount spent
  final double amount;

  /// Date when the expense occurred
  final DateTime date;

  /// Category of the expense
  final Category category;

  /// Payment method used
  final PaymentMethod method;

  /// Optional detailed description
  final String? description;

  /// Currency code
  final String currency;

  /// Embedded recurring details - if present, this expense is recurring
  final RecurringDetails? recurringDetails;

  /// Whether this expense has recurring configuration
  bool get isRecurring => recurringDetails != null;

  /// Creates a new Expense instance
  Expense({
    required this.id,
    required this.remark,
    required this.amount,
    required this.date,
    required this.category,
    required this.method,
    this.description,
    String? currency,
    this.recurringDetails,
  }) : currency = currency ?? DomainConstants.defaultCurrency;

  /// Creates a copy of this Expense with the given fields replaced with new values
  Expense copyWith({
    String? id,
    String? remark,
    double? amount,
    DateTime? date,
    Category? category,
    PaymentMethod? method,
    String? description,
    String? currency,
    RecurringDetails? recurringDetails,
    bool clearRecurringDetails = false,
  }) {
    return Expense(
      id: id ?? this.id,
      remark: remark ?? this.remark,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      method: method ?? this.method,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      recurringDetails: clearRecurringDetails
          ? null
          : (recurringDetails ?? this.recurringDetails),
    );
  }
}
