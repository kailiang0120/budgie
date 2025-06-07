// Add budget screen no longer needed
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

// Budget ViewModel no longer needed
import '../viewmodels/expenses_viewmodel.dart';
import '../widgets/bottom_nav_bar.dart';
// Budget card no longer needed
import '../widgets/date_picker_button.dart';
import '../widgets/animated_float_button.dart';
import '../utils/category_manager.dart';
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

      debugPrint(
          'Initializing filters with date: ${_selectedDate.year}-${_selectedDate.month}');
      debugPrint('Set current month ID to: $_currentMonthId');

      // Apply the filter explicitly
      expensesViewModel.setSelectedMonth(_selectedDate,
          persist: true, screenKey: 'analytics');

      // Force filter application to ensure data is filtered properly
      expensesViewModel.forceFilterByMonth(_selectedDate);

      setState(() {
        _isInitialized = true;
      });

      // Load data with the selected month
      _loadData();
    } catch (e) {
      debugPrint('Error retrieving analytic screen filter: $e');
      _selectedDate = DateTime.now();
      _currentMonthId = formatMonthId(_selectedDate);
      debugPrint('Fallback to current date: $_currentMonthId');
      _loadData();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app is resumed, refresh the data
    if (state == AppLifecycleState.resumed && mounted) {
      _loadData();
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

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get view models
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

      debugPrint(
          'Loading data for month ID: $_currentMonthId (${_selectedDate.year}-${_selectedDate.month})');

      // Set selected month for expenses, ensure we persist the filter
      expensesViewModel.setSelectedMonth(_selectedDate,
          persist: true, screenKey: 'analytics');

      // Explicitly force filtering by selected month
      expensesViewModel.forceFilterByMonth(_selectedDate);

      // Refresh expenses data
      await expensesViewModel.refreshData();

      // Verify filtering was applied correctly
      final filteredExpenses = expensesViewModel.filteredExpenses;
      debugPrint(
          'After filtering: ${filteredExpenses.length} expenses for month $_currentMonthId');

      // Force data refresh for dashboard cards
      setState(() {
        // Trigger rebuild with fresh data
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
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
    debugPrint(
        'Date changed from ${_selectedDate.year}-${_selectedDate.month} to ${newDate.year}-${newDate.month}');

    setState(() {
      _selectedDate = newDate;
      _currentMonthId = formatMonthId(_selectedDate);
      _errorMessage = null;
      // Clear prediction data when date changes
      _predictionResponse = null;
    });

    debugPrint('Updated current month ID to: $_currentMonthId');

    // Save to screen-specific filter and force reload
    final expensesViewModel =
        Provider.of<ExpensesViewModel>(context, listen: false);

    // Make sure we're setting the filter AND applying it immediately
    expensesViewModel.setSelectedMonth(_selectedDate,
        persist: true, screenKey: 'analytics');

    // Explicitly force filtering - important step to ensure data is filtered correctly
    expensesViewModel.forceFilterByMonth(_selectedDate);

    debugPrint('Forced filtering by month: $_currentMonthId');

    // Load data with the new date filter
    _loadData();

    // Force UI refresh for dashboard cards
    setState(() {
      // Trigger rebuild with fresh data
    });

    // Log filtered expenses count
    final filteredCount = expensesViewModel.filteredExpenses.length;
    debugPrint('Filtered expenses count after date change: $filteredCount');
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
            isAuthError ? Icons.analytics_rounded : Icons.error_outline,
            color: Colors.red[300],
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            isAuthError
                ? 'Login to analyze your spending habits'
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
              onPressed: _loadData,
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

                    // Make sure we're using the current selected month
                    expensesViewModel.forceFilterByMonth(_selectedDate);

                    // Refresh data
                    await _loadData();

                    // Refresh expense data
                    await expensesViewModel.refreshData();

                    // Rebuild dashboard cards with new data
                    if (mounted) {
                      setState(() {});
                    }
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
                            prefix: 'Filter by',
                            onDateChanged: _onDateChanged,
                            showDaySelection: false,
                          ),
                        ),
                      ),

                      // Category Distribution Pie Chart
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 16.0),
                        sliver: SliverToBoxAdapter(
                          child: _buildCategoryDistributionCard(context),
                        ),
                      ),

                      // Spending Trends Visualization
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        sliver: SliverToBoxAdapter(
                          child: _buildSpendingTrendsCard(context),
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

                      // Budget card has been removed from the analytics screen

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

  // Build category distribution card with pie chart
  Widget _buildCategoryDistributionCard(BuildContext context) {
    final expensesViewModel = Provider.of<ExpensesViewModel>(context);

    // Ensure we're getting data for the selected month
    expensesViewModel.forceFilterByMonth(_selectedDate);
    final categoryTotals = expensesViewModel.getCategoryTotals();

    // If there's no data, show a placeholder
    if (categoryTotals.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.pie_chart,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Category Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  // Show the filter date
                  Text(
                    '${_selectedDate.year}-${_selectedDate.month}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No expense data for this period',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try selecting a different month or adding expenses',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    // Calculate total amount with currency conversion already applied
    // The getCategoryTotals() method now returns values in the user's preferred currency
    final totalAmount =
        categoryTotals.values.fold<double>(0, (sum, value) => sum + value);

    debugPrint(
        'Total amount for pie chart: $totalAmount in ${expensesViewModel.currentCurrency}');
    debugPrint('Categories: ${categoryTotals.keys.join(", ")}');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Category Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                // Show the filter date
                Text(
                  '${_selectedDate.year}-${_selectedDate.month}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pie chart with fixed height and proper container
            Container(
              height: 250,
              alignment: Alignment.center,
              child: _buildCustomPieChart(categoryTotals),
            ),

            const SizedBox(height: 24),

            // Total amount - now using currency-converted values
            Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Total: ',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text:
                          '${expensesViewModel.currentCurrency} ${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Category legend with better wrapping
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: categoryTotals.entries.map((entry) {
                  final categoryId = entry.key;
                  final percentage =
                      (entry.value / totalAmount * 100).toStringAsFixed(1);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: CategoryManager.getColorFromId(categoryId),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${CategoryManager.getNameFromId(categoryId)} ($percentage%)',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build spending trends visualization
  Widget _buildSpendingTrendsCard(BuildContext context) {
    final expensesViewModel = Provider.of<ExpensesViewModel>(context);

    // Ensure we're getting data for the selected month
    expensesViewModel.forceFilterByMonth(_selectedDate);
    final hasExpenses = expensesViewModel.filteredExpenses.isNotEmpty;

    // If there's no data, show a placeholder
    if (!hasExpenses) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Spending Trends',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  // Show the filter date
                  Text(
                    '${_selectedDate.year}-${_selectedDate.month}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No trend data available',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add more expenses to see spending patterns',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Spending Trends',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                // Show the filter date
                Text(
                  '${_selectedDate.year}-${_selectedDate.month}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top Categories Spending Bar Chart
            _buildTopCategoriesChart(expensesViewModel),

            const SizedBox(height: 16),

            // Daily Spending Pattern
            _buildDailySpendingPattern(context, expensesViewModel),
          ],
        ),
      ),
    );
  }

  // Build top categories chart
  Widget _buildTopCategoriesChart(ExpensesViewModel viewModel) {
    // Ensure we're getting data for the selected month
    viewModel.forceFilterByMonth(_selectedDate);
    final categoryTotals = viewModel.getCategoryTotals();

    if (categoryTotals.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category_outlined, size: 28, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No category data for this period',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Sort categories by amount
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5 categories
    final topCategories = sortedCategories.take(5).toList();

    // Get the highest amount for scaling
    final highestAmount = topCategories.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...topCategories.map((entry) {
          final percentage = entry.value / highestAmount;
          final category = entry.key;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CategoryManager.getIcon(category),
                      size: 16,
                      color: CategoryManager.getColor(category),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CategoryManager.getName(category),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      '${viewModel.currentCurrency} ${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Bar chart
                Stack(
                  children: [
                    // Background bar
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Filled bar
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: CategoryManager.getColor(category),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // Build daily spending pattern visualization
  Widget _buildDailySpendingPattern(
      BuildContext context, ExpensesViewModel viewModel) {
    // Ensure we're getting data for the selected month
    viewModel.forceFilterByMonth(_selectedDate);
    final expenses = viewModel.filteredExpenses;

    if (expenses.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.date_range_outlined,
                  size: 28, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No daily spending data for ${_selectedDate.year}-${_selectedDate.month}',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              Text(
                'Add expenses to see daily patterns',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Group expenses by day
    final Map<int, double> dailyTotals = {};

    // Get all days in the selected month
    final daysInMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;

    // Initialize all days with zero
    for (int day = 1; day <= daysInMonth; day++) {
      dailyTotals[day] = 0;
    }

    // Sum expenses by day
    for (final expense in expenses) {
      final day = expense.date.day;
      dailyTotals[day] = (dailyTotals[day] ?? 0) + expense.amount;
    }

    // Find the highest daily total for scaling
    final highestDaily = dailyTotals.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Spending Pattern',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: Row(
            children: List.generate(daysInMonth, (index) {
              final day = index + 1;
              final amount = dailyTotals[day] ?? 0;
              final percentage = highestDaily > 0 ? amount / highestDaily : 0;

              // Determine if this is today
              final isToday = DateTime.now().day == day &&
                  DateTime.now().month == _selectedDate.month &&
                  DateTime.now().year == _selectedDate.year;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Bar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: (100 * percentage).toDouble(),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isToday
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha((255 * 0.7).toInt()),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Day number
                      Text(
                        day.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // Custom pie chart builder that works with string category IDs
  Widget _buildCustomPieChart(Map<String, double> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No data available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Calculate total for percentages
    final total = data.values.fold<double>(0, (sum, value) => sum + value);

    return PieChart(
      PieChartData(
        sections: data.entries.map((entry) {
          final categoryId = entry.key;
          final value = entry.value;
          final percent = total > 0 ? (value / total * 100) : 0;

          return PieChartSectionData(
            value: value,
            title: '${percent.toStringAsFixed(0)}%',
            color: CategoryManager.getColorFromId(categoryId),
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        startDegreeOffset: 180,
      ),
    );
  }
}
