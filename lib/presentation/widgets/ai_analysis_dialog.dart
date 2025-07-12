import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../viewmodels/analysis_viewmodel.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import 'submit_button.dart';

/// AI Analysis Dialog showing both spending behavior and budget reallocation analysis
class AIAnalysisDialog extends StatefulWidget {
  final DateTime selectedDate;
  final AnalysisViewModel analysisViewModel;

  const AIAnalysisDialog({
    Key? key,
    required this.selectedDate,
    required this.analysisViewModel,
  }) : super(key: key);

  @override
  State<AIAnalysisDialog> createState() => _AIAnalysisDialogState();
}

class _AIAnalysisDialogState extends State<AIAnalysisDialog> {
  bool _isAnalysisStarted = false;

  @override
  void initState() {
    super.initState();
    // Defer clearing results until after the build cycle is complete
    // to prevent "setState() or markNeedsBuild() called during build" errors.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.analysisViewModel.clearResults();
      }
    });
  }

  /// Start the full AI analysis
  Future<void> _performAnalysis() async {
    if (!mounted) return;

    setState(() {
      _isAnalysisStarted = true;
    });

    // Defer the analysis call to after the build is complete
    // to avoid "setState() or markNeedsBuild() called during build" errors.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.analysisViewModel.performFullAnalysis(
          selectedDate: widget.selectedDate,
        );
      }
    });
  }

  /// Copy text to clipboard
  void _copyToClipboard(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$type copied to clipboard',
          style: TextStyle(fontSize: AppConstants.textSizeSmall.sp),
        ),
        duration: AppConstants.animationDurationMedium,
      ),
    );
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
        height: MediaQuery.of(context).size.height * 0.85,
        padding: AppConstants.containerPaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Financial Analysis',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeXLarge.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    size: AppConstants.iconSizeMedium.sp,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConstants.spacingMedium.h),

            // Subtitle
            Text(
              'Generate personalized insights about your spending behavior and get budget optimization recommendations.',
              style: TextStyle(
                fontSize: AppConstants.textSizeMedium.sp,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),

            SizedBox(height: AppConstants.spacingLarge.h),

            // Main Content
            Expanded(
              child: Consumer<AnalysisViewModel>(
                builder: (context, analysisViewModel, child) {
                  if (!_isAnalysisStarted) {
                    return _buildInitialState();
                  }

                  if (analysisViewModel.isLoading) {
                    return _buildLoadingState();
                  }

                  if (analysisViewModel.errorMessage != null) {
                    return _buildErrorState(analysisViewModel.errorMessage!);
                  }

                  return _buildResultsState(analysisViewModel);
                },
              ),
            ),

            // Bottom Actions
            Consumer<AnalysisViewModel>(
              builder: (context, analysisViewModel, child) {
                return _buildBottomActions(analysisViewModel);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build initial state before analysis
  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology,
            size: 64.sp,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: AppConstants.spacingLarge.h),
          Text(
            'Ready to Analyze',
            style: TextStyle(
              fontSize: AppConstants.textSizeXLarge.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          SizedBox(height: AppConstants.spacingMedium.h),
          Text(
            'Click "Start Analysis" to generate AI-powered insights about your spending patterns and budget optimization.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppConstants.textSizeMedium.sp,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading state during analysis
  Widget _buildLoadingState() {
    return Consumer<AnalysisViewModel>(
      builder: (context, analysisViewModel, child) {
        String title;
        String description;

        if (analysisViewModel.isCheckingHealth) {
          title = 'Checking Server Status';
          description =
              'Verifying that the AI analysis services are available and ready to process your data.';
        } else if (analysisViewModel.isAnalyzing) {
          title = 'Analyzing Spending Behavior';
          description =
              'Our AI is examining your spending patterns, budget utilization, and financial habits to provide personalized insights.';
        } else if (analysisViewModel.isReallocating) {
          title = 'Generating Budget Recommendations';
          description =
              'Creating intelligent budget reallocation suggestions based on your spending behavior analysis.';
        } else {
          title = 'Analyzing Your Financial Data';
          description =
              'Our AI is examining your spending patterns, budget utilization, and financial goals to provide personalized insights.';
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 3.w,
              ),
              SizedBox(height: AppConstants.spacingLarge.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppConstants.textSizeXLarge.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              SizedBox(height: AppConstants.spacingMedium.h),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppConstants.textSizeMedium.sp,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build error state
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: Colors.red[400],
          ),
          SizedBox(height: AppConstants.spacingLarge.h),
          Text(
            'Analysis Failed',
            style: TextStyle(
              fontSize: AppConstants.textSizeXLarge.sp,
              fontWeight: FontWeight.w600,
              color: Colors.red[400],
            ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build results state showing analysis panels
  Widget _buildResultsState(AnalysisViewModel analysisViewModel) {
    return Column(
      children: [
        // Success header
        Container(
          padding: AppConstants.containerPaddingMedium,
          decoration: BoxDecoration(
            color: AppTheme.successColor
                .withAlpha((255 * AppConstants.opacityLow).toInt()),
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusMedium.r),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: AppConstants.iconSizeMedium.sp,
              ),
              SizedBox(width: AppConstants.spacingMedium.w),
              Expanded(
                child: Text(
                  'Analysis completed successfully! Review your insights below.',
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

        // Analysis panels
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // Tab bar
                TabBar(
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor:
                      Theme.of(context).textTheme.bodyMedium?.color,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    fontSize: AppConstants.textSizeMedium.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: AppConstants.textSizeMedium.sp,
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: const [
                    Tab(text: 'Spending Behavior'),
                    Tab(text: 'Budget Reallocation'),
                  ],
                ),

                SizedBox(height: AppConstants.spacingMedium.h),

                // Tab content
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSpendingBehaviorPanel(analysisViewModel),
                      _buildBudgetReallocationPanel(analysisViewModel),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build spending behavior analysis panel
  Widget _buildSpendingBehaviorPanel(AnalysisViewModel analysisViewModel) {
    return Column(
      children: [
        // Request panel
        Expanded(
          child: _buildAnalysisPanel(
            title: 'Request Data',
            content: analysisViewModel.getFormattedSpendingRequest(),
            copyLabel: 'Request',
          ),
        ),

        SizedBox(height: AppConstants.spacingMedium.h),

        // Response panel
        Expanded(
          child: _buildAnalysisPanel(
            title: 'AI Analysis Response',
            content: analysisViewModel.getFormattedSpendingResponse(),
            copyLabel: 'Response',
          ),
        ),
      ],
    );
  }

  /// Build budget reallocation analysis panel
  Widget _buildBudgetReallocationPanel(AnalysisViewModel analysisViewModel) {
    return Column(
      children: [
        // Response panel
        Expanded(
          child: _buildAnalysisPanel(
            title: 'Budget Reallocation Recommendations',
            content: analysisViewModel.getFormattedReallocationResponse(),
            copyLabel: 'Recommendations',
          ),
        ),

        // Apply Recommendations Button
        if (analysisViewModel.reallocationResult != null &&
            analysisViewModel.reallocationResult!.suggestions.isNotEmpty) ...[
          SizedBox(height: AppConstants.spacingMedium.h),
          Container(
            width: double.infinity,
            padding:
                EdgeInsets.symmetric(horizontal: AppConstants.spacingMedium.w),
            child: SubmitButton(
              text: 'Apply Recommendations',
              isLoading: analysisViewModel.isReallocating,
              loadingText: 'Applying Changes...',
              onPressed: () async {
                final success =
                    await analysisViewModel.applyBudgetRecommendations(
                  selectedDate: widget.selectedDate,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Budget recommendations applied successfully!'
                            : 'Failed to apply recommendations. Please try again.',
                      ),
                      backgroundColor:
                          success ? Colors.green[600] : Colors.red[600],
                      duration: const Duration(seconds: 3),
                    ),
                  );

                  if (success) {
                    // Close dialog after successful application
                    Navigator.of(context)
                        .pop(true); // Return true to indicate changes were made
                  }
                }
              },
              icon: Icons.check_circle_outline,
              width: double.infinity,
            ),
          ),
        ],
      ],
    );
  }

  /// Build a generic analysis panel
  Widget _buildAnalysisPanel({
    required String title,
    required String content,
    required String copyLabel,
  }) {
    return Container(
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
          // Panel header
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppConstants.textSizeMedium.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(content, copyLabel),
                  icon: Icon(
                    Icons.copy,
                    size: AppConstants.iconSizeSmall.sp,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  constraints: const BoxConstraints(),
                  tooltip: 'Copy $copyLabel',
                ),
              ],
            ),
          ),

          // Panel content
          Expanded(
            child: Container(
              width: double.infinity,
              padding: AppConstants.containerPaddingMedium,
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: AppConstants.textSizeSmall.sp,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build bottom action buttons
  Widget _buildBottomActions(AnalysisViewModel analysisViewModel) {
    if (!_isAnalysisStarted || analysisViewModel.isLoading) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(
                    double.infinity, AppConstants.componentHeightStandard.h),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: AppConstants.textSizeLarge.sp,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ),
          if (!_isAnalysisStarted) ...[
            SizedBox(width: AppConstants.spacingMedium.w),
            Expanded(
              child: SubmitButton(
                text: 'Start Analysis',
                isLoading: false,
                onPressed: _performAnalysis,
                icon: Icons.analytics,
              ),
            ),
          ],
        ],
      );
    }

    // After analysis completion or error
    return Row(
      children: [
        if (analysisViewModel.errorMessage != null) ...[
          Expanded(
            child: SubmitButton(
              text: 'Retry Analysis',
              isLoading: false,
              onPressed: _performAnalysis,
              icon: Icons.refresh,
            ),
          ),
          SizedBox(width: AppConstants.spacingMedium.w),
        ],
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              minimumSize:
                  Size(double.infinity, AppConstants.componentHeightStandard.h),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            child: Text(
              'Close',
              style: TextStyle(
                fontSize: AppConstants.textSizeLarge.sp,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
