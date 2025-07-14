import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/budget.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../widgets/date_picker_button.dart';

/// Compact budget card widget designed for home screen
class HomeBudgetCard extends StatelessWidget {
  /// Budget data to display
  final Budget? budget;

  /// Current selected date for context
  final DateTime selectedDate;

  /// Current filter mode
  final DateFilterMode filterMode;

  /// Callback when budget card is tapped
  final VoidCallback onTap;

  /// Whether the budget is loading
  final bool isLoading;

  const HomeBudgetCard({
    super.key,
    required this.budget,
    required this.selectedDate,
    required this.filterMode,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingCard(context);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppConstants.spacingLarge.w,
          vertical: AppConstants.spacingMedium.h,
        ),
        padding: AppConstants.containerPaddingLarge,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.08).toInt()),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: budget == null
            ? _buildNoBudgetState(context)
            : _buildBudgetContent(context),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLarge.w,
        vertical: AppConstants.spacingMedium.h,
      ),
      padding: AppConstants.containerPaddingLarge,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.08).toInt()),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadiusMedium.r),
                ),
              ),
              SizedBox(width: AppConstants.spacingMedium.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16.h,
                      width: 100.w,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: AppConstants.spacingSmall.h),
                    Container(
                      height: 20.h,
                      width: 150.w,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoBudgetState(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(selectedDate);

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppConstants.spacingMedium.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha((255 * 0.1).toInt()),
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusMedium.r),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: AppConstants.iconSizeLarge.sp,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(width: AppConstants.spacingMedium.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget - $monthName',
                    style: TextStyle(
                      fontSize: AppConstants.textSizeSmall.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingXSmall.h),
                  Text(
                    'No Budget Set',
                    style: TextStyle(
                      fontSize: AppConstants.textSizeLarge.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMedium.w,
                vertical: AppConstants.spacingSmall.h,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusLarge.r),
              ),
              child: Text(
                'Set Budget',
                style: TextStyle(
                  fontSize: AppConstants.textSizeSmall.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppConstants.spacingMedium.h),
        Text(
          'Tap to set your budget for $monthName',
          style: TextStyle(
            fontSize: AppConstants.textSizeSmall.sp,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetContent(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(selectedDate);
    final remaining = budget!.left;
    final percentage = budget!.total > 0 ? (remaining / budget!.total) : 0;
    final isLow = percentage < 0.3 && percentage > 0;
    final isNegative = remaining <= 0;

    final statusColor = isNegative
        ? AppTheme.errorColor
        : isLow
            ? AppTheme.warningColor
            : AppTheme.successColor;

    final statusText = isNegative
        ? 'Overspent'
        : isLow
            ? 'Low Budget'
            : 'On Track';

    return Column(
      children: [
        // Header Row
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppConstants.spacingMedium.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha((255 * 0.1).toInt()),
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusMedium.r),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: AppConstants.iconSizeLarge.sp,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(width: AppConstants.spacingMedium.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget - $monthName',
                    style: TextStyle(
                      fontSize: AppConstants.textSizeSmall.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingXSmall.h),
                  Text(
                    CurrencyFormatter.formatAmount(
                        budget!.total, budget!.currency),
                    style: TextStyle(
                      fontSize: AppConstants.textSizeLarge.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMedium.w,
                vertical: AppConstants.spacingSmall.h,
              ),
              decoration: BoxDecoration(
                color: statusColor.withAlpha((255 * 0.1).toInt()),
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusLarge.r),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: AppConstants.textSizeSmall.sp,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: AppConstants.spacingLarge.h),

        // Budget Progress
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remaining',
                        style: TextStyle(
                          fontSize: AppConstants.textSizeSmall.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Used ${((1 - percentage) * 100).clamp(0, 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: AppConstants.textSizeSmall.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppConstants.spacingSmall.h),
                  Text(
                    CurrencyFormatter.formatAmount(remaining, budget!.currency),
                    style: TextStyle(
                      fontSize: AppConstants.textSizeXLarge.sp,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingMedium.h),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadiusSmall.r),
                    child: LinearProgressIndicator(
                      value: percentage.clamp(0, 1).toDouble(),
                      minHeight: 6.h,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
