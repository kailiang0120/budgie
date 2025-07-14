import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../utils/category_manager.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import 'custom_card.dart';

class CategoryDistributionCard extends StatelessWidget {
  final DateTime selectedDate;

  const CategoryDistributionCard({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final expensesViewModel = Provider.of<ExpensesViewModel>(context);

    return CustomCard(
      padding: AppConstants.containerPaddingLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom header with proper date alignment
          Row(
            children: [
              Icon(
                Icons.pie_chart,
                color: Theme.of(context).colorScheme.primary,
                size: AppConstants.iconSizeMedium.sp,
              ),
              SizedBox(width: AppConstants.spacingSmall.w),
              Expanded(
                child: Text(
                  AppConstants.categoryDistributionTitle,
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
                '${selectedDate.year}-${selectedDate.month}',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: AppConstants.textSizeSmall.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingLarge.h),
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
                    child: Text(
                      'Error loading category data: ${snapshot.error}',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: Colors.red,
                      ),
                    ),
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
                  SizedBox(height: AppConstants.spacingXXLarge.h),

                  // Total amount - now using currency-converted values
                  Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Total Spent : ',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: AppConstants.textSizeLarge.sp,
                            ),
                          ),
                          TextSpan(
                            text:
                                '${expensesViewModel.currentCurrency} ${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: AppConstants.textSizeXLarge.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: AppConstants.spacingXXLarge.h),

                  // Category legend with better wrapping
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: AppConstants.spacingLarge.w,
                      runSpacing: AppConstants.spacingMedium.h,
                      alignment: WrapAlignment.center,
                      children: categoryTotals.entries.map((entry) {
                        final categoryId = entry.key;
                        final percentage = (entry.value / totalAmount * 100)
                            .toStringAsFixed(1);
                        return Container(
                          margin: EdgeInsets.only(
                              bottom: AppConstants.spacingXSmall.h),
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
                              SizedBox(width: AppConstants.spacingXSmall.w),
                              Text(
                                '${CategoryManager.getNameFromId(categoryId)} ($percentage%)',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: AppConstants.textSizeSmall.sp,
                                ),
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
          SizedBox(height: AppConstants.spacingLarge.h),
          Text(
            'No expense data for this period',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacingSmall.h),
          Text(
            'Try selecting a different month or adding expenses',
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

  Widget _buildCustomPieChart(Map<String, double> categoryTotals) {
    final sections = <PieChartSectionData>[];
    final totalAmount =
        categoryTotals.values.fold<double>(0, (sum, value) => sum + value);

    for (final entry in categoryTotals.entries) {
      final categoryId = entry.key;
      final amount = entry.value;
      final percentage = amount / totalAmount;

      sections.add(
        PieChartSectionData(
          color: CategoryManager.getColorFromId(categoryId),
          value: amount,
          title: '${(percentage * 100).toStringAsFixed(0)}%',
          radius: 115.r,
          titleStyle: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: AppConstants.textSizeSmall.sp,
            fontWeight: FontWeight.bold,
          ),
          badgeWidget: _Badge(
            CategoryManager.getIconFromId(categoryId),
            size: AppConstants.iconSizeMedium.sp,
            borderColor: CategoryManager.getColorFromId(categoryId),
          ),
          badgePositionPercentageOffset: 0.9,
          showTitle:
              percentage > 0.05, // Only show percentage for sections > 5%
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 0,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color borderColor;

  const _Badge(
    this.icon, {
    required this.size,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.animationDurationShort,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color:
              Colors.black.withAlpha((255 * AppConstants.opacityLow).toInt()),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withAlpha((255 * AppConstants.opacityLow).toInt()),
            blurRadius: AppConstants.elevationSmall * 2,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: EdgeInsets.all(AppConstants.spacingXXSmall.w),
      child: Icon(icon, size: size, color: borderColor),
    );
  }
}
