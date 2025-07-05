import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/recurring_expense.dart';
import '../../data/infrastructure/services/settings_service.dart';
import '../../data/infrastructure/services/data_collection_service.dart';
import '../../data/infrastructure/services/notification_service.dart';
import '../../presentation/viewmodels/expenses_viewmodel.dart';
import '../../presentation/widgets/recurring_expense_config.dart';
import '../../di/injection_container.dart' as di;
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';
import '../widgets/category_selector.dart';
import '../widgets/custom_dropdown_field.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_time_picker_field.dart';
import '../widgets/submit_button.dart';
import '../../data/infrastructure/errors/app_error.dart';

class AddExpenseScreen extends StatefulWidget {
  final Map<String, dynamic>? prefilledData;

  const AddExpenseScreen({Key? key, this.prefilledData}) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Use lazy loading and caching optimization
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
  final ValueNotifier<bool> _isRecurring = ValueNotifier<bool>(false);
  final ValueNotifier<RecurringFrequency> _recurringFrequency =
      ValueNotifier<RecurringFrequency>(RecurringFrequency.weekly);
  final ValueNotifier<int?> _recurringDayOfMonth = ValueNotifier<int?>(null);
  final ValueNotifier<DayOfWeek?> _recurringDayOfWeek =
      ValueNotifier<DayOfWeek?>(null);
  final ValueNotifier<DateTime?> _recurringEndDate =
      ValueNotifier<DateTime?>(null);

  // Get services
  final _settingsService = di.sl<SettingsService>();
  final _notificationService = di.sl<NotificationService>();

  // Store detection ID for cleanup if this expense comes from notification
  String? _detectionId;

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
    // Initialize currency from settings service
    _currency = ValueNotifier<String>(_settingsService.currency);

