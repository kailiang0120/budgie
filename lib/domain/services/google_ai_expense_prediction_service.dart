import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../entities/expense.dart';
import '../entities/budget.dart';
import '../../data/models/ai_response_models.dart';
import '../../data/models/exceptions.dart';
import '../../data/infrastructure/network/connectivity_service.dart';

/// Service for predicting user expenses using Google AI (Gemini)
class GoogleAIExpensePredictionService {
  static final GoogleAIExpensePredictionService _instance =
      GoogleAIExpensePredictionService._internal();
  factory GoogleAIExpensePredictionService() => _instance;
  GoogleAIExpensePredictionService._internal();

  // API Configuration
  static const String _apiKey = 'AIzaSyDiAw4ef91-wUbu9bOZoZLpfEVzBAebBRA';
  static const String _modelName = 'gemma-3-27b-it';
  static const Duration _timeoutDuration = Duration(seconds: 45);

  // Services
  GenerativeModel? _model;
  ConnectivityService? _connectivityService;
  bool _isInitialized = false;

  /// Set the connectivity service (for dependency injection)
  void setConnectivityService(ConnectivityService connectivityService) {
    _connectivityService = connectivityService;
  }

  /// Initialize the Google AI service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🤖 GoogleAIExpensePredictionService: Initializing...');

