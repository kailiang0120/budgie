import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/expense.dart';
import '../utils/category_manager.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../../core/constants/routes.dart';
import '../utils/app_theme.dart';

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

  // Constants for button sizing and positioning
  static const double cardMinHeight = 80.0;
  static const double buttonSize = 56.0; // Round buttons size
  static const double buttonMargin = 8.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end:
          const Offset(-0.37, 0), // Slide further to fully reveal round buttons
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
    }
  }

  void _showDeleteConfirmation() {
    _closeSwipe(); // Close swipe before showing dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: const Text(
              'Are you sure you want to delete this expense? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteExpense();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteExpense() async {
    try {
      final viewModel = Provider.of<ExpensesViewModel>(context, listen: false);
      await viewModel.deleteExpense(widget.expense.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted successfully'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );

        if (widget.onExpenseUpdated != null) {
          widget.onExpenseUpdated!();
        }
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
    const double sensitivity = 8.0;

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
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.eWallet:
        return 'e-Wallet';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: cardMinHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background container for round action buttons
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDarkMode
                    ? Colors.grey.shade900.withValues(alpha: 0.3)
                    : Colors.grey.shade300,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Edit Button - Round with fixed ratio
                  Container(
                    width: buttonSize,
                    height: buttonSize,
                    margin: const EdgeInsets.only(right: buttonMargin),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _navigateToEdit,
                        borderRadius: BorderRadius.circular(buttonSize / 2),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  // Delete Button - Round with fixed ratio
                  Container(
                    width: buttonSize,
                    height: buttonSize,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade500,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade500.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showDeleteConfirmation,
                        borderRadius: BorderRadius.circular(buttonSize / 2),
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                          size: 24,
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
                height: cardMinHeight,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Category Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              CategoryManager.getColor(widget.expense.category),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CategoryManager.getIcon(widget.expense.category),
                          color: Colors.white,
                          size: 24,
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Expense Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.expense.remark,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${dateFormat.format(widget.expense.date)} at ${timeFormat.format(widget.expense.date)}',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
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
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getPaymentMethodString(widget.expense.method),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
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
