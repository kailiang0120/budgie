import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/expense.dart';
import '../../presentation/utils/category_manager.dart';
import 'currency_conversion_service.dart';

/// Budget calculation service class
class BudgetCalculationService {
  static final CurrencyConversionService _currencyService =
      CurrencyConversionService();

  /// Calculate total budget remaining amount and category remaining budgets
  ///
  /// [budget] Original budget data
  /// [expenses] Expense list (must be filtered by month)
  /// Returns updated budget object
  static Future<Budget> calculateBudget(
      Budget budget, List<Expense> expenses) async {
    // debugPrint('🧮 Starting budget calculation');
    // debugPrint('🧮 Budget currency: ${budget.currency}');

    // Create a copy we can modify directly instead of using compute
    // This avoids the async limitation in compute
    final result = _calculateBudgetDirect(budget, expenses);

    return result;
  }

  /// Direct calculation function that can handle async operations
  static Future<Budget> _calculateBudgetDirect(
      Budget budget, List<Expense> expenses) async {
    final String budgetCurrency = budget.currency;

    // debugPrint('🧮 Calculating budget with currency: $budgetCurrency');
    // debugPrint('🧮 Total budget amount: ${budget.total}');
    // debugPrint('🧮 Number of expenses to process: ${expenses.length}');

    // Create category expense mapping
    final Map<String, double> categoryExpenses = {};

    // Calculate total expenses for each category
    // Note: assumes expenses are already filtered by month
    for (final expense in expenses) {
      final categoryId = expense.category.id;

      // Convert expense amount to budget currency if needed
      double convertedAmount = expense.amount;

      if (expense.currency != budgetCurrency) {
        try {
          // Convert the expense amount to budget currency
          convertedAmount = await _currencyService.convertCurrency(
              expense.amount, expense.currency, budgetCurrency);

          // debugPrint('🧮 Converted ${expense.amount} ${expense.currency} to $convertedAmount $budgetCurrency');
        } catch (e) {
          // debugPrint('🧮 Error converting currency: $e');
          // debugPrint('🧮 Using original amount due to conversion error');
        }
      }

      // Add the (converted) amount to category total
      categoryExpenses[categoryId] =
          (categoryExpenses[categoryId] ?? 0) + convertedAmount;
    }

    // Log category totals for debugging
    categoryExpenses.forEach((categoryId, amount) {
      final categoryName = CategoryManager.getNameFromId(categoryId);
      // debugPrint('🧮 Category "$categoryName" total expenses: $amount $budgetCurrency');
    });

    // Calculate total expenses
    final double totalExpenses =
        categoryExpenses.values.fold(0.0, (sum, amount) => sum + amount);

    // debugPrint('🧮 Total expenses (converted to $budgetCurrency): $totalExpenses');

    // Calculate total remaining budget
    final double totalLeft = budget.total - totalExpenses;
    // debugPrint('🧮 Remaining budget: $totalLeft $budgetCurrency');

    // Create new category budget mapping
    final Map<String, CategoryBudget> newCategories = {};

    // Update remaining budget for each category
    for (final entry in budget.categories.entries) {
      final String categoryId = entry.key;
      final CategoryBudget categoryBudget = entry.value;

      // Get expenses for this category
      final double categoryExpense = categoryExpenses[categoryId] ?? 0;

      // Calculate category remaining budget
      final double categoryLeft = categoryBudget.budget - categoryExpense;

      // Create new category budget object
      newCategories[categoryId] = CategoryBudget(
        budget: categoryBudget.budget,
        left: categoryLeft,
      );

      //   debugPrint('🧮 Category "${CategoryManager.getNameFromId(categoryId)}" budget: ${categoryBudget.budget}, spent: $categoryExpense, left: $categoryLeft');
    }

    // Create and return new budget object
    return Budget(
      total: budget.total,
      left: totalLeft,
      categories: newCategories,
      currency: budgetCurrency,
    );
  }
}

/// Calculation parameters class for compute function
class _CalculationParams {
  final Budget budget;
  final List<Expense> expenses;

  _CalculationParams({
    required this.budget,
    required this.expenses,
  });
}