      _model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.4,
          topK: 30,
          topP: 0.85,
          maxOutputTokens: 2048,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(
              HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(
              HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
      );

      _isInitialized = true;
      debugPrint(
          '🤖 GoogleAIExpensePredictionService: Initialized successfully');
    } catch (e) {
      debugPrint(
          '🤖 GoogleAIExpensePredictionService: Initialization error: $e');
      throw AIApiException(
        'Failed to initialize Google AI service: $e',
        code: 'INITIALIZATION_ERROR',
      );
    }
  }

  /// Predict expenses based on historical data and current budget
  Future<ExpensePredictionResponse> predictExpenses({
    required List<Expense> pastExpenses,
    required Budget currentBudget,
    required DateTime targetMonth,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      await _ensureInitialized();
      _validateAuthentication();
      await _checkConnectivity();
      _validateInputData(pastExpenses, currentBudget);

      debugPrint('🤖 Starting expense prediction...');

      final request = _prepareRequest(
          pastExpenses, currentBudget, targetMonth, userProfile);
      final prompt = _generatePrompt(request);
      final response = await _callGeminiAPI(prompt);
      final predictionResponse = await _parseResponse(response);

      debugPrint('🤖 Prediction completed successfully');
      return predictionResponse;
    } catch (e) {
      debugPrint('🤖 Prediction error: $e');

      if (e is AIApiException) {
        rethrow;
      }

      throw AIApiException(
        'Failed to predict expenses: $e',
        code: 'PREDICTION_ERROR',
        details: {'originalError': e.toString()},
      );
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized || _model == null) {
      await initialize();
    }
  }

  void _validateAuthentication() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw AIApiException(
        'User must be authenticated to use expense prediction',
        code: 'AUTH_REQUIRED',
      );
    }
  }

  Future<void> _checkConnectivity() async {
    if (_connectivityService == null) {
      throw AIApiException(
        'Connectivity service not initialized',
        code: 'SERVICE_NOT_INITIALIZED',
      );
    }

    final isConnected = await _connectivityService!.isConnected;
    if (!isConnected) {
      throw AIApiException(
        'Internet connection required for expense prediction',
        code: 'NO_CONNECTIVITY',
      );
    }
  }

  void _validateInputData(List<Expense> pastExpenses, Budget currentBudget) {
    if (pastExpenses.isEmpty) {
      throw AIApiException(
        'At least some expense history is required for prediction',
        code: 'INSUFFICIENT_DATA',
      );
    }

    if (currentBudget.total <= 0) {
      throw AIApiException(
        'Valid budget data is required for prediction',
        code: 'INVALID_BUDGET',
      );
    }

    final cutoffDate = DateTime.now().subtract(const Duration(days: 60));
    final recentExpenses =
        pastExpenses.where((expense) => expense.date.isAfter(cutoffDate));

    if (recentExpenses.isEmpty) {
      throw AIApiException(
        'Recent expense data (within 60 days) is required for accurate prediction',
        code: 'OUTDATED_DATA',
      );
    }
  }

  ExpensePredictionRequest _prepareRequest(
    List<Expense> pastExpenses,
    Budget currentBudget,
    DateTime targetMonth,
    Map<String, dynamic>? userProfile,
  ) {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 14));
    final recentExpenses = pastExpenses
        .where((expense) => expense.date.isAfter(cutoffDate))
        .toList();

    debugPrint('🤖 [DATA PREPARATION] ===================================');
    debugPrint('🤖 Total expenses in dataset: ${pastExpenses.length}');
    debugPrint('🤖 Expenses in last 14 days: ${recentExpenses.length}');
    debugPrint('🤖 Cutoff date: ${cutoffDate.toIso8601String()}');

    // Log all past 14 days expenses
    debugPrint('🤖 [PAST 14 DAYS EXPENSES] ============================');
    for (int i = 0; i < recentExpenses.length; i++) {
      final expense = recentExpenses[i];
      debugPrint(
          '🤖 Expense ${i + 1}: ${expense.date.toIso8601String().split('T')[0]} | '
          '${expense.amount} ${expense.currency} | ${expense.category.name} | ${expense.remark}');
    }

    final expenseData = recentExpenses
        .map((expense) => ExpenseData.fromExpense(expense))
        .toList();

    final budgetData = BudgetData.fromBudget(currentBudget);

    return ExpensePredictionRequest(
      pastExpenses: expenseData,
      currentBudget: budgetData,
      currency:
          recentExpenses.isNotEmpty ? recentExpenses.first.currency : 'MYR',
      targetMonth: targetMonth,
      userProfile: userProfile,
    );
  }

  String _generatePrompt(ExpensePredictionRequest request) {
    final targetMonthStr =
        '${request.targetMonth.year}-${request.targetMonth.month.toString().padLeft(2, '0')}';

    final prompt = '''
You are an AI financial advisor specializing in expense prediction. Analyze the provided expense history and budget data to predict next month's expenses.

 **Current Budget Overview:**
 - Total Budget: ${request.currentBudget.totalBudget} ${request.currentBudget.currency}
 - Remaining Budget: ${request.currentBudget.remainingBudget} ${request.currentBudget.currency}

 **Recent Expense History (Last 14 days):**
 ${request.pastExpenses.map((expense) => '- ${expense.date}: ${expense.amount} ${expense.currency} for ${expense.categoryName} (${expense.description})').join('\n')}

**Prediction Target:** ${targetMonthStr}

**Instructions:**
1. Analyze spending patterns, frequency, and trends from the expense history
2. Consider seasonal factors and the target month
3. Account for the user's budget constraints
4. Provide realistic predictions with confidence levels
5. Include category-wise breakdown
6. Suggest optimization opportunities

**Response Format (JSON only):**
{
  "predictions": [
    {
      "category": "Food & Dining",
      "predicted_amount": 150.50,
      "confidence": 0.85,
      "reasoning": "Based on recent spending patterns and upcoming weekend"
    },
    {
      "category": "Transportation", 
      "predicted_amount": 75.00,
      "confidence": 0.70,
      "reasoning": "Regular commute expenses expected"
    }
  ],
  "total_predicted": 225.50,
  "budget_utilization": 0.65,
  "insights": [
    {
      "type": "warning",
      "message": "Transportation spending trending up this month",
      "priority": "medium"
    }
  ],
  "recommendations": [
    {
      "action": "Consider meal planning to reduce food expenses",
      "expected_saving": 25.00,
      "difficulty": "easy"
    }
  ]
}

Provide ONLY the JSON response, no additional text.
''';

    debugPrint('🤖 [PROMPT GENERATED] =====================================');
    debugPrint('🤖 Prompt length: ${prompt.length} characters');
    return prompt;
  }

  Future<GenerateContentResponse> _callGeminiAPI(String prompt) async {
    try {
      debugPrint('🤖 Calling Gemini API...');

      final content = [Content.text(prompt)];
      final response =
          await _model!.generateContent(content).timeout(_timeoutDuration);

      if (response.text == null || response.text!.isEmpty) {
        throw AIApiException(
          'Empty response from AI service',
          code: 'EMPTY_RESPONSE',
        );
      }

      debugPrint(
          '🤖 Gemini API response received: ${response.text!.length} characters');
      return response;
    } on TimeoutException {
      throw AIApiException(
        'AI service request timeout',
        code: 'TIMEOUT',
      );
    } catch (e) {
      if (e is AIApiException) rethrow;

      throw AIApiException(
        'Failed to call AI service: $e',
        code: 'API_ERROR',
        details: {'originalError': e.toString()},
      );
    }
  }

  Future<ExpensePredictionResponse> _parseResponse(
      GenerateContentResponse response) async {
    try {
      final responseText = response.text!.trim();
      debugPrint('🤖 [AI RESPONSE] ==========================================');
      debugPrint('🤖 Raw response: $responseText');

      // Try to extract JSON from the response
      String jsonText = responseText;

      // Handle cases where AI might add explanatory text before/after JSON
      final jsonStart = responseText.indexOf('{');
      final jsonEnd = responseText.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        jsonText = responseText.substring(jsonStart, jsonEnd + 1);
      }

      final jsonData = jsonDecode(jsonText);

      // Transform the AI response format to match our model structure
      final transformedData = _transformAIResponse(jsonData);
      final predictionResponse =
          ExpensePredictionResponse.fromJson(transformedData);

      debugPrint('🤖 [PARSED PREDICTION] ================================');
      debugPrint(
          '🤖 Total predicted: ${predictionResponse.summary.totalPredictedSpending}');
      debugPrint(
          '🤖 Budget utilization: ${predictionResponse.summary.budgetUtilizationRate}%');
      debugPrint(
          '🤖 Number of category predictions: ${predictionResponse.predictedExpenses.length}');
      debugPrint(
          '🤖 Number of insights: ${predictionResponse.insights.length}');
      debugPrint(
          '🤖 Number of reallocation suggestions: ${predictionResponse.budgetReallocationSuggestions.length}');

      return predictionResponse;
    } catch (e) {
      debugPrint('🤖 Failed to parse AI response: $e');
      debugPrint('🤖 Raw response was: ${response.text}');

      throw AIApiException(
        'Failed to parse AI response: $e',
        code: 'PARSE_ERROR',
        details: {
          'originalError': e.toString(),
          'rawResponse': response.text,
        },
      );
    }
  }

  /// Transform AI response format to match ExpensePredictionResponse structure
  Map<String, dynamic> _transformAIResponse(Map<String, dynamic> aiResponse) {
    debugPrint('🤖 [TRANSFORMING AI RESPONSE] ==========================');
    debugPrint('🤖 AI Response keys: ${aiResponse.keys.join(', ')}');

    // Extract predictions
    final predictions = aiResponse['predictions'] as List<dynamic>? ?? [];
    final totalPredicted =
        (aiResponse['total_predicted'] as num?)?.toDouble() ?? 0.0;
    final budgetUtilization =
        (aiResponse['budget_utilization'] as num?)?.toDouble() ?? 0.0;
    final insights = aiResponse['insights'] as List<dynamic>? ?? [];
    final recommendations =
        aiResponse['recommendations'] as List<dynamic>? ?? [];

    debugPrint('🤖 Found ${predictions.length} predictions');
    debugPrint('🤖 Total predicted: $totalPredicted');
    debugPrint('🤖 Budget utilization: $budgetUtilization');

    // Transform predictions to match PredictedExpense structure
    final predictedExpenses = predictions.map((pred) {
      try {
        final predMap = pred as Map<String, dynamic>;
        final categoryName = predMap['category']?.toString() ?? 'Unknown';
        final predictedAmount =
            (predMap['predicted_amount'] as num?)?.toDouble() ?? 0.0;
        final confidence = (predMap['confidence'] as num?)?.toDouble() ?? 0.0;
        final reasoning = predMap['reasoning']?.toString() ?? '';

        debugPrint(
            '🤖 Processing prediction: $categoryName -> $predictedAmount (confidence: $confidence)');

        return {
          'categoryId': _getCategoryIdFromName(categoryName),
          'categoryName': categoryName,
          'predictedAmount': predictedAmount,
          'estimatedDate':
              DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'confidence': confidence,
          'reasoning': reasoning,
          'willExceedBudget': false,
          'budgetShortfall': 0.0,
        };
      } catch (e) {
        debugPrint('🤖 Error processing prediction: $e');
        // Return a default prediction in case of parsing error
        return {
          'categoryId': 'others',
          'categoryName': 'Other',
          'predictedAmount': 0.0,
          'estimatedDate':
              DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'confidence': 0.0,
          'reasoning': 'Unable to parse prediction data',
          'willExceedBudget': false,
          'budgetShortfall': 0.0,
        };
      }
    }).toList();

    // Transform insights to match SpendingInsight structure
    final transformedInsights = insights.map((insight) {
      final insightMap = insight as Map<String, dynamic>;
      return {
        'type': insightMap['type'] ?? 'info',
        'category': '',
        'message': insightMap['message'] ?? '',
        'impact': 0.0,
        'recommendations': [],
      };
    }).toList();

    // Transform recommendations to budget reallocation suggestions
    final budgetReallocationSuggestions = recommendations.map((rec) {
      final recMap = rec as Map<String, dynamic>;
      return {
        'fromCategory': 'General',
        'toCategory': 'Savings',
        'suggestedAmount':
            (recMap['expected_saving'] as num?)?.toDouble() ?? 0.0,
        'reason': recMap['action'] ?? '',
      };
    }).toList();

    // Determine risk level based on budget utilization
    String riskLevel = 'low';
    if (budgetUtilization > 0.9) {
      riskLevel = 'high';
    } else if (budgetUtilization > 0.7) {
      riskLevel = 'medium';
    }

    final transformedResponse = {
      'predictedExpenses': predictedExpenses,
      'summary': {
        'totalPredictedSpending': totalPredicted,
        'budgetUtilizationRate': budgetUtilization,
        'riskLevel': riskLevel,
        'categoriesAtRisk': <String>[],
        'totalBudgetShortfall': 0.0,
      },
      'confidenceScore': predictedExpenses.isEmpty
          ? 0.0
          : (predictedExpenses
                  .map((e) => e['confidence'] as double)
                  .reduce((a, b) => a + b) /
              predictedExpenses.length),
      'insights': transformedInsights,
      'budgetReallocationSuggestions': budgetReallocationSuggestions,
      'metadata': {
        'aiModel': _modelName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };

    debugPrint(
        '🤖 Transformation complete. ${predictedExpenses.length} expenses transformed.');

    // Validate the structure before returning
    _validateTransformedResponse(transformedResponse);

    return transformedResponse;
  }

  /// Validate the transformed response structure
  void _validateTransformedResponse(Map<String, dynamic> response) {
    debugPrint('🤖 [VALIDATION] =======================================');

    final predictions = response['predictedExpenses'] as List<dynamic>?;
    debugPrint('🤖 Validating ${predictions?.length ?? 0} predicted expenses');

    if (predictions != null) {
      for (int i = 0; i < predictions.length; i++) {
        final pred = predictions[i] as Map<String, dynamic>;
        debugPrint('🤖 Prediction $i:');
        debugPrint('🤖   - categoryName: ${pred['categoryName']}');
        debugPrint('🤖   - predictedAmount: ${pred['predictedAmount']}');
        debugPrint('🤖   - confidence: ${pred['confidence']}');
        debugPrint('🤖   - reasoning: ${pred['reasoning']}');
      }
    }

    final summary = response['summary'] as Map<String, dynamic>?;
    if (summary != null) {
      debugPrint('🤖 Summary validation:');
      debugPrint(
          '🤖   - totalPredictedSpending: ${summary['totalPredictedSpending']}');
      debugPrint(
          '🤖   - budgetUtilizationRate: ${summary['budgetUtilizationRate']}');
      debugPrint('🤖   - riskLevel: ${summary['riskLevel']}');
    }

    debugPrint('🤖 Validation complete.');
  }

  /// Helper method to get category ID from category name
  String _getCategoryIdFromName(String categoryName) {
    // Enhanced mapping with more variations and case-insensitive matching
    final categoryMap = <String, String>{
      // Food categories
      'Food & Dining': 'food',
      'Food': 'food',
      'Dining': 'food',
      'Restaurant': 'food',
      'Groceries': 'food',
      'Food and Dining': 'food',

      // Transportation categories
      'Transportation': 'transport',
      'Transport': 'transport',
      'Travel': 'transport',
      'Fuel': 'transport',
      'Gas': 'transport',
      'Petrol': 'transport',
      'Public Transport': 'transport',
      'Taxi': 'transport',
      'Uber': 'transport',
      'Grab': 'transport',

      // Shopping categories
      'Shopping': 'shopping',
      'Retail': 'shopping',
      'Clothing': 'shopping',
      'Electronics': 'shopping',

      // Entertainment categories
      'Entertainment': 'entertainment',
      'Movies': 'entertainment',
      'Games': 'entertainment',
      'Sports': 'entertainment',

      // Bills categories
      'Bills & Utilities': 'bills',
      'Bills': 'bills',
      'Utilities': 'bills',
      'Internet': 'bills',
      'Phone': 'bills',
      'Electricity': 'bills',
      'Water': 'bills',

      // Healthcare categories
      'Healthcare': 'healthcare',
      'Medical': 'healthcare',
      'Doctor': 'healthcare',
      'Medicine': 'healthcare',
      'Hospital': 'healthcare',

      // Education categories
      'Education': 'education',
      'School': 'education',
      'Books': 'education',
      'Course': 'education',

      // Personal care categories
      'Personal Care': 'personal',
      'Personal': 'personal',
      'Beauty': 'personal',
      'Salon': 'personal',
      'Haircut': 'personal',

      // Other categories
      'Other': 'others',
      'Others': 'others',
      'Miscellaneous': 'others',
      'General': 'others',
    };

    // Try exact match first
    String result = categoryMap[categoryName] ?? '';

    // If no exact match, try case-insensitive match
    if (result.isEmpty) {
      final lowerCaseName = categoryName.toLowerCase();
      for (final entry in categoryMap.entries) {
        if (entry.key.toLowerCase() == lowerCaseName) {
          result = entry.value;
          break;
        }
      }
    }

    // If still no match, try partial matching
    if (result.isEmpty) {
      final lowerCaseName = categoryName.toLowerCase();
      for (final entry in categoryMap.entries) {
        if (lowerCaseName.contains(entry.key.toLowerCase()) ||
            entry.key.toLowerCase().contains(lowerCaseName)) {
          result = entry.value;
          break;
        }
      }
    }

    debugPrint(
        '🤖 Category mapping: "$categoryName" -> "${result.isEmpty ? 'others' : result}"');
    return result.isEmpty ? 'others' : result;
  }

  /// Clean up resources
  void dispose() {
    _model = null;
    _connectivityService = null;
    _isInitialized = false;
    debugPrint('🤖 GoogleAIExpensePredictionService: Disposed');
  }
}
