// Add budget screen no longer needed
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

// Budget ViewModel no longer needed
import '../viewmodels/expenses_viewmodel.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../widgets/bottom_nav_bar.dart';
// Budget card no longer needed
import '../widgets/date_picker_button.dart';
import '../widgets/animated_float_button.dart';
import '../utils/category_manager.dart';
import 'add_expense_screen.dart';

import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';
import '../../data/infrastructure/services/settings_service.dart';
import '../../domain/services/ai_expense_prediction_service.dart';
import '../../domain/services/budget_reallocation_service.dart';
import '../../data/models/ai_response_models.dart';
import '../../di/injection_container.dart' as di;

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

  // To track currency changes
  String? _currentCurrency;

  // Flag to prevent redundant refreshes
  bool _isDataLoaded = false;

  // AI Prediction state
  bool _isLoadingPrediction = false;
  ExpensePredictionResponse? _predictionResult;
  String? _predictionError;

  // Budget reallocation state
  bool _isReallocating = false;

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
    if (_isInitialized) return;

    try {
      final expensesViewModel =
          Provider.of<ExpensesViewModel>(context, listen: false);

      // Get the screen-specific filter
      _selectedDate = expensesViewModel.getScreenFilterDate('analytics');
      _currentMonthId = formatMonthId(_selectedDate);

      debugPrint(
          'Analytics: Initializing filters with date: ${_selectedDate.year}-${_selectedDate.month}');
      debugPrint('Analytics: Set current month ID to: $_currentMonthId');
      debugPrint('Analytics: Selected date details: $_selectedDate');

      // Apply the filter explicitly - only need to call this once
      expensesViewModel.setSelectedMonth(_selectedDate,
          persist: true, screenKey: 'analytics');

      debugPrint('Analytics: Filter applied for analytics screen');

      // Set initialized flag without calling setState during build
      _isInitialized = true;

      // Defer data loading to after build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadData();
        }
      });
    } catch (e) {
      debugPrint('Error retrieving analytic screen filter: $e');
      _selectedDate = DateTime.now();
      _currentMonthId = formatMonthId(_selectedDate);
      debugPrint('Fallback to current date: $_currentMonthId');

      // Set initialized flag without calling setState during build
      _isInitialized = true;

      // Defer data loading to after build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadData();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app is resumed, refresh the data
    if (state == AppLifecycleState.resumed && mounted) {
      // Only refresh data when app is resumed from background
      _loadData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    // Use post frame callback to ensure we're not in build phase
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadData();
        }
      });
      return;
    }

    if (_isLoading) return;

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
        debugPrint('Analytics: Updating to user currency: $_currentCurrency');
      }

      debugPrint(
          'Analytics: Loading data for month ID: $_currentMonthId (${_selectedDate.year}-${_selectedDate.month})');
      debugPrint('Analytics: Selected date details: $_selectedDate');

      // Only set the filter if it's not already set to avoid redundant operations
      if (!_isDataLoaded) {
        debugPrint('Analytics: Setting filter for first time');
        // Apply the filter explicitly - only set it once
        expensesViewModel.setSelectedMonth(_selectedDate,
            persist: true, screenKey: 'analytics');

        debugPrint('Analytics: Filter set, refreshing data...');
        // Refresh expenses data
        await expensesViewModel.refreshData();

        _isDataLoaded = true;
        debugPrint('Analytics: Data loaded successfully');
      }

      // Verify filtering was applied correctly
      final filteredExpenses = expensesViewModel.filteredExpenses;
      final selectedMonth = expensesViewModel.selectedMonth;
      debugPrint(
          'Analytics: After filtering: ${filteredExpenses.length} expenses for month $_currentMonthId');
      debugPrint(
          'Analytics: ViewModel selected month: ${selectedMonth.year}-${selectedMonth.month}');
      debugPrint(
          'Analytics: Screen selected date: ${_selectedDate.year}-${_selectedDate.month}');

      // Force data refresh for dashboard cards
      if (mounted) {
        setState(() {
          // Trigger rebuild with fresh data
        });
      }
    } catch (e) {
      debugPrint('Analytics: Error loading data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onDateChanged(DateTime newDate) {
    debugPrint(
        'Analytics: Date changed from ${_selectedDate.year}-${_selectedDate.month} to ${newDate.year}-${newDate.month}');

    // Avoid redundant operations if date hasn't changed
    if (_selectedDate.year == newDate.year &&
        _selectedDate.month == newDate.month) {
      debugPrint('Analytics: Date unchanged, skipping refresh');
      return;
    }

    setState(() {
      _selectedDate = newDate;
      _currentMonthId = formatMonthId(_selectedDate);
      _errorMessage = null;
      _isDataLoaded = false; // Reset data loaded flag when date changes
    });

    debugPrint('Analytics: Updated current month ID to: $_currentMonthId');
    debugPrint('Analytics: New selected date details: $_selectedDate');

    // Save to screen-specific filter and force reload
    final expensesViewModel =
        Provider.of<ExpensesViewModel>(context, listen: false);

    debugPrint('Analytics: Setting filter for new date');
    // Make sure we're setting the filter
    expensesViewModel.setSelectedMonth(_selectedDate,
        persist: true, screenKey: 'analytics');

    debugPrint('Analytics: Filter set, loading data...');
    // Load data with the new date filter
    _loadData();
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, Routes.login);
  }

  /// Get AI prediction for the selected month
  Future<void> _getAIPrediction() async {
    setState(() {
      _isLoadingPrediction = true;
      _predictionError = null;
    });

    try {
      final expensesViewModel =
          Provider.of<ExpensesViewModel>(context, listen: false);
      final budgetViewModel =
          Provider.of<BudgetViewModel>(context, listen: false);

      // Get the AI service
      final aiService = di.sl<AIExpensePredictionService>();

      // Initialize the service if needed
      await aiService.initialize();

      // Check if we have sufficient data
      final expenses = expensesViewModel.filteredExpenses;
      final budget = budgetViewModel.budget;

      if (expenses.isEmpty) {
        setState(() {
          _predictionError = 'Need expense history to generate predictions';
          _isLoadingPrediction = false;
        });
        return;
      }

      if (budget == null) {
        setState(() {
          _predictionError = 'Budget data required for predictions';
          _isLoadingPrediction = false;
        });
        return;
      }

      // Calculate target date (tomorrow)
      final targetDate = DateTime.now().add(const Duration(days: 1));

      // Get prediction
      final result = await aiService.predictNextDayExpenses(
        pastExpenses: expenses,
        currentBudget: budget,
        targetDate: targetDate,
        userProfile: {
          'location': 'Malaysia',
          'currency': budget.currency,
        },
      );

      setState(() {
        _predictionResult = result;
        _isLoadingPrediction = false;
      });

      debugPrint('🤖 AI Prediction completed successfully');
      debugPrint(
          '📊 Prediction result has ${result.predictedExpenses.length} expenses');

      // Debug the top 3 expenses
      final sortedExpenses =
          List<PredictedExpense>.from(result.predictedExpenses)
            ..sort((a, b) => b.confidence.compareTo(a.confidence));
      final top3 = sortedExpenses.take(3).toList();

      debugPrint('📊 Top 3 expenses by confidence:');
      for (int i = 0; i < top3.length; i++) {
        final exp = top3[i];
        debugPrint(
            '📊 ${i + 1}. ${exp.categoryName}: ${exp.predictedAmount} (confidence: ${exp.confidence})');
      }
    } catch (e) {
      setState(() {
        _predictionError = e.toString();
        _isLoadingPrediction = false;
      });

      debugPrint('🤖 AI Prediction failed: $e');
    }
  }

  /// Reallocate budget based on AI predictions
  Future<void> _reallocateBudget() async {
    if (_predictionResult == null) return;

    setState(() {
      _isReallocating = true;
    });

    try {
      final budgetViewModel =
          Provider.of<BudgetViewModel>(context, listen: false);
      final currentBudget = budgetViewModel.budget;

      if (currentBudget == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No budget data available for reallocation'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get the reallocation service
      final reallocationService = di.sl<BudgetReallocationService>();

      // Get current month ID
      final monthId = formatMonthId(_selectedDate);

      // Perform reallocation
      final reallocatedBudget = await reallocationService.reallocateBudget(
        currentBudget: currentBudget,
        predictions: _predictionResult!,
        monthId: monthId,
      );

      // Update the budget in the view model by saving it
      await budgetViewModel.saveBudget(monthId, reallocatedBudget);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Budget successfully reallocated based on AI predictions!',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      debugPrint('✅ Budget reallocation completed successfully');
    } catch (e) {
      debugPrint('❌ Budget reallocation failed: $e');

      String errorMessage = 'Failed to reallocate budget';
      if (e.toString().contains('REALLOCATION_IMPOSSIBLE')) {
        errorMessage = 'Cannot reallocate - all categories exceed their limits';
      } else if (e.toString().contains('NO_SUGGESTIONS')) {
        errorMessage = 'No reallocation suggestions available from AI';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReallocating = false;
        });
      }
    }
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
            size: 48.sp,
          ),
          SizedBox(height: 16.h),
          Text(
            isAuthError
                ? 'Login to analyze your spending habits'
                : _errorMessage ?? 'Error occurred',
            style: TextStyle(color: Colors.red[300]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Analytic',
          style:
              TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            color: Theme.of(context).dividerColor,
            height: 0.5.h,
          ),
        ),
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
                    // Reset data loaded flag to force refresh
                    _isDataLoaded = false;
                    // Perform a complete refresh
                    await _loadData();
                  },
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.only(top: 16.h),
                        sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                      ),

                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Expanded(
                                child: DatePickerButton(
                                  date: _selectedDate,
                                  themeColor:
                                      Theme.of(context).colorScheme.primary,
                                  prefix: 'Filter by',
                                  onDateChanged: _onDateChanged,
                                  showDaySelection: false,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withAlpha((255 * 0.1).toInt()),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12.r),
                                    onTap: _isLoadingPrediction
                                        ? null
                                        : _getAIPrediction,
                                    child: Padding(
                                      padding: EdgeInsets.all(12.w),
                                      child: _isLoadingPrediction
                                          ? SizedBox(
                                              width: 24.w,
                                              height: 24.h,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.w,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            )
                                          : Icon(
                                              Icons.lightbulb_outline,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              size: 24.sp,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // AI Prediction Result Card
                      if (_predictionResult != null || _predictionError != null)
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          sliver: SliverToBoxAdapter(
                            child: _buildAIPredictionCard(context),
                          ),
                        ),

                      // Category Distribution Pie Chart
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 16.h),
                        sliver: SliverToBoxAdapter(
                          child: _buildCategoryDistributionCard(context),
                        ),
                      ),

                      // Spending Trends Visualization
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        sliver: SliverToBoxAdapter(
                          child: _buildSpendingTrendsCard(context),
                        ),
                      ),

                      // Budget card has been removed from the analytics screen

                      SliverPadding(
                        padding: EdgeInsets.only(bottom: 80.h),
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

  // Build AI prediction result card
  Widget _buildAIPredictionCard(BuildContext context) {
    if (_predictionError != null) {
      return Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.red[400],
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'AI Prediction Error',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[400],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                _predictionError!,
                style: TextStyle(
                  color: Colors.red[300],
                  fontSize: 14.sp,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _predictionError = null;
                      });
                    },
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Dismiss',
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      backgroundColor: Colors.grey[100],
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _getAIPrediction,
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Retry',
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_predictionResult == null) return const SizedBox.shrink();

    final prediction = _predictionResult!;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowFormatted =
        '${tomorrow.day}/${tomorrow.month}/${tomorrow.year}';

    // Get top 3 predicted expenses with highest confidence
    final sortedExpenses =
        List<PredictedExpense>.from(prediction.predictedExpenses)
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final top3Expenses = sortedExpenses.take(3).toList();

    debugPrint(
        '📊 Card rendering: Total expenses: ${prediction.predictedExpenses.length}');
    debugPrint('📊 Card rendering: Top 3 expenses: ${top3Expenses.length}');
    for (int i = 0; i < top3Expenses.length; i++) {
      final exp = top3Expenses[i];
      debugPrint(
          '📊 Card rendering ${i + 1}: ${exp.categoryName} - ${exp.predictedAmount} (${exp.confidence})');
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withAlpha((255 * 0.1).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Spending Prediction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        'For Tomorrow ($tomorrowFormatted)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRiskLevelColor(prediction.summary.riskLevel)
                        .withAlpha((255 * 0.1).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    prediction.summary.riskLevel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getRiskLevelColor(prediction.summary.riskLevel),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary Stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha((255 * 0.3).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Predicted Spending',
                      'MYR ${prediction.summary.totalPredictedSpending.toStringAsFixed(2)}',
                      Icons.trending_up,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Budget Utilization',
                      '${(prediction.summary.budgetUtilizationRate * 100).toStringAsFixed(1)}%',
                      Icons.account_balance_wallet_outlined,
                      _getBudgetUtilizationColor(
                          prediction.summary.budgetUtilizationRate),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Top 3 Predicted Expenses
            if (top3Expenses.isNotEmpty) ...[
              Text(
                'Top Likely Expenses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...top3Expenses.asMap().entries.map((entry) {
                final index = entry.key;
                final expense = entry.value;
                final confidencePercentage = (expense.confidence * 100).round();
                final likelihoodColor = _getConfidenceColor(expense.confidence);
                final likelihoodText =
                    _getConfidenceLikelihoodText(expense.confidence);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(100),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Rank indicator
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Expense details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    expense.categoryName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'MYR ${expense.predictedAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (expense.reasoning.isNotEmpty)
                              Text(
                                expense.reasoning,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Confidence indicator
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: likelihoodColor
                                  .withAlpha((255 * 0.1).toInt()),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: likelihoodColor
                                    .withAlpha((255 * 0.3).toInt()),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              likelihoodText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: likelihoodColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$confidencePercentage%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: likelihoodColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],

            // Budget Reallocation Suggestions
            if (prediction.budgetReallocationSuggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Budget Reallocation Suggestions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...prediction.budgetReallocationSuggestions.map(
                (suggestion) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha((255 * 0.1).toInt()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withAlpha((255 * 0.3).toInt()),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Move MYR ${suggestion.suggestedAmount.toStringAsFixed(2)} from ${suggestion.fromCategory} to ${suggestion.toCategory}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              suggestion.reason,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Categories at Risk
            if (prediction.summary.categoriesAtRisk.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Categories at Risk',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: prediction.summary.categoriesAtRisk
                    .map(
                      (category) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha((255 * 0.1).toInt()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withAlpha((255 * 0.3).toInt()),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            // Insights
            if (prediction.insights.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'AI Insights for Tomorrow',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...prediction.insights.take(3).map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _getInsightIcon(insight.type),
                          size: 16,
                          color: _getInsightColor(insight.type),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insight.message,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _predictionResult = null;
                    });
                  },
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Dismiss',
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    backgroundColor: Colors.grey[100],
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 8),
                // Reallocate button - only show if there are reallocation suggestions
                if (prediction.budgetReallocationSuggestions.isNotEmpty) ...[
                  IconButton(
                    onPressed: _isReallocating ? null : _reallocateBudget,
                    icon: _isReallocating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.swap_horiz, size: 20),
                    tooltip: 'Reallocate Budget',
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  onPressed: _getAIPrediction,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh',
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getConfidenceLikelihoodText(double confidence) {
    if (confidence >= 0.8) return 'HIGH';
    if (confidence >= 0.6) return 'MEDIUM';
    return 'LOW';
  }

  Color _getBudgetUtilizationColor(double utilization) {
    if (utilization <= 0.7) return Colors.green;
    if (utilization <= 0.9) return Colors.orange;
    return Colors.red;
  }

  IconData _getInsightIcon(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'opportunity':
        return Icons.lightbulb_outline;
      case 'info':
        return Icons.info_outline;
      case 'reallocation':
        return Icons.swap_horiz;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _getInsightColor(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return Colors.orange;
      case 'opportunity':
        return Colors.green;
      case 'info':
        return Colors.blue;
      case 'reallocation':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Build category distribution card with pie chart
  Widget _buildCategoryDistributionCard(BuildContext context) {
    final expensesViewModel = Provider.of<ExpensesViewModel>(context);

    // Ensure we're getting data for the selected month
    // We no longer need to force filtering here as it's already done during initialization
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
                    size: 24.sp,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Category Distribution',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  // Show the filter date
                  Text(
                    '${_selectedDate.year}-${_selectedDate.month}',
                    style: TextStyle(
                      fontSize: 14.sp,
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
                      size: 48.sp,
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
                        fontSize: 12.sp,
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
                  size: 24.sp,
                ),
                const SizedBox(width: 8),
                Text(
                  'Category Distribution',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                // Show the filter date
                Text(
                  '${_selectedDate.year}-${_selectedDate.month}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pie chart with fixed height and proper container
            Container(
              height: 280.h,
              alignment: Alignment.center,
              child: _buildCustomPieChart(categoryTotals),
            ),
            SizedBox(height: 24.h),
            // Total amount - now using currency-converted values
            Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Total: ',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16.sp,
                      ),
                    ),
                    TextSpan(
                      text:
                          '${expensesViewModel.currentCurrency} ${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
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
                    margin: EdgeInsets.only(bottom: 4.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12.w,
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: CategoryManager.getColorFromId(categoryId),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${CategoryManager.getNameFromId(categoryId)} ($percentage%)',
                          style: TextStyle(fontSize: 12.sp),
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
    // We no longer need to force filtering here as it's already done during initialization
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
                    size: 24.sp,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Spending Trends',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  // Show the filter date
                  Text(
                    '${_selectedDate.year}-${_selectedDate.month}',
                    style: TextStyle(
                      fontSize: 12.sp,
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
                      size: 48.sp,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No trend data available',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Add more expenses to see spending patterns',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40.h),
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
                  size: 24.sp,
                ),
                const SizedBox(width: 8),
                Text(
                  'Spending Trends',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                // Show the filter date
                Text(
                  '${_selectedDate.year}-${_selectedDate.month}',
                  style: TextStyle(
                    fontSize: 14.sp,
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
    // We no longer need to force filtering here as it's already done during initialization
    final categoryTotals = viewModel.getCategoryTotals();

    if (categoryTotals.isEmpty) {
      return SizedBox(
        height: 120.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category_outlined,
                  size: 28.sp, color: Colors.grey[400]),
              SizedBox(height: 8.h),
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
        Text(
          'Top Categories',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
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
                      size: 16.sp,
                      color: CategoryManager.getColor(category),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      CategoryManager.getName(category),
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    Spacer(),
                    Text(
                      '${viewModel.currentCurrency} ${entry.value.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                // Bar chart
                Stack(
                  children: [
                    // Background bar
                    Container(
                      height: 8.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    // Filled bar
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: CategoryManager.getColor(category),
                          borderRadius: BorderRadius.circular(4.r),
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
    // We no longer need to force filtering here as it's already done during initialization
    final expenses = viewModel.filteredExpenses;

    if (expenses.isEmpty) {
      return SizedBox(
        height: 150.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.date_range_outlined,
                  size: 28.sp, color: Colors.grey[400]),
              SizedBox(height: 8.h),
              Text(
                'No daily spending data for ${_selectedDate.year}-${_selectedDate.month}',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              Text(
                'Add expenses to see daily patterns',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
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
        Text(
          'Daily Spending Pattern',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 120.h,
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
                  padding: EdgeInsets.symmetric(horizontal: 1.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Bar - use Flexible to prevent overflow
                      Flexible(
                        flex: 8,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: (80 * percentage)
                              .toDouble()
                              .h, // Reduced from 100 to 80
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isToday
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha((255 * 0.7).toInt()),
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(4.r)),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h), // Reduced spacing
                      // Day number - use Flexible to prevent overflow
                      Flexible(
                        flex: 2,
                        child: Text(
                          day.toString(),
                          style: TextStyle(
                            fontSize: 9.sp, // Slightly smaller font
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
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
              size: 48.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 8.h),
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
            radius: 100.r,
            titleStyle: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2.r,
        centerSpaceRadius: 40.r,
        startDegreeOffset: 180.r,
      ),
    );
  }
}
