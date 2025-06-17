import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/recurring_expense.dart';

import '../viewmodels/expenses_viewmodel.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';
import '../widgets/category_selector.dart';
import '../widgets/custom_dropdown_field.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_time_picker_field.dart';
import '../widgets/recurring_expense_config.dart';
import '../widgets/submit_button.dart';
import '../../data/infrastructure/errors/app_error.dart';
import '../../data/infrastructure/services/settings_service.dart';
import '../../di/injection_container.dart' as di;

class EditExpenseScreen extends StatefulWidget {
  final Expense expense;

  const EditExpenseScreen({Key? key, required this.expense}) : super(key: key);

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isDeleting = false;
  bool _isLoadingRecurringData = true;

  // Controllers and notifiers
  late final ValueNotifier<String> _currency;
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final ValueNotifier<DateTime> _selectedDateTime;
  late final ValueNotifier<Category> _selectedCategory;
  late final ValueNotifier<String> _selectedPaymentMethod;
  late final ValueNotifier<bool> _isRecurring;
  final ValueNotifier<RecurringFrequency> _recurringFrequency =
      ValueNotifier<RecurringFrequency>(RecurringFrequency.weekly);
  final ValueNotifier<int?> _recurringDayOfMonth = ValueNotifier<int?>(null);
  final ValueNotifier<DayOfWeek?> _recurringDayOfWeek =
      ValueNotifier<DayOfWeek?>(null);
  final ValueNotifier<DateTime?> _recurringEndDate =
      ValueNotifier<DateTime?>(null);

  // Services
  final _settingsService = di.sl<SettingsService>();

  // Payment method mapping
  final Map<String, PaymentMethod> _paymentMethodMap = {
    'Card': PaymentMethod.card,
    'Cash': PaymentMethod.cash,
    'E-Wallet': PaymentMethod.eWallet,
    'Bank Transfer': PaymentMethod.bankTransfer,
    'Other': PaymentMethod.other,
  };

  @override
  void initState() {
    super.initState();
    _initializeWithExpenseData();
  }

