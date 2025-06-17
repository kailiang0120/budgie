import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../viewmodels/expenses_viewmodel.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/date_picker_button.dart';
import '../widgets/animated_float_button.dart';
import '../widgets/ai_prediction_card.dart';
import '../widgets/category_distribution_card.dart';
import '../widgets/spending_trends_card.dart';
import 'add_expense_screen.dart';

import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';

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

  // Flag to prevent redundant refreshes
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize with default values
    _selectedDate = DateTime.now();
    _currentMonthId = formatMonthId(_selectedDate);

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

  String _getMonthIdFromDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Analytics: Starting data load...');
      final expensesViewModel =
          Provider.of<ExpensesViewModel>(context, listen: false);

      // Get current month ID for consistency
      _currentMonthId = _getMonthIdFromDate(_selectedDate);
      debugPrint('Analytics: Current month ID: $_currentMonthId');

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

  // Method to refresh analytics data (similar to home screen)
  Future<void> _refreshData() async {
    if (!mounted) return;

    debugPrint('Analytics: Manual refresh triggered');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isDataLoaded = false; // Reset to force complete refresh
    });

    try {
      final expensesViewModel =
          Provider.of<ExpensesViewModel>(context, listen: false);

      // Clear any cached data and refresh from source
      debugPrint('Analytics: Refreshing expenses data...');
      await expensesViewModel.refreshData();

      // Reapply filter for current screen
      debugPrint('Analytics: Reapplying filter for analytics screen...');
      expensesViewModel.setSelectedMonth(_selectedDate,
          persist: true, screenKey: 'analytics');

      _isDataLoaded = true;
      debugPrint('Analytics: Refresh completed successfully');

      if (mounted) {
        setState(() {
          // Trigger rebuild with fresh data
        });
      }
    } catch (e) {
      debugPrint('Analytics: Error during refresh: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to refresh data: ${e.toString()}';
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
                    // Use the unified refresh method for complete data reload
                    await _refreshData();
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
                              AIPredictionCard(selectedDate: _selectedDate),
                            ],
                          ),
                        ),
                      ),

                      // Category Distribution Pie Chart
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 16.h),
                        sliver: SliverToBoxAdapter(
                          child: CategoryDistributionCard(
                            selectedDate: _selectedDate,
                          ),
                        ),
                      ),

                      // Spending Trends Visualization
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        sliver: SliverToBoxAdapter(
                          child: SpendingTrendsCard(
                            selectedDate: _selectedDate,
                          ),
                        ),
                      ),

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
          ).then((result) {
            // Only refresh data if an expense was actually added (result == true)
            if (!mounted || result != true) return;

            // Refresh the analytics data using unified refresh method
            _refreshData();
          });
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
