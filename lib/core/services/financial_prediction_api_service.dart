import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../di/injection_container.dart' as di;
import 'api_models.dart';

// ============================================================================
// REQUEST MODELS
// ============================================================================

/// Expense record for the API request
class ExpenseRecordRequest {
  final String date; // ISO format: YYYY-MM-DDTHH:mm:ssZ
  final String category;
  final double amount;
  final String currency;
  final String recurrenceStatus;
  final String paymentMethod;
  final String remark;

  ExpenseRecordRequest({
    required this.date,
    required this.category,
    required this.amount,
    required this.currency,
    required this.recurrenceStatus,
    required this.paymentMethod,
    required this.remark,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'category': category,
      'amount': amount,
      'currency': currency,
      'recurrence_status': recurrenceStatus,
      'payment_method': paymentMethod,
      'remark': remark,
    };
  }

  /// Convert from domain Expense entity to API request format
  factory ExpenseRecordRequest.fromExpense(Expense expense) {
    return ExpenseRecordRequest(
      date: expense.date.toIso8601String(),
      category: expense.category.id,
      amount: expense.amount,
      currency: expense.currency,
      recurrenceStatus: 'non_recurring', // Default for now
      paymentMethod: _mapPaymentMethod(expense.method),
      remark: expense.remark,
    );
  }

  /// Map domain PaymentMethod to API string format
  static String _mapPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'credit_card';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.eWallet:
        return 'e_wallet';
    }
  }
}

/// Budget category detail for the API request
class BudgetCategoryDetailRequest {
  final double budgetTotal;
  final double amountLeft;

  BudgetCategoryDetailRequest({
    required this.budgetTotal,
    required this.amountLeft,
  });

  Map<String, dynamic> toJson() {
    return {
      'budget_total': budgetTotal,
      'amount_left': amountLeft,
    };
  }
}

/// Monthly budget status for the API request
class MonthlyBudgetStatusRequest {
  final String monthYear; // Format: YYYY-MM
  final double totalBudgetedForMonth;
  final double totalAmountLeftForMonth;
  final String currency;
  final Map<String, BudgetCategoryDetailRequest> categoryBudgets;

  MonthlyBudgetStatusRequest({
    required this.monthYear,
    required this.totalBudgetedForMonth,
    required this.totalAmountLeftForMonth,
    required this.currency,
    required this.categoryBudgets,
  });

