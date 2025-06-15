import 'package:flutter/foundation.dart';
import 'constants.dart';

/// Budget allocation for a specific category
class CategoryBudget {
  /// Total budget allocated for this category
  final double budget;

  /// Remaining budget for this category
  final double left;

  /// Creates a new CategoryBudget instance
  CategoryBudget({required this.budget, required this.left});

  /// Converts the CategoryBudget to a Map for serialization
  Map<String, dynamic> toMap() => {
        'budget': budget,
        'left': left,
      };

  /// Creates a CategoryBudget from a Map
  factory CategoryBudget.fromMap(Map<String, dynamic> map) => CategoryBudget(
        budget: (map['budget'] as num?)?.toDouble() ?? 0,
        left: (map['left'] as num?)?.toDouble() ?? 0,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CategoryBudget) return false;

    // Use epsilon for double comparison to handle floating point precision issues
    return (other.budget - budget).abs() < DomainConstants.epsilon &&
        (other.left - left).abs() < DomainConstants.epsilon;
  }

  @override
  int get hashCode => budget.hashCode ^ left.hashCode;
}

/// Overall budget entity containing total budget and category-wise allocations
class Budget {
  /// Total budget amount
  final double total;

  /// Total remaining budget
  final double left;

  /// Budget allocations by category ID
  final Map<String, CategoryBudget> categories;

  /// Unallocated budget amount (saving)
  /// This represents the amount of total budget that hasn't been allocated to any category
  final double saving;

  /// Currency code
  final String currency;

  /// Creates a new Budget instance
  Budget({
    required this.total,
    required this.left,
    required this.categories,
    double? saving,
    String? currency,
  })  : saving = saving ?? _calculateSaving(total, categories),
        currency = currency ?? DomainConstants.defaultCurrency;

  /// Calculate saving amount from total budget and category allocations
  static double _calculateSaving(
      double total, Map<String, CategoryBudget> categories) {
    final totalAllocated =
        categories.values.fold(0.0, (sum, cat) => sum + cat.budget);
    return total - totalAllocated;
  }

  /// Converts the Budget to a Map for serialization
  Map<String, dynamic> toMap() => {
        'total': total,
        'left': left,
        'categories': categories.map((k, v) => MapEntry(k, v.toMap())),
        'saving': saving,
        'currency': currency,
      };

  /// Creates a Budget from a Map
  factory Budget.fromMap(Map<String, dynamic> map) {
    final total = (map['total'] as num?)?.toDouble() ?? 0;
    final categories = (map['categories'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, CategoryBudget.fromMap(v)));

    // If saving is not provided, calculate it from total and categories
    final saving = map['saving'] != null
        ? (map['saving'] as num?)?.toDouble() ?? 0
        : _calculateSaving(total, categories);

    return Budget(
      total: total,
      left: (map['left'] as num?)?.toDouble() ?? 0,
      categories: categories,
      saving: saving,
      currency: map['currency'] as String?,
    );
  }

  /// Creates a copy of this Budget with the given fields replaced with new values
  Budget copyWith({
    double? total,
    double? left,
    Map<String, CategoryBudget>? categories,
    double? saving,
    String? currency,
  }) {
    return Budget(
      total: total ?? this.total,
      left: left ?? this.left,
      categories: categories ?? this.categories,
      saving: saving ?? this.saving,
      currency: currency ?? this.currency,
    );
  }

  /// Creates a new Budget with all amounts converted to a different currency
  Budget convertCurrency(
      String newCurrency, Map<String, double> conversionRates) {
    // If currency is the same, return the same budget
    if (newCurrency == currency) {
      return this;
    }

    // Get conversion rate from current currency to new currency
    final conversionRate = conversionRates[newCurrency] ?? 1.0;

    // Log only if in debug mode
    if (kDebugMode) {
      debugPrint(
          '💱 Converting budget: $currency → $newCurrency (rate: $conversionRate)');
    }

    // Convert total, left, and saving amounts with 2 decimal precision
    final newTotal = double.parse((total * conversionRate).toStringAsFixed(2));
    final newLeft = double.parse((left * conversionRate).toStringAsFixed(2));
    final newSaving =
        double.parse((saving * conversionRate).toStringAsFixed(2));

    // Convert each category budget
    final newCategories = <String, CategoryBudget>{};
    for (final entry in categories.entries) {
      final categoryId = entry.key;
      final categoryBudget = entry.value;

      // Convert category budget and left amounts with 2 decimal precision
      final newCategoryBudget = double.parse(
          (categoryBudget.budget * conversionRate).toStringAsFixed(2));
      final newCategoryLeft = double.parse(
          (categoryBudget.left * conversionRate).toStringAsFixed(2));

      newCategories[categoryId] = CategoryBudget(
        budget: newCategoryBudget,
        left: newCategoryLeft,
      );
    }

    // Create new budget with converted amounts
    return Budget(
      total: newTotal,
      left: newLeft,
      categories: newCategories,
      saving: newSaving,
      currency: newCurrency,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Budget) return false;

    // Use epsilon for double comparison
    if ((other.total - total).abs() >= DomainConstants.epsilon ||
        (other.left - left).abs() >= DomainConstants.epsilon ||
        (other.saving - saving).abs() >= DomainConstants.epsilon ||
        other.currency != currency) {
      return false;
    }

    // Check if categories are the same
    if (other.categories.length != categories.length) {
      return false;
    }

    // Compare each category budget
    for (final entry in categories.entries) {
      final key = entry.key;
      final value = entry.value;

      if (!other.categories.containsKey(key)) {
        return false;
      }

      if (other.categories[key] != value) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode =>
      total.hashCode ^
      left.hashCode ^
      categories.hashCode ^
      saving.hashCode ^
      currency.hashCode;
}
