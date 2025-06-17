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
import '../viewmodels/budget_viewmodel.dart';

class ExpenseCard extends StatefulWidget {
  final Expense expense;
  final VoidCallback? onExpenseUpdated;

  const ExpenseCard({
    Key? key,
    required this.expense,
    this.onExpenseUpdated,
  }) : super(key: key);

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
      duration: const Duration(milliseconds: 300),
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

      Future.delayed(const Duration(milliseconds: 300), () {
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
            style: TextStyle(fontSize: 18.sp),
          ),
          content: Text(
            'Are you sure you want to delete this expense? This action cannot be undone.',
            style: TextStyle(fontSize: 14.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 14.sp),
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
                'Delete',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ],
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

      await viewModel.deleteExpense(widget.expense.id);

      // Trigger the callback first to refresh expenses
      if (widget.onExpenseUpdated != null) {
        widget.onExpenseUpdated!();
      }

      // Add a small delay then refresh budget data after expense deletion
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            budgetVM.refreshBudget(monthId);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted successfully'),
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

  void _onTap() {
    if (_isSwipeOpened) {
      _closeSwipe();
    } else {
      _navigateToEdit();
    }
  }

  String _getPaymentMethodString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.eWallet:
        return 'E-Wallet';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  String _getRecurringDetailsString() {
    if (!widget.expense.isRecurring) {
      return '';
    }

    final recurringDetails = widget.expense.recurringDetails;
    if (recurringDetails == null) {
      debugPrint(
          'Warning: Expense ${widget.expense.id} marked as recurring but has no recurringDetails');
      return 'Recurring (details not available)';
    }

    final frequency = recurringDetails.frequency;
    if (frequency == RecurringFrequency.weekly &&
        recurringDetails.dayOfWeek != null) {
      return 'Recurring weekly on ${recurringDetails.dayOfWeek!.displayName}';
    } else if (frequency == RecurringFrequency.monthly &&
        recurringDetails.dayOfMonth != null) {
      return 'Recurring monthly on day ${recurringDetails.dayOfMonth}';
    }

    return 'Recurring ${frequency.displayName.toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Calculate dynamic height based on content
    final baseHeight = 85.h;
    final additionalHeight = widget.expense.isRecurring
        ? 16.h
        : 0.h; // Extra space for recurring details
    final cardHeight = baseHeight + additionalHeight;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background container for round action buttons
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                color: isDarkMode
                    ? Colors.grey.shade900.withValues(alpha: 0.3)
                    : Colors.grey.shade300,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Edit Button - Round with fixed ratio
                  Container(
                    width: 56.w,
                    height: 56.w,
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 4.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _navigateToEdit,
                        borderRadius: BorderRadius.circular(28.r),
                        child: Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ),

                  // Delete Button - Round with fixed ratio
                  Container(
                    width: 56.w,
                    height: 56.w,
                    margin: EdgeInsets.only(right: 16.w),
                    decoration: BoxDecoration(
                      color: Colors.red.shade500,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade500.withValues(alpha: 0.2),
                          blurRadius: 4.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showDeleteConfirmation,
                        borderRadius: BorderRadius.circular(28.r),
                        child: Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main card content that slides over the buttons
          SlideTransition(
            position: _slideAnimation,
            child: GestureDetector(
              onTap: _onTap,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Container(
                height: cardHeight,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      // Category Icon
                      Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color:
                              CategoryManager.getColor(widget.expense.category),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CategoryManager.getIcon(widget.expense.category),
                          color: Colors.white,
                          size: 24.sp,
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 5.r,
                              offset: Offset(0, 5.h),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 12.w),

                      // Expense Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.expense.remark,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.expense.isRecurring) ...[
                                  SizedBox(width: 4.w),
                                  Icon(
                                    Icons.repeat,
                                    size: 16.sp,
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(width: 10.w),
                                ],
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${dateFormat.format(widget.expense.date)} at ${timeFormat.format(widget.expense.date)}',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 10.sp,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
                            if (widget.expense.isRecurring) ...[
                              SizedBox(height: 2.h),
                              Text(
                                _getRecurringDetailsString(),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 8.5.sp,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Amount and Payment Method
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${widget.expense.currency} ${widget.expense.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w500,
                              fontSize: 16.sp,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _getPaymentMethodString(widget.expense.method),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 10.sp,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                          if (widget.expense.isRecurring) ...[
                            SizedBox(height: 16.h),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
