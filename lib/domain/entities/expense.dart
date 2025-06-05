import 'category.dart';

/// Available payment methods for expenses
enum PaymentMethod {
  creditCard,
  cash,
  eWallet,
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

  /// Currency code (default: MYR)
  final String currency;

  /// Reference to recurring expense if this expense was auto-generated
  final String? recurringExpenseId;

  /// Creates a new Expense instance
  Expense({
    required this.id,
    required this.remark,
    required this.amount,
    required this.date,
    required this.category,
    required this.method,
    this.description,
    this.currency = 'MYR',
    this.recurringExpenseId,
  });

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
    String? recurringExpenseId,
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
      recurringExpenseId: recurringExpenseId ?? this.recurringExpenseId,
    );
  }
}
