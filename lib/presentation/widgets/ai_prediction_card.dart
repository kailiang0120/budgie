import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../../data/models/ai_response_models.dart';
import '../../domain/services/ai_expense_prediction_service.dart';
import '../../domain/services/budget_reallocation_service.dart';
import '../../data/infrastructure/services/firebase_data_fetcher_service.dart';
import '../../di/injection_container.dart' as di;
import 'custom_card.dart';

String formatMonthId(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

class AIPredictionCard extends StatefulWidget {
  final DateTime selectedDate;

  const AIPredictionCard({
    Key? key,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<AIPredictionCard> createState() => _AIPredictionCardState();
}

class _AIPredictionCardState extends State<AIPredictionCard> {
  bool _isLoadingPrediction = false;
  ExpensePredictionResponse? _predictionResult;
  String? _predictionError;
  bool _isReallocating = false;

  /// Get AI prediction for the selected day using Firebase data
  Future<void> _getAIPrediction() async {
    setState(() {
      _isLoadingPrediction = true;
      _predictionError = null;
    });

    try {
      // Get services
      final firebaseDataFetcher = di.sl<FirebaseDataFetcherService>();
      final aiService = di.sl<AIExpensePredictionService>();

      // Initialize the AI service if needed
      await aiService.initialize();

      // Calculate target date (tomorrow)
      final targetDate = DateTime.now().add(const Duration(days: 1));
      final monthId = formatMonthId(widget.selectedDate);

      debugPrint('🤖 Fetching data for AI prediction...');

      // Fetch expenses data from Firebase with recent data priority
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final expensesResult = await firebaseDataFetcher.fetchExpensesData(
        startDate: cutoffDate,
        limit: 100, // Get recent 100 expenses for analysis
        forceRefresh: false, // Allow cache for performance
      );

      // Fetch budget data from Firebase
      final budgetResult = await firebaseDataFetcher.fetchBudgetData(
        monthId: monthId,
        forceRefresh: false,
      );

      // Validate data
      if (expensesResult.expenses.isEmpty) {
        setState(() {
          _isLoadingPrediction = false;
        });
        _showErrorSnackBar('Need expense history to generate predictions');
        return;
      }

      if (!budgetResult.hasBudget) {
        setState(() {
          _isLoadingPrediction = false;
        });
        _showErrorSnackBar('Budget data required for predictions');
        return;
      }

      debugPrint(
          '🤖 Data fetched - ${expensesResult.expenses.length} expenses, budget available');

      // Get prediction
      final result = await aiService.predictNextDayExpenses(
        pastExpenses: expensesResult.expenses,
        currentBudget: budgetResult.budget!,
        targetDate: targetDate,
        userProfile: {
          'location': 'Malaysia',
          'currency': budgetResult.budget!.currency,
          'dataSource': expensesResult.source.name,
          'expenseCount': expensesResult.expenses.length,
        },
      );

      // Store prediction result in Firebase for historical analysis
      try {
        await firebaseDataFetcher.storePredictionResult(
          monthId: monthId,
          predictionDate: DateTime.now(),
          predictionData: result.toFirebaseDocument(),
        );
        debugPrint('🤖 Prediction stored in Firebase for historical analysis');
      } catch (e) {
        debugPrint('🤖 Warning: Failed to store prediction in Firebase: $e');
        // Don't fail the whole operation if storage fails
      }

      setState(() {
        _predictionResult = result;
        _isLoadingPrediction = false;
      });

      debugPrint('🤖 AI Prediction completed successfully');

      // Show data source info if using cached data
      if (expensesResult.isFromCache || budgetResult.isFromCache) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      'Prediction based on cached data. Connect to internet for latest data.',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingPrediction = false;
      });
      _showErrorSnackBar(e.toString());
      debugPrint('🤖 AI Prediction failed: $e');
    }
  }

  void _showErrorSnackBar(String errorMessage) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 16.sp),
            SizedBox(width: 8.w),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                errorMessage,
                style: TextStyle(fontSize: 12.sp),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Reallocate budget based on AI predictions
  Future<void> _reallocateBudget() async {
    if (_predictionResult == null) return;

    setState(() {
      _isReallocating = true;
    });

    try {
      // Get current month ID
      final monthId = formatMonthId(widget.selectedDate);

      // Fetch current budget data using Firebase data fetcher
      final firebaseDataFetcher = di.sl<FirebaseDataFetcherService>();
      final budgetResult = await firebaseDataFetcher.fetchBudgetData(
        monthId: monthId,
        forceRefresh: true, // Get latest budget data
      );

      if (!budgetResult.hasBudget) {
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

      debugPrint('🔄 Starting budget reallocation...');

      // Get the reallocation service
      final reallocationService = di.sl<BudgetReallocationService>();

      // Perform reallocation
      final reallocatedBudget = await reallocationService.reallocateBudget(
        currentBudget: budgetResult.budget!,
        predictions: _predictionResult!,
        monthId: monthId,
      );

      // Update the budget in view model if available
      final budgetViewModel =
          Provider.of<BudgetViewModel>(context, listen: false);
      await budgetViewModel.saveBudget(monthId, reallocatedBudget);

      // Store the reallocation result for historical tracking
      try {
        await firebaseDataFetcher.storePredictionResult(
          monthId: monthId,
          predictionDate: DateTime.now(),
          predictionData: {
            ..._predictionResult!.toFirebaseDocument(),
            'reallocationApplied': true,
            'reallocationTimestamp': DateTime.now().toIso8601String(),
            'originalBudget': budgetResult.budget!.toMap(),
            'reallocatedBudget': reallocatedBudget.toMap(),
          },
        );
        debugPrint('🔄 Reallocation result stored for historical analysis');
      } catch (e) {
        debugPrint('🔄 Warning: Failed to store reallocation result: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    'Budget successfully reallocated based on AI predictions!\nTotal: ${reallocatedBudget.total.toStringAsFixed(2)} ${reallocatedBudget.currency}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      debugPrint('✅ Budget reallocation completed successfully');

      // Refresh the prediction to reflect new budget state
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _getAIPrediction();
      }
    } catch (e) {
      debugPrint('❌ Budget reallocation failed: $e');

      String errorMessage = 'Failed to reallocate budget';
      if (e.toString().contains('REALLOCATION_IMPOSSIBLE')) {
        errorMessage =
            'Cannot reallocate - insufficient surplus to cover shortfalls';
      } else if (e.toString().contains('NO_SUGGESTIONS')) {
        errorMessage = 'No reallocation suggestions available from AI';
      } else if (e.toString().contains('INSUFFICIENT_DATA')) {
        errorMessage = 'Insufficient expense history for accurate reallocation';
      } else if (e.toString().contains('INVALID_BUDGET')) {
        errorMessage = 'Invalid budget data detected';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  fit: FlexFit.loose,
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

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    // Always show the button, regardless of prediction state
    if (_predictionResult == null) {
      return Container(
        height: 45.h,
        width: 45.h,
        decoration: BoxDecoration(
          color: themeColor.withAlpha((255 * 0.1).toInt()),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: themeColor.withAlpha((255 * 0.3).toInt()),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.r),
            onTap: _isLoadingPrediction ? null : _getAIPrediction,
            child: Center(
              child: _isLoadingPrediction
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.w,
                        color: themeColor,
                      ),
                    )
                  : Icon(
                      Icons.lightbulb_outline,
                      color: themeColor,
                      size: 20.sp,
                    ),
            ),
          ),
        ),
      );
    }

    return CustomCard(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: _buildCardContent(context),
    );
  }

  Widget _buildCardContent(BuildContext context) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(context, tomorrowFormatted, prediction),
        SizedBox(height: 16.h),

        // Summary Stats
        _buildSummaryStats(context, prediction),
        SizedBox(height: 16.h),

        // Top 3 Predicted Expenses
        if (top3Expenses.isNotEmpty) ...[
          _buildTopExpenses(context, top3Expenses),
          SizedBox(height: 16.h),
        ],

        // Budget Reallocation Suggestions
        if (prediction.budgetReallocationSuggestions.isNotEmpty) ...[
          _buildReallocationSuggestions(context, prediction),
          SizedBox(height: 16.h),
        ],

        // Categories at Risk
        if (prediction.summary.categoriesAtRisk.isNotEmpty) ...[
          _buildCategoriesAtRisk(context, prediction),
          SizedBox(height: 16.h),
        ],

        // Insights
        if (prediction.insights.isNotEmpty) ...[
          _buildInsights(context, prediction),
          SizedBox(height: 16.h),
        ],

        // Action buttons
        _buildActionButtons(context, prediction),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String tomorrowFormatted,
      ExpensePredictionResponse prediction) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withAlpha((255 * 0.1).toInt()),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.lightbulb,
            color: Theme.of(context).colorScheme.primary,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Spending Prediction',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                'For Tomorrow ($tomorrowFormatted)',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: _getRiskLevelColor(prediction.summary.riskLevel)
                .withAlpha((255 * 0.1).toInt()),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            prediction.summary.riskLevel.toUpperCase(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: _getRiskLevelColor(prediction.summary.riskLevel),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStats(
      BuildContext context, ExpensePredictionResponse prediction) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withAlpha((255 * 0.3).toInt()),
        borderRadius: BorderRadius.circular(12.r),
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
            width: 1.w,
            height: 40.h,
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
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20.sp),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTopExpenses(
      BuildContext context, List<PredictedExpense> top3Expenses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Likely Expenses',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        ...top3Expenses.asMap().entries.map((entry) {
          final index = entry.key;
          final expense = entry.value;
          final confidencePercentage = (expense.confidence * 100).round();
          final likelihoodColor = _getConfidenceColor(expense.confidence);
          final likelihoodText =
              _getConfidenceLikelihoodText(expense.confidence);

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12.r),
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
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Expense details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              expense.categoryName,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'MYR ${expense.predictedAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      if (expense.reasoning.isNotEmpty)
                        Text(
                          expense.reasoning,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),

                // Confidence indicator
                Column(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: likelihoodColor.withAlpha((255 * 0.1).toInt()),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: likelihoodColor.withAlpha((255 * 0.3).toInt()),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        likelihoodText,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: likelihoodColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '$confidencePercentage%',
                      style: TextStyle(
                        fontSize: 12.sp,
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
    );
  }

  Widget _buildReallocationSuggestions(
      BuildContext context, ExpensePredictionResponse prediction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Reallocation Suggestions',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        ...prediction.budgetReallocationSuggestions.map(
          (suggestion) => Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Colors.orange.withAlpha((255 * 0.3).toInt()),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_horiz,
                  size: 16.sp,
                  color: Colors.orange[700],
                ),
                SizedBox(width: 8.w),
                Flexible(
                  fit: FlexFit.loose,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Move MYR ${suggestion.suggestedAmount.toStringAsFixed(2)} from ${suggestion.fromCategory} to ${suggestion.toCategory}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[800],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        suggestion.reason,
                        style: TextStyle(
                          fontSize: 12.sp,
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
    );
  }

  Widget _buildCategoriesAtRisk(
      BuildContext context, ExpensePredictionResponse prediction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories at Risk',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.red[700],
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 4.h,
          children: prediction.summary.categoriesAtRisk
              .map(
                (category) => Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha((255 * 0.1).toInt()),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.red.withAlpha((255 * 0.3).toInt()),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildInsights(
      BuildContext context, ExpensePredictionResponse prediction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Insights for Tomorrow',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        ...prediction.insights.take(3).map((insight) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getInsightIcon(insight.type),
                    size: 16.sp,
                    color: _getInsightColor(insight.type),
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      insight.message,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, ExpensePredictionResponse prediction) {
    return Row(
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
            padding: EdgeInsets.all(8.w),
          ),
        ),
        SizedBox(width: 8.w),
        // Reallocate button - only show if there are reallocation suggestions
        if (prediction.budgetReallocationSuggestions.isNotEmpty) ...[
          IconButton(
            onPressed: _isReallocating ? null : _reallocateBudget,
            icon: _isReallocating
                ? SizedBox(
                    width: 16.w,
                    height: 16.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.swap_horiz, size: 20),
            tooltip: 'Reallocate Budget',
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.orange,
              padding: EdgeInsets.all(8.w),
            ),
          ),
          SizedBox(width: 8.w),
        ],
        IconButton(
          onPressed: _getAIPrediction,
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh',
          style: IconButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding: EdgeInsets.all(8.w),
          ),
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
}
