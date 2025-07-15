import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode

import '../viewmodels/analysis_viewmodel.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import 'submit_button.dart';

/// AI Analysis Dialog showing spending behavior analysis in modern UI sections
class AIAnalysisDialog extends StatefulWidget {
  final DateTime selectedDate;
  final AnalysisViewModel analysisViewModel;

  const AIAnalysisDialog({
    super.key,
    required this.selectedDate,
    required this.analysisViewModel,
  });

  @override
  State<AIAnalysisDialog> createState() => _AIAnalysisDialogState();
}

class _AIAnalysisDialogState extends State<AIAnalysisDialog>
    with SingleTickerProviderStateMixin {
  bool _isAnalysisStarted = false;
  bool _hasLoadedPreviousAnalysis = false;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    // Load previous analysis if available
    _loadPreviousAnalysis();
  }

  void _initializeTabController() {
    _tabController = TabController(length: 2, vsync: this);
    // Add listener to update bottom actions when tab changes
    _tabController?.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// Load previous analysis from local database
  Future<void> _loadPreviousAnalysis() async {
    if (!mounted) return;

    try {
      // Check if there's a previous analysis
      final hasPrevious = await widget.analysisViewModel.hasPreviousAnalysis();
      if (hasPrevious && mounted) {
        // Load the previous analysis
        await widget.analysisViewModel.loadLatestAnalysis();
        if (mounted) {
          setState(() {
            _hasLoadedPreviousAnalysis = true;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading previous analysis: $e');
      }
      // Don't show error for loading previous analysis, just continue without it
      if (mounted) {
        setState(() {
          _hasLoadedPreviousAnalysis = false;
        });
      }
    }
  }

  /// Start the full AI analysis
  Future<void> _performAnalysis() async {
    if (!mounted) return;

    setState(() {
      _isAnalysisStarted = true;
      _hasLoadedPreviousAnalysis = false; // Reset previous analysis state
    });

    try {
      // Clear previous results first
      widget.analysisViewModel.clearResults();

      // Defer the analysis call to after the build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.analysisViewModel.performFullAnalysis(
            selectedDate: widget.selectedDate,
          );
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error starting analysis: $e');
      }
      if (mounted) {
        setState(() {
          _isAnalysisStarted = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(AppConstants.spacingLarge.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor.withValues(alpha: 1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.fromLTRB(
                AppConstants.spacingLarge.w,
                AppConstants.spacingLarge.h,
                AppConstants.spacingMedium.w,
                AppConstants.spacingMedium.h,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1.w,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  SizedBox(height: AppConstants.spacingMedium.h),
                  _buildSubtitle(),
                ],
              ),
            ),

            // Main Content Section
            Expanded(
              child: Container(
                padding: EdgeInsets.all(AppConstants.spacingLarge.w),
                child: Consumer<AnalysisViewModel>(
                  builder: (context, analysisViewModel, child) {
                    return _buildMainContent(analysisViewModel);
                  },
                ),
              ),
            ),

            // Bottom Actions Section
            Container(
              padding: EdgeInsets.all(AppConstants.spacingLarge.w),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1.w,
                  ),
                ),
              ),
              child: Consumer<AnalysisViewModel>(
                builder: (context, analysisViewModel, child) {
                  return _buildBottomActions(analysisViewModel);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build dialog header
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppConstants.spacingSmall.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(30),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadiusSmall.r),
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  size: AppConstants.iconSizeMedium.sp,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: AppConstants.spacingMedium.w),
              Expanded(
                child: Text(
                  'AI Financial Analysis',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeXLarge.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: AppConstants.spacingMedium.w),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.close,
            size: AppConstants.iconSizeMedium.sp,
            color: Theme.of(context).iconTheme.color,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surface,
            padding: EdgeInsets.all(AppConstants.spacingSmall.w),
            minimumSize: Size(44.w, 44.h),
          ),
        ),
      ],
    );
  }

  /// Build subtitle
  Widget _buildSubtitle() {
    return Text(
      'Get personalized insights about your spending behavior and budget optimization recommendations.',
      style: TextStyle(
        fontSize: AppConstants.textSizeMedium.sp,
        color: Theme.of(context).textTheme.bodyMedium?.color,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Build main content based on state
  Widget _buildMainContent(AnalysisViewModel analysisViewModel) {
    if (!_isAnalysisStarted && !_hasLoadedPreviousAnalysis) {
      return _buildInitialState();
    }

    if (_hasLoadedPreviousAnalysis && !_isAnalysisStarted) {
      return _buildPreviousAnalysisState(analysisViewModel);
    }

    if (analysisViewModel.isLoading) {
      return _buildLoadingState(analysisViewModel);
    }

    if (analysisViewModel.errorMessage != null) {
      return _buildErrorState(analysisViewModel.errorMessage!);
    }

    return _buildAnalysisResultsState(analysisViewModel);
  }

  /// Build initial state before analysis
  Widget _buildInitialState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppConstants.spacingXLarge.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 64.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: AppConstants.spacingXLarge.h),
            Text(
              'Ready to Analyze Your Finances',
              style: TextStyle(
                fontSize: AppConstants.textSizeXLarge.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.spacingMedium.h),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: AppConstants.spacingLarge.w),
              child: Text(
                'Our AI will analyze your spending patterns, budget utilization, and provide personalized recommendations to optimize your financial health.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppConstants.textSizeMedium.sp,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build previous analysis state
  Widget _buildPreviousAnalysisState(AnalysisViewModel analysisViewModel) {
    return Column(
      children: [
        // Previous analysis indicator
        Container(
          padding: AppConstants.containerPaddingMedium,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withAlpha(20),
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusMedium.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.secondary.withAlpha(40),
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.history,
                color: Theme.of(context).colorScheme.secondary,
                size: AppConstants.iconSizeMedium.sp,
              ),
              SizedBox(width: AppConstants.spacingMedium.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Previous Analysis Results',
                      style: TextStyle(
                        fontSize: AppConstants.textSizeLarge.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    SizedBox(height: AppConstants.spacingXSmall.h),
                    Text(
                      'Showing your latest financial analysis. Run a new analysis to get updated insights.',
                      style: TextStyle(
                        fontSize: AppConstants.textSizeSmall.sp,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: AppConstants.spacingLarge.h),

        // Previous analysis content
        Expanded(
          child: _buildAnalysisResultsContent(analysisViewModel),
        ),
      ],
    );
  }

  /// Build loading state
  Widget _buildLoadingState(AnalysisViewModel analysisViewModel) {
    String title = 'Processing Your Financial Data';
    String description =
        'Please wait while we analyze your financial information...';

    if (analysisViewModel.isCheckingHealth) {
      title = 'Connecting to AI Services';
      description =
          'Verifying that our AI analysis services are available and ready to process your data.';
    } else if (analysisViewModel.isAnalyzing) {
      title = 'Analyzing Spending Patterns';
      description =
          'Our AI is examining your spending behavior, budget utilization, and financial habits.';
    } else if (analysisViewModel.isReallocating) {
      title = 'Generating Smart Recommendations';
      description =
          'Creating personalized budget optimization suggestions based on your financial data.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(10),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(
                width: 80.w,
                height: 80.w,
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 4.w,
                ),
              ),
              Icon(
                Icons.analytics_outlined,
                size: 32.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingXLarge.h),
          Text(
            title,
            style: TextStyle(
              fontSize: AppConstants.textSizeXLarge.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          SizedBox(height: AppConstants.spacingMedium.h),
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: AppConstants.spacingXLarge.w),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppConstants.textSizeMedium.sp,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppConstants.spacingXLarge.w),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64.sp,
                color: Colors.red[400],
              ),
            ),
            SizedBox(height: AppConstants.spacingXLarge.h),
            Text(
              'Analysis Failed',
              style: TextStyle(
                fontSize: AppConstants.textSizeXLarge.sp,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.spacingMedium.h),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: AppConstants.spacingLarge.w),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppConstants.textSizeMedium.sp,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build analysis results state
  Widget _buildAnalysisResultsState(AnalysisViewModel analysisViewModel) {
    return Column(
      children: [
        // Success indicator
        Container(
          padding: AppConstants.containerPaddingMedium,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withAlpha(20),
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusMedium.r),
            border: Border.all(
              color: AppTheme.successColor.withAlpha(40),
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppTheme.successColor,
                size: AppConstants.iconSizeMedium.sp,
              ),
              SizedBox(width: AppConstants.spacingMedium.w),
              Expanded(
                child: Text(
                  'Analysis completed successfully! Review your personalized insights below.',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeMedium.sp,
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: AppConstants.spacingLarge.h),

        // Analysis content
        Expanded(
          child: _buildAnalysisResultsContent(analysisViewModel),
        ),
      ],
    );
  }

  /// Build analysis results content with tabs
  Widget _buildAnalysisResultsContent(AnalysisViewModel analysisViewModel) {
    // Return loading state if TabController is not initialized
    if (_tabController == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Custom tab bar
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusMedium.r),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1.w,
            ),
          ),
          child: TabBar(
            controller: _tabController!,
            labelColor: Colors.white,
            unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
            indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusMedium.r),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: EdgeInsets.all(AppConstants.spacingXSmall.w),
            dividerColor: Colors.transparent,
            labelStyle: TextStyle(
              fontSize: AppConstants.textSizeMedium.sp,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: AppConstants.textSizeMedium.sp,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMedium.w,
                    vertical: AppConstants.spacingSmall.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined,
                          size: AppConstants.iconSizeSmall.sp),
                      SizedBox(width: AppConstants.spacingSmall.w),
                      const Flexible(
                        child: Text(
                          'Spending Analysis',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Tab(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMedium.w,
                    vertical: AppConstants.spacingSmall.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swap_horiz,
                          size: AppConstants.iconSizeSmall.sp),
                      SizedBox(width: AppConstants.spacingSmall.w),
                      const Flexible(
                        child: Text(
                          'Budget Reallocation',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: AppConstants.spacingLarge.h),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController!,
            children: [
              _buildSpendingAnalysisTab(analysisViewModel),
              _buildBudgetReallocationTab(analysisViewModel),
            ],
          ),
        ),
      ],
    );
  }

  /// Build spending analysis tab content
  Widget _buildSpendingAnalysisTab(AnalysisViewModel analysisViewModel) {
    return _buildAnalysisContent(analysisViewModel);
  }

  /// Build budget reallocation tab content
  Widget _buildBudgetReallocationTab(AnalysisViewModel analysisViewModel) {
    if (analysisViewModel.reallocationResult == null) {
      return _buildEmptyReallocationState();
    }

    return _buildReallocationContent(analysisViewModel);
  }

  /// Build empty reallocation state
  Widget _buildEmptyReallocationState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(AppConstants.spacingXLarge.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.trending_up,
              size: 48.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: AppConstants.spacingXLarge.h),
          Text(
            'No Budget Reallocation Needed',
            style: TextStyle(
              fontSize: AppConstants.textSizeLarge.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          SizedBox(height: AppConstants.spacingMedium.h),
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: AppConstants.spacingXLarge.w),
            child: Text(
              'Your current budget allocation appears to be well-optimized. No reallocation suggestions are available at this time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppConstants.textSizeMedium.sp,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build analysis content with sections
  Widget _buildAnalysisContent(AnalysisViewModel analysisViewModel) {
    final result = analysisViewModel.spendingAnalysisResult;
    if (result == null) {
      return Center(
        child: Text(
          'No analysis data available',
          style: TextStyle(
            fontSize: AppConstants.textSizeMedium.sp,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Executive Summary Section
          _buildSummarySection(result.summary),
          SizedBox(height: AppConstants.spacingLarge.h),

          // Key Insights Section
          _buildKeyInsightsSection(result.keyInsights),
          SizedBox(height: AppConstants.spacingLarge.h),

          // Category Analysis Section
          _buildCategoryAnalysisSection(result.categoryInsights),
          SizedBox(height: AppConstants.spacingLarge.h),

          // Recommendations Section
          _buildRecommendationsSection(result.actionableRecommendations),
        ],
      ),
    );
  }

  /// Build budget reallocation content
  Widget _buildReallocationContent(AnalysisViewModel analysisViewModel) {
    final result = analysisViewModel.reallocationResult;
    if (result == null || result.suggestions.isEmpty) {
      return _buildEmptyReallocationState();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Suggestions header
          _buildSection(
            title: 'Budget Reallocation Suggestions',
            icon: Icons.swap_horiz,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Based on your spending patterns, here are some budget adjustments that could help optimize your financial allocation:',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeMedium.sp,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: AppConstants.spacingLarge.h),
                ...result.suggestions
                    .map((suggestion) => _buildSuggestionItem(suggestion)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build summary section
  Widget _buildSummarySection(String summary) {
    return _buildSection(
      title: 'Executive Summary',
      icon: Icons.summarize,
      child: Text(
        summary,
        style: TextStyle(
          fontSize: AppConstants.textSizeMedium.sp,
          color: Theme.of(context).textTheme.bodyMedium?.color,
          height: 1.5,
        ),
      ),
    );
  }

  /// Build key insights section
  Widget _buildKeyInsightsSection(List<String> insights) {
    return _buildSection(
      title: 'Key Insights',
      icon: Icons.lightbulb,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            insights.map((insight) => _buildInsightItem(insight)).toList(),
      ),
    );
  }

  /// Build category analysis section
  Widget _buildCategoryAnalysisSection(List<dynamic> categoryInsights) {
    return _buildSection(
      title: 'Category Analysis',
      icon: Icons.pie_chart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categoryInsights
            .map((insight) => _buildCategoryItem(insight))
            .toList(),
      ),
    );
  }

  /// Build recommendations section
  Widget _buildRecommendationsSection(List<String> recommendations) {
    return _buildSection(
      title: 'Actionable Recommendations',
      icon: Icons.recommend,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: recommendations
            .map((recommendation) => _buildRecommendationItem(recommendation))
            .toList(),
      ),
    );
  }

  /// Build a generic section container
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1.w,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: AppConstants.containerPaddingMedium,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadiusMedium.r),
                topRight: Radius.circular(AppConstants.borderRadiusMedium.r),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: AppConstants.iconSizeMedium.sp,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: AppConstants.spacingMedium.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppConstants.textSizeLarge.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
              ],
            ),
          ),

          // Section content
          Container(
            width: double.infinity,
            padding: AppConstants.containerPaddingMedium,
            child: child,
          ),
        ],
      ),
    );
  }

  /// Build insight item
  Widget _buildInsightItem(String insight) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacingMedium.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h),
            width: 6.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppConstants.spacingMedium.w),
          Expanded(
            child: Text(
              insight,
              style: TextStyle(
                fontSize: AppConstants.textSizeMedium.sp,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build category item
  Widget _buildCategoryItem(dynamic categoryInsight) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spacingMedium.h),
      padding: AppConstants.containerPaddingMedium,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .cardColor
            .withAlpha((255 * AppConstants.opacityLow).toInt()),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryInsight.categoryName ?? 'Unknown Category',
                style: TextStyle(
                  fontSize: AppConstants.textSizeMedium.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingSmall.w,
                  vertical: AppConstants.spacingXSmall.h,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(categoryInsight.status),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadiusSmall.r),
                ),
                child: Text(
                  categoryInsight.status ?? 'Unknown',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeSmall.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingSmall.h),
          Text(
            'Spent: ${categoryInsight.spentAmount?.toStringAsFixed(2) ?? '0.00'} / Budget: ${categoryInsight.budgetAmount?.toStringAsFixed(2) ?? '0.00'}',
            style: TextStyle(
              fontSize: AppConstants.textSizeSmall.sp,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          SizedBox(height: AppConstants.spacingSmall.h),
          LinearProgressIndicator(
            value: (categoryInsight.utilizationRate ?? 0.0).clamp(0.0, 1.0),
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getStatusColor(categoryInsight.status),
            ),
          ),
          SizedBox(height: AppConstants.spacingSmall.h),
          Text(
            categoryInsight.insight ?? 'No insight available',
            style: TextStyle(
              fontSize: AppConstants.textSizeSmall.sp,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Build recommendation item
  Widget _buildRecommendationItem(String recommendation) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spacingMedium.h),
      padding: AppConstants.containerPaddingMedium,
      decoration: BoxDecoration(
        color: AppTheme.successColor
            .withAlpha((255 * AppConstants.opacityLow).toInt()),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall.r),
        border: Border.all(
          color: AppTheme.successColor
              .withAlpha((255 * AppConstants.opacityMedium).toInt()),
          width: 1.w,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: AppConstants.iconSizeSmall.sp,
            color: AppTheme.successColor,
          ),
          SizedBox(width: AppConstants.spacingMedium.w),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(
                fontSize: AppConstants.textSizeMedium.sp,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build budget reallocation suggestion item
  Widget _buildSuggestionItem(dynamic suggestion) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spacingLarge.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha(30),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with amount and criticality
          Container(
            padding: AppConstants.containerPaddingMedium,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(15),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadiusLarge.r),
                topRight: Radius.circular(AppConstants.borderRadiusLarge.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: AppConstants.textSizeSmall.sp,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: AppConstants.spacingSmall.h),
                    Text(
                      'RM ${suggestion.amount?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontSize: AppConstants.textSizeXLarge.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMedium.w,
                    vertical: AppConstants.spacingSmall.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getCriticalityColor(suggestion.criticality),
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadiusLarge.r),
                  ),
                  child: Text(
                    suggestion.criticality?.toUpperCase() ?? 'MEDIUM',
                    style: TextStyle(
                      fontSize: AppConstants.textSizeSmall.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: AppConstants.containerPaddingMedium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transfer visualization
                Row(
                  children: [
                    // From category
                    Expanded(
                      child: Container(
                        padding: AppConstants.containerPaddingMedium,
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusMedium.r),
                          border:
                              Border.all(color: Colors.red[200]!, width: 1.w),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From',
                              style: TextStyle(
                                fontSize: AppConstants.textSizeMedium.sp,
                                color: Colors.red[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: AppConstants.spacingSmall.h),
                            Text(
                              suggestion.fromCategory ?? 'Unknown',
                              style: TextStyle(
                                fontSize: AppConstants.textSizeMedium.sp,
                                color: Colors.red[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Enhanced arrow
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingMedium.w),
                      child: Container(
                        padding: EdgeInsets.all(AppConstants.spacingSmall.w),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: AppConstants.iconSizeSmall.sp,
                        ),
                      ),
                    ),

                    // To category
                    Expanded(
                      child: Container(
                        padding: AppConstants.containerPaddingMedium,
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusMedium.r),
                          border:
                              Border.all(color: Colors.green[200]!, width: 1.w),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To',
                              style: TextStyle(
                                fontSize: AppConstants.textSizeMedium.sp,
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: AppConstants.spacingSmall.h),
                            Text(
                              suggestion.toCategory ?? 'Unknown',
                              style: TextStyle(
                                fontSize: AppConstants.textSizeMedium.sp,
                                color: Colors.green[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppConstants.spacingLarge.h),

                // Reason section
                Container(
                  width: double.infinity,
                  padding: AppConstants.containerPaddingMedium,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium.r),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1.w,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: AppConstants.iconSizeSmall.sp,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: AppConstants.spacingSmall.w),
                          Text(
                            'Reason',
                            style: TextStyle(
                              fontSize: AppConstants.textSizeMedium.sp,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppConstants.spacingMedium.h),
                      Text(
                        suggestion.reason ?? 'No reason provided',
                        style: TextStyle(
                          fontSize: AppConstants.textSizeMedium.sp,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get criticality color based on suggestion criticality
  Color _getCriticalityColor(String? criticality) {
    switch (criticality?.toLowerCase()) {
      case 'high':
        return Colors.red[600]!;
      case 'medium':
        return Colors.orange[600]!;
      case 'low':
        return Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  /// Get status color based on category status
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'over_budget':
        return Colors.red[600]!;
      case 'near_limit':
        return Colors.orange[600]!;
      case 'on_track':
        return Colors.green[600]!;
      case 'under_budget':
        return Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  /// Build secondary button with consistent styling
  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, 48.h),
        maximumSize: Size(double.infinity, 48.h),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1.w,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.borderRadiusMedium.r),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMedium.w,
          vertical: AppConstants.spacingSmall.h,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppConstants.iconSizeSmall.sp,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            SizedBox(width: AppConstants.spacingSmall.w),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppConstants.textSizeMedium.sp,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Build bottom action buttons
  Widget _buildBottomActions(AnalysisViewModel analysisViewModel) {
    if (!_isAnalysisStarted && !_hasLoadedPreviousAnalysis) {
      return _buildInitialActions();
    }

    if (_hasLoadedPreviousAnalysis && !_isAnalysisStarted) {
      return _buildPreviousAnalysisActions(analysisViewModel);
    }

    if (analysisViewModel.isLoading) {
      return _buildLoadingActions();
    }

    if (analysisViewModel.errorMessage != null) {
      return _buildErrorActions();
    }

    // After analysis completion - show contextual actions based on current tab
    return _buildCompletedAnalysisActions(analysisViewModel);
  }

  /// Build initial state actions
  Widget _buildInitialActions() {
    return Row(
      children: [
        Expanded(
          child: _buildSecondaryButton(
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icons.close,
          ),
        ),
        SizedBox(width: AppConstants.spacingMedium.w),
        Expanded(
          flex: 2,
          child: SubmitButton(
            text: 'Start Analysis',
            isLoading: false,
            onPressed: _performAnalysis,
            icon: Icons.analytics_outlined,
            height: 48.0.h,
          ),
        ),
      ],
    );
  }

  /// Build previous analysis state actions
  Widget _buildPreviousAnalysisActions(AnalysisViewModel analysisViewModel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show apply suggestions button if on reallocation tab and has suggestions
        if (_tabController?.index == 1 &&
            analysisViewModel.reallocationResult != null &&
            analysisViewModel.reallocationResult!.suggestions.isNotEmpty) ...[
          SizedBox(
            width: double.infinity,
            child: SubmitButton(
              text: 'Apply All Suggestions',
              isLoading: analysisViewModel.isReallocating,
              loadingText: 'Applying Changes...',
              onPressed: () => _applyBudgetSuggestions(analysisViewModel),
              icon: Icons.check_circle_outline,
              height: 48.0.h,
            ),
          ),
          SizedBox(height: AppConstants.spacingMedium.h),
        ],

        // Main action buttons
        Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                text: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icons.close,
              ),
            ),
            SizedBox(width: AppConstants.spacingMedium.w),
            Expanded(
              child: SubmitButton(
                text: 'New Analysis',
                isLoading: false,
                onPressed: _performAnalysis,
                icon: Icons.refresh,
                height: 48.0.h,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build loading state actions
  Widget _buildLoadingActions() {
    return _buildSecondaryButton(
      text: 'Cancel',
      onPressed: () => Navigator.of(context).pop(),
      icon: Icons.close,
    );
  }

  /// Build error state actions
  Widget _buildErrorActions() {
    return Row(
      children: [
        Expanded(
          child: SubmitButton(
            text: 'Retry Analysis',
            isLoading: false,
            onPressed: _performAnalysis,
            icon: Icons.refresh,
            height: 48.0.h,
          ),
        ),
        SizedBox(width: AppConstants.spacingMedium.w),
        Expanded(
          child: _buildSecondaryButton(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icons.close,
          ),
        ),
      ],
    );
  }

  /// Build completed analysis state actions
  Widget _buildCompletedAnalysisActions(AnalysisViewModel analysisViewModel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show apply suggestions button if on reallocation tab and has suggestions
        if (_tabController?.index == 1 &&
            analysisViewModel.reallocationResult != null &&
            analysisViewModel.reallocationResult!.suggestions.isNotEmpty) ...[
          SizedBox(
            width: double.infinity,
            child: SubmitButton(
              text: 'Apply All Suggestions',
              isLoading: analysisViewModel.isReallocating,
              loadingText: 'Applying Changes...',
              onPressed: () => _applyBudgetSuggestions(analysisViewModel),
              icon: Icons.check_circle_outline,
              height: 48.0.h,
            ),
          ),
          SizedBox(height: AppConstants.spacingMedium.h),
        ],

        // Main action buttons
        Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                text: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icons.close,
              ),
            ),
            SizedBox(width: AppConstants.spacingMedium.w),
            Expanded(
              child: SubmitButton(
                text: 'New Analysis',
                isLoading: false,
                onPressed: _performAnalysis,
                icon: Icons.refresh,
                height: 48.0.h,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Apply budget suggestions
  Future<void> _applyBudgetSuggestions(
      AnalysisViewModel analysisViewModel) async {
    if (!mounted) return;

    try {
      final success = await analysisViewModel.applyBudgetRecommendations(
        selectedDate: widget.selectedDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    success
                        ? 'Budget recommendations applied successfully!'
                        : 'Failed to apply recommendations. Please try again.',
                  ),
                ),
              ],
            ),
            backgroundColor: success
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );

        if (success) {
          // Close dialog after successful application
          Navigator.of(context)
              .pop(true); // Return true to indicate changes were made
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error applying budget suggestions: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error applying suggestions: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
