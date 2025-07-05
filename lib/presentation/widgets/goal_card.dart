import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/financial_goal.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

/// A reusable card widget for displaying financial goals
class GoalCard extends StatelessWidget {
  /// The financial goal to display
  final FinancialGoal goal;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Callback when the edit button is tapped
  final VoidCallback? onEdit;

  /// Callback when the delete button is tapped
  final VoidCallback? onDelete;

  /// Callback when the complete button is tapped
  final VoidCallback? onComplete;

  /// Whether to show action buttons
  final bool showActions;

  /// Creates a goal card widget
  const GoalCard({
    Key? key,
    required this.goal,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onComplete,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedTarget =
        CurrencyFormatter.formatAmount(goal.targetAmount, 'MYR');
    final formattedCurrent =
        CurrencyFormatter.formatAmount(goal.currentAmount, 'MYR');
    final formattedRemaining =
        CurrencyFormatter.formatAmount(goal.amountRemaining, 'MYR');
    final deadlineFormatted = DateFormat('MMM yyyy').format(goal.deadline);

    // Determine status color
    Color statusColor = goal.icon.color;
    if (goal.isOverdue) {
      statusColor = AppTheme.errorColor;
    } else if (goal.progressPercentage >= 90) {
      statusColor = AppTheme.successColor;
    }

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
                      color: goal.icon.color.withAlpha((255 * 0.1).toInt()),
                      borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusSmall.r),
                    ),
                    child: Icon(
                      goal.icon.icon,
                      color: goal.icon.color,
                      size: AppConstants.iconSizeMedium.sp,
                    ),
                  ),
                  SizedBox(width: AppConstants.spacingMedium.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: TextStyle(
                            fontSize: AppConstants.textSizeLarge.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Target by $deadlineFormatted',
                          style: TextStyle(
                            fontSize: AppConstants.textSizeSmall.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${goal.progressPercentage}%',
                    style: TextStyle(
                      fontSize: AppConstants.textSizeLarge.sp,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppConstants.spacingLarge.h),
              LinearProgressIndicator(
                value: goal.progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6.h,
              ),
              SizedBox(height: AppConstants.spacingMedium.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedCurrent,
                    style: TextStyle(
                      fontSize: AppConstants.textSizeMedium.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    formattedTarget,
                    style: TextStyle(
                      fontSize: AppConstants.textSizeMedium.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (goal.daysRemaining > 0) ...[
                SizedBox(height: AppConstants.spacingSmall.h),
                Text(
                  '${goal.daysRemaining} days remaining',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeSmall.sp,
                    color:
                        goal.isOverdue ? AppTheme.errorColor : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (showActions) ...[
                SizedBox(height: AppConstants.spacingMedium.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          size: AppConstants.iconSizeSmall.sp,
                          color: Colors.grey[600],
                        ),
                        onPressed: onEdit,
                        tooltip: 'Edit Goal',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(AppConstants.spacingSmall.w),
                      ),
                    if (onDelete != null) ...[
                      SizedBox(width: AppConstants.spacingSmall.w),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          size: AppConstants.iconSizeSmall.sp,
                          color: Colors.grey[600],
                        ),
                        onPressed: onDelete,
                        tooltip: 'Delete Goal',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(AppConstants.spacingSmall.w),
                      ),
                    ],
                    if (onComplete != null) ...[
                      SizedBox(width: AppConstants.spacingSmall.w),
                      IconButton(
                        icon: Icon(
                          Icons.check_circle,
                          size: AppConstants.iconSizeSmall.sp,
                          color: AppTheme.successColor,
                        ),
                        onPressed: onComplete,
                        tooltip: 'Mark as Complete',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(AppConstants.spacingSmall.w),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
