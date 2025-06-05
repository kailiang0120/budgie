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

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // 使用懒加载和缓存优化
  late final ValueNotifier<String> _currency;
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ValueNotifier<DateTime> _selectedDateTime =
      ValueNotifier<DateTime>(DateTime.now());
  final ValueNotifier<Category> _selectedCategory =
      ValueNotifier<Category>(Category.food);
  final ValueNotifier<String> _selectedPaymentMethod =
      ValueNotifier<String>('Cash');
  final ValueNotifier<RecurringFrequency> _recurringFrequency =
      ValueNotifier<RecurringFrequency>(RecurringFrequency.oneTime);
  final ValueNotifier<int?> _recurringDayOfMonth = ValueNotifier<int?>(null);
  final ValueNotifier<DayOfWeek?> _recurringDayOfWeek =
      ValueNotifier<DayOfWeek?>(null);
  final ValueNotifier<DateTime?> _recurringEndDate =
      ValueNotifier<DateTime?>(null);

  // Get services
  final _settingsService = di.sl<SettingsService>();
  final _recurringExpensesRepository = di.sl<RecurringExpensesRepository>();

  // Payment method mapping
  final Map<String, PaymentMethod> _paymentMethodMap = {
    'Credit Card': PaymentMethod.creditCard,
    'Cash': PaymentMethod.cash,
    'e-Wallet': PaymentMethod.eWallet,
  };

  @override
  void initState() {
    super.initState();
    // Initialize currency from settings service
    _currency = ValueNotifier<String>(_settingsService.currency);
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

  void _handleSubmit() {
    _submit();
  }

  void _submit() async {
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

        String? recurringExpenseId;

        // If it's a recurring expense, create the recurring expense record first
        if (_recurringFrequency.value != RecurringFrequency.oneTime) {
          final recurringExpense = RecurringExpense(
            id: '', // Let repository assign ID
            frequency: _recurringFrequency.value,
            dayOfMonth: _recurringDayOfMonth.value,
            dayOfWeek: _recurringDayOfWeek.value,
            startDate: _selectedDateTime.value,
            endDate: _recurringEndDate.value,
            isActive: true,
            lastProcessedDate:
                _selectedDateTime.value, // Mark as processed to avoid duplicate
            expenseRemark: remarkText,
            expenseAmount: amount,
            expenseCategoryId: _selectedCategory.value.id,
            expensePaymentMethod:
                _selectedPaymentMethod.value.toLowerCase().replaceAll(' ', ''),
            expenseCurrency: _currency.value,
            expenseDescription: null,
          );

          final createdRecurringExpense = await _recurringExpensesRepository
              .addRecurringExpense(recurringExpense);
          recurringExpenseId = createdRecurringExpense.id;
        }

        // Create the expense with the recurring expense ID if applicable
        final expense = Expense(
          id: '', // Use empty ID to let repository handle Firebase/offline ID assignment
          remark: remarkText,
          amount: amount,
          date: _selectedDateTime.value,
          category: _selectedCategory.value,
          method: _getPaymentMethodEnum(_selectedPaymentMethod.value),
          description: null, // No longer storing recurring info in description
          currency: _currency.value,
          recurringExpenseId: recurringExpenseId,
        );

        await viewModel.addExpense(expense);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.expenseAddedMessage),
              backgroundColor: AppTheme.primaryColor,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          AppConstants.newExpenseTitle,
        ),
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                              CurrencyFormatter.getCurrencySymbol(currency);
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

                // Submit button - Square with corner radius
                SizedBox(
                  width: double.infinity,
                  height: 56, // Square-ish height
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16.0), // Corner radius
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
                                AppConstants.addingText,
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
                              Icon(Icons.add_rounded, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Add New Expenses',
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
