import 'package:flutter/material.dart';

import '../../domain/entities/financial_goal.dart';
import '../viewmodels/goals_viewmodel.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'custom_card.dart';
import 'submit_button.dart';

class GoalSnapshotCard extends StatelessWidget {
  const GoalSnapshotCard({
    super.key,
    required this.activeGoals,
    required this.summary,
    required this.onManage,
    this.manageLabel = 'Manage Goals',
    this.manageIcon = Icons.flag_circle,
    this.focusGoal,
    this.availableSavings,
    this.currency,
    this.recommendation,
    this.onAllocate,
    this.allocateLabel = 'Allocate Savings',
    this.canAllocate = false,
    this.isAllocating = false,
  });

  final int activeGoals;
  final String summary;
  final FinancialGoal? focusGoal;
  final double? availableSavings;
  final String? currency;
  final GoalRecommendation? recommendation;
  final bool canAllocate;
  final bool isAllocating;
  final VoidCallback? onAllocate;
  final VoidCallback onManage;
  final String manageLabel;
  final IconData manageIcon;
  final String allocateLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return CustomCard(
      child: Padding(
        padding: AppConstants.containerPaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Goals Snapshot',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Chip(
                  label: Text(
                    '$activeGoals active',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: AppConstants.opacityLow),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingSmall),
            Text(
              summary,
              style: textTheme.bodyMedium?.copyWith(
                color: onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (availableSavings != null && availableSavings! > 0) ...[
              SizedBox(height: AppConstants.spacingSmall),
              Text(
                'Available: ${CurrencyFormatter.formatAmount(availableSavings!, currency ?? 'MYR')}',
                style: textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (focusGoal != null) ...[
              SizedBox(height: AppConstants.spacingMedium),
              Text(
                'Next focus: ${focusGoal!.title}',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppConstants.spacingXSmall),
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusLarge,
                ),
                child: LinearProgressIndicator(
                  value: focusGoal!.progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: AppConstants.opacityMedium),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(height: AppConstants.spacingXSmall),
              Text(
                _buildProgressCaption(focusGoal!),
                style: textTheme.bodySmall?.copyWith(
                  color: onSurfaceVariant,
                ),
              ),
            ],
            if (recommendation != null) ...[
              SizedBox(height: AppConstants.spacingMedium),
              Container(
                width: double.infinity,
                padding: AppConstants.containerPaddingMedium,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer
                      .withValues(alpha: AppConstants.opacityMedium),
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusLarge,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_graph_rounded,
                      size: AppConstants.iconSizeMedium,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    SizedBox(width: AppConstants.spacingSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation!.title,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppConstants.spacingXSmall),
                          Text(
                            recommendation!.description,
                            style: textTheme.bodySmall?.copyWith(
                              color: onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: AppConstants.spacingLarge),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (onAllocate != null) ...[
                  SubmitButton(
                    text: allocateLabel,
                    loadingText: 'Allocating...',
                    isLoading: isAllocating,
                    enabled: canAllocate && !isAllocating,
                    icon: Icons.auto_awesome,
                    color: canAllocate
                        ? AppTheme.successColor
                        : theme.colorScheme.surfaceContainerHighest,
                    height: 50,
                    onPressed: onAllocate!,
                  ),
                  SizedBox(height: AppConstants.spacingSmall),
                ],
                SubmitButton(
                  text: manageLabel,
                  isLoading: false,
                  icon: manageIcon,
                  color: theme.colorScheme.primary,
                  height: 50,
                  onPressed: onManage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildProgressCaption(FinancialGoal goal) {
    final days = goal.daysRemaining;
    final deadlineText =
        days <= 0 ? 'Deadline today' : '$days day${days == 1 ? '' : 's'} left';
    return '$deadlineText • ${goal.progressPercentage}% complete';
  }
}
