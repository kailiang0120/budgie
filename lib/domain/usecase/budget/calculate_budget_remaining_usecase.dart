import '../../entities/budget.dart';
import '../../entities/expense.dart';
import '../../../data/infrastructure/services/currency_conversion_service.dart';
import '../../../data/infrastructure/errors/app_error.dart';
import '../../services/budget_calculation_service.dart';

/// Use case for calculating budget remaining amounts
class CalculateBudgetRemainingUseCase {
  final CurrencyConversionService _currencyConversionService;
  final BudgetCalculationService _budgetCalculationService;

  CalculateBudgetRemainingUseCase({
    required CurrencyConversionService currencyConversionService,
    required BudgetCalculationService budgetCalculationService,
  })  : _currencyConversionService = currencyConversionService,
        _budgetCalculationService = budgetCalculationService;

  /// Execute the calculate budget remaining use case
  Future<Budget> execute(Budget budget, List<Expense> expenses) async {
    try {
      // Convert expenses to budget currency if needed
      final convertedExpenses =
          await _convertExpensesToBudgetCurrency(budget, expenses);

      // Use budget calculation service to calculate remaining budget
      final updatedBudget = await Future.microtask(() async {
        return await _budgetCalculationService.calculateBudget(
            budget, convertedExpenses);
      });

      return updatedBudget;
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      rethrow;
    }
  }

  /// Convert expenses to the same currency as the budget
  Future<List<Expense>> _convertExpensesToBudgetCurrency(
      Budget budget, List<Expense> expenses) async {
    if (expenses.isEmpty) {
      return expenses;
    }

    final budgetCurrency = budget.currency;
    final result = <Expense>[];

    print(
        'Converting ${expenses.length} expenses to budget currency: $budgetCurrency');
    int convertedCount = 0;

    for (final expense in expenses) {
      if (expense.currency == budgetCurrency) {
        // No conversion needed
        result.add(expense);
      } else {
        try {
          // Convert expense amount to budget currency
          final convertedAmount =
              await _currencyConversionService.convertCurrency(
            expense.amount,
            expense.currency,
            budgetCurrency,
          );

          convertedCount++;
          if (convertedCount <= 3) {
            // Only log a few conversions to avoid log spam
            print(
                'Converted expense: ${expense.amount} ${expense.currency} → $convertedAmount $budgetCurrency (${expense.remark})');
          }

          // Create a copy of the expense with the converted amount and budget currency
          final convertedExpense = expense.copyWith(
            amount: convertedAmount,
            currency: budgetCurrency,
          );

          result.add(convertedExpense);
        } catch (e) {
          print('Error converting expense currency: $e');
          // If conversion fails, use original expense
          result.add(expense);
        }
      }
    }

    if (convertedCount > 3) {
      print('Converted $convertedCount expenses to $budgetCurrency');
    }

    return result;
  }
}
