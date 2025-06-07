// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/expenses_viewmodel.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../widgets/expense_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/date_picker_button.dart';
import '../widgets/animated_float_button.dart';
import '../utils/currency_formatter.dart';
// Using theme from MaterialApp
import '../utils/category_manager.dart';
import 'add_expense_screen.dart';
import 'add_budget_screen.dart';

import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';
import '../../domain/entities/budget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late DateTime _selectedDate;
  bool _filterByDay = false;
  bool _showDetailedBudget = false;
  // Add animation controller and animation duration
  static const _animationDuration = Duration(milliseconds: 300);
  static const _animationCurve = Curves.easeInOut;

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
      _filterByDay = vm.isDayFilteringForScreen('home');

      // Apply the filter
      vm.setSelectedMonth(_selectedDate,
          filterByDay: _filterByDay, screenKey: 'home');

      setState(() {});
    } catch (e) {
      debugPrint('Error initializing date filter: $e');
      _selectedDate = DateTime.now();
    }
  }

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
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });

    try {
      final vm = Provider.of<ExpensesViewModel>(context, listen: false);
      vm.setSelectedMonth(_selectedDate,
          filterByDay: _filterByDay, screenKey: 'home');

      // Also update budget for the selected month
      final budgetVM = Provider.of<BudgetViewModel>(context, listen: false);
      budgetVM.loadBudget(_getMonthIdFromDate(_selectedDate));
    } catch (e) {
      debugPrint('Error changing selected month: $e');
    }
  }

  void _toggleFilterMode() {
    setState(() {
      _filterByDay = !_filterByDay;
    });

    try {
      final vm = Provider.of<ExpensesViewModel>(context, listen: false);
      vm.setSelectedMonth(_selectedDate,
          filterByDay: _filterByDay, screenKey: 'home');
    } catch (e) {
      debugPrint('Error toggling filter mode: $e');
    }
  }

  void _navigateToBudgetScreen() {
    Navigator.push(
      context,
      PageTransition(
        child: AddBudgetScreen(
          monthId: _getMonthIdFromDate(_selectedDate),
        ),
        type: TransitionType.slideRight,
      ),
    ).then((_) {
      // Refresh budget data when returning from budget screen
      if (mounted) {
        Provider.of<BudgetViewModel>(context, listen: false)
            .loadBudget(_getMonthIdFromDate(_selectedDate));
      }
    });
  }

  Widget _buildBudgetCard() {
    return Consumer<BudgetViewModel>(
      builder: (context, budgetVM, _) {
        final budget = budgetVM.budget;
        final themeColor = Theme.of(context).colorScheme.primary;

        if (budget == null) {
          // Show empty budget card with call to action
          return Card(
            elevation: 4,
            shadowColor: Colors.black.withAlpha((255 * 0.3).toInt()),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: _navigateToBudgetScreen,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 40,
                      color: themeColor.withAlpha((255 * 0.5).toInt()),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Set Budget',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap here to set your monthly budget',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Budget exists - show either compact or detailed view
        final remaining = budget.left;
        final percentage = budget.total > 0 ? (remaining / budget.total) : 0;
        final isLow = percentage < 0.3 && percentage > 0;
        final isNegative = remaining <= 0;
        final currencySymbol =
            CurrencyFormatter.getCurrencySymbol(budget.currency);

        final statusColor = isNegative
            ? Colors.red
            : isLow
                ? Colors.orange
                : Colors.green.shade700;

        return Card(
          elevation: 8,
          shadowColor: Colors.black.withAlpha((255 * 0.3).toInt()),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: _showDetailedBudget
                ? null // Disable tap when already expanded
                : () {
                    setState(() {
                      _showDetailedBudget = true;
                    });
                  },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: _animationDuration,
              curve: _animationCurve,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeColor.withAlpha((255 * 0.1).toInt()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          size: 28,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Budget',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$currencySymbol${budget.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Amount left for this month',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$currencySymbol${remaining.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha((255 * 0.1).toInt()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isNegative
                              ? 'Overspent'
                              : isLow
                                  ? 'Low Budget'
                                  : 'Budget Healthy',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage.clamp(0, 1).toDouble(),
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Used ${((1 - percentage) * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  if (!_showDetailedBudget) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showDetailedBudget = true;
                          });
                        },
                        icon: const Icon(Icons.expand_more, size: 20),
                        label: const Text('Show more'),
                        style: TextButton.styleFrom(
                          foregroundColor: themeColor,
                        ),
                      ),
                    ),
                  ],

                  // Detailed budget view (category breakdown)
                  // Use AnimatedCrossFade for a smoother transition between expanded/collapsed states
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: budget.categories.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Categories',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _navigateToBudgetScreen,
                                    child: const Text('Edit Budget'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ..._buildCategoryList(budget),

                              // Show less button
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.center,
                                child: TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _showDetailedBudget = false;
                                    });
                                  },
                                  icon: const Icon(Icons.expand_less, size: 20),
                                  label: const Text('Show less'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: themeColor,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                    crossFadeState: _showDetailedBudget
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: _animationDuration,
                    sizeCurve: _animationCurve,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCategoryList(budget) {
    final categories = budget.categories.entries.toList();
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(budget.currency);

    // Sort categories by remaining budget percentage (from low to high)
    categories.sort((MapEntry<String, CategoryBudget> a,
        MapEntry<String, CategoryBudget> b) {
      final percentA = a.value.budget > 0 ? a.value.left / a.value.budget : 0;
      final percentB = b.value.budget > 0 ? b.value.left / b.value.budget : 0;
      return percentA.compareTo(percentB);
    });

    return categories.map<Widget>((entry) {
      final catId = entry.key;
      final catBudget = entry.value;

      // Get category information
      final category = CategoryManager.getCategoryFromId(catId);
      final categoryIcon =
          category != null ? CategoryManager.getIcon(category) : Icons.category;
      final categoryColor =
          category != null ? CategoryManager.getColor(category) : Colors.grey;
      final categoryName =
          category != null ? CategoryManager.getName(category) : catId;

      // Calculate percentage
      final percentage = catBudget.budget > 0
          ? (catBudget.left / catBudget.budget).clamp(0.0, 1.0)
          : 0.0;

      // Status color
      final statusColor = catBudget.left <= 0
          ? Colors.red
          : percentage < 0.3
              ? Colors.orange
              : Colors.green.shade700;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: categoryColor.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                categoryIcon,
                size: 18,
                color: categoryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$currencySymbol${catBudget.left.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Method to refresh both expenses and budget data
  Future<void> _refreshData() async {
    if (mounted) {
      final expensesVM = Provider.of<ExpensesViewModel>(context, listen: false);
      final budgetVM = Provider.of<BudgetViewModel>(context, listen: false);

      // Refresh expenses data
      await expensesVM.refreshData();

      // Refresh budget data for the selected month
      await budgetVM.refreshBudget(_getMonthIdFromDate(_selectedDate));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpensesViewModel>();
    final expenses = vm.expenses;
    final isLoading = vm.isLoading;

    // Load budget for the selected month
    final monthId = _getMonthIdFromDate(_selectedDate);
    if (mounted) {
      Provider.of<BudgetViewModel>(context, listen: false).loadBudget(monthId);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        automaticallyImplyLeading: false,
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
                  const SliverPadding(
                    padding: EdgeInsets.only(top: 16.0),
                    sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),

                  // Month/day selector row (moved to top)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: DatePickerButton(
                              date: _selectedDate,
                              themeColor: Theme.of(context).colorScheme.primary,
                              prefix: 'Filter by',
                              onDateChanged: _onDateChanged,
                              showDaySelection: _filterByDay,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Filter toggle button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _toggleFilterMode,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                constraints: const BoxConstraints(
                                    minHeight: 45, minWidth: 45),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withAlpha((255 * 0.1).toInt()),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha((255 * 0.3).toInt()),
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    _filterByDay
                                        ? Icons.calendar_today
                                        : Icons.calendar_month,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Budget Card
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    sliver: SliverToBoxAdapter(
                      child: _buildBudgetCard(),
                    ),
                  ),

                  // Expense list
                  expenses.isEmpty
                      ? const SliverPadding(
                          padding: EdgeInsets.all(32.0),
                          sliver: SliverToBoxAdapter(
                            child: Center(
                              child: Text(
                                'No expenses for this period. Add your first expense by tapping the + button below',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              // Store an instance of the view model before any async operation
                              final expensesVM = Provider.of<ExpensesViewModel>(
                                  context,
                                  listen: false);
                              return ExpenseCard(
                                expense: expenses[index],
                                onExpenseUpdated: () {
                                  // Use the captured view model to refresh data
                                  expensesVM.refreshData();
                                },
                              );
                            },
                            childCount: expenses.length,
                          ),
                        ),

                  // Padding at bottom so FAB + NavBar don't cover last card
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: 90),
                    sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
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
          ).then((_) {
            // Refresh budget data when returning from expense screen
            if (!mounted) return;

            // Capture context reference safely since we've checked mounted
            final budgetVM =
                Provider.of<BudgetViewModel>(context, listen: false);
            budgetVM.refreshBudget(_getMonthIdFromDate(_selectedDate));
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
                navigator.pushReplacementNamed(Routes.profile);
                break;
            }
          }
        },
      ),
    );
  }
}
