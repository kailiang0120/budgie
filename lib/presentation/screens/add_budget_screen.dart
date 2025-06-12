import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/budget.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/category_manager.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/submit_button.dart';
import '../utils/currency_formatter.dart';
import '../../data/infrastructure/services/settings_service.dart';

class AddBudgetScreen extends StatefulWidget {
  final String? monthId;

  const AddBudgetScreen({
    Key? key,
    this.monthId,
  }) : super(key: key);

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Use ValueNotifier instead of direct setState calls
  final ValueNotifier<double?> _totalBudgetNotifier =
      ValueNotifier<double?>(null);
  final ValueNotifier<double> _totalAllocatedNotifier =
      ValueNotifier<double>(0);
  final ValueNotifier<double> _savingsNotifier = ValueNotifier<double>(0);

  // Add a controller for the total budget field
  final TextEditingController _totalBudgetController = TextEditingController();

  // Map to track percentage allocations for each category
  final Map<String, double> _categoryPercentages = {};
  // Map to track if sliders are being dragged (to avoid text/slider update loops)
  final Map<String, bool> _isDraggingSlider = {};

  // Date related properties
  DateTime _selectedDate = DateTime.now();
  String _currentMonthId = '';

  // Currency from settings (default value)
  String _currency = 'MYR';

  // 使用类别ID作为键的控制器映射
  final Map<String, TextEditingController> _categoryControllers = {};

  // 获取预算使用的类别ID列表
  List<String> get _budgetCategoryIds => CategoryManager.getBudgetCategoryIds();

  @override
  void dispose() {
    // Dispose all controllers
    for (var c in _categoryControllers.values) {
      c.dispose();
    }
    _categoryControllers.clear();
    _categoryPercentages.clear();
    _isDraggingSlider.clear();

    // Dispose all notifiers
    _totalBudgetNotifier.dispose();
    _totalAllocatedNotifier.dispose();
    _savingsNotifier.dispose();

    // Dispose the total budget controller
    _totalBudgetController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentMonthId = widget.monthId ?? _getMonthIdFromDate(_selectedDate);

    // Parse the month ID to get the date if provided
    if (widget.monthId != null) {
      try {
        final parts = widget.monthId!.split('-');
        if (parts.length == 2) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          _selectedDate = DateTime(year, month);
        }
      } catch (e) {
        // If parsing fails, use current date
        _selectedDate = DateTime.now();
      }
    }

    // Get currency from settings service
    final settingsService = SettingsService.instance;
    if (settingsService != null) {
      _currency = settingsService.currency;
      debugPrint('Using currency from settings: $_currency');
    }

    _setupListeners();

    // Setup controller listener to update the notifier (one-way only)
    _totalBudgetController.addListener(() {
      final value = _totalBudgetController.text.isEmpty
          ? null
          : double.tryParse(_totalBudgetController.text);

      // Only update if the value actually changed to avoid infinite loops
      if (_totalBudgetNotifier.value != value) {
        _totalBudgetNotifier.value = value;
      }
    });

    // Add listener for total budget changes (but don't update controller here)
    _totalBudgetNotifier.addListener(() {
      _onTotalBudgetChanged(_totalBudgetNotifier.value);
    });

