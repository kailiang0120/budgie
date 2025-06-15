import 'currency_formatter.dart';

/// Application constants management class
class AppConstants {
  /// Currency list - use popular currencies for better UX
  static final List<String> currencies = [
    'MYR',
    'USD',
    'EUR',
    'SGD',
    'JPY',
    'CNY',
  ];

  /// Get all supported currencies from formatter
  static List<String> getAllSupportedCurrencies() {
    return CurrencyFormatter.getSupportedCurrencies();
  }

  /// Payment methods list
  static const List<String> paymentMethods = [
    'Card',
    'Cash',
    'E-Wallet',
    'Bank Transfer',
    'Other'
  ];

  /// Recurring payment options
  static const List<String> recurringOptions = [
    'One-time',
    'Weekly',
    'Monthly'
  ];

  /// Days of week for weekly recurring
  static const List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  /// Days of month for monthly recurring (1-31)
  static List<String> getDaysOfMonth() {
    return List.generate(31, (index) => (index + 1).toString());
  }

  /// Date formats
  static const String dateFormat = 'yyyy MMMM dd';
  static const String timeFormat = 'HH : mm : ss';
  static const String monthYearFormat = 'MMMM yyyy';

  /// Form validation messages
  static const String requiredFieldMessage = 'This field is required';
  static const String invalidNumberMessage = 'Please enter a valid number';
  static const String positiveNumberMessage =
      'Amount must be greater than zero';

  /// Success messages
  static const String expenseAddedMessage = 'Expense added successfully';
  static const String budgetSavedMessage = 'Budget saved successfully';

  /// Error messages
  static const String generalErrorMessage =
      'An error occurred. Please try again.';

  /// Screen titles
  static const String newExpenseTitle = 'New Expenses';
  static const String setBudgetTitle = 'Set Budget';
  static const String analyticsTitle = 'Analytics';
  static const String settingsTitle = 'Settings';

  /// Button texts
  static const String saveButtonText = 'Save';
  static const String addButtonText = 'Add';
  static const String cancelButtonText = 'Cancel';
  static const String currentTimeButtonText = 'Current Time';

  /// Action in progress status texts
  static const String addingText = 'Adding...';
  static const String savingText = 'Saving...';
  static const String loadingText = 'Loading...';
}
