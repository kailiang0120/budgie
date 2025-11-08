import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/financial_goal.dart';
import '../../presentation/viewmodels/goals_viewmodel.dart';
import '../../data/infrastructure/services/settings_service.dart';
import '../../di/injection_container.dart' as di;
import '../widgets/bottom_nav_bar.dart';
import '../widgets/animated_float_button.dart';
import '../widgets/goal_card.dart';
import '../widgets/goal_history_card.dart';
import '../widgets/goal_form_dialog.dart';
import '../widgets/custom_card.dart';
import '../widgets/funding_preview_dialog.dart';
import '../widgets/goal_snapshot_card.dart';
import '../widgets/submit_button.dart';
import '../utils/dialog_utils.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxActiveGoals = 3;

  bool _loading = false;
  late TabController _tabController;
  late GoalsViewModel _goalsViewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _goalsViewModel = di.sl<GoalsViewModel>();
    _loadGoalsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGoalsData() async {
    setState(() {
      _loading = true;
    });

    try {
      await _goalsViewModel.init(force: true);
    } catch (e) {
      debugPrint('Error loading goals data: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showAddGoalDialog() async {
    final canAddMore = await _goalsViewModel.canAddMoreGoals();

    if (!mounted) return;

    if (!canAddMore) {
      DialogUtils.showInfoDialog(
        context,
        title: 'Goal Limit Reached',
        message:
            'You can only have $_maxActiveGoals active goals at a time. Please complete or delete an existing goal before adding a new one.',
      );
      return;
    }

    showGoalFormDialog(
      context: context,
      onSave: (goal) async {
        await _goalsViewModel.saveGoal(goal);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _goalsViewModel,
      child: Consumer<GoalsViewModel>(
        builder: (context, goalsViewModel, _) {
          final isBusy = _loading || goalsViewModel.isLoading;
          final canShowFab =
              !isBusy && goalsViewModel.goals.length < _maxActiveGoals;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _buildAppBar(context),
            body: SafeArea(
              child: isBusy
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildActiveGoalsTab(goalsViewModel),
                        _buildHistoryTab(goalsViewModel),
                      ],
                    ),
            ),
            extendBody: true,
            floatingActionButton: canShowFab
                ? AnimatedFloatButton(
                    onPressed: _showAddGoalDialog,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: const CircleBorder(),
                    enableFeedback: true,
                    reactToRouteChange: true,
                    child: Icon(
                      Icons.flag_rounded,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : null,
            floatingActionButtonLocation:
                canShowFab ? FloatingActionButtonLocation.centerDocked : null,
            bottomNavigationBar: BottomNavBar(
              currentIndex: 2, // Goals tab
              onTap: (idx) {
                // Navigation handled in BottomNavBar
              },
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        AppConstants.goalsTitle,
        style: TextStyle(
          color: Theme.of(context).textTheme.titleLarge?.color,
          fontSize: AppConstants.textSizeXXLarge,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(AppConstants.componentHeightStandard),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: AppTheme.greyTextLight,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                fontSize: AppConstants.textSizeMedium,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: AppConstants.textSizeMedium,
                fontWeight: FontWeight.normal,
              ),
              tabs: const [
                Tab(text: 'Active Goals'),
                Tab(text: 'History'),
              ],
            ),
            Container(
              color: Theme.of(context).dividerColor,
              height: 0.5.h,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveGoalsTab(GoalsViewModel goalsViewModel) {
    final activeGoals = goalsViewModel.goals
        .where((goal) => !goal.isCompleted)
        .toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));

    if (activeGoals.isEmpty) {
      return _buildEmptyGoalsState();
    }

    final currency = di.sl<SettingsService>().currency;
    final availableSavings = goalsViewModel.availableSavings;
    final canAllocate = availableSavings > 0 && activeGoals.isNotEmpty;
    final summary = canAllocate
        ? 'You have ${CurrencyFormatter.formatAmount(availableSavings, currency)} ready to allocate.'
        : 'No surplus savings awaiting allocation. Keep tracking your budget to free up funds.';
    final recommendation = goalsViewModel.goalRecommendations.isNotEmpty
        ? goalsViewModel.goalRecommendations.first
        : null;

    return RefreshIndicator(
      onRefresh: () async {
        await goalsViewModel.init(force: true);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: AppConstants.screenPaddingHorizontal.copyWith(
              top: AppConstants.spacingLarge,
            ),
            sliver: SliverToBoxAdapter(
              child: GoalSnapshotCard(
                activeGoals: activeGoals.length,
                summary: summary,
                focusGoal: activeGoals.first,
                availableSavings: availableSavings,
                currency: currency,
                recommendation: recommendation,
                canAllocate: canAllocate,
                isAllocating: goalsViewModel.isFundingGoals,
                onAllocate: () => _handleAllocateSavings(goalsViewModel),
                onManage: _showAddGoalDialog,
                manageLabel: goalsViewModel.goals.length < _maxActiveGoals
                    ? 'Add Goal'
                    : 'Manage Goals',
                manageIcon: goalsViewModel.goals.length < _maxActiveGoals
                    ? Icons.add_circle
                    : Icons.flag_circle,
              ),
            ),
          ),
          SliverPadding(
            padding: AppConstants.screenPaddingHorizontal.copyWith(
              top: AppConstants.spacingLarge,
            ),
            sliver: SliverToBoxAdapter(
              child: _buildStatisticsSection(context, goalsViewModel),
            ),
          ),
          if (goalsViewModel.hasSavingsToAllocate)
            SliverPadding(
              padding: AppConstants.screenPaddingHorizontal.copyWith(
                top: AppConstants.spacingLarge,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildFundingSection(context, goalsViewModel),
              ),
            ),
          if (goalsViewModel.goalRecommendations.isNotEmpty)
            SliverPadding(
              padding: AppConstants.screenPaddingHorizontal.copyWith(
                top: AppConstants.spacingLarge,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildRecommendationsSection(context, goalsViewModel),
              ),
            ),
          SliverPadding(
            padding: AppConstants.screenPaddingHorizontal.copyWith(
              top: AppConstants.spacingLarge,
            ),
            sliver: SliverToBoxAdapter(
              child: _buildFinancialGoalsList(context, goalsViewModel),
            ),
          ),
          if (goalsViewModel.goals.length < _maxActiveGoals)
            SliverPadding(
              padding: AppConstants.screenPaddingHorizontal.copyWith(
                top: AppConstants.spacingLarge,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildAddGoalSection(),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: AppConstants.bottomPaddingWithNavBar),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGoalsState() {
    return Center(
      child: Padding(
        padding: AppConstants.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.savings_rounded,
              size: AppConstants.iconSizeXLarge * 2,
              color: Colors.grey[400],
            ),
            SizedBox(height: AppConstants.spacingXLarge),
            Text(
              'No Financial Goals Yet',
              style: TextStyle(
                fontSize: AppConstants.textSizeXXLarge,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: AppConstants.spacingMedium),
            Text(
              'Create your first goal to start saving towards your dreams and aspirations.',
              style: TextStyle(
                fontSize: AppConstants.textSizeMedium,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.spacingXXLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddGoalDialog,
                icon:
                    Icon(Icons.add_rounded, size: AppConstants.iconSizeMedium),
                label: Text(
                  'Create Your First Goal',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeLarge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: AppConstants.spacingLarge,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadiusLarge),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(GoalsViewModel goalsViewModel) {
    if (goalsViewModel.isHistoryLoading && goalsViewModel.goalHistory.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (goalsViewModel.goalHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: AppConstants.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_rounded,
                size: AppConstants.iconSizeXLarge * 2,
                color: Colors.grey[400],
              ),
              SizedBox(height: AppConstants.spacingXLarge),
              Text(
                'No Completed Goals Yet',
                style: TextStyle(
                  fontSize: AppConstants.textSizeXXLarge,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: AppConstants.spacingMedium),
              Text(
                'Your completed goals will appear here as a record of your achievements.',
                style: TextStyle(
                  fontSize: AppConstants.textSizeMedium,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await goalsViewModel.loadGoalHistory();
      },
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: AppConstants.spacingLarge.w,
          right: AppConstants.spacingLarge.w,
          top: AppConstants.spacingLarge.h,
          bottom: AppConstants.bottomPaddingWithNavBar,
        ),
        itemCount: goalsViewModel.goalHistory.length,
        itemBuilder: (context, index) {
          final history = goalsViewModel.goalHistory[index];
          return Padding(
            padding: AppConstants.cardMarginStandard,
            child: GoalHistoryCard(
              history: history,
              onTap: () {
                DialogUtils.showInfoDialog(
                  context,
                  title: history.title,
                  message:
                      'Goal completed on ${DateFormat('d MMM yyyy').format(history.completedDate)}',
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsSection(
      BuildContext context, GoalsViewModel goalsViewModel) {
    final totalTargetAmount =
        goalsViewModel.goals.fold(0.0, (sum, goal) => sum + goal.targetAmount);
    final totalCurrentAmount =
        goalsViewModel.goals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
    final overallProgress =
        totalTargetAmount > 0 ? (totalCurrentAmount / totalTargetAmount) : 0.0;

    return Padding(
      padding: AppConstants.screenPaddingHorizontal,
      child: Column(
        children: [
          // Main Overview Card
          CustomCard(
            child: Padding(
              padding: AppConstants.containerPaddingLarge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Goals Overview',
                        style: TextStyle(
                          fontSize: AppConstants.textSizeXLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingMedium,
                          vertical: AppConstants.spacingXSmall,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: AppConstants.opacityOverlay),
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusLarge),
                        ),
                        child: Text(
                          '${goalsViewModel.goals.length}/$_maxActiveGoals Goals',
                          style: TextStyle(
                            fontSize: AppConstants.textSizeSmall,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppConstants.spacingMedium),

                  // Progress Bar
                  Container(
                    height: 8.h,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadiusLarge),
                      color: Colors.grey[300],
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: overallProgress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusLarge),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingMedium),

                  Text(
                    '${(overallProgress * 100).round()}% Complete',
                    style: TextStyle(
                      fontSize: AppConstants.textSizeSmall,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: AppConstants.spacingSmall),

          // Statistics Cards Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Saved',
                  CurrencyFormatter.formatAmount(totalCurrentAmount, 'MYR'),
                  Icons.savings_rounded,
                  AppTheme.successColor,
                ),
              ),
              SizedBox(width: AppConstants.spacingSmall),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Target',
                  CurrencyFormatter.formatAmount(totalTargetAmount, 'MYR'),
                  Icons.flag_rounded,
                  AppTheme.warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return CustomCard(
      child: Padding(
        padding: AppConstants.containerPaddingMedium,
        child: Column(
          children: [
            Icon(
              icon,
              size: AppConstants.iconSizeLarge,
              color: color,
            ),
            SizedBox(height: AppConstants.spacingSmall),
            Text(
              title,
              style: TextStyle(
                fontSize: AppConstants.textSizeSmall,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppConstants.spacingXSmall),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: AppConstants.textSizeSmall,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFundingSection(
      BuildContext context, GoalsViewModel goalsViewModel) {
    return Padding(
      padding: AppConstants.screenPaddingHorizontal,
      child: CustomCard(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            gradient: LinearGradient(
              colors: [
                AppTheme.successColor.withValues(alpha: 0.1),
                AppTheme.successColor.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: AppConstants.containerPaddingLarge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppConstants.spacingMedium),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppTheme.successColor,
                        size: AppConstants.iconSizeLarge,
                      ),
                    ),
                    SizedBox(width: AppConstants.spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Savings Available',
                            style: TextStyle(
                              fontSize: AppConstants.textSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatAmount(
                                goalsViewModel.availableSavings, 'MYR'),
                            style: TextStyle(
                              fontSize: AppConstants.textSizeXLarge,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppConstants.spacingLarge),
                Text(
                  'Fund your goals with last month\'s savings automatically allocated based on priority.',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeMedium,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: AppConstants.spacingLarge),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: goalsViewModel.isFundingGoals
                        ? null
                        : () =>
                            _showCustomFundingDialog(context, goalsViewModel),
                    icon: goalsViewModel.isFundingGoals
                        ? SizedBox(
                            width: AppConstants.iconSizeSmall,
                            height: AppConstants.iconSizeSmall,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.trending_up_rounded,
                            size: AppConstants.iconSizeMedium),
                    label: Text(
                      goalsViewModel.isFundingGoals
                          ? 'Allocating Savings...'
                          : 'Fund Goals',
                      style: TextStyle(
                        fontSize: AppConstants.textSizeLarge,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: AppConstants.spacingLarge,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusLarge),
                      ),
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

  Widget _buildRecommendationsSection(
      BuildContext context, GoalsViewModel goalsViewModel) {
    final recommendations = goalsViewModel.goalRecommendations;
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    final currency = di.sl<SettingsService>().currency;

    return Padding(
      padding: AppConstants.screenPaddingHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended For You',
            style: TextStyle(
              fontSize: AppConstants.textSizeXLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConstants.spacingMedium),
          ...recommendations.map((recommendation) {
            final deadline =
                DateTime.now().add(recommendation.suggestedDuration);
            final months =
                (recommendation.suggestedDuration.inDays / 30).round();
            return Padding(
              padding: AppConstants.cardMarginStandard,
              child: CustomCard(
                child: Padding(
                  padding: AppConstants.containerPaddingLarge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(AppConstants.spacingMedium),
                            decoration: BoxDecoration(
                              color: recommendation.icon.color.withValues(
                                  alpha: AppConstants.opacityOverlay),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              recommendation.icon.icon,
                              color: recommendation.icon.color,
                              size: AppConstants.iconSizeLarge,
                            ),
                          ),
                          SizedBox(width: AppConstants.spacingMedium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recommendation.title,
                                  style: TextStyle(
                                    fontSize: AppConstants.textSizeLarge,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: AppConstants.spacingXSmall),
                                Text(
                                  recommendation.description,
                                  style: TextStyle(
                                    fontSize: AppConstants.textSizeSmall,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppConstants.spacingMedium),
                      Wrap(
                        spacing: AppConstants.spacingSmall,
                        runSpacing: AppConstants.spacingSmall,
                        children: [
                          Chip(
                            label: Text(
                              'Target: ${CurrencyFormatter.formatAmount(recommendation.suggestedAmount, currency)}',
                              style: TextStyle(
                                fontSize: AppConstants.textSizeXSmall,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              'Timeline: ${months <= 1 ? '1 month' : '$months months'}',
                              style: TextStyle(
                                fontSize: AppConstants.textSizeXSmall,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              'Suggested deadline: ${DateFormat('MMM yyyy').format(deadline)}',
                              style: TextStyle(
                                fontSize: AppConstants.textSizeXSmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppConstants.spacingMedium),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showRecommendationDetails(
                                context,
                                recommendation,
                              ),
                              child: const Text('Why this suggestion?'),
                            ),
                          ),
                          SizedBox(width: AppConstants.spacingSmall),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _applyRecommendationTemplate(recommendation),
                              child: const Text('Use Template'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showRecommendationDetails(
      BuildContext context, GoalRecommendation recommendation) {
    DialogUtils.showInfoDialog(
      context,
      title: recommendation.title,
      message: recommendation.rationale,
    );
  }

  Future<void> _applyRecommendationTemplate(
      GoalRecommendation recommendation) async {
    final suggestedDeadline =
        DateTime.now().add(recommendation.suggestedDuration);

    await showGoalFormDialog(
      context: context,
      initialTitle: recommendation.title,
      initialTargetAmount: recommendation.suggestedAmount,
      initialDeadline: suggestedDeadline,
      initialIcon: recommendation.icon,
      onSave: (goal) async {
        final success = await _goalsViewModel.saveGoal(goal);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Goal "${goal.title}" created from template.'
                  : 'Unable to create goal from template.',
            ),
            backgroundColor: success
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        );
      },
    );
  }

  Widget _buildFinancialGoalsList(
      BuildContext context, GoalsViewModel goalsViewModel) {
    return Padding(
      padding: AppConstants.screenPaddingHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Goals',
            style: TextStyle(
              fontSize: AppConstants.textSizeXLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConstants.spacingMedium),
          ...goalsViewModel.goals.map((goal) {
            return Padding(
              padding: AppConstants.cardMarginStandard,
              child: GoalCard(
                goal: goal,
                onTap: () => _showGoalDetails(context, goal),
                onEdit: () => _showEditGoalDialog(goal),
                onDelete: () => _showDeleteConfirmation(goal),
                onComplete: () => _showCompleteConfirmation(goal),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAddGoalSection() {
    return Padding(
      padding: AppConstants.screenPaddingHorizontal,
      child: Column(
        children: [
          SizedBox(height: AppConstants.spacingMedium),
          SubmitButton(
            text: 'Add New Goal',
            isLoading: false,
            icon: Icons.add_circle,
            color: Theme.of(context).colorScheme.primary,
            height: 50,
            onPressed: _showAddGoalDialog,
          ),
          // Add extra spacing to prevent FAB overlap
          SizedBox(height: AppConstants.spacingXXLarge),
        ],
      ),
    );
  }

  Future<void> _handleAllocateSavings(GoalsViewModel goalsVM) async {
    if (!mounted || goalsVM.isFundingGoals) {
      return;
    }

    if (goalsVM.availableSavings <= 0) {
      DialogUtils.showInfoDialog(
        context,
        title: 'No Savings Available',
        message:
            'There are no surplus savings to allocate right now. Try refreshing after tracking new expenses or closing the month.',
      );
      return;
    }

    final distribution = await goalsVM.previewFundingDistribution();
    if (!mounted) {
      return;
    }

    if (distribution.isEmpty) {
      DialogUtils.showInfoDialog(
        context,
        title: 'Allocation Not Required',
        message:
            'Great news! Your active goals are already fully funded with the current savings.',
      );
      return;
    }

    await showFundingPreviewDialog(
      context: context,
      availableSavings: goalsVM.availableSavings,
      distribution: distribution,
      goals: goalsVM.goals,
      onConfirm: () async {
        final success = await goalsVM.allocateSavingsToGoals();
        if (!mounted) {
          return;
        }

        final messenger = ScaffoldMessenger.of(context);
        if (success) {
          messenger.showSnackBar(
            SnackBar(
              content: const Text('Savings allocated to your goals.'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          await goalsVM.init(force: true);
          setState(() {});
        } else {
          messenger.showSnackBar(
            SnackBar(
              content:
                  Text(goalsVM.errorMessage ?? 'Unable to allocate savings'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
    );
  }

  // Dialog and interaction methods
  void _showCustomFundingDialog(
      BuildContext context, GoalsViewModel goalsViewModel) {
    final TextEditingController amountController = TextEditingController();
    final double maxAmount = goalsViewModel.availableSavings;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        child: Padding(
          padding: AppConstants.containerPaddingLarge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppTheme.successColor,
                    size: AppConstants.iconSizeLarge,
                  ),
                  SizedBox(width: AppConstants.spacingMedium),
                  Expanded(
                    child: Text(
                      'Fund Your Goals',
                      style: TextStyle(
                        fontSize: AppConstants.textSizeXLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppConstants.spacingXLarge),

              // Available amount info
              Container(
                padding: AppConstants.containerPaddingMedium,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available:',
                      style: TextStyle(
                        fontSize: AppConstants.textSizeMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatAmount(maxAmount, 'MYR'),
                      style: TextStyle(
                        fontSize: AppConstants.textSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppConstants.spacingLarge),

              // Amount input
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount to Allocate',
                  hintText: 'Enter amount to distribute to goals',
                  prefixText: 'RM ',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadiusMedium),
                  ),
                ),
              ),
              SizedBox(height: AppConstants.spacingMedium),

              // Quick amount buttons
              Row(
                children: [
                  _buildQuickAmountButton(
                      amountController, maxAmount * 0.25, '25%'),
                  SizedBox(width: AppConstants.spacingSmall),
                  _buildQuickAmountButton(
                      amountController, maxAmount * 0.5, '50%'),
                  SizedBox(width: AppConstants.spacingSmall),
                  _buildQuickAmountButton(
                      amountController, maxAmount * 0.75, '75%'),
                  SizedBox(width: AppConstants.spacingSmall),
                  _buildQuickAmountButton(amountController, maxAmount, 'All'),
                ],
              ),
              SizedBox(height: AppConstants.spacingLarge),

              // Info text
              Text(
                'Amount will be distributed among your goals based on their priority and urgency.',
                style: TextStyle(
                  fontSize: AppConstants.textSizeSmall,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppConstants.spacingXLarge),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: AppConstants.textSizeMedium),
                      ),
                    ),
                  ),
                  SizedBox(width: AppConstants.spacingMedium),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final amount = double.tryParse(amountController.text);
                        if (amount != null &&
                            amount > 0 &&
                            amount <= maxAmount) {
                          Navigator.pop(context);
                          _allocateCustomAmount(
                              context, goalsViewModel, amount);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        padding: EdgeInsets.symmetric(
                          vertical: AppConstants.spacingMedium,
                        ),
                      ),
                      child: Text(
                        'Preview Distribution',
                        style: TextStyle(fontSize: AppConstants.textSizeMedium),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(
      TextEditingController controller, double amount, String label) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          controller.text = amount.toStringAsFixed(2);
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSmall),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: AppConstants.textSizeSmall),
        ),
      ),
    );
  }

  Future<void> _allocateCustomAmount(BuildContext context,
      GoalsViewModel goalsViewModel, double amount) async {
    // Capture context locally and guard with both State and BuildContext mounted
    final ctx = context;

    final distribution =
        await goalsViewModel.previewCustomFundingDistribution(amount);

    if (!mounted || !ctx.mounted) return;

    if (distribution.isEmpty) {
      DialogUtils.showInfoDialog(
        ctx,
        title: 'No Allocation Possible',
        message: 'Unable to allocate the specified amount to your goals.',
      );
      return;
    }

    // Show enhanced funding preview dialog
    if (!mounted || !ctx.mounted) return;
    showFundingPreviewDialog(
      context: ctx,
      availableSavings: amount,
      distribution: distribution,
      goals: goalsViewModel.goals,
      onConfirm: () async {
        final success =
            await goalsViewModel.allocateCustomSavingsToGoals(amount);
        if (!mounted || !ctx.mounted) return;
        _showFundingResult(ctx, success, amount, goalsViewModel.errorMessage);
      },
    );
  }

  void _showFundingResult(
      BuildContext context, bool success, double amount, String? errorMessage) {
    final ctx = context;
    if (!mounted || !ctx.mounted) return;
    if (success) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully allocated ${CurrencyFormatter.formatAmount(amount, 'MYR')} to your goals!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Failed to allocate savings'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          ),
        ),
      );
    }
  }

  void _showGoalDetails(BuildContext context, FinancialGoal goal) {
    DialogUtils.showInfoDialog(
      context,
      title: goal.title,
      message:
          'Target: ${CurrencyFormatter.formatAmount(goal.targetAmount, 'MYR')}\n'
          'Current: ${CurrencyFormatter.formatAmount(goal.currentAmount, 'MYR')}\n'
          'Progress: ${goal.progressPercentage}%\n'
          'Days remaining: ${goal.daysRemaining}',
    );
  }

  void _showEditGoalDialog(FinancialGoal goal) {
    showGoalFormDialog(
      context: context,
      goal: goal,
      onSave: (updatedGoal) async {
        await _goalsViewModel.updateGoal(updatedGoal);
      },
    );
  }

  void _showDeleteConfirmation(FinancialGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        contentPadding: AppConstants.containerPaddingLarge,
        title: Text(
          'Delete Goal',
          style: TextStyle(
            fontSize: AppConstants.textSizeXLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${goal.title}"? This action cannot be undone.',
          style: TextStyle(
            fontSize: AppConstants.textSizeMedium,
            height: 1.4,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(
              left: AppConstants.spacingLarge,
              right: AppConstants.spacingLarge,
              bottom: AppConstants.spacingLarge,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: AppConstants.spacingLarge,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusLarge,
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: AppConstants.textSizeMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppConstants.spacingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _goalsViewModel.deleteGoal(goal.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      padding: EdgeInsets.symmetric(
                        vertical: AppConstants.spacingLarge,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusLarge,
                        ),
                      ),
                    ),
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: AppConstants.textSizeMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteConfirmation(FinancialGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        contentPadding: AppConstants.containerPaddingLarge,
        title: Text(
          'Complete Goal',
          style: TextStyle(
            fontSize: AppConstants.textSizeXLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Mark "${goal.title}" as completed? It will be moved to your goal history.',
          style: TextStyle(
            fontSize: AppConstants.textSizeMedium,
            height: 1.4,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(
              left: AppConstants.spacingLarge,
              right: AppConstants.spacingLarge,
              bottom: AppConstants.spacingLarge,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: AppConstants.spacingLarge,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusLarge,
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: AppConstants.textSizeMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppConstants.spacingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _goalsViewModel.completeGoal(goal.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: EdgeInsets.symmetric(
                        vertical: AppConstants.spacingLarge,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusLarge,
                        ),
                      ),
                    ),
                    child: Text(
                      'Complete',
                      style: TextStyle(
                        fontSize: AppConstants.textSizeMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