    // Handle prefilled data from expense extraction
    if (widget.prefilledData != null) {
      _preloadDataFromExtraction();
    }
  }

  void _preloadDataFromExtraction() {
    final data = widget.prefilledData!;

    debugPrint('📱 AddExpenseScreen: Processing extracted data: $data');

    // Set amount if available
    if (data['amount'] != null) {
      final amount = data['amount'];
      if (amount is double) {
        _amountController.text = amount.toStringAsFixed(2);
      } else if (amount is String) {
        final cleanAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
        final parsedAmount = double.tryParse(cleanAmount);
        if (parsedAmount != null) {
          _amountController.text = parsedAmount.toStringAsFixed(2);
        } else {
          _amountController.text = amount;
        }
      }
    }

    // Set merchant name as remark (primary change as per user requirement)
    if (data['merchantName'] != null &&
        data['merchantName'].toString().trim().isNotEmpty) {
      _remarkController.text = data['merchantName'].toString();
    } else if (data['merchant'] != null &&
        data['merchant'].toString().trim().isNotEmpty) {
      _remarkController.text = data['merchant'].toString();
    }

    // Set currency (default to MYR if not extracted or not supported)
    if (data['currency'] != null) {
      final extractedCurrency = data['currency'].toString().toUpperCase();
      // Only use extracted currency if it's supported
      if (['MYR', 'USD', 'EUR', 'SGD', 'THB', 'IDR']
          .contains(extractedCurrency)) {
        _currency.value = extractedCurrency;
      } else {
        _currency.value = 'MYR'; // Default to MYR for unsupported currencies
      }
    } else {
      _currency.value = 'MYR'; // Default to MYR if no currency detected
    }

    // Set payment method if extracted
    if (data['paymentMethod'] != null ||
        (data['metadata'] != null &&
            data['metadata']['paymentMethod'] != null)) {
      final extractedPaymentMethod =
          data['paymentMethod'] ?? data['metadata']['paymentMethod'];
      final normalizedPaymentMethod =
          _normalizePaymentMethod(extractedPaymentMethod.toString());
      if (normalizedPaymentMethod != null &&
          _paymentMethodMap.containsKey(normalizedPaymentMethod)) {
        _selectedPaymentMethod.value = normalizedPaymentMethod;
      }
    }

    // Set date/time if available
    if (data['datetime'] != null) {
      try {
        DateTime parsedDate;
        if (data['datetime'] is DateTime) {
          parsedDate = data['datetime'];
        } else {
          parsedDate = DateTime.parse(data['datetime'].toString());
        }
        _selectedDateTime.value = parsedDate;
      } catch (e) {
        // Keep current time if parsing fails
        debugPrint('Failed to parse extracted datetime: $e');
      }
    }

    // Set detection ID if available
    if (data['detectionId'] != null) {
      _detectionId = data['detectionId'].toString();
    }

    debugPrint(
        '📱 AddExpenseScreen: Preloaded data - Amount: ${_amountController.text}, Merchant: ${_remarkController.text}, Currency: ${_currency.value}, Payment Method: ${_selectedPaymentMethod.value}');
  }

  /// Normalize extracted payment method to match app's payment method options
  String? _normalizePaymentMethod(String paymentMethod) {
    final method = paymentMethod.toLowerCase().trim();

    // Map common variations to app's payment methods
    if (method.contains('card') ||
        method.contains('credit') ||
        method.contains('debit')) {
      return 'Card';
    } else if (method.contains('cash') || method.contains('banknote')) {
      return 'Cash';
    } else if (method.contains('wallet') ||
        method.contains('grab') ||
        method.contains('touch') ||
        method.contains('pay') ||
        method.contains('digital')) {
      return 'E-Wallet';
    } else if (method.contains('transfer') ||
        method.contains('bank') ||
        method.contains('online')) {
      return 'Bank Transfer';
    }

    return null; // Return null if no match found, will use default
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

        // Create the expense with the embedded recurring details
        final expense = Expense(
          id: '', // Use empty ID to let repository handle Firebase/offline ID assignment
          remark: remarkText,
          amount: amount,
          date: _selectedDateTime.value,
          category: _selectedCategory.value,
          method: _getPaymentMethodEnum(_selectedPaymentMethod.value),
          description: _isRecurring.value
              ? _recurringFrequency.value.displayName
              : 'One-time Payment',
          currency: _currency.value,
          recurringDetails: recurringDetails,
        );

        await viewModel.addExpense(expense);

        // Record data for model improvement if user has consented
        try {
          final dataCollector = di.sl<DataCollectionService>();
          await dataCollector.recordManualExpense(
            amount: amount,
            currency: _currency.value,
            selectedCategory: _selectedCategory.value,
            userRemark: remarkText,
            entryMethod: 'manual_form',
            additionalMetadata: {
              'paymentMethod': _selectedPaymentMethod.value,
              'isRecurring': _isRecurring.value,
              'recurringFrequency':
                  _isRecurring.value ? _recurringFrequency.value.name : null,
              'entryTimestamp': DateTime.now().toIso8601String(),
              'hasDescription': _descriptionController.text.trim().isNotEmpty,
            },
          );
          debugPrint(
              '📊 Model improvement data recorded successfully for manual expense');
        } catch (modelError) {
          // Don't fail the expense saving if model improvement fails
          debugPrint(
              '📊 Failed to record model improvement data for manual expense: $modelError');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.expenseAddedMessage),
              backgroundColor: AppTheme.primaryColor,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context)
              .pop(true); // Return true to indicate successful addition
        }

        // Cleanup after successful expense addition
        if (_detectionId != null) {
          _notificationService.cleanupAfterExpenseAdded(_detectionId!);
          debugPrint(
              '📱 Notification cleanup completed for detection ID: $_detectionId');
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
        title: Text(
          AppConstants.newExpenseTitle,
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingLarge.w,
                vertical: AppConstants.spacingXXLarge.h),
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
                SizedBox(height: AppConstants.spacingXXLarge.h),

                Row(
                  children: [
                    Container(
                      width: 100.w,
                      margin:
                          EdgeInsets.only(right: AppConstants.spacingSmall.w),
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
                SizedBox(height: AppConstants.spacingLarge.h),

                CustomTextField(
                  controller: _remarkController,
                  labelText: 'Remark',
                  isRequired: true,
                  prefixIcon: Icons.note,
                ),
                SizedBox(height: AppConstants.spacingLarge.h),

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
                SizedBox(height: AppConstants.spacingLarge.h),

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
                SizedBox(height: AppConstants.spacingLarge.h),

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
                              fontSize: AppConstants.textSizeLarge.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Set up automatic recurring payments',
                            style: TextStyle(
                              fontSize: AppConstants.textSizeSmall.sp,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          value: isRecurring,
                          onChanged: (value) {
                            _isRecurring.value = value;
                          },
                        ),
                        if (isRecurring) ...[
                          SizedBox(height: AppConstants.spacingLarge.h),
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
                SizedBox(height: AppConstants.spacingXXLarge.h),

                // Submit button
                SubmitButton(
                  text: AppConstants.addButtonText,
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
                  icon: Icons.add,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
