import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/financial_goal.dart';
import '../utils/app_constants.dart';
import '../utils/dialog_utils.dart';
import 'goal_icon_selector.dart';

/// Dialog for creating or editing a financial goal
class GoalFormDialog extends StatefulWidget {
  /// Goal to edit (null for new goal)
  final FinancialGoal? goal;

  /// Callback when goal is saved
  final Function(FinancialGoal) onSave;

  /// Constructor
  const GoalFormDialog({
    Key? key,
    this.goal,
    required this.onSave,
  }) : super(key: key);

  @override
  State<GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<GoalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  late DateTime _deadline;
  late GoalIcon _selectedIcon;
  final _uuid = const Uuid();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.goal != null;

    if (_isEditing) {
      _titleController.text = widget.goal!.title;
      _amountController.text = widget.goal!.targetAmount.toString();
      _deadline = widget.goal!.deadline;
      _selectedIcon = widget.goal!.icon;
    } else {
      // Default values for new goal
      _deadline = DateTime.now().add(const Duration(days: 90));
      _selectedIcon = GoalIcon(
        icon: Icons.savings,
        name: 'savings',
        color: Colors.blue,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final double amount = double.parse(_amountController.text);

      final FinancialGoal goal = FinancialGoal(
        id: _isEditing ? widget.goal!.id : _uuid.v4(),
        title: _titleController.text,
        targetAmount: amount,
        currentAmount: _isEditing ? widget.goal!.currentAmount : 0.0,
        deadline: _deadline,
        icon: _selectedIcon,
        isCompleted: _isEditing ? widget.goal!.isCompleted : false,
        createdAt: _isEditing ? widget.goal!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(goal);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacingLarge.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  _isEditing ? 'Edit Goal' : 'Create New Goal',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeXLarge.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppConstants.spacingLarge.h),

                // Icon selector
                GoalIconSelector(
                  initialIcon: _selectedIcon,
                  onIconSelected: (icon) {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                ),
                SizedBox(height: AppConstants.spacingLarge.h),

                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title',
                    hintText: 'e.g., New Car, Vacation, etc.',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppConstants.spacingMedium.h),

                // Amount field
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount',
                    hintText: 'e.g., 5000',
                    prefixText: 'RM ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    try {
                      final amount = double.parse(value);
                      if (amount <= 0) {
                        return 'Amount must be greater than 0';
                      }
                    } catch (e) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppConstants.spacingMedium.h),

                // Deadline field
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Deadline',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(_deadline),
                    ),
                  ),
                ),
                SizedBox(height: AppConstants.spacingLarge.h),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: AppConstants.spacingLarge.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusLarge.r,
                            ),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            fontSize: AppConstants.textSizeMedium.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppConstants.spacingMedium.w),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saveGoal,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: AppConstants.spacingLarge.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusLarge.r,
                            ),
                          ),
                        ),
                        child: Text(
                          _isEditing ? 'UPDATE' : 'CREATE',
                          style: TextStyle(
                            fontSize: AppConstants.textSizeMedium.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Show the goal form dialog
Future<void> showGoalFormDialog({
  required BuildContext context,
  FinancialGoal? goal,
  required Function(FinancialGoal) onSave,
}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return GoalFormDialog(
        goal: goal,
        onSave: onSave,
      );
    },
  );
}