  void _initializeWithExpenseData() async {
    // Initialize currency from settings
    _currency = ValueNotifier<String>(_settingsService.currency);

    // Pre-populate fields with expense data
    _amountController.text = widget.expense.amount.toString();
    _remarkController.text = widget.expense.remark;

    // Initialize description controller with payment type if available, otherwise keep empty
    _descriptionController.text = widget.expense.description ?? '';

    _selectedDateTime = ValueNotifier<DateTime>(widget.expense.date);
    _selectedCategory = ValueNotifier<Category>(widget.expense.category);
    _selectedPaymentMethod =
        ValueNotifier<String>(_getPaymentMethodString(widget.expense.method));
    _currency.value = widget.expense.currency;
    _isRecurring = ValueNotifier<bool>(widget.expense.isRecurring);

    // Load recurring details from embedded field
    if (widget.expense.recurringDetails != null) {
      _recurringFrequency.value = widget.expense.recurringDetails!.frequency;
      _recurringDayOfMonth.value = widget.expense.recurringDetails!.dayOfMonth;
      _recurringDayOfWeek.value = widget.expense.recurringDetails!.dayOfWeek;
      _recurringEndDate.value = widget.expense.recurringDetails!.endDate;
    }

    setState(() {
      _isLoadingRecurringData = false;
    });
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

  @override
  void dispose() {
    _amountController.dispose();
    _remarkController.dispose();
    _descriptionController.dispose();
    _currency.dispose();
    _selectedDateTime.dispose();
    _selectedCategory.dispose();
    _selectedPaymentMethod.dispose();
    _isRecurring.dispose();
    _recurringFrequency.dispose();
    _recurringDayOfMonth.dispose();
    _recurringDayOfWeek.dispose();
    _recurringEndDate.dispose();
    super.dispose();
  }

  void _setCurrentDateTime() {
    _selectedDateTime.value = DateTime.now();
  }

  void _handleUpdate() {
    _updateExpense();
  }

  void _handleDelete() {
    _showDeleteConfirmation();
  }

  void _updateExpense() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isSubmitting = true;
        });

        final viewModel =
            Provider.of<ExpensesViewModel>(context, listen: false);

        // Safely parse amount with null check
        final amountText = _amountController.text.trim();
        if (amountText.isEmpty) {
          throw Exception('Amount cannot be empty');
        }

        final amount = double.tryParse(amountText);
        if (amount == null || amount <= 0) {
          throw Exception('Please enter a valid amount greater than zero');
        }

        // Safely get remark with null check
        final remarkText = _remarkController.text.trim();
        if (remarkText.isEmpty) {
          throw Exception('Remark cannot be empty');
        }

        // Create recurring details if this is a recurring expense
        RecurringDetails? recurringDetails;
        if (_isRecurring.value) {
          recurringDetails = RecurringDetails(
            frequency: _recurringFrequency.value,
            dayOfMonth: _recurringFrequency.value == RecurringFrequency.monthly
                ? _recurringDayOfMonth.value
                : null,
            dayOfWeek: _recurringFrequency.value == RecurringFrequency.weekly
                ? _recurringDayOfWeek.value
                : null,
            endDate: _recurringEndDate.value,
          );
        }

        // Create updated expense with embedded recurring details
        final updatedExpense = widget.expense.copyWith(
          remark: remarkText,
          amount: amount,
          date: _selectedDateTime.value,
          category: _selectedCategory.value,
          method: _getPaymentMethodEnum(_selectedPaymentMethod.value),
          description: _isRecurring.value
              ? _recurringFrequency.value.displayName
              : "One-time Payment",
          currency: _currency.value,
          recurringDetails: recurringDetails,
          clearRecurringDetails: !_isRecurring.value,
        );

        await viewModel.updateExpense(updatedExpense);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense updated successfully'),
              backgroundColor: AppTheme.primaryColor,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context)
              .pop(true); // Return true to indicate successful update
        }
      } catch (e, stackTrace) {
        final error = AppError.from(e, stackTrace);
        error.log();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: const Text('Are you sure you want to delete this expense?'),
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
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteExpense() async {
    try {
      setState(() {
        _isDeleting = true;
      });

      final viewModel = Provider.of<ExpensesViewModel>(context, listen: false);
      await viewModel.deleteExpense(widget.expense.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context)
            .pop(true); // Return true to indicate successful delete
      }
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting expense: ${error.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  PaymentMethod _getPaymentMethodEnum(String paymentMethodString) {
    return _paymentMethodMap[paymentMethodString] ?? PaymentMethod.cash;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(
              context, false), // Return false when no action taken
        ),
        title: const Text('Edit Expense'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Divider(
            height: 1.h,
            thickness: 1.h,
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoadingRecurringData
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ValueListenableBuilder<Category>(
                          valueListenable: _selectedCategory,
                          builder: (context, selectedCategory, _) {
                            return CategorySelector(
                              selectedCategory: selectedCategory,
                              onCategorySelected: (category) {
                                _selectedCategory.value = category;
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 24.h),

                      Row(
                        children: [
                          Container(
                            width: 100.w,
                            margin: EdgeInsets.only(right: 8.w),
                            child: ValueListenableBuilder<String>(
                              valueListenable: _currency,
                              builder: (context, currency, _) {
                                return CustomDropdownField<String>(
                                  value: currency,
                                  items: AppConstants.currencies,
                                  labelText: 'Currency',
                                  onChanged: (value) {
                                    if (value != null) {
                                      _currency.value = value;
                                    }
                                  },
                                  itemLabelBuilder: (item) => item,
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: ValueListenableBuilder<String>(
                              valueListenable: _currency,
                              builder: (context, currency, _) {
                                final currencySymbol =
                                    CurrencyFormatter.getCurrencySymbol(
                                        currency);
                                return CustomTextField.number(
                                  controller: _amountController,
                                  labelText: 'Amount',
                                  prefixText: currencySymbol,
                                  isRequired: true,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      CustomTextField(
                        controller: _remarkController,
                        labelText: 'Remark',
                        isRequired: true,
                        prefixIcon: Icons.note,
                      ),
                      SizedBox(height: 16.h),

                      ValueListenableBuilder<DateTime>(
                        valueListenable: _selectedDateTime,
                        builder: (context, selectedDateTime, _) {
                          return DateTimePickerField(
                            dateTime: selectedDateTime,
                            onDateChanged: (dateTime) {
                              _selectedDateTime.value = dateTime;
                            },
                            onTimeChanged: (dateTime) {
                              _selectedDateTime.value = dateTime;
                            },
                            onCurrentTimePressed: _setCurrentDateTime,
                          );
                        },
                      ),
                      SizedBox(height: 16.h),

                      ValueListenableBuilder<String>(
                        valueListenable: _selectedPaymentMethod,
                        builder: (context, selectedPaymentMethod, _) {
                          return CustomDropdownField<String>(
                            value: selectedPaymentMethod,
                            items: AppConstants.paymentMethods,
                            labelText: 'Payment Method',
                            onChanged: (value) {
                              if (value != null) {
                                _selectedPaymentMethod.value = value;
                              }
                            },
                            itemLabelBuilder: (item) => item,
                            prefixIcon: Icons.payment,
                          );
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Recurring expense toggle and configuration
                      ValueListenableBuilder<bool>(
                        valueListenable: _isRecurring,
                        builder: (context, isRecurring, _) {
                          return Column(
                            children: [
                              SwitchListTile(
                                title: Text(
                                  'Recurring Expense',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Set up automatic recurring payments',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                value: isRecurring,
                                onChanged: (value) {
                                  _isRecurring.value = value;
                                },
                              ),
                              if (isRecurring) ...[
                                SizedBox(height: 16.h),
                                RecurringExpenseConfig(
                                  initialFrequency: _recurringFrequency.value,
                                  initialDayOfMonth: _recurringDayOfMonth.value,
                                  initialDayOfWeek: _recurringDayOfWeek.value,
                                  initialEndDate: _recurringEndDate.value,
                                  onFrequencyChanged: (newFrequency) {
                                    _recurringFrequency.value = newFrequency;
                                  },
                                  onDayOfMonthChanged: (newDayOfMonth) {
                                    _recurringDayOfMonth.value = newDayOfMonth;
                                  },
                                  onDayOfWeekChanged: (newDayOfWeek) {
                                    _recurringDayOfWeek.value = newDayOfWeek;
                                  },
                                  onEndDateChanged: (newEndDate) {
                                    _recurringEndDate.value = newEndDate;
                                  },
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 24.h),

                      // Update and Delete buttons
                      Column(
                        children: [
                          SubmitButton(
                            text: 'Update',
                            isLoading: _isSubmitting,
                            onPressed: _isSubmitting || _isDeleting
                                ? () {}
                                : _handleUpdate,
                            icon: Icons.update,
                          ),
                          SizedBox(height: 16.h),
                          SubmitButton(
                            text: 'Delete',
                            isLoading: _isDeleting,
                            onPressed: _isSubmitting || _isDeleting
                                ? () {}
                                : _handleDelete,
                            icon: Icons.delete,
                            color: Colors.red,
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
