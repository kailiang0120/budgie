// ignore_for_file: use_build_context_synchronously
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../viewmodels/expenses_viewmodel.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../widgets/expense_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/date_picker_button.dart';
import '../widgets/animated_float_button.dart';
import '../widgets/home_budget_card.dart';
import '../utils/app_constants.dart';
// Using theme from MaterialApp
import 'add_expense_screen.dart';
import 'add_budget_screen.dart';

import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late DateTime _selectedDate;
  DateFilterMode _filterMode = DateFilterMode.month;
  // Removed: StreamSubscription<NotificationNavigationAction>? _navigationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize with current date as default
    _selectedDate = DateTime.now();

    // Initialize filters in post-frame callback to avoid build phase issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeFilters();

        // Auto refresh both expenses and budget when the home screen loads
        _refreshData();

        // Force budget refresh to ensure it's loaded
        final monthId = _getBudgetMonthId();
        debugPrint('🏠 HomeScreen: Initial budget refresh for month: $monthId');
        Provider.of<BudgetViewModel>(context, listen: false)
            .refreshBudget(monthId);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Remove initialization from didChangeDependencies to avoid build phase issues
  }

  void _initializeFilters() {
    try {
      final vm = Provider.of<ExpensesViewModel>(context, listen: false);

      // Use the screen-specific filter settings
      _selectedDate = vm.getScreenFilterDate('home');
      _filterMode = vm.getFilterMode('home');

      debugPrint(
          '🏠 HomeScreen: Initializing filters - selectedDate: $_selectedDate, filterMode: $_filterMode');

      // Apply the filter using the new filter mode system
      vm.setFilterMode(_filterMode, _selectedDate, screenKey: 'home');

      setState(() {});
    } catch (e) {
      debugPrint('🏠 HomeScreen: Error initializing date filter: $e');
      _selectedDate = DateTime.now();
      _filterMode = DateFilterMode.month;
    }
  }

  // Removed: void _setupNavigationListener() { ... }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app is resumed, refresh the data
    if (state == AppLifecycleState.resumed && mounted) {
      Provider.of<ExpensesViewModel>(context, listen: false).refreshData();
      Provider.of<BudgetViewModel>(context, listen: false).loadBudget(
        _getMonthIdFromDate(_selectedDate),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _getMonthIdFromDate(DateTime date) {
    // Format with leading zero for month to ensure consistent format
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Get budget month ID based on current filter mode and selected date
  String _getBudgetMonthId() {
    switch (_filterMode) {
      case DateFilterMode.day:
      case DateFilterMode.month:
        // For day and month filters, use the month containing the selected date
        return _getMonthIdFromDate(_selectedDate);
      case DateFilterMode.year:
        // For year filter, use current month of the selected year
        final now = DateTime.now();
        final yearDate = DateTime(_selectedDate.year, now.month, 1);
        return _getMonthIdFromDate(yearDate);
    }
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });

    try {
      final vm = Provider.of<ExpensesViewModel>(context, listen: false);

      // First clear any cached data
      vm.refreshData();

      // Then apply the new filter using the filter mode system
      vm.setFilterMode(_filterMode, _selectedDate, screenKey: 'home');

      // Also update budget for the selected month using smart filtering
      final budgetVM = Provider.of<BudgetViewModel>(context, listen: false);
      final monthId = _getBudgetMonthId();

      // Use refreshBudget to ensure we get fresh data
      budgetVM.refreshBudget(monthId);
    } catch (e) {
      debugPrint('Error changing selected month: $e');
    }
  }

  void _onFilterModeChanged(DateFilterMode newMode) {
    setState(() {
      _filterMode = newMode;
    });

    try {
      final vm = Provider.of<ExpensesViewModel>(context, listen: false);
      vm.setFilterMode(_filterMode, _selectedDate, screenKey: 'home');
    } catch (e) {
      debugPrint('Error changing filter mode: $e');
    }
  }

  void _navigateToBudgetScreen() {
    Navigator.push(
      context,
      PageTransition(
        child: AddBudgetScreen(
          monthId: _getBudgetMonthId(),
        ),
        type: TransitionType.slideRight,
      ),
    ).then((result) {
      // Refresh budget data when returning from budget screen
      if (mounted) {
        final monthId = _getBudgetMonthId();
        debugPrint(
            '🏠 HomeScreen: Returned from budget screen with result: $result');

        // Use refreshBudget instead of loadBudget to ensure we get fresh data
        Provider.of<BudgetViewModel>(context, listen: false)
            .refreshBudget(monthId);

        // Also refresh expenses to ensure proper calculations
        Provider.of<ExpensesViewModel>(context, listen: false).refreshData();

        // Force a complete refresh of both expenses and budget
        _refreshData();
      }
    });
  }

  Widget _buildBudgetCard() {
    return Consumer<BudgetViewModel>(
      builder: (context, budgetVM, _) {
        return HomeBudgetCard(
          budget: budgetVM.budget,
          selectedDate: _selectedDate,
          filterMode: _filterMode,
          onTap: _navigateToBudgetScreen,
          isLoading: budgetVM.isLoading,
        );
      },
    );
  }

  Widget _buildFilterSection() {
    return DatePickerButton(
      date: _selectedDate,
      themeColor: Theme.of(context).colorScheme.primary,
      prefix: 'Filter by',
      onDateChanged: _onDateChanged,
      filterMode: _filterMode,
      onFilterModeChanged: _onFilterModeChanged,
      showFilterModeSelector: true,
    );
  }

  // Method to refresh both expenses and budget data
  Future<void> _refreshData() async {
    if (!mounted) {
      debugPrint(
          '🏠 HomeScreen: _refreshData called but widget is not mounted');
      return;
    }

    debugPrint('🏠 HomeScreen: Manual refresh triggered');

    try {
      setState(() {
        // Show loading indicator if needed
      });

      final expensesVM = Provider.of<ExpensesViewModel>(context, listen: false);
      final budgetVM = Provider.of<BudgetViewModel>(context, listen: false);
      final monthId = _getBudgetMonthId();

      // Step 1: Clear any cached data and refresh expenses from source
      debugPrint('🏠 HomeScreen: Refreshing expenses data...');
      await expensesVM.refreshData();

      // Step 2: Reapply current filter settings for home screen
      debugPrint('🏠 HomeScreen: Reapplying filter for home screen...');
      expensesVM.setFilterMode(_filterMode, _selectedDate, screenKey: 'home');

      // Step 3: Get the filtered expenses for the current month/day
      final currentExpenses = _filterMode == DateFilterMode.day
          ? expensesVM
              .filteredExpenses // Use filtered expenses when filtering by day
          : expensesVM.getExpensesForMonth(
              _selectedDate.year, _selectedDate.month);

      debugPrint(
          '🏠 HomeScreen: Found ${currentExpenses.length} expenses for the selected period');

      // Step 4: Refresh budget data for the selected month (optimize by combining operations)
      if (mounted) {
        debugPrint('🏠 HomeScreen: Refreshing budget for month: $monthId');

        // Optimize: Use refreshBudget which internally loads and calculates
        await budgetVM.refreshBudget(monthId);
        debugPrint(
            '🏠 HomeScreen: Budget after refresh exists: ${budgetVM.budget != null}');

        // Only calculate budget remaining if needed (avoid redundant calculation)
        if (budgetVM.budget != null && currentExpenses.isNotEmpty) {
          await budgetVM.calculateBudgetRemaining(currentExpenses, monthId);
          debugPrint(
              '🏠 HomeScreen: Budget after recalculation exists: ${budgetVM.budget != null}');
        }

        debugPrint(
            '🏠 HomeScreen: Refresh completed successfully - expenses count: ${expensesVM.expenses.length}');

        // Force UI update only if still mounted
        if (mounted) {
          setState(() {
            // Update UI with fresh data
          });
        }
      }
    } catch (e) {
      debugPrint('🏠 HomeScreen: Error during refresh: $e');

      // Show error to user if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpensesViewModel>();
    final expenses = vm.expenses;
    final isLoading = vm.isLoading;

    debugPrint(
        '🏠 HomeScreen: Building UI with ${expenses.length} expenses, loading: $isLoading');

    // Use post-frame callback to load budget to avoid calling setState during build
    if (mounted) {
      // Use a post-frame callback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final monthId = _getBudgetMonthId();
          debugPrint(
              '🏠 HomeScreen: Post-frame callback refreshing budget for month: $monthId');
          Provider.of<BudgetViewModel>(context, listen: false)
              .refreshBudget(monthId);
        }
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          AppConstants.homeTitle,
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

      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary))
          : RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: () async {
                // Use the shared refresh method to refresh both expenses and budget
                await _refreshData();
                // No BuildContext used after async gap
                return;
              },
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.only(top: 16.h),
                    sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),

                  // Filter Section with improved UX design
                  SliverPadding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    sliver: SliverToBoxAdapter(
                      child: _buildFilterSection(),
                    ),
                  ),

                  // Budget Card
                  SliverToBoxAdapter(
                    child: _buildBudgetCard(),
                  ),

                  // Expense list
                  expenses.isEmpty
                      ? SliverPadding(
                          padding: EdgeInsets.all(AppConstants.spacingHuge.w),
                          sliver: const SliverToBoxAdapter(
                            child: Center(
                              child: Text(
                                'Add your first expense by tapping the + button below',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: AppConstants.spacingLarge.w),
                                child: ExpenseCard(
                                  key: ValueKey(
                                      expenses[index].id), // Add unique key
                                  expense: expenses[index],
                                  onExpenseUpdated: () {
                                    // Use unified refresh method for complete data reload
                                    _refreshData();
                                  },
                                ),
                              );
                            },
                            childCount: expenses.length,
                          ),
                        ),

                  // Padding at bottom so FAB + NavBar don't cover last card
                  SliverPadding(
                    padding: EdgeInsets.only(
                        bottom: AppConstants.bottomPaddingWithNavBar),
                    sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),
                ],
              ),
            ),

      // Floating "+" button
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
            debugPrint(
                '🏠 HomeScreen: Returned from AddExpenseScreen with result: $result');
            if (!mounted || result != true) {
              debugPrint(
                  '🏠 HomeScreen: Not refreshing - mounted: $mounted, result: $result');
              return;
            }

            debugPrint(
                '🏠 HomeScreen: Expense added successfully, triggering refresh');
            // Use unified refresh method for complete data reload
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

      // Bottom nav bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (idx) {
          if (idx != 0) {
            final navigator = Navigator.of(context);
            if (!navigator.mounted) return;

            switch (idx) {
              case 1:
                navigator.pushReplacementNamed(Routes.analytic);
                break;
              case 2:
                navigator.pushReplacementNamed(Routes.settings);
                break;
              case 3:
                navigator.pushReplacementNamed(Routes.goals);
                break;
            }
          }
        },
      ),
    );
  }
}
