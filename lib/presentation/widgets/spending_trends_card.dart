import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../utils/category_manager.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import 'custom_card.dart';
import 'date_picker_button.dart';

class SpendingTrendsCard extends StatelessWidget {
  final DateTime selectedDate;
  final DateFilterMode? filterMode;

  const SpendingTrendsCard({
    Key? key,
    required this.selectedDate,
    this.filterMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final expensesViewModel = Provider.of<ExpensesViewModel>(context);

    // Ensure we're getting data for the selected period
    final hasExpenses = expensesViewModel.filteredExpenses.isNotEmpty;

    return CustomCard(
      padding: AppConstants.containerPaddingLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom header with proper date alignment
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Theme.of(context).colorScheme.primary,
                size: AppConstants.iconSizeMedium.sp,
              ),
              SizedBox(width: AppConstants.spacingSmall.w),
              Expanded(
                child: Text(
                  AppConstants.spendingTrendsTitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: AppConstants.textSizeXLarge.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
              Text(
                _getDateDisplayText(),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: AppConstants.textSizeSmall.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingLarge.h),

          // If there's no data, show a placeholder
          if (!hasExpenses)
            _buildEmptyState(context)
          else ...[
            // Top Categories Spending Bar Chart
            _buildTopCategoriesChart(expensesViewModel),
            SizedBox(height: AppConstants.spacingLarge.h),
            // Time-based Spending Pattern (daily for month/day, monthly for year)
            _buildSpendingPattern(context, expensesViewModel),
          ],
        ],
      ),
    );
  }

