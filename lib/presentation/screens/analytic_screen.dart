import 'package:budgie/presentation/screens/add_budget_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/budget_card.dart';
import '../widgets/date_picker_button.dart';
import '../widgets/animated_float_button.dart';
import 'add_expense_screen.dart';

import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/financial_prediction_api_service.dart';

String formatMonthId(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

class AnalyticScreen extends StatefulWidget {
  const AnalyticScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticScreen> createState() => _AnalyticScreenState();
}

class _AnalyticScreenState extends State<AnalyticScreen>
    with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();
  String _currentMonthId = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // Financial prediction related state
  bool _isPredictionLoading = false;
  LLMPredictionApiResponse? _predictionResponse;

  // Financial prediction service
  final _financialPredictionService = FinancialPredictionApiService();

  // To track currency changes
  String? _currentCurrency;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize with default values
    _selectedDate = DateTime.now();
    _currentMonthId = formatMonthId(_selectedDate);

    // Get initial currency from settings
    final settingsService = SettingsService.instance;
    if (settingsService != null) {
      _currentCurrency = settingsService.currency;
    }

    // Delay initialization to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeFilters();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeFilters();
    }
  }

  void _initializeFilters() {
    try {
      final expensesViewModel =
          Provider.of<ExpensesViewModel>(context, listen: false);

      // Get the screen-specific filter
      _selectedDate = expensesViewModel.getScreenFilterDate('analytics');
      _currentMonthId = formatMonthId(_selectedDate);

      // Apply the filter
      expensesViewModel.setSelectedMonth(_selectedDate,
          persist: true, screenKey: 'analytics');

      setState(() {
        _isInitialized = true;
      });

      // Load the budget data with the selected month
      _loadBudgetData();
    } catch (e) {
      debugPrint('Error retrieving analytic screen filter: $e');
      _selectedDate = DateTime.now();
      _currentMonthId = formatMonthId(_selectedDate);
      _loadBudgetData();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app is resumed, refresh the data
    if (state == AppLifecycleState.resumed && mounted) {
      _loadBudgetData();
      Provider.of<ExpensesViewModel>(context, listen: false).refreshData();
    }
  }

  @override
  void dispose() {
    // Dispose prediction service resources
    _financialPredictionService.dispose();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadBudgetData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get view models
      final budgetViewModel =
          Provider.of<BudgetViewModel>(context, listen: false);
      final expensesViewModel =
          Provider.of<ExpensesViewModel>(context, listen: false);

      // Get user's currency setting
      final settingsService = SettingsService.instance;
      final userCurrency = settingsService?.currency ?? 'MYR';

      // Update current currency if needed
      if (_currentCurrency != userCurrency) {
        _currentCurrency = userCurrency;
        debugPrint('Updating to user currency: $_currentCurrency');
      }

      // Set selected month for expenses, ensure we persist the filter
      expensesViewModel.setSelectedMonth(_selectedDate,
          persist: true, screenKey: 'analytics');

      // Explicitly update budget for this month to ensure it's current
      await expensesViewModel.updateBudgetForMonth(
          _selectedDate.year, _selectedDate.month);

      // Load budget data from database (now updated)
      // Pass checkCurrency=true to automatically check if currency conversion is needed
      await budgetViewModel.loadBudget(_currentMonthId, checkCurrency: true);

      // Make sure budget is using the right currency
      if (budgetViewModel.budget != null &&
          budgetViewModel.budget!.currency != _currentCurrency) {
        debugPrint(
            'Budget currency (${budgetViewModel.budget!.currency}) needs conversion to $_currentCurrency');
        await budgetViewModel.checkAndConvertBudgetCurrency(
            _currentMonthId, _currentCurrency!);
      }

      // Check for errors
      if (budgetViewModel.errorMessage != null) {
        setState(() {
          _errorMessage = budgetViewModel.errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load budgets: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performExpensePrediction() async {
    setState(() {
      _isPredictionLoading = true;
      _predictionResponse = null;
    });

    try {
      // Step 1: Check API server health
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checking API server health...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final isHealthy = await _financialPredictionService.checkHealth();

      if (!isHealthy) {
        throw Exception(
            'API server is not available. Please ensure the backend server is running at http://10.0.2.2:8000');
      }

      // Step 2: Show success for health check
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('API server is healthy. Getting expense prediction...'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Step 3: Build request data and call prediction API
      final response =
          await _financialPredictionService.getPredictionForCurrentUser();

      // Step 4: Update UI with successful response
      if (mounted) {
        setState(() {
          _predictionResponse = response;
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense prediction completed successfully!'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _predictionResponse = null;
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prediction failed: ${e.toString()}'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _performExpensePrediction,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPredictionLoading = false;
        });
      }
    }
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _currentMonthId = formatMonthId(_selectedDate);
      _errorMessage = null;
      // Clear prediction data when date changes
      _predictionResponse = null;
    });

    // Save to screen-specific filter
    final expensesViewModel =
        Provider.of<ExpensesViewModel>(context, listen: false);
    expensesViewModel.setSelectedMonth(_selectedDate,
        persist: true, screenKey: 'analytics');

    _loadBudgetData();
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, Routes.login);
  }

  Widget _buildErrorWidget() {
    final bool isAuthError =
        _errorMessage?.contains('not authenticated') ?? false;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAuthError ? Icons.login : Icons.error_outline,
            color: Colors.red[300],
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            isAuthError
                ? 'Login to view your Budgets'
                : _errorMessage ?? 'Error occurred',
            style: TextStyle(color: Colors.red[300]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (isAuthError)
            ElevatedButton(
              onPressed: _navigateToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF57C00),
              ),
              child: const Text('Login'),
            ),
          if (!isAuthError)
            ElevatedButton(
              onPressed: _loadBudgetData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF57C00),
              ),
              child: const Text('Retry again'),
            ),
        ],
      ),
    );
  }

  Widget _buildPredictionResultsCard() {
    if (_predictionResponse == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Expense Prediction',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Prediction for: ${_predictionResponse!.predictionForDate}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Predicted expenses
            if (_predictionResponse!.predictedNextDayExpenses.isNotEmpty) ...[
              Text(
                'Predicted Tomorrow Expenses:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              ..._predictionResponse!.predictedNextDayExpenses
                  .map(
                    (expense) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha((255 * 0.1).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                expense.category.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${expense.currency} ${expense.estimatedAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (expense.predictedRemark.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              expense.predictedRemark,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: expense.likelihood == 'high'
                                      ? Colors.red
                                          .withAlpha((255 * 0.2).toInt())
                                      : expense.likelihood == 'medium'
                                          ? Colors.orange
                                              .withAlpha((255 * 0.2).toInt())
                                          : Colors.green
                                              .withAlpha((255 * 0.2).toInt()),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${expense.likelihood.toUpperCase()} likelihood',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: expense.likelihood == 'high'
                                        ? Colors.red.shade700
                                        : expense.likelihood == 'medium'
                                            ? Colors.orange.shade700
                                            : Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (expense.reasoning.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              expense.reasoning,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                  .toList(),
              const SizedBox(height: 16),
            ],

            // Budget advice
            if (_predictionResponse!
                .budgetReallocationAdvice.analysisSummary.isNotEmpty) ...[
              Text(
                'Budget Analysis:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _predictionResponse!.budgetReallocationAdvice.analysisSummary,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Overspending alerts
            if (_predictionResponse!.budgetReallocationAdvice
                .overspendingAlertsForNextDay.isNotEmpty) ...[
              Text(
                'Overspending Alerts:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ..._predictionResponse!
                  .budgetReallocationAdvice.overspendingAlertsForNextDay
                  .map(
                    (alert) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha((255 * 0.1).toInt()),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.red.withAlpha((255 * 0.3).toInt())),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.category.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.alertMessage,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              const SizedBox(height: 12),
            ],

            // Confidence note
            if (_predictionResponse!.overallConfidenceNote.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _predictionResponse!.overallConfidenceNote,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytic'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : _errorMessage != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  onRefresh: () async {
                    // Capture ViewModel references before async operations
                    final expensesViewModel =
                        Provider.of<ExpensesViewModel>(context, listen: false);

                    // Refresh budget data
                    await _loadBudgetData();
                    // Refresh expense data
                    await expensesViewModel.refreshData();
                  },
                  child: CustomScrollView(
                    slivers: [
                      // 顶部间距
                      const SliverPadding(
                        padding: EdgeInsets.only(top: 16.0),
                        sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                      ),

                      // Prediction Results Card
                      SliverToBoxAdapter(
                        child: _buildPredictionResultsCard(),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverToBoxAdapter(
                          child: DatePickerButton(
                            date: _selectedDate,
                            themeColor: Theme.of(context).colorScheme.primary,
                            prefix: 'Budget for',
                            onDateChanged: _onDateChanged,
                            showDaySelection: false,
                          ),
                        ),
                      ),

                      // Financial Prediction Button
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 16.0),
                        sliver: SliverToBoxAdapter(
                          child: ElevatedButton.icon(
                            onPressed: _isPredictionLoading
                                ? null
                                : _performExpensePrediction,
                            icon: _isPredictionLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.psychology),
                            label: Text(
                              _isPredictionLoading
                                  ? 'Getting AI Prediction...'
                                  : 'Get AI Expense Prediction',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        sliver: SliverToBoxAdapter(
                          child: Consumer<BudgetViewModel>(
                            builder: (context, vm, _) {
                              return BudgetCard(
                                budget: vm.budget,
                                onTap: () async {
                                  if (!mounted) return;
                                  Navigator.push(
                                    context,
                                    PageTransition(
                                      child: AddBudgetScreen(
                                        monthId: _currentMonthId,
                                      ),
                                      type: TransitionType.slideRight,
                                    ),
                                  ).then((_) {
                                    _loadBudgetData();
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),

                      const SliverPadding(
                        padding: EdgeInsets.only(bottom: 80.0),
                        sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                      ),
                    ],
                  ),
                ),
      extendBody: true,
      floatingActionButton: AnimatedFloatButton(
        onPressed: () {
          Navigator.push(
            context,
            PageTransition(
              child: const AddExpenseScreen(),
              type: TransitionType.fadeAndSlideUp,
              settings: const RouteSettings(name: Routes.expenses),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        enableFeedback: true,
        reactToRouteChange: true,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (idx) {
          // Navigation is handled in BottomNavBar
        },
      ),
    );
  }
}