  Map<String, dynamic> toJson() {
    return {
      'month_year': monthYear,
      'total_budgeted_for_month': totalBudgetedForMonth,
      'total_amount_left_for_month': totalAmountLeftForMonth,
      'currency': currency,
      'category_budgets':
          categoryBudgets.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  /// Convert from domain Budget entity to API request format
  factory MonthlyBudgetStatusRequest.fromBudget(
      Budget budget, String monthYear) {
    // Convert category budgets to the required format
    final Map<String, BudgetCategoryDetailRequest> categoryBudgets = {};

    // Define the required categories with defaults
    final requiredCategories = [
      'education',
      'entertainment',
      'food',
      'medical',
      'others',
      'rental',
      'shopping',
      'transportation',
      'travel',
      'utilities'
    ];

    for (final categoryKey in requiredCategories) {
      final categoryBudget = budget.categories[categoryKey];
      if (categoryBudget != null) {
        categoryBudgets[categoryKey] = BudgetCategoryDetailRequest(
          budgetTotal: categoryBudget.budget,
          amountLeft: categoryBudget.left,
        );
      } else {
        // Default empty budget for missing categories
        categoryBudgets[categoryKey] = BudgetCategoryDetailRequest(
          budgetTotal: 0.0,
          amountLeft: 0.0,
        );
      }
    }

    return MonthlyBudgetStatusRequest(
      monthYear: monthYear,
      totalBudgetedForMonth: budget.total,
      totalAmountLeftForMonth: budget.left,
      currency: budget.currency,
      categoryBudgets: categoryBudgets,
    );
  }
}

/// Main request object for the financial prediction API
class FinancialPredictionApiRequest {
  final String currentDate; // Format: YYYY-MM-DD
  final List<ExpenseRecordRequest> expenseHistoryLast14Days;
  final MonthlyBudgetStatusRequest monthlyBudgetStatus;

  FinancialPredictionApiRequest({
    required this.currentDate,
    required this.expenseHistoryLast14Days,
    required this.monthlyBudgetStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_date': currentDate,
      'expense_history_last_14_days':
          expenseHistoryLast14Days.map((e) => e.toJson()).toList(),
      'monthly_budget_status': monthlyBudgetStatus.toJson(),
    };
  }
}

// ============================================================================
// RESPONSE MODELS
// ============================================================================

/// Predicted expense detail from the API response
class PredictedExpenseDetailResponse {
  final String category;
  final String predictedRemark;
  final double estimatedAmount;
  final String currency;
  final String likelihood;
  final String reasoning;

  PredictedExpenseDetailResponse({
    required this.category,
    required this.predictedRemark,
    required this.estimatedAmount,
    required this.currency,
    required this.likelihood,
    required this.reasoning,
  });

  factory PredictedExpenseDetailResponse.fromJson(Map<String, dynamic> json) {
    return PredictedExpenseDetailResponse(
      category: json['category'] ?? '',
      predictedRemark: json['predicted_remark'] ?? '',
      estimatedAmount: (json['estimated_amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? '',
      likelihood: json['likelihood'] ?? '',
      reasoning: json['reasoning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'predicted_remark': predictedRemark,
      'estimated_amount': estimatedAmount,
      'currency': currency,
      'likelihood': likelihood,
      'reasoning': reasoning,
    };
  }
}

/// Overspending alert from the API response
class OverspendingAlertResponse {
  final String category;
  final double currentAmountLeftInBudget;
  final double totalPredictedSpendInCategoryNextDay;
  final double potentialRemainingAfterNextDay;
  final String alertMessage;

  OverspendingAlertResponse({
    required this.category,
    required this.currentAmountLeftInBudget,
    required this.totalPredictedSpendInCategoryNextDay,
    required this.potentialRemainingAfterNextDay,
    required this.alertMessage,
  });

  factory OverspendingAlertResponse.fromJson(Map<String, dynamic> json) {
    return OverspendingAlertResponse(
      category: json['category'] ?? '',
      currentAmountLeftInBudget:
          (json['current_amount_left_in_budget'] ?? 0.0).toDouble(),
      totalPredictedSpendInCategoryNextDay:
          (json['total_predicted_spend_in_category_next_day'] ?? 0.0)
              .toDouble(),
      potentialRemainingAfterNextDay:
          (json['potential_remaining_after_next_day'] ?? 0.0).toDouble(),
      alertMessage: json['alert_message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'current_amount_left_in_budget': currentAmountLeftInBudget,
      'total_predicted_spend_in_category_next_day':
          totalPredictedSpendInCategoryNextDay,
      'potential_remaining_after_next_day': potentialRemainingAfterNextDay,
      'alert_message': alertMessage,
    };
  }
}

/// Suggested reallocation from the API response
class SuggestedReallocationResponse {
  final String fromCategory;
  final String toCategory;
  final double reallocateAmount;
  final String currency;
  final String reasoning;

  SuggestedReallocationResponse({
    required this.fromCategory,
    required this.toCategory,
    required this.reallocateAmount,
    required this.currency,
    required this.reasoning,
  });

  factory SuggestedReallocationResponse.fromJson(Map<String, dynamic> json) {
    return SuggestedReallocationResponse(
      fromCategory: json['from_category'] ?? '',
      toCategory: json['to_category'] ?? '',
      reallocateAmount: (json['reallocate_amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? '',
      reasoning: json['reasoning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from_category': fromCategory,
      'to_category': toCategory,
      'reallocate_amount': reallocateAmount,
      'currency': currency,
      'reasoning': reasoning,
    };
  }
}

/// Budget reallocation advice from the API response
class BudgetReallocationAdviceResponse {
  final String analysisSummary;
  final List<OverspendingAlertResponse> overspendingAlertsForNextDay;
  final List<SuggestedReallocationResponse> suggestedReallocations;
  final String reallocationNotes;

  BudgetReallocationAdviceResponse({
    required this.analysisSummary,
    required this.overspendingAlertsForNextDay,
    required this.suggestedReallocations,
    required this.reallocationNotes,
  });

  factory BudgetReallocationAdviceResponse.fromJson(Map<String, dynamic> json) {
    return BudgetReallocationAdviceResponse(
      analysisSummary: json['analysis_summary'] ?? '',
      overspendingAlertsForNextDay:
          (json['overspending_alerts_for_next_day'] as List? ?? [])
              .map((item) => OverspendingAlertResponse.fromJson(item))
              .toList(),
      suggestedReallocations: (json['suggested_reallocations'] as List? ?? [])
          .map((item) => SuggestedReallocationResponse.fromJson(item))
          .toList(),
      reallocationNotes: json['reallocation_notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysis_summary': analysisSummary,
      'overspending_alerts_for_next_day':
          overspendingAlertsForNextDay.map((e) => e.toJson()).toList(),
      'suggested_reallocations':
          suggestedReallocations.map((e) => e.toJson()).toList(),
      'reallocation_notes': reallocationNotes,
    };
  }
}

/// Main response object from the financial prediction API
class LLMPredictionApiResponse {
  final String predictionForDate;
  final List<PredictedExpenseDetailResponse> predictedNextDayExpenses;
  final BudgetReallocationAdviceResponse budgetReallocationAdvice;
  final String overallConfidenceNote;

  LLMPredictionApiResponse({
    required this.predictionForDate,
    required this.predictedNextDayExpenses,
    required this.budgetReallocationAdvice,
    required this.overallConfidenceNote,
  });

  factory LLMPredictionApiResponse.fromJson(Map<String, dynamic> json) {
    return LLMPredictionApiResponse(
      predictionForDate: json['prediction_for_date'] ?? '',
      predictedNextDayExpenses:
          (json['predicted_next_day_expenses'] as List? ?? [])
              .map((item) => PredictedExpenseDetailResponse.fromJson(item))
              .toList(),
      budgetReallocationAdvice: BudgetReallocationAdviceResponse.fromJson(
          json['budget_reallocation_advice'] ?? {}),
      overallConfidenceNote: json['overall_confidence_note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prediction_for_date': predictionForDate,
      'predicted_next_day_expenses':
          predictedNextDayExpenses.map((e) => e.toJson()).toList(),
      'budget_reallocation_advice': budgetReallocationAdvice.toJson(),
      'overall_confidence_note': overallConfidenceNote,
    };
  }
}

// ============================================================================
// API SERVICE
// ============================================================================

/// Service for interacting with the financial prediction API
class FinancialPredictionApiService {
  static final FinancialPredictionApiService _instance =
      FinancialPredictionApiService._internal();
  factory FinancialPredictionApiService() => _instance;
  FinancialPredictionApiService._internal();

  // API Configuration
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const Duration timeoutDuration =
      Duration(seconds: 300); // Longer timeout for LLM processing

  /// Get daily expense prediction from the LLM API
  Future<LLMPredictionApiResponse> getDailyExpensePrediction(
      FinancialPredictionApiRequest requestData) async {
    // Create a new client for each request to avoid "client is closed" errors
    final client = http.Client();

    try {
      final uri = Uri.parse('$baseUrl/predict-daily-expenses');

      debugPrint('=== Financial Prediction API Request ===');
      debugPrint('Making request to: $uri');
      debugPrint('Timeout: ${timeoutDuration.inSeconds} seconds');
      debugPrint(
          'Request data size: ${jsonEncode(requestData.toJson()).length} bytes');

      final requestBody = jsonEncode(requestData.toJson());

      final response = await client
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      )
          .timeout(timeoutDuration, onTimeout: () {
        throw TimeoutException(
          'Request timeout after ${timeoutDuration.inSeconds} seconds',
          timeoutDuration,
        );
      });

      debugPrint('=== Financial Prediction API Response ===');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');
      debugPrint('Response body length: ${response.body.length} bytes');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonData = jsonDecode(response.body);
          debugPrint('Successfully parsed response JSON');
          return LLMPredictionApiResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Failed to parse response JSON: $e');
          debugPrint('Raw response: ${response.body}');
          throw ApiException('Invalid JSON response from server: $e');
        }
      } else {
        // Try to parse error message from response
        String errorMessage =
            'Failed to get financial prediction (Status: ${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['detail'] ?? errorData['message'] ?? errorMessage;
        } catch (e) {
          // If can't parse error, include raw response
          errorMessage += '\nRaw response: ${response.body}';
        }
        debugPrint('API request failed: $errorMessage');
        throw ApiException(errorMessage, response.statusCode);
      }
    } on TimeoutException catch (e) {
      debugPrint('Request timeout: $e');
      throw ApiException(
          'Request timeout - the LLM prediction took longer than ${timeoutDuration.inSeconds} seconds');
    } on http.ClientException catch (e) {
      debugPrint('HTTP Client error: $e');
      throw ApiException(
          'Network error: ${e.message}. Check if the server is running at $baseUrl');
    } on FormatException catch (e) {
      debugPrint('JSON Format error: $e');
      throw ApiException('Invalid response format: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error in API request: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    } finally {
      // Always close the client after use
      client.close();
      debugPrint('HTTP client closed');
    }
  }

  /// Build request data from current user's expenses and budget
  Future<FinancialPredictionApiRequest> buildRequestFromCurrentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ApiException('User not authenticated');
    }

    try {
      // Get repositories from dependency injection
      final expensesRepository = di.sl<ExpensesRepository>();
      final budgetRepository = di.sl<BudgetRepository>();

      // Get current date
      final now = DateTime.now();
      final currentDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Get last 14 days of expenses
      final allExpenses = await expensesRepository.getExpenses();
      final fourteenDaysAgo = now.subtract(const Duration(days: 14));
      final recentExpenses = allExpenses
          .where((expense) => expense.date.isAfter(fourteenDaysAgo))
          .toList();

      // Convert expenses to API format
      final expenseHistory = recentExpenses
          .map((expense) => ExpenseRecordRequest.fromExpense(expense))
          .toList();

      // Get current month budget
      final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final budget = await budgetRepository.getBudget(monthId);

      if (budget == null) {
        throw ApiException(
            'No budget found for current month. Please create a budget first.');
      }

      // Convert budget to API format
      final monthlyBudgetStatus =
          MonthlyBudgetStatusRequest.fromBudget(budget, monthId);

      return FinancialPredictionApiRequest(
        currentDate: currentDate,
        expenseHistoryLast14Days: expenseHistory,
        monthlyBudgetStatus: monthlyBudgetStatus,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to build request data: $e');
    }
  }

  /// Convenient method to get prediction using current user's data
  Future<LLMPredictionApiResponse> getPredictionForCurrentUser() async {
    final requestData = await buildRequestFromCurrentData();
    return await getDailyExpensePrediction(requestData);
  }

  /// Check if the API server is healthy
  Future<bool> checkHealth() async {
    // Create a new client for each request
    final client = http.Client();

    try {
      final uri = Uri.parse('$baseUrl/health');

      debugPrint('=== API Health Check ===');
      debugPrint('Checking health at: $uri');

      final response = await client.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Health check timeout after 10 seconds');
      });

      debugPrint('Health check response status: ${response.statusCode}');
      debugPrint('Health check response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final isHealthy = data['status'] == 'healthy';
          debugPrint('API health status: $isHealthy');
          return isHealthy;
        } catch (e) {
          debugPrint('Failed to parse health check response: $e');
          return false;
        }
      }

      debugPrint('Health check failed with status: ${response.statusCode}');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('Health check timeout: $e');
      return false;
    } on http.ClientException catch (e) {
      debugPrint('Health check client error: $e');
      return false;
    } catch (e) {
      debugPrint('Health check unexpected error: $e');
      return false;
    } finally {
      // Always close the client after use
      client.close();
      debugPrint('Health check HTTP client closed');
    }
  }

  /// Test the API connection
  Future<bool> testConnection() async {
    try {
      return await checkHealth();
    } catch (e) {
      debugPrint('Financial prediction API test failed: $e');
      return false;
    }
  }

  /// Dispose of resources (no longer needed since we create clients per request)
  void dispose() {
    // No longer needed since we create and dispose clients per request
    debugPrint('FinancialPredictionApiService disposed');
  }
}
