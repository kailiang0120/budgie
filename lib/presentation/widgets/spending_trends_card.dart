import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../utils/category_manager.dart';
import 'custom_card.dart';

class SpendingTrendsCard extends StatelessWidget {
  final DateTime selectedDate;

  const SpendingTrendsCard({
    Key? key,
    required this.selectedDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final expensesViewModel = Provider.of<ExpensesViewModel>(context);

    // Ensure we're getting data for the selected month
    final hasExpenses = expensesViewModel.filteredExpenses.isNotEmpty;

    return CustomCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom header with proper date alignment
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Theme.of(context).colorScheme.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Spending Trends',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
              Text(
                '${selectedDate.year}-${selectedDate.month}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // If there's no data, show a placeholder
          if (!hasExpenses)
            _buildEmptyState(context)
          else ...[
            // Top Categories Spending Bar Chart
            _buildTopCategoriesChart(expensesViewModel),
            SizedBox(height: 16.h),
            // Daily Spending Pattern
            _buildDailySpendingPattern(context, expensesViewModel),
          ],
        ],
      ),
    );
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
          SizedBox(height: 16.h),
          Text(
            'No trend data available',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Add more expenses to see spending patterns',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12.sp,
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
                      size: 28.sp, color: Colors.grey[400]),
                  SizedBox(height: 8.h),
                  Text(
                    'No category data for this period',
                    style: TextStyle(color: Colors.grey[600]),
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
              'Top Categories',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            ...topCategories.map((entry) {
              final percentage = entry.value / highestAmount;
              final category = entry.key;

              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CategoryManager.getIcon(category),
                          size: 16.sp,
                          color: CategoryManager.getColor(category),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          CategoryManager.getName(category),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        const Spacer(),
                        Text(
                          '${viewModel.currentCurrency} ${entry.value.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    // Bar chart
                    Stack(
                      children: [
                        // Background bar
                        Container(
                          height: 8.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        // Filled bar
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            height: 8.h,
                            decoration: BoxDecoration(
                              color: CategoryManager.getColor(category),
                              borderRadius: BorderRadius.circular(4.r),
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

  // Build daily spending pattern visualization
  Widget _buildDailySpendingPattern(
      BuildContext context, ExpensesViewModel viewModel) {
    final expenses = viewModel.filteredExpenses;

    if (expenses.isEmpty) {
      return SizedBox(
        height: 150.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.date_range_outlined,
                  size: 28.sp, color: Colors.grey[400]),
              SizedBox(height: 8.h),
              Text(
                'No daily spending data for ${selectedDate.year}-${selectedDate.month}',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              Text(
                'Add expenses to see daily patterns',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Group expenses by day
    final Map<int, double> dailyTotals = {};

    // Get all days in the selected month
    final daysInMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

    // Initialize all days with zero
    for (int day = 1; day <= daysInMonth; day++) {
      dailyTotals[day] = 0;
    }

    // Sum expenses by day
    for (final expense in expenses) {
      final day = expense.date.day;
      dailyTotals[day] = (dailyTotals[day] ?? 0) + expense.amount;
    }

    // Find the highest daily total for scaling
    final highestDaily = dailyTotals.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Spending Pattern',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 120.h,
          child: Row(
            children: List.generate(daysInMonth, (index) {
              final day = index + 1;
              final amount = dailyTotals[day] ?? 0;
              final percentage = highestDaily > 0 ? amount / highestDaily : 0;

              // Determine if this is today
              final isToday = DateTime.now().day == day &&
                  DateTime.now().month == selectedDate.month &&
                  DateTime.now().year == selectedDate.year;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Bar - use Flexible to prevent overflow
                      Flexible(
                        flex: 8,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: (80 * percentage)
                              .toDouble()
                              .h, // Reduced from 100 to 80
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isToday
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha((255 * 0.7).toInt()),
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(4.r)),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h), // Reduced spacing
                      // Day number - use Flexible to prevent overflow
                      Flexible(
                        flex: 2,
                        child: Text(
                          day.toString(),
                          style: TextStyle(
                            fontSize: 9.sp, // Slightly smaller font
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
