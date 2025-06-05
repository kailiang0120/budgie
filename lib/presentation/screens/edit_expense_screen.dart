import 'package:flutter/material.dart';
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
import '../../core/errors/app_error.dart';
import '../../core/services/settings_service.dart';
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
    'Credit Card': PaymentMethod.creditCard,
    'Cash': PaymentMethod.cash,
    'e-Wallet': PaymentMethod.eWallet,
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
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.eWallet:
        return 'e-Wallet';
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
              dayOfMonth: _recurringDayOfMonth.value,
              dayOfWeek: _recurringDayOfWeek.value,
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
              expenseDescription: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
            );

            await _recurringExpensesRepository
                .updateRecurringExpense(updatedRecurringExpense);
          } else {
            // Create new recurring expense
            final newRecurringExpense = RecurringExpense(
              id: '', // Let repository assign ID
              frequency: _recurringFrequency.value,
              dayOfMonth: _recurringDayOfMonth.value,
              dayOfWeek: _recurringDayOfWeek.value,
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
              expenseDescription: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
            );

            final createdRecurringExpense = await _recurringExpensesRepository
                .addRecurringExpense(newRecurringExpense);
            recurringExpenseId = createdRecurringExpense.id;
          }
        } else if (_originalRecurringExpense != null) {
          // User changed from recurring to one-time, deactivate the recurring expense
          final deactivatedRecurringExpense =
              _originalRecurringExpense!.copyWith(isActive: false);
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
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
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
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
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
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 8),
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
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _remarkController,
                        labelText: 'Remark',
                        prefixIcon: Icons.note,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 24),

                      // Update button - Square with corner radius
                      SizedBox(
                        width: double.infinity,
                        height: 56, // Square-ish height
                        child: ElevatedButton(
                          onPressed: _isSubmitting || _isDeleting
                              ? null
                              : _handleUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12.0), // Corner radius
                            ),
                            elevation: 2,
                          ),
                          child: _isSubmitting
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Updating...',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.update_rounded, size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      'Update Expense',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Delete button - Square with corner radius
                      SizedBox(
                        width: double.infinity,
                        height: 56, // Square-ish height
                        child: ElevatedButton(
                          onPressed: _isSubmitting || _isDeleting
                              ? null
                              : _handleDelete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12.0), // Corner radius
                            ),
                            elevation: 2,
                          ),
                          child: _isDeleting
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Deleting...',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.delete_rounded, size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete Expense',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 16,
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
