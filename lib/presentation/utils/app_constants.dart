import 'currency_formatter.dart';

/// Application constants management class
class AppConstants {
  /// Currency list - use popular currencies for better UX
  static final List<String> currencies = [
    'MYR',
    'USD',
    'EUR',
    'GBP',
    'SGD',
    'JPY',
    'CNY',
    'THB',
    'INR',
    'AUD',
    'CAD',
    'HKD',
    'KRW',
    'CHF',
    'NZD',
    'PHP',
    'VND',
    'IDR'
  ];

  /// Get all supported currencies from formatter
  static List<String> getAllSupportedCurrencies() {
    return CurrencyFormatter.getSupportedCurrencies();
  }

  /// Payment methods list
  static const List<String> paymentMethods = [
    'Credit Card',
    'Cash',
    'e-Wallet'
  ];

  /// Recurring payment options
  static const List<String> recurringOptions = [
    'One-time',
    'Recurring Payment'
  ];

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
