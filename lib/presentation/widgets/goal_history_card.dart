import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/financial_goal.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';

/// A reusable card widget for displaying completed goal history
class GoalHistoryCard extends StatelessWidget {
  /// The goal history record to display
  final GoalHistory history;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Creates a goal history card widget
  const GoalHistoryCard({
    Key? key,
    required this.history,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedTarget =
        CurrencyFormatter.formatAmount(history.targetAmount, 'MYR');
    final formattedFinal =
        CurrencyFormatter.formatAmount(history.finalAmount, 'MYR');
    final completedDate =
        DateFormat('d MMM yyyy').format(history.completedDate);
    final createdDate = DateFormat('d MMM yyyy').format(history.createdDate);

    return Card(
      elevation: AppConstants.elevationSmall,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacingLarge.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppConstants.spacingSmall.w),
                    decoration: BoxDecoration(
                      color: history.icon.color.withAlpha((255 * 0.1).toInt()),
                      borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusSmall.r),
                    ),
                    child: Icon(
                      history.icon.icon,
                      color: history.icon.color,
                      size: AppConstants.iconSizeMedium.sp,
                    ),
                  ),
                  SizedBox(width: AppConstants.spacingMedium.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          history.title,
                          style: TextStyle(
                            fontSize: AppConstants.textSizeLarge.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Completed on $completedDate',
                          style: TextStyle(
                            fontSize: AppConstants.textSizeSmall.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingMedium.w,
                      vertical: AppConstants.spacingXSmall.h,
                    ),
                    decoration: BoxDecoration(
                      color: history.icon.color.withAlpha((255 * 0.1).toInt()),
                      borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusSmall.r),
                    ),
                    child: Text(
                      '${history.achievementPercentage}%',
                      style: TextStyle(
                        fontSize: AppConstants.textSizeMedium.sp,
                        fontWeight: FontWeight.bold,
                        color: history.icon.color,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppConstants.spacingMedium.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target',
                          style: TextStyle(
                            fontSize: AppConstants.textSizeXSmall.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          formattedTarget,
                          style: TextStyle(
                            fontSize: AppConstants.textSizeMedium.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Achieved',
                          style: TextStyle(
                            fontSize: AppConstants.textSizeXSmall.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          formattedFinal,
                          style: TextStyle(
                            fontSize: AppConstants.textSizeMedium.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time Taken',
                          style: TextStyle(
                            fontSize: AppConstants.textSizeXSmall.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${history.daysTaken} days',
                          style: TextStyle(
                            fontSize: AppConstants.textSizeMedium.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (history.notes != null && history.notes!.isNotEmpty) ...[
                SizedBox(height: AppConstants.spacingMedium.h),
                Divider(height: 1.h),
                SizedBox(height: AppConstants.spacingMedium.h),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeXSmall.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: AppConstants.spacingXSmall.h),
                Text(
                  history.notes!,
                  style: TextStyle(
                    fontSize: AppConstants.textSizeSmall.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
