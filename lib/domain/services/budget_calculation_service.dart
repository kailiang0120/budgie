import '../entities/budget.dart';
import '../entities/category.dart';
import '../entities/expense.dart';
import '../../data/infrastructure/services/currency_conversion_service.dart';

/// Domain service responsible for calculating budget data based on expenses
class BudgetCalculationService {
  final CurrencyConversionService _currencyService;

  BudgetCalculationService({
    required CurrencyConversionService currencyService,
  }) : _currencyService = currencyService;

  /// Calculate total budget remaining amount and category-specific remaining budgets
  ///
  /// [budget] Original budget data
  /// [expenses] Expense list (must be filtered by month)
  ///
  /// Returns an updated Budget object with recalculated amounts
  Future<Budget> calculateBudget(Budget budget, List<Expense> expenses) async {
    return await _calculateBudgetDirect(budget, expenses);
  }

  /// Perform direct budget calculation with currency conversion support
  ///
  /// This method handles async currency conversion operations
  Future<Budget> _calculateBudgetDirect(
      Budget budget, List<Expense> expenses) async {
    final String budgetCurrency = budget.currency;
    final Map<String, double> categoryExpenses = {};

    // Calculate expenses for each category with currency conversion
    await _calculateCategoryExpenses(
        expenses, budgetCurrency, categoryExpenses);

    // Calculate total expenses across all categories
    final double totalExpenses = _calculateTotalExpenses(categoryExpenses);

    // Calculate remaining budget amount
    final double totalLeft = budget.total - totalExpenses;

    // Update category budgets with remaining amounts
    final Map<String, CategoryBudget> newCategories =
        _updateCategoryBudgets(budget.categories, categoryExpenses);

    // Create and return updated budget object
    return Budget(
      total: budget.total,
      left: totalLeft,
      categories: newCategories,
      currency: budgetCurrency,
    );
  }

  /// Calculate expenses per category with currency conversion if needed
  Future<void> _calculateCategoryExpenses(List<Expense> expenses,
      String budgetCurrency, Map<String, double> categoryExpenses) async {
    for (final expense in expenses) {
      final categoryId = expense.category.id;
      double convertedAmount = expense.amount;

      // Convert expense amount to budget currency if needed
      if (expense.currency != budgetCurrency) {
        try {
          convertedAmount = await _currencyService.convertCurrency(
              expense.amount, expense.currency, budgetCurrency);
        } catch (e) {
          // Use original amount if conversion fails
        }
      }

      // Add the (converted) amount to category total
      categoryExpenses[categoryId] =
          (categoryExpenses[categoryId] ?? 0) + convertedAmount;
    }
  }

  /// Calculate total expenses across all categories
  double _calculateTotalExpenses(Map<String, double> categoryExpenses) {
    return categoryExpenses.values.fold(0.0, (sum, amount) => sum + amount);
  }

  /// Update each category budget with calculated remaining amounts
  Map<String, CategoryBudget> _updateCategoryBudgets(
      Map<String, CategoryBudget> originalCategories,
      Map<String, double> categoryExpenses) {
    final Map<String, CategoryBudget> newCategories = {};

    for (final entry in originalCategories.entries) {
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
    }

    return newCategories;
  }
}
