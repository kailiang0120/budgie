import 'package:flutter/material.dart';

import '../../domain/entities/financial_goal.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

/// Dialog for previewing funding distribution before allocation
class FundingPreviewDialog extends StatelessWidget {
  /// The available savings amount
  final double availableSavings;

  /// Map of goal ID to allocated amount
  final Map<String, double> distribution;

  /// List of active goals
  final List<FinancialGoal> goals;

  /// Callback when user confirms the allocation
  final VoidCallback onConfirm;

  /// Constructor
  const FundingPreviewDialog({
    super.key,
    required this.availableSavings,
    required this.distribution,
    required this.goals,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    const currency = 'MYR'; // You can make this dynamic based on settings
    final totalAllocated =
        distribution.values.fold(0.0, (sum, amount) => sum + amount);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section
            Container(
              padding: AppConstants.containerPaddingLarge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                  topRight: Radius.circular(AppConstants.borderRadiusLarge),
                ),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.successColor.withAlpha((255 * 0.1).toInt()),
                    AppTheme.successColor.withAlpha((255 * 0.05).toInt()),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Title Row
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppConstants.spacingMedium),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor
                              .withAlpha((255 * 0.2).toInt()),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.preview,
                          color: AppTheme.successColor,
                          size: AppConstants.iconSizeLarge,
                        ),
                      ),
                      SizedBox(width: AppConstants.spacingMedium),
                      Expanded(
                        child: Text(
                          'Funding Preview',
                          style: TextStyle(
                            fontSize: AppConstants.textSizeXLarge,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppConstants.spacingLarge),

                  // Available savings info
                  Container(
                    padding: AppConstants.containerPaddingMedium,
                    decoration: BoxDecoration(
                      color:
                          AppTheme.successColor.withAlpha((255 * 0.15).toInt()),
                      borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusMedium),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount to Allocate:',
                          style: TextStyle(
                            fontSize: AppConstants.textSizeMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatAmount(
                              availableSavings, currency),
                          style: TextStyle(
                            fontSize: AppConstants.textSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Flexible(
              child: Padding(
                padding: AppConstants.containerPaddingLarge,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Distribution title
                    Text(
                      'Distribution Plan:',
                      style: TextStyle(
                        fontSize: AppConstants.textSizeLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppConstants.spacingMedium),

                    // Distribution list
                    if (distribution.isEmpty)
                      Padding(
                        padding: AppConstants.containerPaddingMedium,
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: AppConstants.iconSizeLarge,
                              color: Colors.grey[500],
                            ),
                            SizedBox(height: AppConstants.spacingMedium),
                            Text(
                              'No funding allocation planned.',
                              style: TextStyle(
                                fontSize: AppConstants.textSizeMedium,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: distribution.entries.length,
                          itemBuilder: (context, index) {
                            final entry = distribution.entries.elementAt(index);
                            final goalId = entry.key;
                            final amount = entry.value;
                            final goal =
                                goals.firstWhere((g) => g.id == goalId);
                            final willComplete =
                                _isGoalCompletable(goal, amount);

                            return Container(
                              margin: EdgeInsets.only(
                                  bottom: AppConstants.spacingSmall),
                              padding: AppConstants.containerPaddingMedium,
                              decoration: BoxDecoration(
                                color: goal.icon.color
                                    .withAlpha((255 * 0.05).toInt()),
                                border: Border.all(
                                  color: goal.icon.color
                                      .withAlpha((255 * 0.2).toInt()),
                                ),
                                borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadiusMedium),
                              ),
                              child: Row(
                                children: [
                                  // Goal icon
                                  Container(
                                    padding: EdgeInsets.all(
                                        AppConstants.spacingSmall),
                                    decoration: BoxDecoration(
                                      color: goal.icon.color
                                          .withAlpha((255 * 0.15).toInt()),
                                      borderRadius: BorderRadius.circular(
                                          AppConstants.borderRadiusSmall),
                                    ),
                                    child: Icon(
                                      goal.icon.icon,
                                      color: goal.icon.color,
                                      size: AppConstants.iconSizeMedium,
                                    ),
                                  ),
                                  SizedBox(width: AppConstants.spacingMedium),

                                  // Goal info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                goal.title,
                                                style: TextStyle(
                                                  fontSize: AppConstants
                                                      .textSizeMedium,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (willComplete)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      AppConstants.spacingSmall,
                                                  vertical: AppConstants
                                                          .spacingXSmall /
                                                      2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.successColor,
                                                  borderRadius: BorderRadius
                                                      .circular(AppConstants
                                                          .borderRadiusSmall),
                                                ),
                                                child: Text(
                                                  'COMPLETE!',
                                                  style: TextStyle(
                                                    fontSize: AppConstants
                                                        .textSizeXSmall,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(
                                            height: AppConstants.spacingXSmall),
                                        Text(
                                          'Progress: ${goal.progressPercentage}% → ${_calculateNewProgress(goal, amount)}%',
                                          style: TextStyle(
                                            fontSize:
                                                AppConstants.textSizeSmall,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Allocation amount
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        CurrencyFormatter.formatAmount(
                                            amount, currency),
                                        style: TextStyle(
                                          fontSize: AppConstants.textSizeMedium,
                                          fontWeight: FontWeight.bold,
                                          color: goal.icon.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    SizedBox(height: AppConstants.spacingLarge),

                    // Summary
                    if (distribution.isNotEmpty)
                      Container(
                        padding: AppConstants.containerPaddingMedium,
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha((255 * 0.1).toInt()),
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusMedium),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Allocated:',
                              style: TextStyle(
                                fontSize: AppConstants.textSizeMedium,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatAmount(
                                  totalAllocated, currency),
                              style: TextStyle(
                                fontSize: AppConstants.textSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: AppConstants.containerPaddingLarge,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: AppConstants.textSizeMedium,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppConstants.spacingMedium),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: distribution.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              onConfirm();
                            },
                      icon: Icon(
                        Icons.check_circle_outline,
                        size: AppConstants.iconSizeMedium,
                      ),
                      label: Text(
                        'Confirm Allocation',
                        style: TextStyle(
                          fontSize: AppConstants.textSizeMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: AppConstants.spacingMedium,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusLarge),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calculate what the new progress percentage would be after funding
  int _calculateNewProgress(FinancialGoal goal, double additionalAmount) {
    final newAmount = goal.currentAmount + additionalAmount;
    final newProgress = goal.targetAmount > 0
        ? (newAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    return (newProgress * 100).round();
  }

  /// Check if this funding amount would complete the goal
  bool _isGoalCompletable(FinancialGoal goal, double additionalAmount) {
    return (goal.currentAmount + additionalAmount) >= goal.targetAmount;
  }
}

/// Show the funding preview dialog
Future<void> showFundingPreviewDialog({
  required BuildContext context,
  required double availableSavings,
  required Map<String, double> distribution,
  required List<FinancialGoal> goals,
  required VoidCallback onConfirm,
}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return FundingPreviewDialog(
        availableSavings: availableSavings,
        distribution: distribution,
        goals: goals,
        onConfirm: onConfirm,
      );
    },
  );
}