  String _getDateDisplayText() {
    switch (filterMode) {
      case DateFilterMode.day:
        return '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}';
      case DateFilterMode.year:
        return '${selectedDate.year}';
      case DateFilterMode.month:
      default:
        return '${selectedDate.year}-${selectedDate.month}';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: AppConstants.spacingLarge.h),
          Text(
            'No trend data available',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacingSmall.h),
          Text(
            'Add more expenses to see spending patterns',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: Colors.grey[500],
              fontSize: AppConstants.textSizeSmall.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build top categories chart
  Widget _buildTopCategoriesChart(ExpensesViewModel viewModel) {
    return FutureBuilder<Map<String, double>>(
      future: viewModel.getCategoryTotals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 120.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final categoryTotals = snapshot.data ?? {};

        if (categoryTotals.isEmpty) {
          return SizedBox(
            height: 120.h,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined,
                      size: AppConstants.iconSizeXLarge.sp,
                      color: Colors.grey[400]),
                  SizedBox(height: AppConstants.spacingSmall.h),
                  Text(
                    'No category data for this period',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Sort categories by amount
        final sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Take top 5 categories
        final topCategories = sortedCategories.take(5).toList();

        // Get the highest amount for scaling
        final highestAmount = topCategories.first.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.topCategoriesTitle,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: AppConstants.textSizeLarge.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppConstants.spacingMedium.h),
            ...topCategories.map((entry) {
              final percentage = entry.value / highestAmount;
              final category = entry.key;

              return Padding(
                padding: EdgeInsets.only(bottom: AppConstants.spacingMedium.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CategoryManager.getIcon(category),
                          size: AppConstants.iconSizeSmall.sp,
                          color: CategoryManager.getColor(category),
                        ),
                        SizedBox(width: AppConstants.spacingSmall.w),
                        Text(
                          CategoryManager.getName(category),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: AppConstants.textSizeMedium.sp,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${viewModel.currentCurrency} ${entry.value.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: AppConstants.textSizeMedium.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppConstants.spacingXSmall.h),
                    // Bar chart
                    Stack(
                      children: [
                        // Background bar
                        Container(
                          height: 12.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey
                                .withOpacity(AppConstants.opacityLow),
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadiusSmall.r),
                          ),
                        ),
                        // Foreground bar showing the percentage
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            height: 12.h,
                            decoration: BoxDecoration(
                              color: CategoryManager.getColor(category),
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadiusSmall.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  // Build spending pattern based on filter mode
  Widget _buildSpendingPattern(
      BuildContext context, ExpensesViewModel viewModel) {
    switch (filterMode) {
      case DateFilterMode.year:
        return _buildYearlySpendingPattern(context, viewModel);
      case DateFilterMode.day:
      case DateFilterMode.month:
      default:
        return _buildDailySpendingPattern(context, viewModel);
    }
  }

  // Build daily spending pattern for month/day view
  Widget _buildDailySpendingPattern(
      BuildContext context, ExpensesViewModel viewModel) {
    return FutureBuilder<Map<int, double>>(
      future: viewModel.calculateDailySpendingPattern(selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 150.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final dailyTotals = snapshot.data ?? {};

        if (dailyTotals.isEmpty ||
            dailyTotals.values.every((amount) => amount == 0.0)) {
          return SizedBox(
            height: 150.h,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: AppConstants.iconSizeXLarge.sp,
                      color: Colors.grey[400]),
                  SizedBox(height: AppConstants.spacingSmall.h),
                  Text(
                    'No daily data for this period',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Get the highest daily amount for scaling
        final highestAmount =
            dailyTotals.values.where((amount) => amount > 0).isNotEmpty
                ? dailyTotals.values.reduce((a, b) => a > b ? a : b)
                : 1.0;

        // Get the number of days in the selected month
        final daysInMonth =
            DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.dailySpendingTitle,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: AppConstants.textSizeLarge.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppConstants.spacingMedium.h),
            SizedBox(
              height: 150.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(daysInMonth, (index) {
                  final day = index + 1;
                  final amount = dailyTotals[day] ?? 0.0;
                  final barHeight =
                      amount > 0 ? (amount / highestAmount) * 120.h : 0.0;
                  final isToday = day == DateTime.now().day &&
                      selectedDate.year == DateTime.now().year &&
                      selectedDate.month == DateTime.now().month;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingXXSmall.w),
                      child: GestureDetector(
                        onTap: amount > 0
                            ? () {
                                // Show tooltip with exact amount
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Day $day: ${viewModel.currentCurrency} ${amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontFamily: AppTheme.fontFamily),
                                    ),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              }
                            : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: amount > 0
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha(
                                            (255 * AppConstants.opacityHigh)
                                                .toInt())
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha(
                                            (255 * AppConstants.opacityOverlay)
                                                .toInt()),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(
                                      AppConstants.borderRadiusSmall.r),
                                ),
                              ),
                            ),
                            SizedBox(height: AppConstants.spacingXXSmall.h),
                            Text(
                              day.toString(),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: AppConstants.textSizeXXSmall.sp,
                                fontWeight: isToday
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isToday
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  // Build yearly spending pattern (monthly bars for a year)
  Widget _buildYearlySpendingPattern(
      BuildContext context, ExpensesViewModel viewModel) {
    return FutureBuilder<Map<int, double>>(
      future: viewModel.calculateYearlySpendingPattern(selectedDate.year),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 150.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final monthlyTotals = snapshot.data ?? {};

        if (monthlyTotals.isEmpty ||
            monthlyTotals.values.every((amount) => amount == 0.0)) {
          return SizedBox(
            height: 150.h,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.date_range,
                      size: AppConstants.iconSizeXLarge.sp,
                      color: Colors.grey[400]),
                  SizedBox(height: AppConstants.spacingSmall.h),
                  Text(
                    'No yearly data for this period',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Get the highest monthly amount for scaling
        final highestAmount =
            monthlyTotals.values.where((amount) => amount > 0).isNotEmpty
                ? monthlyTotals.values.reduce((a, b) => a > b ? a : b)
                : 1.0;

        const monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Spending Pattern',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: AppConstants.textSizeLarge.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppConstants.spacingMedium.h),
            SizedBox(
              height: 150.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(12, (index) {
                  final month = index + 1;
                  final amount = monthlyTotals[month] ?? 0.0;
                  final barHeight =
                      amount > 0 ? (amount / highestAmount) * 120.h : 0.0;
                  final isCurrentMonth = month == DateTime.now().month &&
                      selectedDate.year == DateTime.now().year;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingXXSmall.w),
                      child: GestureDetector(
                        onTap: amount > 0
                            ? () {
                                // Show tooltip with exact amount
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${monthNames[index]}: ${viewModel.currentCurrency} ${amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontFamily: AppTheme.fontFamily),
                                    ),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              }
                            : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: amount > 0
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha(
                                            (255 * AppConstants.opacityHigh)
                                                .toInt())
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha(
                                            (255 * AppConstants.opacityOverlay)
                                                .toInt()),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(
                                      AppConstants.borderRadiusSmall.r),
                                ),
                              ),
                            ),
                            SizedBox(height: AppConstants.spacingXXSmall.h),
                            Text(
                              monthNames[index],
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: AppConstants.textSizeXXSmall.sp,
                                fontWeight: isCurrentMonth
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isCurrentMonth
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}
