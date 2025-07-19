import 'currency_formatter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

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
  static double textSizeXXSmall = 10.sp; // Very tiny text (increased from 8.sp)
  static double textSizeXSmall =
      12.sp; // Extra small text (increased from 10.sp)
  static double textSizeSmall =
      14.sp; // Small text, subtitles (increased from 12.sp)
  static double textSizeMedium =
      16.sp; // Regular body text (increased from 14.sp)
  static double textSizeLarge =
      18.sp; // Large text, button text (increased from 16.sp)
  static double textSizeXLarge =
      20.sp; // Section headers (increased from 18.sp)
  static double textSizeXXLarge = 22.sp; // Screen titles (increased from 20.sp)
  static double textSizeHuge = 26.sp; // Large headers (increased from 24.sp)
  static double textSizeGiant = 30.sp; // Very large text (increased from 28.sp)

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
  static double iconSizeXLarge = 28.sp;
  static double iconSizeXXLarge = 32.sp;

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
  static double bottomPaddingWithNavBar =
      140.h; // Updated to 150px as requested

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

  /// Debug method to print text sizes and screen info
  static void debugTextSizes() {
    if (kDebugMode) {
      debugPrint('=== AppConstants Debug Info ===');
      debugPrint('Screen Width: ${1.sw}');
      debugPrint('Screen Height: ${1.sh}');
      debugPrint('Text Scale Factor: ${ScreenUtil().textScaleFactor}');
      debugPrint('Status Bar Height: ${ScreenUtil().statusBarHeight}');
      debugPrint('Bottom Bar Height: ${ScreenUtil().bottomBarHeight}');
      debugPrint('');
      debugPrint('Text Sizes:');
      debugPrint(
          'textSizeXXSmall: ${textSizeXXSmall}sp = ${textSizeXXSmall.sp}px');
      debugPrint(
          'textSizeXSmall: ${textSizeXSmall}sp = ${textSizeXSmall.sp}px');
      debugPrint('textSizeSmall: ${textSizeSmall}sp = ${textSizeSmall.sp}px');
      debugPrint(
          'textSizeMedium: ${textSizeMedium}sp = ${textSizeMedium.sp}px');
      debugPrint('textSizeLarge: ${textSizeLarge}sp = ${textSizeLarge.sp}px');
      debugPrint(
          'textSizeXLarge: ${textSizeXLarge}sp = ${textSizeXLarge.sp}px');
      debugPrint(
          'textSizeXXLarge: ${textSizeXXLarge}sp = ${textSizeXXLarge.sp}px');
      debugPrint('textSizeHuge: ${textSizeHuge}sp = ${textSizeHuge.sp}px');
      debugPrint('textSizeGiant: ${textSizeGiant}sp = ${textSizeGiant.sp}px');
      debugPrint('==============================');
    }
  }
}
