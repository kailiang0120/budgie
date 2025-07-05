import 'currency_formatter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

/// Application constants management class
class AppConstants {
  /// Currency list - BNM supported currencies for better exchange rate accuracy
  /// Ordered by popularity for Malaysian users
  static final List<String> currencies = [
    'MYR', // Malaysian Ringgit (base currency)
    'USD', // US Dollar
    'SGD', // Singapore Dollar
    'EUR', // Euro
    'CNY', // Chinese Yuan
    'AUD', // Australian Dollar
    'IDR', // Indonesian Rupiah
  ];

  /// Get all supported currencies from formatter (includes BNM supported currencies)
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
  static const String shortDateFormat = 'MMM dd, yyyy';
  static const String shortTimeFormat = 'HH:mm';

  /// Form validation messages
  static const String requiredFieldMessage = 'This field is required';
  static const String invalidNumberMessage = 'Please enter a valid number';
  static const String positiveNumberMessage =
      'Amount must be greater than zero';

  /// Success messages
  static const String expenseAddedMessage = 'Expense added successfully';
  static const String budgetSavedMessage = 'Budget saved successfully';
  static const String dataRefreshedMessage = 'Data refreshed successfully';
  static const String expenseDeletedMessage = 'Expense deleted successfully';

  /// Error messages
  static const String generalErrorMessage =
      'An error occurred. Please try again.';
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String dataLoadErrorMessage =
      'Failed to load data. Please try again.';

  /// Screen titles
  static const String newExpenseTitle = 'New Expense';
  static const String setBudgetTitle = 'Set Budget';
  static const String analyticsTitle = 'Analytics';
  static const String settingsTitle = 'Settings';
  static const String homeTitle = 'Home';
  static const String goalsTitle = 'Financial Goals';
  static const String editExpenseTitle = 'Edit Expense';

  /// Button texts
  static const String saveButtonText = 'Save';
  static const String addButtonText = 'Add';
  static const String cancelButtonText = 'Cancel';
  static const String currentTimeButtonText = 'Current Time';
  static const String deleteButtonText = 'Delete';
  static const String confirmButtonText = 'Confirm';
  static const String editButtonText = 'Edit';
  static const String refreshButtonText = 'Refresh';
  static const String closeButtonText = 'Close';

  /// Action in progress status texts
  static const String addingText = 'Adding...';
  static const String savingText = 'Saving...';
  static const String loadingText = 'Loading...';
  static const String deletingText = 'Deleting...';
  static const String processingText = 'Processing...';

  /// Card titles
  static const String budgetCardTitle = 'Total Budget';
  static const String expensesCardTitle = 'Expenses';
  static const String categoryDistributionTitle = 'Category Distribution';
  static const String spendingTrendsTitle = 'Spending Trends';
  static const String topCategoriesTitle = 'Top Categories';
  static const String dailySpendingTitle = 'Daily Spending Pattern';

  /// Profile section titles
  static const String dataManagementTitle = 'Data Management';
  static const String syncDataTitle = 'Sync Data';
  static const String refreshDataTitle = 'Refresh Data';
  static const String exportDataTitle = 'Export Data';

  /// Text sizes - Using consistent sizes throughout the app
  static double textSizeXXSmall = 8.sp; // Very tiny text
  static double textSizeXSmall = 10.sp; // Extra small text
  static double textSizeSmall = 12.sp; // Small text, subtitles
  static double textSizeMedium = 14.sp; // Regular body text
  static double textSizeLarge = 16.sp; // Large text, button text
  static double textSizeXLarge = 18.sp; // Section headers
  static double textSizeXXLarge = 20.sp; // Screen titles
  static double textSizeHuge = 24.sp; // Large headers
  static double textSizeGiant = 28.sp; // Very large text

  /// Spacing constants
  static double spacingXXSmall = 2.sp;
  static double spacingXSmall = 4.sp;
  static double spacingSmall = 8.sp;
  static double spacingMedium = 12.sp;
  static double spacingLarge = 16.sp;
  static double spacingXLarge = 20.sp;
  static double spacingXXLarge = 24.sp;
  static double spacingHuge = 32.sp;

  /// Icon sizes
  static double iconSizeSmall = 16.sp;
  static double iconSizeMedium = 20.sp;
  static double iconSizeLarge = 24.sp;
  static double iconSizeXLarge = 32.sp;

  /// Border radius
  static double borderRadiusSmall = 8.sp;
  static double borderRadiusMedium = 12.sp;
  static double borderRadiusLarge = 16.sp;
  static double borderRadiusXLarge = 24.sp;
  static double borderRadiusCircular = 45.sp;

  /// Card elevations
  static double elevationSmall = 1.0;
  static double elevationStandard = 2.0;
  static double elevationLarge = 4.0;

  /// Animation durations
  static const Duration animationDurationShort = Duration(milliseconds: 150);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);

  /// Opacity values
  static const double opacityDisabled = 0.6;
  static const double opacityOverlay = 0.1;
  static const double opacityLow = 0.3;
  static const double opacityMedium = 0.2;
  static const double opacityHigh = 0.3;
  static const double opacityVeryHigh = 0.4;
  static const double opacityFull = 0.7;

  /// Component sizes
  static double componentHeightSmall = 36.h;
  static double componentHeightStandard = 48.h;
  static double componentHeightLarge = 56.h;

  /// Bottom padding for screens with FAB and bottom nav
  static double bottomPaddingWithNavBar = 90.h;

  /// Container padding
  static EdgeInsets containerPaddingSmall = EdgeInsets.all(spacingSmall.w);
  static EdgeInsets containerPaddingMedium = EdgeInsets.all(spacingMedium.w);
  static EdgeInsets containerPaddingLarge = EdgeInsets.all(spacingLarge.w);

  /// Card margins
  static EdgeInsets cardMarginStandard =
      EdgeInsets.only(bottom: spacingLarge.h);
  static EdgeInsets cardMarginSmall = EdgeInsets.only(bottom: spacingSmall.h);

  /// Screen paddings
  static EdgeInsets screenPadding = EdgeInsets.all(spacingLarge.w);
  static EdgeInsets screenPaddingHorizontal =
      EdgeInsets.symmetric(horizontal: spacingLarge.w);
  static EdgeInsets screenPaddingVertical =
      EdgeInsets.symmetric(vertical: spacingLarge.h);
}
