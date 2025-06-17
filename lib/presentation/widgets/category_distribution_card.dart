import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../utils/category_manager.dart';
import 'custom_card.dart';

class CategoryDistributionCard extends StatelessWidget {
  final DateTime selectedDate;

  const CategoryDistributionCard({
    Key? key,
    required this.selectedDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final expensesViewModel = Provider.of<ExpensesViewModel>(context);

    return CustomCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom header with proper date alignment
          Row(
            children: [
              Icon(
                Icons.pie_chart,
                color: Theme.of(context).colorScheme.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Category Distribution',
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
          // Content
          FutureBuilder<Map<String, double>>(
            future: expensesViewModel.getCategoryTotals(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 400.h,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 400.h,
                  child: Center(
                    child:
                        Text('Error loading category data: ${snapshot.error}'),
                  ),
                );
              }

              final categoryTotals = snapshot.data ?? {};

              // If there's no data, show a placeholder
              if (categoryTotals.isEmpty) {
                return _buildEmptyState(context);
              }

              // Calculate total amount with currency conversion already applied
              final totalAmount = categoryTotals.values
                  .fold<double>(0, (sum, value) => sum + value);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pie chart with fixed height and proper container
                  Container(
                    height: 280.h,
                    alignment: Alignment.center,
                    child: _buildCustomPieChart(categoryTotals),
                  ),
                  SizedBox(height: 24.h),

                  // Total amount - now using currency-converted values
                  Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Total Spent : ',
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: 16.sp,
                            ),
                          ),
                          TextSpan(
                            text:
                                '${expensesViewModel.currentCurrency} ${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 18.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Category legend with better wrapping
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 16.w,
                      runSpacing: 12.h,
                      alignment: WrapAlignment.center,
                      children: categoryTotals.entries.map((entry) {
                        final categoryId = entry.key;
                        final percentage = (entry.value / totalAmount * 100)
                            .toStringAsFixed(1);
                        return Container(
                          margin: EdgeInsets.only(bottom: 4.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12.w,
                                height: 12.h,
                                decoration: BoxDecoration(
                                  color: CategoryManager.getColorFromId(
                                      categoryId),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '${CategoryManager.getNameFromId(categoryId)} ($percentage%)',
                                style: TextStyle(fontSize: 12.sp),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
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
            Icons.pie_chart_outline,
            size: 48.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No expense data for this period',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Try selecting a different month or adding expenses',
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

  // Custom pie chart builder that works with string category IDs
  Widget _buildCustomPieChart(Map<String, double> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 8.h),
            Text(
              'No data available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: data.entries.map((entry) {
          final categoryId = entry.key;
          final value = entry.value;

          return PieChartSectionData(
            value: value,
            title: '',
            color: CategoryManager.getColorFromId(categoryId),
            radius: 120.r,
            titleStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 1.r,
        centerSpaceRadius: 0.r,
        startDegreeOffset: 180.r,
      ),
    );
  }
}
