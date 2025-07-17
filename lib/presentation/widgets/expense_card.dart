import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/recurring_expense.dart';

import '../utils/category_manager.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../../core/constants/routes.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';
import '../viewmodels/budget_viewmodel.dart';

class ExpenseCard extends StatefulWidget {
  final Expense expense;
  final VoidCallback? onExpenseUpdated;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onExpenseUpdated,
  });

  @override
  State<ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<ExpenseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isSwipeOpened = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.animationDurationMedium,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-0.37.h, 0), // Slide further to fully reveal round buttons
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToEdit() async {
    _closeSwipe(); // Close swipe before navigating
    final result = await Navigator.pushNamed(
      context,
      Routes.editExpense,
      arguments: widget.expense,
    );

    if (result == true && widget.onExpenseUpdated != null) {
      widget.onExpenseUpdated!();

      if (!mounted) return;

      // Refresh budget data after expense update with a delay
      final budgetVM = Provider.of<BudgetViewModel>(context, listen: false);
      final monthId =
          '${widget.expense.date.year}-${widget.expense.date.month.toString().padLeft(2, '0')}';

      Future.delayed(AppConstants.animationDurationMedium, () {
        if (mounted) {
          budgetVM.refreshBudget(monthId);
        }
      });
    }
  }

  void _showDeleteConfirmation() {
    _closeSwipe(); // Close swipe before showing dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Expense',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: AppConstants.textSizeXLarge.sp,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this expense? This action cannot be undone.',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: AppConstants.textSizeMedium.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppConstants.cancelButtonText,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: AppConstants.textSizeMedium.sp,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteExpense();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(
                AppConstants.deleteButtonText,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: AppConstants.textSizeMedium.sp,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusMedium.r),
          ),
        );
      },
    );
  }

  void _deleteExpense() async {
    try {
      final viewModel = Provider.of<ExpensesViewModel>(context, listen: false);
      final budgetVM = Provider.of<BudgetViewModel>(context, listen: false);
      final monthId =
          '${widget.expense.date.year}-${widget.expense.date.month.toString().padLeft(2, '0')}';

      await viewModel.deleteExpense(widget.expense.id, widget.expense.date);

      // Clear any cached filter data to ensure deleted expense doesn't show up
      await viewModel.refreshData();

      // Trigger the callback to refresh the parent widget
      if (widget.onExpenseUpdated != null) {
        widget.onExpenseUpdated!();
      }

      // Add a small delay then refresh budget data after expense deletion
      if (mounted) {
        Future.delayed(AppConstants.animationDurationMedium, () {
          if (mounted) {
            budgetVM.refreshBudget(monthId);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.expenseDeletedMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting expense: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Calculate the sensitivity of the swipe
    double sensitivity = 8.0.w;

    if (details.delta.dx < -sensitivity && !_isSwipeOpened) {
      // Swipe left to show actions
      setState(() {
        _isSwipeOpened = true;
      });
      _animationController.forward();
    } else if (details.delta.dx > sensitivity && _isSwipeOpened) {
      // Swipe right to hide actions
      _closeSwipe();
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    // Auto-close if swipe velocity is high enough to the right
    if (details.primaryVelocity != null &&
        details.primaryVelocity! > 100 &&
        _isSwipeOpened) {
      _closeSwipe();
    }
  }

  void _closeSwipe() {
    if (_isSwipeOpened) {
      setState(() {
        _isSwipeOpened = false;
      });
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    final category = expense.category;
    final categoryColor = CategoryManager.getColor(category);
    final categoryIcon = CategoryManager.getIcon(category);
    final categoryName = CategoryManager.getName(category);

    // Format date
    final dateFormatter = DateFormat(AppConstants.shortDateFormat);
    final formattedDate = dateFormatter.format(expense.date);

    // Format time
    final timeFormatter = DateFormat(AppConstants.shortTimeFormat);
    final formattedTime = timeFormatter.format(expense.date);

    // Format amount with the original currency from the expense record
    final formattedAmount =
        CurrencyFormatter.formatAmount(expense.amount, expense.currency);

    // Get recurring badge info if applicable
    final bool isRecurring = expense.isRecurring;
    RecurringFrequency? frequency;
    if (isRecurring && expense.recurringDetails != null) {
      frequency = expense.recurringDetails!.frequency;
    }

    return GestureDetector(
      onTap: _navigateToEdit,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Container(
        margin: AppConstants.cardMarginSmall,
        child: Stack(
          children: [
            // Action buttons container (positioned behind the card)
            Positioned.fill(
              child: Container(
                margin: EdgeInsets.only(right: AppConstants.spacingXSmall.w),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 154, 154, 154)
                      .withAlpha((255 * AppConstants.opacityHigh).toInt()),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadiusLarge.r),
                ),
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: AppConstants.spacingMedium.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit button
                      _buildActionButton(
                        Icons.edit,
                        Colors.blueGrey,
                        _navigateToEdit,
                      ),
                      SizedBox(width: AppConstants.spacingMedium.w),
                      // Delete button
                      _buildActionButton(
                        Icons.delete,
                        Colors.red,
                        _showDeleteConfirmation,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Main card content (animated)
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadiusMedium.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(
                          (255 * AppConstants.opacityOverlay).toInt()),
                      blurRadius: AppConstants.elevationSmall * 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: AppConstants.containerPaddingLarge,
                  child: Row(
                    children: [
                      // Category icon
                      Container(
                        width: 50.w,
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: categoryColor.withAlpha(
                              (255 * AppConstants.opacityOverlay).toInt()),
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusLarge.r),
                        ),
                        child: Icon(
                          categoryIcon,
                          color: categoryColor,
                          size: AppConstants.iconSizeLarge.sp,
                        ),
                      ),
                      SizedBox(width: AppConstants.spacingMedium),
                      // Expense details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Title with optional recurring badge
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          categoryName,
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            fontSize:
                                                AppConstants.textSizeLarge.sp,
                                            fontWeight: FontWeight.w500,
                                            color: categoryColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isRecurring) ...[
                                        SizedBox(
                                            width:
                                                AppConstants.spacingXSmall.w),
                                        _buildRecurringBadge(frequency),
                                      ],
                                    ],
                                  ),
                                ),
                                // Amount
                                Text(
                                  formattedAmount,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: AppConstants.textSizeLarge.sp,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppConstants.spacingXSmall.h),
                            // Category and date/time
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Remarks text with proper wrapping
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    expense.remark.isNotEmpty
                                        ? expense.remark
                                        : 'No remarks',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: AppConstants.textSizeSmall.sp,
                                      color: expense.remark.isNotEmpty
                                          ? Colors.grey[600]
                                          : Colors.grey[400],
                                      fontStyle: expense.remark.isNotEmpty
                                          ? FontStyle.normal
                                          : FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                  ),
                                ),
                                SizedBox(width: AppConstants.spacingSmall.w),
                                // Date and time section
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: AppConstants.iconSizeSmall.sp,
                                            color: Colors.grey[600],
                                          ),
                                          SizedBox(
                                              width: AppConstants
                                                  .spacingXXSmall.w),
                                          Flexible(
                                            child: Text(
                                              formattedDate,
                                              style: TextStyle(
                                                fontFamily: AppTheme.fontFamily,
                                                fontSize: AppConstants
                                                    .textSizeSmall.sp,
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (formattedTime.isNotEmpty) ...[
                                        SizedBox(
                                            height:
                                                AppConstants.spacingXXSmall.h),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size:
                                                  AppConstants.iconSizeSmall.sp,
                                              color: Colors.grey[600],
                                            ),
                                            SizedBox(
                                                width: AppConstants
                                                    .spacingXXSmall.w),
                                            Flexible(
                                              child: Text(
                                                formattedTime,
                                                style: TextStyle(
                                                  fontFamily:
                                                      AppTheme.fontFamily,
                                                  fontSize: AppConstants
                                                      .textSizeSmall.sp,
                                                  color: Colors.grey[600],
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withAlpha((255 * AppConstants.opacityLow).toInt()),
            blurRadius: AppConstants.elevationSmall * 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            color: color,
            size: AppConstants.iconSizeMedium.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildRecurringBadge(RecurringFrequency? frequency) {
    IconData icon;
    String tooltip;

    switch (frequency) {
      case RecurringFrequency.weekly:
        icon = Icons.view_week;
        tooltip = 'Weekly recurring expense';
        break;
      case RecurringFrequency.monthly:
        icon = Icons.calendar_month;
        tooltip = 'Monthly recurring expense';
        break;
      default:
        icon = Icons.repeat;
        tooltip = 'Recurring expense';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor
              .withAlpha((255 * AppConstants.opacityOverlay).toInt()),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall.r),
        ),
        child: Icon(
          icon,
          size: AppConstants.iconSizeSmall.sp,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}
