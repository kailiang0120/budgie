import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/recurring_expense.dart';
import '../../domain/repositories/recurring_expenses_repository.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';
import '../widgets/category_selector.dart';
import '../widgets/custom_dropdown_field.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_time_picker_field.dart';
import '../widgets/recurring_expense_config.dart';
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
  final ValueNotifier<RecurringFrequency> _recurringFrequency =
      ValueNotifier<RecurringFrequency>(RecurringFrequency.oneTime);
  final ValueNotifier<int?> _recurringDayOfMonth = ValueNotifier<int?>(null);
  final ValueNotifier<DayOfWeek?> _recurringDayOfWeek =
      ValueNotifier<DayOfWeek?>(null);
  final ValueNotifier<DateTime?> _recurringEndDate =
      ValueNotifier<DateTime?>(null);

  // Services
  final _settingsService = di.sl<SettingsService>();
  final _recurringExpensesRepository = di.sl<RecurringExpensesRepository>();

  // Recurring expense data
  RecurringExpense? _originalRecurringExpense;

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

    // Load recurring expense data if this expense is part of a recurring series
    if (widget.expense.recurringExpenseId != null) {
      await _loadRecurringExpenseData();
    } else {
      // Set default frequency to one-time if not a recurring expense
      _recurringFrequency.value = RecurringFrequency.oneTime;
      setState(() {
        _isLoadingRecurringData = false;
      });
    }
  }

  Future<void> _loadRecurringExpenseData() async {
    try {
      if (widget.expense.recurringExpenseId != null) {
        // Get all recurring expenses and find the one with matching ID
        final allRecurringExpenses =
            await _recurringExpensesRepository.getRecurringExpenses();
        _originalRecurringExpense = allRecurringExpenses.firstWhere(
          (expense) => expense.id == widget.expense.recurringExpenseId,
          orElse: () => throw Exception('Recurring expense not found'),
        );

        if (_originalRecurringExpense != null) {
          // Set recurring configuration values
          _recurringFrequency.value = _originalRecurringExpense!.frequency;
          _recurringDayOfMonth.value = _originalRecurringExpense!.dayOfMonth;
          _recurringDayOfWeek.value = _originalRecurringExpense!.dayOfWeek;
          _recurringEndDate.value = _originalRecurringExpense!.endDate;
        }
      }
    } catch (e) {
      debugPrint('Error loading recurring expense data: $e');
    } finally {
      setState(() {
        _isLoadingRecurringData = false;
      });
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

  @override
  void dispose() {
    _amountController.dispose();
    _remarkController.dispose();
    _descriptionController.dispose();
    _currency.dispose();
    _selectedDateTime.dispose();
    _selectedCategory.dispose();
    _selectedPaymentMethod.dispose();
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

        String? recurringExpenseId = widget.expense.recurringExpenseId;

        // Handle recurring expense updates
        if (_recurringFrequency.value != RecurringFrequency.oneTime) {
          if (_originalRecurringExpense != null) {
            // Update existing recurring expense
            final updatedRecurringExpense = RecurringExpense(
              id: _originalRecurringExpense!.id,
              frequency: _recurringFrequency.value,
              dayOfMonth:
                  _recurringFrequency.value == RecurringFrequency.monthly
                      ? _recurringDayOfMonth.value
                      : null,
              dayOfWeek: _recurringFrequency.value == RecurringFrequency.weekly
                  ? _recurringDayOfWeek.value
                  : null,
              startDate: _originalRecurringExpense!.startDate,
              endDate: _recurringEndDate.value,
              isActive: true,
              lastProcessedDate: _originalRecurringExpense!.lastProcessedDate,
              expenseRemark: remarkText,
              expenseAmount: amount,
              expenseCategoryId: _selectedCategory.value.id,
              expensePaymentMethod: _selectedPaymentMethod.value
                  .toLowerCase()
                  .replaceAll(' ', ''),
              expenseCurrency: _currency.value,
              expenseDescription: _recurringFrequency.value.displayName,
            );

            await _recurringExpensesRepository
                .updateRecurringExpense(updatedRecurringExpense);
          } else {
            // Create new recurring expense
            final newRecurringExpense = RecurringExpense(
              id: '', // Let repository assign ID
              frequency: _recurringFrequency.value,
              dayOfMonth:
                  _recurringFrequency.value == RecurringFrequency.monthly
                      ? _recurringDayOfMonth.value
                      : null,
              dayOfWeek: _recurringFrequency.value == RecurringFrequency.weekly
                  ? _recurringDayOfWeek.value
                  : null,
              startDate: _selectedDateTime.value,
              endDate: _recurringEndDate.value,
              isActive: true,
              lastProcessedDate: _selectedDateTime.value,
              expenseRemark: remarkText,
              expenseAmount: amount,
              expenseCategoryId: _selectedCategory.value.id,
              expensePaymentMethod: _selectedPaymentMethod.value
                  .toLowerCase()
                  .replaceAll(' ', ''),
              expenseCurrency: _currency.value,
              expenseDescription: _recurringFrequency.value.displayName,
            );

            final createdRecurringExpense = await _recurringExpensesRepository
                .addRecurringExpense(newRecurringExpense);
            recurringExpenseId = createdRecurringExpense.id;
          }
        } else if (_originalRecurringExpense != null) {
          // User changed from recurring to one-time, deactivate the recurring expense
          // and explicitly set dayOfMonth and dayOfWeek to null
          final deactivatedRecurringExpense =
              _originalRecurringExpense!.copyWith(
            isActive: false,
            dayOfMonth: null,
            dayOfWeek: null,
          );
          await _recurringExpensesRepository
              .updateRecurringExpense(deactivatedRecurringExpense);
          recurringExpenseId = null;
        }

        // Create updated expense
        final updatedExpense = Expense(
          id: widget.expense.id, // Keep the same ID
          remark: remarkText,
          amount: amount,
          date: _selectedDateTime.value,
          category: _selectedCategory.value,
          method: _getPaymentMethodEnum(_selectedPaymentMethod.value),
          description: _recurringFrequency.value == RecurringFrequency.oneTime
              ? "One-time Payment"
              : _recurringFrequency.value.displayName,
          currency: _currency.value,
          recurringExpenseId: recurringExpenseId,
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
          Navigator.of(context).pop(true); // Return true to indicate success
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
      setState(() {
        _isDeleting = true;
      });

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
        Navigator.of(context).pop(true); // Return true to indicate success
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
                        prefixIcon: Icons.note,
                        isRequired: true,
                      ),
                      SizedBox(height: 16.h),

                      ValueListenableBuilder<DateTime>(
                        valueListenable: _selectedDateTime,
                        builder: (context, selectedDateTime, _) {
                          return DateTimePickerField(
                            dateTime: selectedDateTime,
                            onDateChanged: (date) {
                              _selectedDateTime.value = date;
                            },
                            onTimeChanged: (time) {
                              _selectedDateTime.value = time;
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

                      // Recurring expense configuration
                      ValueListenableBuilder<RecurringFrequency>(
                        valueListenable: _recurringFrequency,
                        builder: (context, frequency, _) {
                          return ValueListenableBuilder<int?>(
                            valueListenable: _recurringDayOfMonth,
                            builder: (context, dayOfMonth, _) {
                              return ValueListenableBuilder<DayOfWeek?>(
                                valueListenable: _recurringDayOfWeek,
                                builder: (context, dayOfWeek, _) {
                                  return ValueListenableBuilder<DateTime?>(
                                    valueListenable: _recurringEndDate,
                                    builder: (context, endDate, _) {
                                      return RecurringExpenseConfig(
                                        initialFrequency: frequency,
                                        initialDayOfMonth: dayOfMonth,
                                        initialDayOfWeek: dayOfWeek,
                                        initialEndDate: endDate,
                                        onFrequencyChanged: (newFrequency) {
                                          _recurringFrequency.value =
                                              newFrequency;
                                        },
                                        onDayOfMonthChanged: (newDayOfMonth) {
                                          _recurringDayOfMonth.value =
                                              newDayOfMonth;
                                        },
                                        onDayOfWeekChanged: (newDayOfWeek) {
                                          _recurringDayOfWeek.value =
                                              newDayOfWeek;
                                        },
                                        onEndDateChanged: (newEndDate) {
                                          _recurringEndDate.value = newEndDate;
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      SizedBox(height: 24.h),

                      // Update button - Square with corner radius
                      SizedBox(
                        width: double.infinity,
                        height: 56.h, // Square-ish height
                        child: ElevatedButton(
                          onPressed: _isSubmitting || _isDeleting
                              ? null
                              : _handleUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 16.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12.r), // Corner radius
                            ),
                            elevation: 2,
                          ),
                          child: _isSubmitting
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.w,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      'Updating...',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.update_rounded, size: 22.sp),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Update Expense',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Delete button - Square with corner radius
                      SizedBox(
                        width: double.infinity,
                        height: 56.h, // Square-ish height
                        child: ElevatedButton(
                          onPressed: _isSubmitting || _isDeleting
                              ? null
                              : _handleDelete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 16.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12.r), // Corner radius
                            ),
                            elevation: 2,
                          ),
                          child: _isDeleting
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.w,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      'Deleting...',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.delete_rounded, size: 22.sp),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Delete Expense',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  PaymentMethod _getPaymentMethodEnum(String methodString) {
    return _paymentMethodMap[methodString] ?? PaymentMethod.cash;
  }
}
