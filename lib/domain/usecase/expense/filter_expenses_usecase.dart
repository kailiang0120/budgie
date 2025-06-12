import 'package:flutter/foundation.dart';

import '../../entities/expense.dart';
import '../../../data/infrastructure/monitoring/performance_monitor.dart';

/// Use case for filtering expenses by various criteria
class FilterExpensesUseCase {
  // Cache mechanism
  final Map<String, List<Expense>> _cache = {};

  /// Filter expenses by month
  List<Expense> filterByMonth(List<Expense> expenses, DateTime selectedMonth,
      {bool isDayFiltering = false}) {
    PerformanceMonitor.startTimer('filter_expenses');

    final cacheKey = isDayFiltering
        ? '${selectedMonth.year}-${selectedMonth.month}-${selectedMonth.day}'
        : '${selectedMonth.year}-${selectedMonth.month}';

    // Use cached data if available
    if (_cache.containsKey(cacheKey)) {
      debugPrint(
          'Using cached data for $cacheKey: ${_cache[cacheKey]!.length} expenses');
      PerformanceMonitor.stopTimer('filter_expenses', logResult: true);
      return _cache[cacheKey]!;
    }

    // Filter synchronously to avoid state inconsistency
    try {
      debugPrint('Filtering expenses for ${selectedMonth.toString()}');
      debugPrint('Total expenses available: ${expenses.length}');
      debugPrint(
          'Filtering for year: ${selectedMonth.year}, month: ${selectedMonth.month}');

      List<Expense> filteredExpenses;

      if (isDayFiltering) {
        // Filter by exact date (day level)
        filteredExpenses = expenses.where((expense) {
          final matches = expense.date.year == selectedMonth.year &&
              expense.date.month == selectedMonth.month &&
              expense.date.day == selectedMonth.day;
          return matches;
        }).toList();
        debugPrint(
            'Day filtering result: ${filteredExpenses.length} expenses for ${selectedMonth.year}-${selectedMonth.month}-${selectedMonth.day}');
      } else {
        // Filter by month only
        filteredExpenses = expenses.where((expense) {
          final matches = expense.date.year == selectedMonth.year &&
              expense.date.month == selectedMonth.month;
          if (matches) {
            debugPrint(
                'Expense matches filter: ${expense.remark} - ${expense.date} (${expense.date.year}-${expense.date.month})');
          }
          return matches;
        }).toList();
        debugPrint(
            'Month filtering result: ${filteredExpenses.length} expenses for ${selectedMonth.year}-${selectedMonth.month}');
      }

      // Update cache
      _cache[cacheKey] = filteredExpenses;

      PerformanceMonitor.stopTimer('filter_expenses');
      return filteredExpenses;
    } catch (e) {
      debugPrint('Error during expense filtering: $e');
      PerformanceMonitor.stopTimer('filter_expenses');
      // Ensure valid list even if filtering fails
      return [];
    }
  }

  /// Get expenses for a specific month
  List<Expense> getExpensesForMonth(
      List<Expense> expenses, int year, int month) {
    return PerformanceMonitor.measure('get_expenses_for_month', () {
      return expenses.where((expense) {
        return expense.date.year == year && expense.date.month == month;
      }).toList();
    });
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }
}
