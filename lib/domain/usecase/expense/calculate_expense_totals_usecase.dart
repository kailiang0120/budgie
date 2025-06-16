import 'package:budgie/domain/entities/category.dart';
import 'package:flutter/foundation.dart';

import '../../entities/expense.dart';
import '../../../data/infrastructure/services/settings_service.dart';

/// Use case for calculating expense totals and category totals
class CalculateExpenseTotalsUseCase {
  final SettingsService _settingsService;

  CalculateExpenseTotalsUseCase({
    required SettingsService settingsService,
  }) : _settingsService = settingsService;

  /// Get total expenses for the selected month by category with currency conversion
  Future<Map<String, double>> getCategoryTotals(List<Expense> expenses) async {
    if (expenses.isEmpty) {
      return {};
    }

    return await Future.microtask(() async {
      final Map<String, double> result = {};
      final String targetCurrency =
          _settingsService.currency; // Use user's preferred currency

      // Use a converter to handle currency conversion
      for (var expense in expenses) {
        final String categoryId = expense.category.id;
        double convertedAmount = expense.amount;

        // If expense currency doesn't match target currency, convert it
        if (expense.currency != targetCurrency) {
          // Since currency conversion is async, we use cached rates or defaults
          final conversionRate =
              _getApproximateConversionRate(expense.currency, targetCurrency);
          convertedAmount = expense.amount * conversionRate;
        }

        result[categoryId] = (result[categoryId] ?? 0) + convertedAmount;
      }

      return result;
    });
  }

  /// Get total expenses for the selected month with currency conversion
  Future<double> getTotalExpenses(List<Expense> expenses) async {
    if (expenses.isEmpty) {
      return 0.0;
    }

    return await Future.microtask(() async {
      final String targetCurrency = _settingsService.currency;
      double total = 0.0;

      for (var expense in expenses) {
        if (expense.currency == targetCurrency) {
          // No conversion needed
          total += expense.amount;
        } else {
          // Convert currency
          final conversionRate =
              _getApproximateConversionRate(expense.currency, targetCurrency);
          total += expense.amount * conversionRate;
        }
      }

      return total;
    });
  }

  /// Get approximate conversion rate for synchronous operations
  double _getApproximateConversionRate(String from, String to) {
    // If currencies are the same, no conversion needed
    if (from == to) return 1.0;

    // Simple hardcoded conversion rates for common currencies
    final Map<String, Map<String, double>> rates = {
      'MYR': {'USD': 0.21, 'EUR': 0.19, 'GBP': 0.17},
      'USD': {'MYR': 4.73, 'EUR': 0.92, 'GBP': 0.79},
      'EUR': {'MYR': 5.26, 'USD': 1.09, 'GBP': 0.86},
      'GBP': {'MYR': 6.12, 'USD': 1.26, 'EUR': 1.16},
    };

    // Check if we have the conversion rate
    if (rates.containsKey(from) && rates[from]!.containsKey(to)) {
      return rates[from]![to]!;
    }

    // Fallback to default rate of 1.0
    debugPrint('No conversion rate found for $from to $to, using 1.0');
    return 1.0;
  }
}
