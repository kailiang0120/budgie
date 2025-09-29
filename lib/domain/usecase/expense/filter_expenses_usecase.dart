import 'dart:collection';
import 'package:flutter/foundation.dart';

import '../../entities/expense.dart';

/// Use case for filtering expenses by various criteria
class FilterExpensesUseCase {
  static const int _cacheLimit = 24;

  // Cache mechanism
  final Map<String, List<Expense>> _cache = {};
  final ListQueue<String> _cacheOrder = ListQueue<String>();

  /// Filter expenses by month
  List<Expense> filterByMonth(List<Expense> expenses, DateTime selectedMonth,
      {bool isDayFiltering = false}) {
    final cacheKey = isDayFiltering
        ? '${selectedMonth.year}-${selectedMonth.month}-${selectedMonth.day}'
        : '${selectedMonth.year}-${selectedMonth.month}';

    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final bool shouldTraceMatches = kDebugMode && expenses.length <= 50;

    // Filter synchronously to avoid state inconsistency
    try {
      if (kDebugMode) {
        debugPrint('Filtering expenses for ${selectedMonth.toString()}');
        debugPrint('Total expenses available: ${expenses.length}');
        debugPrint(
            'Filtering for year: ${selectedMonth.year}, month: ${selectedMonth.month}');
      }

      List<Expense> filteredExpenses;

      if (isDayFiltering) {
        // Filter by exact date (day level)
        filteredExpenses = expenses.where((expense) {
          final matches = expense.date.year == selectedMonth.year &&
              expense.date.month == selectedMonth.month &&
              expense.date.day == selectedMonth.day;
          return matches;
        }).toList();
        if (shouldTraceMatches) {
          debugPrint(
              'Day filtering result: ${filteredExpenses.length} expenses for ${selectedMonth.year}-${selectedMonth.month}-${selectedMonth.day}');
        }
      } else {
        // Filter by month only
        filteredExpenses = expenses.where((expense) {
          final matches = expense.date.year == selectedMonth.year &&
              expense.date.month == selectedMonth.month;
          if (matches && shouldTraceMatches) {
            debugPrint(
                'Expense matches filter: ${expense.remark} - ${expense.date} (${expense.date.year}-${expense.date.month})');
          }
          return matches;
        }).toList();
        if (shouldTraceMatches) {
          debugPrint(
              'Month filtering result: ${filteredExpenses.length} expenses for ${selectedMonth.year}-${selectedMonth.month}');
        }
      }

      final result = List<Expense>.unmodifiable(filteredExpenses);
      _cache[cacheKey] = result;
      _cacheOrder.addLast(cacheKey);
      if (_cacheOrder.length > _cacheLimit) {
        final evictedKey = _cacheOrder.removeFirst();
        _cache.remove(evictedKey);
      }

      return result;
    } catch (e) {
      debugPrint('Error during expense filtering: $e');
      return const <Expense>[];
    }
  }

  /// Get expenses for a specific month
  List<Expense> getExpensesForMonth(
      List<Expense> expenses, int year, int month) {
    return expenses.where((expense) {
      return expense.date.year == year && expense.date.month == month;
    }).toList();
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    _cacheOrder.clear();
  }
}
