import 'dart:collection';

import 'package:budgie/domain/entities/category.dart';
import 'package:flutter/foundation.dart';

import '../../entities/expense.dart';
import '../../../data/infrastructure/services/settings_service.dart';

/// Use case for calculating expense totals and category totals
class CalculateExpenseTotalsUseCase {
  final SettingsService _settingsService;

  String? _lastCacheKey;
  Map<String, double> _cachedCategoryTotals = const <String, double>{};
  UnmodifiableMapView<String, double> _cachedCategoryTotalsView =
      _emptyUnmodifiableMap;
  double _cachedTotal = 0.0;

  static const Map<String, Map<String, double>> _fallbackRates = {
    'MYR': {'USD': 0.21, 'EUR': 0.19, 'GBP': 0.17},
    'USD': {'MYR': 4.73, 'EUR': 0.92, 'GBP': 0.79},
    'EUR': {'MYR': 5.26, 'USD': 1.09, 'GBP': 0.86},
    'GBP': {'MYR': 6.12, 'USD': 1.26, 'EUR': 1.16},
  };

  static final UnmodifiableMapView<String, double> _emptyUnmodifiableMap =
      UnmodifiableMapView(const <String, double>{});

  CalculateExpenseTotalsUseCase({
    required SettingsService settingsService,
  }) : _settingsService = settingsService;

  Future<Map<String, double>> getCategoryTotals(List<Expense> expenses) {
    if (expenses.isEmpty) {
      _resetCache(currency: _settingsService.currency, keySuffix: 'empty');
      return SynchronousFuture(_emptyUnmodifiableMap);
    }

    final String targetCurrency = _settingsService.currency;
    final cacheKey = _buildCacheKey(expenses, targetCurrency);

    if (_lastCacheKey != cacheKey) {
      _refreshCache(expenses, cacheKey, targetCurrency);
    }

    return SynchronousFuture(_cachedCategoryTotalsView);
  }

  Future<double> getTotalExpenses(List<Expense> expenses) {
    if (expenses.isEmpty) {
      _resetCache(currency: _settingsService.currency, keySuffix: 'empty');
      return SynchronousFuture(0.0);
    }

    final String targetCurrency = _settingsService.currency;
    final cacheKey = _buildCacheKey(expenses, targetCurrency);

    if (_lastCacheKey != cacheKey) {
      _refreshCache(expenses, cacheKey, targetCurrency);
    }

    return SynchronousFuture(_cachedTotal);
  }

  void _refreshCache(
    List<Expense> expenses,
    String cacheKey,
    String targetCurrency,
  ) {
    final Map<String, double> categoryTotals = <String, double>{};
    double total = 0.0;

    for (final expense in expenses) {
      final double convertedAmount = _convertAmount(expense, targetCurrency);
      final String categoryId = expense.category.id;

      categoryTotals[categoryId] =
          (categoryTotals[categoryId] ?? 0.0) + convertedAmount;
      total += convertedAmount;
    }

    _lastCacheKey = cacheKey;
    _cachedCategoryTotals = categoryTotals;
    _cachedCategoryTotalsView = UnmodifiableMapView(_cachedCategoryTotals);
    _cachedTotal = total;
  }

  void _resetCache({
    required String currency,
    required String keySuffix,
  }) {
    _lastCacheKey = '$currency|$keySuffix';
    _cachedCategoryTotals = const <String, double>{};
    _cachedCategoryTotalsView = _emptyUnmodifiableMap;
    _cachedTotal = 0.0;
  }

  double _convertAmount(Expense expense, String targetCurrency) {
    if (expense.currency == targetCurrency) {
      return expense.amount;
    }

    final rate = _getApproximateConversionRate(
      expense.currency,
      targetCurrency,
    );
    return expense.amount * rate;
  }

  double _getApproximateConversionRate(String from, String to) {
    if (from == to) return 1.0;

    final rate = _fallbackRates[from]?[to];
    if (rate != null) {
      return rate;
    }

    if (kDebugMode) {
      debugPrint('No conversion rate found for $from to $to, using 1.0');
    }
    return 1.0;
  }

  String _buildCacheKey(List<Expense> expenses, String targetCurrency) {
    final buffer = StringBuffer(targetCurrency)
      ..write('|')
      ..write(expenses.length);

    for (final expense in expenses) {
      buffer
        ..write('|')
        ..write(expense.id)
        ..write('@')
        ..write(expense.amount.toStringAsFixed(4))
        ..write('#')
        ..write(expense.date.microsecondsSinceEpoch)
        ..write('%')
        ..write(expense.currency);
    }

    return buffer.toString();
  }
}
