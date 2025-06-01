import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/expenses_viewmodel.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/legend_card.dart';
import '../widgets/expense_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/date_picker_button.dart';
import '../widgets/animated_float_button.dart';
import '../utils/currency_formatter.dart';
import 'add_expense_screen.dart';

import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';
import '../../domain/entities/category.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late DateTime _selectedDate;
  bool _filterByDay = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize with current date as default
    _selectedDate = DateTime.now();

    // Get view model for expenses
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
      final vm = Provider.of<ExpensesViewModel>(context, listen: false);

      // Use the screen-specific filter settings
      _selectedDate = vm.getScreenFilterDate('home');
      _filterByDay = vm.isDayFilteringForScreen('home');

      // Apply the filter
      vm.setSelectedMonth(_selectedDate,
          filterByDay: _filterByDay, screenKey: 'home');

      setState(() {
        _isInitialized = true;
      });
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
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });

    try {
      final vm = Provider.of<ExpensesViewModel>(context, listen: false);
      vm.setSelectedMonth(_selectedDate,
          filterByDay: _filterByDay, screenKey: 'home');
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpensesViewModel>();
    final expenses = vm
        .expenses; // This will now return filtered expenses if filtering is active
    final height = MediaQuery.of(context).size.height;
    final isLoading = vm.isLoading;

    // Use the ViewModel's method to get category totals
    final categoryTotals = vm.getCategoryTotals();
    final totalAmount = vm.getTotalExpenses();

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
                await Provider.of<ExpensesViewModel>(context, listen: false)
                    .refreshData();
              },
              child: CustomScrollView(
                slivers: [
                  const SliverPadding(
                    padding: EdgeInsets.only(top: 16.0),
                    sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),

                  // Auto-detected expenses are now handled via overlay

                  // Month/day selector row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: DatePickerButton(
                              date: _selectedDate,
                              themeColor: Theme.of(context).colorScheme.primary,
                              prefix: 'Expenses for',
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

                  // Summary info
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Total: ${CurrencyFormatter.formatAmount(totalAmount, vm.currentCurrency)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 1) Pie chart in a fixed box
                  SliverToBoxAdapter(
                    child: expenses.isEmpty
                        ? SizedBox(
                            height: height * 0.25,
                            child: const Center(
                              child: Text(
                                'No expenses for this month',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : SizedBox(
                            height: height * 0.25,
                            child: ExpensePieChart(data: categoryTotals),
                          ),
                  ),

                  // 2) Some breathing room
                  const SliverToBoxAdapter(child: SizedBox(height: 15)),

                  // 3) Legend card, auto-height 2×3 grid
                  if (expenses.isNotEmpty)
                    SliverToBoxAdapter(
                      child: LegendCard(
                          categories:
                              categoryTotals.keys.map((e) => e.id).toList()),
                    ),

                  // 4) More breathing room
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // 5) All your expense cards
                  expenses.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
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
                            (context, index) =>
                                ExpenseCard(expense: expenses[index]),
                            childCount: expenses.length,
                          ),
                        ),

                  // 6) Padding at bottom so FAB + NavBar don't cover last card
                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
            ),

      // 3) Floating "+" button
      floatingActionButton: AnimatedFloatButton(
        onPressed: () {
          // 使用自定义动画导航到添加支出页面
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

      // 4) Bottom nav bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (idx) {
          // 实现导航逻辑
          if (idx != 0) {
            switch (idx) {
              case 1:
                Navigator.pushReplacementNamed(context, Routes.analytic);
                break;
              case 2:
                Navigator.pushReplacementNamed(context, Routes.settings);
                break;
              case 3:
                Navigator.pushReplacementNamed(context, Routes.profile);
                break;
            }
          }
        },
      ),
    );
  }

  // Auto-detected expenses are now handled via overlay system
}