    // Use post-frame callback to load budget data after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.monthId != null) {
          _loadBudgetData(_currentMonthId);
        }
      }
    });
  }

  String _getMonthIdFromDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  void _setupListeners() {
    // Listen for total budget changes, calculate savings
    _totalAllocatedNotifier.addListener(_calculateSavings);
    // Don't add _totalBudgetNotifier listener here since we add it in initState

    // Create controllers for each category
    for (final catId in _budgetCategoryIds) {
      if (!_categoryControllers.containsKey(catId)) {
        final controller = TextEditingController();
        _categoryControllers[catId] = controller;

        // Initialize category percentages to 0
        _categoryPercentages[catId] = 0.0;
        _isDraggingSlider[catId] = false;

        // Use a debounced listener to avoid excessive calculations
        controller.addListener(() {
          // Only update percentages if not currently dragging slider
          if (!(_isDraggingSlider[catId] ?? false)) {
            // Debounce rapid text changes
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _updatePercentageFromAmount(catId);
                _calculateTotalAllocated();
              }
            });
          }
        });
      }
    }
  }

  void _calculateSavings() {
    final totalBudget = _totalBudgetNotifier.value ?? 0;
    final totalAllocated = _totalAllocatedNotifier.value;
    final savings = totalBudget - totalAllocated;

    final newSavings = savings > 0 ? savings : 0.0;

    // Only update if the value actually changed
    if (_savingsNotifier.value != newSavings) {
      _savingsNotifier.value = newSavings;
    }
  }

  void _loadBudgetData(String monthId) async {
    if (!mounted) return;

    final budgetVM = Provider.of<BudgetViewModel>(context, listen: false);

    // 直接从数据库加载预算数据
    // 预算的剩余金额已经在添加/更新/删除支出时自动更新到数据库
    await budgetVM.loadBudget(monthId, checkCurrency: true);

    if (!mounted) return;

    final budget = budgetVM.budget;
    debugPrint('📊 Loading budget data for monthId: $monthId');
    debugPrint('📊 Budget exists: ${budget != null}');

    if (budget != null) {
      debugPrint(
          '📊 Budget total: ${budget.total}, currency: ${budget.currency}');

      // Update currency from the loaded budget if it exists
      if (_currency != budget.currency) {
        setState(() {
          _currency = budget.currency;
        });
      }

      // Use a local variable first to avoid multiple notifier updates
      final newTotalBudget = budget.total;

      // Update controller and notifier with the budget total value
      if (_totalBudgetController.text != newTotalBudget.toString()) {
        _totalBudgetController.text = newTotalBudget.toString();
        debugPrint(
            '📊 Updated total budget controller to: ${_totalBudgetController.text}');
      }

      // The controller listener will automatically update the notifier
      // No need to manually update _totalBudgetNotifier here

      // Update category controllers without triggering listeners
      for (final catId in _budgetCategoryIds) {
        if (_categoryControllers.containsKey(catId)) {
          final controller = _categoryControllers[catId]!;
          final budgetValue =
              budget.categories[catId]?.budget.toString() ?? '0.0';

          // Only update if different to avoid unnecessary rebuilds
          if (controller.text != budgetValue) {
            controller.text = budgetValue;
          }

          // Update category percentages
          if (newTotalBudget > 0) {
            final categoryBudget = budget.categories[catId]?.budget ?? 0;
            _categoryPercentages[catId] =
                (categoryBudget / newTotalBudget * 100).clamp(0.0, 100.0);
          } else {
            _categoryPercentages[catId] = 0.0;
          }
        }
      }
    } else {
      debugPrint('📊 No budget found for monthId: $monthId');

      // If no budget exists, get currency from settings
      final settingsService = SettingsService.instance;
      if (settingsService != null && _currency != settingsService.currency) {
        setState(() {
          _currency = settingsService.currency;
        });
      }

      // Clear the controller - the listener will handle updating the notifier
      if (_totalBudgetController.text.isNotEmpty) {
        _totalBudgetController.text = '';
        debugPrint('📊 Cleared total budget controller');
      }

      // Clear category controllers
      for (final catId in _budgetCategoryIds) {
        if (_categoryControllers.containsKey(catId)) {
          _categoryControllers[catId]!.text = '';
          _categoryPercentages[catId] = 0.0;
        }
      }
    }

    // Calculate allocated budget after all controllers are updated
    _calculateTotalAllocated();
  }

  void _calculateTotalAllocated() {
    double total = 0;
    for (final catId in _budgetCategoryIds) {
      final controller = _categoryControllers[catId];
      if (controller != null) {
        final text = controller.text.trim();
        if (text.isNotEmpty) {
          final val = double.tryParse(text);
          if (val != null) {
            total += val;
          }
        }
        // If text is empty, we treat it as 0.0
      }
    }

    // Only update if the value actually changed
    if (_totalAllocatedNotifier.value != total) {
      _totalAllocatedNotifier.value = total;
    }
  }

  void _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isSubmitting = true;
      });

      final totalBudget = _totalBudgetNotifier.value;
      if (totalBudget == null) {
        throw Exception('Please enter a total budget amount');
      }

      final Map<String, CategoryBudget> cats = {};

      for (final catId in _budgetCategoryIds) {
        final controller = _categoryControllers[catId];
        if (controller != null) {
          final text = controller.text.trim();
          // Accept empty text as 0.0 or any valid number including zero
          final val = text.isNotEmpty ? (double.tryParse(text) ?? 0.0) : 0.0;
          // Initially set budget left = budget
          cats[catId] = CategoryBudget(budget: val, left: val);
        }
      }

      if (!mounted) return;
      final budgetVM = Provider.of<BudgetViewModel>(context, listen: false);
      final expensesVM = Provider.of<ExpensesViewModel>(context, listen: false);

      // Get the user's current currency setting
      final settingsService = SettingsService.instance;
      if (settingsService != null && _currency != settingsService.currency) {
        setState(() {
          _currency = settingsService.currency;
        });
      }

      // Get year and month from month ID and calculate remaining budget
      try {
        final parts = _currentMonthId.split('-');
        if (parts.length == 2) {
          final year = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);

          if (year != null && month != null) {
            // Create new budget object with current currency
            final newBudget = Budget(
              total: totalBudget,
              left: totalBudget,
              categories: cats,
              currency: _currency, // Use the current currency from settings
            );

            // Get expenses for current month
            final expenses = expensesVM.getExpensesForMonth(year, month);

            // First save the new budget
            await budgetVM.saveBudget(_currentMonthId, newBudget);

            // Then calculate the budget with expenses factored in
            await budgetVM.calculateBudgetRemaining(expenses, _currentMonthId);
            debugPrint(
                'Budget saved with expenses factored in, currency: $_currency');
          }
        }
      } catch (e) {
        debugPrint('Error calculating budget during save: $e');
        rethrow; // Re-throw to show error message
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.budgetSavedMessage),
          backgroundColor: AppTheme.primaryColor,
          duration: Duration(seconds: 2),
        ),
      );

      // Use Future.delayed to ensure budget update before returning to previous page
      // This ensures user sees latest data when returning to analytics page
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  // Update percentage based on the amount entered in text field
  void _updatePercentageFromAmount(String categoryId) {
    final totalBudget = _totalBudgetNotifier.value ?? 0;
    if (totalBudget <= 0) return;

    final controller = _categoryControllers[categoryId];
    if (controller != null) {
      final text = controller.text.trim();
      final amount = text.isNotEmpty ? (double.tryParse(text) ?? 0.0) : 0.0;

      // Calculate percentage (0-100)
      final percentage = (amount / totalBudget * 100).clamp(0.0, 100.0);

      setState(() {
        _categoryPercentages[categoryId] = percentage;
      });
    }
  }

  // Update amount based on slider percentage
  void _updateAmountFromPercentage(String categoryId, double percentage) {
    final totalBudget = _totalBudgetNotifier.value ?? 0;
    if (totalBudget <= 0) return;

    // Calculate amount based on percentage of total budget
    final amount = (percentage / 100 * totalBudget).toStringAsFixed(2);

    final controller = _categoryControllers[categoryId];
    if (controller != null && controller.text != amount) {
      // Mark that we're updating from slider to avoid loops
      _isDraggingSlider[categoryId] = true;

      controller.text = amount;

      // Reset dragging flag after text update
      Future.delayed(const Duration(milliseconds: 50), () {
        _isDraggingSlider[categoryId] = false;
      });
    }
  }

  // Calculate total allocated percentage
  double _getTotalAllocatedPercentage() {
    return _categoryPercentages.values.fold(0.0, (sum, value) => sum + value);
  }

  // Add total budget changed handler
  void _onTotalBudgetChanged(double? newTotal) {
    // Update all category amounts based on their percentages when total budget changes
    if (newTotal != null && newTotal > 0) {
      // Update all category amounts based on their percentages
      for (final catId in _budgetCategoryIds) {
        final percentage = _categoryPercentages[catId] ?? 0.0;
        if (percentage > 0) {
          // Only update if percentage is set
          _updateAmountFromPercentage(catId, percentage);
        }
      }
    }

    // Recalculate total allocated
    _calculateTotalAllocated();
  }

  @override
  Widget build(BuildContext context) {
    // Check for currency updates from settings service instead of just budget view model
    final settingsService = SettingsService.instance;
    final budgetVM = Provider.of<BudgetViewModel>(context);

    // Priority order:
    // 1. Existing budget currency (if it exists)
    // 2. User's setting currency
    if (budgetVM.budget != null && _currency != budgetVM.budget!.currency) {
      setState(() {
        _currency = budgetVM.budget!.currency;
      });
    } else if (settingsService != null &&
        _currency != settingsService.currency) {
      setState(() {
        _currency = settingsService.currency;
      });
    }

    final currencySymbol = CurrencyFormatter.getCurrencySymbol(_currency);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppConstants.setBudgetTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // //Date picker button for selecting budget month
            // DatePickerButton(
            //   prefix: 'Budget for',
            //   date: _selectedDate,
            //   onDateChanged: _onDateChanged,
            //   themeColor: AppTheme.primaryColor,
            // ),
            // const SizedBox(height: 16),
            // Total budget card
            CustomCard.withTitle(
              title: 'Total Budget',
              icon: Icons.account_balance_wallet,
              iconColor: AppTheme.primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<double?>(
                    valueListenable: _totalBudgetNotifier,
                    builder: (context, totalBudget, _) {
                      return CustomTextField.currency(
                        controller: _totalBudgetController,
                        labelText: 'Total Budget',
                        currencySymbol: currencySymbol,
                        isRequired: true,
                        allowZero: true,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // 预算分配进度
                  ValueListenableBuilder<double?>(
                    valueListenable: _totalBudgetNotifier,
                    builder: (context, totalBudget, _) {
                      return ValueListenableBuilder<double>(
                        valueListenable: _totalAllocatedNotifier,
                        builder: (context, totalAllocated, _) {
                          final total = totalBudget ?? 0;
                          final percentage = total > 0
                              ? (totalAllocated / total * 100).clamp(0, 100)
                              : 0.0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Allocated: $currencySymbol${totalAllocated.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: total > 0 ? totalAllocated / total : 0,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  percentage > 100
                                      ? AppTheme.errorColor
                                      : AppTheme.primaryColor,
                                ),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),

                              // Show total percentage allocated
                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Allocation:',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                    ),
                                  ),
                                  Builder(builder: (context) {
                                    final totalPercentage =
                                        _getTotalAllocatedPercentage();
                                    final Color textColor =
                                        totalPercentage > 100
                                            ? Colors.red
                                            : totalPercentage == 100
                                                ? Colors.green
                                                : Colors.orange;

                                    return Text(
                                      '${totalPercentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Builder(builder: (context) {
                                final totalPercentage =
                                    _getTotalAllocatedPercentage();
                                final Color progressColor =
                                    totalPercentage > 100
                                        ? Colors.red
                                        : totalPercentage == 100
                                            ? Colors.green
                                            : Colors.orange;

                                return LinearProgressIndicator(
                                  value: totalPercentage / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      progressColor),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                );
                              }),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // savings card
            ValueListenableBuilder<double>(
              valueListenable: _savingsNotifier,
              builder: (context, savings, _) {
                return CustomCard.withTitle(
                  title: 'Savings',
                  icon: Icons.savings,
                  iconColor: AppTheme.primaryColor,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          '$currencySymbol${savings.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: savings > 0
                                ? AppTheme.successColor
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          savings > 0
                              ? 'Available for savings'
                              : 'No savings available',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            color: savings > 0
                                ? AppTheme.successColor
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // category budgets card
            CustomCard.withTitle(
              title: 'Category Budgets',
              icon: Icons.category,
              iconColor: AppTheme.primaryColor,
              child: Column(
                children: _budgetCategoryIds.map((catId) {
                  final category = CategoryManager.getCategoryFromId(catId);
                  final categoryIcon = category != null
                      ? CategoryManager.getIcon(category)
                      : CategoryManager.getIconFromId(catId);
                  final categoryColor = category != null
                      ? CategoryManager.getColor(category)
                      : CategoryManager.getColorFromId(catId);
                  final categoryName = category != null
                      ? CategoryManager.getName(category)
                      : CategoryManager.getNameFromId(catId);

                  // 获取该类别的剩余预算（如果有）
                  final categoryBudget = Provider.of<BudgetViewModel>(context)
                      .budget
                      ?.categories[catId];
                  final hasExistingBudget = categoryBudget != null;
                  final remainingBudget =
                      hasExistingBudget ? categoryBudget.left : 0.0;
                  final budgetPercentage =
                      hasExistingBudget && categoryBudget.budget > 0
                          ? (remainingBudget / categoryBudget.budget)
                              .clamp(0.0, 1.0)
                          : 0.0;

                  // status color based on remaining budget
                  final statusColor = remainingBudget <= 0
                      ? Colors.red
                      : budgetPercentage < 0.3
                          ? Colors.orange
                          : Colors.green.shade700;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: categoryColor
                                    .withAlpha((255 * 0.1).toInt()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                categoryIcon,
                                color: categoryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField.currency(
                                controller: _categoryControllers[catId],
                                labelText: categoryName,
                                currencySymbol: currencySymbol,
                                // Allow zero values explicitly
                                allowZero: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Add percentage slider for budget allocation
                      Padding(
                        padding: const EdgeInsets.only(left: 52.0, bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Show percentage label
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Allocation:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                ValueListenableBuilder<double?>(
                                  valueListenable: _totalBudgetNotifier,
                                  builder: (context, totalBudget, _) {
                                    // Only show percentages if total budget is set
                                    if (totalBudget == null ||
                                        totalBudget <= 0) {
                                      return const Text(
                                        'Set total budget first',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                      );
                                    }

                                    return Text(
                                      '${_categoryPercentages[catId]?.toStringAsFixed(1) ?? '0.0'}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: categoryColor,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            // Add slider
                            ValueListenableBuilder<double?>(
                              valueListenable: _totalBudgetNotifier,
                              builder: (context, totalBudget, _) {
                                // Disable slider if total budget is not set
                                final isEnabled =
                                    totalBudget != null && totalBudget > 0;

                                return Opacity(
                                  opacity: isEnabled ? 1.0 : 0.5,
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4.0,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6.0,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                        overlayRadius: 14.0,
                                      ),
                                      activeTrackColor: categoryColor,
                                      inactiveTrackColor: Colors.grey.shade200,
                                      thumbColor: categoryColor,
                                      overlayColor: categoryColor
                                          .withAlpha((255 * 0.3).toInt()),
                                    ),
                                    child: Slider(
                                      value: _categoryPercentages[catId] ?? 0.0,
                                      min: 0.0,
                                      max: 100.0,
                                      divisions: 100,
                                      onChanged: isEnabled
                                          ? (newValue) {
                                              // Calculate total percentage excluding this category
                                              final otherCategoriesTotal =
                                                  _getTotalAllocatedPercentage() -
                                                      (_categoryPercentages[
                                                              catId] ??
                                                          0.0);

                                              // Limit slider to remaining percentage
                                              final maxAllowed =
                                                  (100.0 - otherCategoriesTotal)
                                                      .clamp(0.0, 100.0);
                                              final clampedValue = newValue
                                                  .clamp(0.0, maxAllowed);

                                              setState(() {
                                                _categoryPercentages[catId] =
                                                    clampedValue;
                                              });

                                              // Update amount in text field based on percentage
                                              _updateAmountFromPercentage(
                                                  catId, clampedValue);

                                              // Calculate total allocated
                                              _calculateTotalAllocated();
                                            }
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // 类别预算剩余信息
                      if (hasExistingBudget) ...[
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 52.0, bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Remaining:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '$currencySymbol${remainingBudget.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Stack(
                                children: [
                                  Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: budgetPercentage,
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.05).toInt()),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SubmitButton(
          text: '${AppConstants.saveButtonText} ${AppConstants.setBudgetTitle}',
          loadingText: AppConstants.savingText,
          isLoading: _isSubmitting,
          onPressed: _saveBudget,
          icon: Icons.save,
        ),
      ),
    );
  }
}
