import 'package:flutter/foundation.dart';
import '../../entities/budget.dart';
import '../../repositories/budget_repository.dart';
import '../../../data/infrastructure/services/currency_conversion_service.dart';

/// Use case for converting budget currency
class ConvertBudgetCurrencyUseCase {
  final BudgetRepository _budgetRepository;
  final CurrencyConversionService _currencyConversionService;

  // Flag to track if a currency conversion is in progress
  bool _isConvertingCurrency = false;

  ConvertBudgetCurrencyUseCase({
    required BudgetRepository budgetRepository,
    required CurrencyConversionService currencyConversionService,
  })  : _budgetRepository = budgetRepository,
        _currencyConversionService = currencyConversionService;

  /// Execute currency conversion for a budget
  Future<Budget?> execute(String monthId, String targetCurrency) async {
    try {
      final budget = await _budgetRepository.getBudget(monthId);

      // If no budget or already in progress or currencies match, skip conversion
      if (budget == null ||
          _isConvertingCurrency ||
          budget.currency == targetCurrency) {
        debugPrint(
            'Currency check - No conversion needed: ${budget?.currency ?? 'No budget'} -> $targetCurrency');
        return budget;
      }

      debugPrint('Currency check - STARTING conversion check');
      debugPrint(
          'Current budget currency: ${budget.currency}, Target currency: $targetCurrency');
      debugPrint('Current budget total: ${budget.total}');

      // If currencies differ, perform conversion
      if (budget.currency != targetCurrency) {
        debugPrint(
            'Currency conversion NEEDED - converting ${budget.currency} to $targetCurrency');
        final convertedBudget =
            await _convertBudget(budget, targetCurrency, monthId);
        debugPrint(
            'After conversion - Budget currency: ${convertedBudget?.currency}, Budget total: ${convertedBudget?.total}');
        return convertedBudget;
      }

      return budget;
    } catch (e) {
      debugPrint('Error checking/converting budget currency: $e');
      // Reset the conversion flag in case of error to prevent deadlock
      _isConvertingCurrency = false;
      // Don't rethrow - this is a background operation
      return null;
    }
  }

  /// Convert budget to new currency
  Future<Budget?> _convertBudget(
      Budget budget, String newCurrency, String monthId) async {
    // Check if the currency is already the same
    if (budget.currency == newCurrency) {
      print('Budget currency already matches new currency: $newCurrency');
      return budget;
    }

    // Check if a conversion is already in progress
    if (_isConvertingCurrency) {
      print(
          'Currency conversion already in progress, skipping duplicate request');
      return budget;
    }

    try {
      // Set the conversion flag to prevent duplicate conversions
      _isConvertingCurrency = true;

      print(
          'Currency changed to $newCurrency - updating budget from ${budget.currency}');
      print('Before conversion - Budget total: ${budget.total}');

      // Convert the budget using our enhanced CurrencyConversionService
      final oldCurrency = budget.currency;

      // Create a new Budget object with converted values
      final newCategories = <String, CategoryBudget>{};

      // Convert each category budget
      for (final entry in budget.categories.entries) {
        final categoryId = entry.key;
        final categoryBudget = entry.value;

        // Convert budget and left amounts
        final convertedBudget = await _currencyConversionService
            .convertCurrency(categoryBudget.budget, oldCurrency, newCurrency);

        final convertedLeft = await _currencyConversionService.convertCurrency(
            categoryBudget.left, oldCurrency, newCurrency);

        newCategories[categoryId] = CategoryBudget(
          budget: convertedBudget,
          left: convertedLeft,
        );

        print(
            'Converted category "$categoryId": Budget ${categoryBudget.budget} $oldCurrency → $convertedBudget $newCurrency');
      }

      // Convert total, left, and saving amounts
      final convertedTotal = await _currencyConversionService.convertCurrency(
          budget.total, oldCurrency, newCurrency);

      final convertedLeft = await _currencyConversionService.convertCurrency(
          budget.left, oldCurrency, newCurrency);

      final convertedSaving = await _currencyConversionService.convertCurrency(
          budget.saving, oldCurrency, newCurrency);

      // Create the new budget with converted values
      final convertedBudget = Budget(
        total: convertedTotal,
        left: convertedLeft,
        categories: newCategories,
        saving: convertedSaving,
        currency: newCurrency,
      );

      print(
          'Converted total budget: ${budget.total} $oldCurrency → ${convertedBudget.total} $newCurrency');
      print(
          'Converted left budget: ${budget.left} $oldCurrency → ${convertedBudget.left} $newCurrency');
      print(
          'Converted saving: ${budget.saving} $oldCurrency → ${convertedBudget.saving} $newCurrency');

      // Save the converted budget to Firebase
      print('Saving converted budget to Firebase with currency: $newCurrency');
      await _budgetRepository.setBudget(monthId, convertedBudget);

      print(
          'Budget successfully converted and saved with new currency: $newCurrency');
      print('Final budget total: ${convertedBudget.total}');

      return convertedBudget;
    } catch (e) {
      print('Error handling currency change: $e');
      rethrow;
    } finally {
      // Reset the conversion flag
      _isConvertingCurrency = false;
    }
  }
}
