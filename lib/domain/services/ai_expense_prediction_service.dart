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

/// Service for predicting daily user expenses using Google AI (Gemini)
///
/// This service analyzes historical expense data and budget information to predict
/// likely expenses for the next day or a specific target date. It considers:
/// - Recent spending patterns (last 7 days)
/// - Same-day-of-week historical patterns
/// - Current budget constraints
/// - Day-specific factors (weekday vs weekend, typical activities)
class AIExpensePredictionService {
  static final AIExpensePredictionService _instance =
      AIExpensePredictionService._internal();
  factory AIExpensePredictionService() => _instance;
  AIExpensePredictionService._internal();

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
      debugPrint('🤖 AIExpensePredictionService: Initializing...');

      _model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.4,
          topK: 20,
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
      debugPrint('🤖 AIExpensePredictionService: Initialized successfully');
    } catch (e) {
      debugPrint('🤖 AIExpensePredictionService: Initialization error: $e');
      throw AIApiException(
        'Failed to initialize Google AI service: $e',
        code: 'INITIALIZATION_ERROR',
      );
    }
  }

  /// Predict expenses for the next day based on historical data and current budget
  ///
  /// This method analyzes recent spending patterns (last 7 days) and same-day-of-week
  /// historical data to predict likely expenses for tomorrow or a specific target date.
  ///
  /// Parameters:
  /// - [pastExpenses]: Historical expense data for pattern analysis
  /// - [currentBudget]: Current budget constraints
  /// - [targetDate]: The date to predict for (defaults to tomorrow)
  /// - [userProfile]: Optional user profile data for personalization
  Future<ExpensePredictionResponse> predictNextDayExpenses({
    required List<Expense> pastExpenses,
    required Budget currentBudget,
    DateTime? targetDate,
    Map<String, dynamic>? userProfile,
  }) async {
    return _predictExpenses(
      pastExpenses: pastExpenses,
      currentBudget: currentBudget,
      targetDate: targetDate,
      userProfile: userProfile,
    );
  }

  /// Legacy method for backward compatibility - now predicts next month
  @Deprecated('Use predictNextDayExpenses for daily predictions')
  Future<ExpensePredictionResponse> predictExpenses({
    required List<Expense> pastExpenses,
    required Budget currentBudget,
    required DateTime targetMonth,
    Map<String, dynamic>? userProfile,
  }) async {
    return _predictExpenses(
      pastExpenses: pastExpenses,
      currentBudget: currentBudget,
      targetDate: targetMonth,
      userProfile: userProfile,
    );
  }

  /// Internal prediction implementation
  Future<ExpensePredictionResponse> _predictExpenses({
    required List<Expense> pastExpenses,
    required Budget currentBudget,
    DateTime? targetDate,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      await _ensureInitialized();
      _validateAuthentication();
      await _checkConnectivity();
      _validateInputData(pastExpenses, currentBudget);

      debugPrint('🤖 Starting expense prediction...');

      final effectiveTargetDate =
          targetDate ?? DateTime.now().add(const Duration(days: 1));
      final request = _prepareDailyRequest(
          pastExpenses, currentBudget, effectiveTargetDate, userProfile);
      final prompt = _generatePrompt(request);
      final response = await _callGeminiAPI(prompt);
      final predictionResponse =
          await _parseResponse(response, effectiveTargetDate);

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

    // For daily predictions, require more recent data (within 14 days)
    final cutoffDate = DateTime.now().subtract(const Duration(days: 14));
    final recentExpenses =
        pastExpenses.where((expense) => expense.date.isAfter(cutoffDate));

    if (recentExpenses.isEmpty) {
      throw AIApiException(
        'Recent expense data (within 14 days) is required for accurate daily prediction',
        code: 'OUTDATED_DATA',
      );
    }
  }

  ExpensePredictionRequest _prepareDailyRequest(
    List<Expense> pastExpenses,
    Budget currentBudget,
    DateTime targetDate,
    Map<String, dynamic>? userProfile,
  ) {
    // For daily predictions, use last 7 days for more recent patterns
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    final recentExpenses = pastExpenses
        .where((expense) => expense.date.isAfter(cutoffDate))
        .toList();

    // Also analyze daily patterns for the same day of week
    final targetDayOfWeek = targetDate.weekday;
    final sameDayExpenses = pastExpenses
        .where((expense) =>
            expense.date.weekday == targetDayOfWeek &&
            expense.date
                .isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .toList();

    debugPrint('🤖 [DAILY DATA PREPARATION] =============================');
    debugPrint('🤖 Total expenses in dataset: ${pastExpenses.length}');
    debugPrint('🤖 Expenses in last 7 days: ${recentExpenses.length}');
    debugPrint('🤖 Same day of week (last 30 days): ${sameDayExpenses.length}');
    debugPrint(
        '🤖 Target date: ${targetDate.toIso8601String().split('T')[0]} (${_getDayName(targetDayOfWeek)})');
    debugPrint('🤖 Cutoff date: ${cutoffDate.toIso8601String()}');

    // Log recent expenses
    debugPrint('🤖 [RECENT EXPENSES (7 days)] ========================');
    for (int i = 0; i < recentExpenses.length; i++) {
      final expense = recentExpenses[i];
      debugPrint(
          '🤖 Expense ${i + 1}: ${expense.date.toIso8601String().split('T')[0]} (${_getDayName(expense.date.weekday)}) | '
          '${expense.amount} ${expense.currency} | ${expense.category.name} | ${expense.remark}');
    }

    // Log same-day patterns
    debugPrint('🤖 [SAME DAY PATTERNS] ===============================');
    for (int i = 0; i < sameDayExpenses.length; i++) {
      final expense = sameDayExpenses[i];
      debugPrint(
          '🤖 Same day ${i + 1}: ${expense.date.toIso8601String().split('T')[0]} | '
          '${expense.amount} ${expense.currency} | ${expense.category.name} | ${expense.remark}');
    }

    // Combine recent and same-day expenses, prioritizing recent ones
    final combinedExpenses = [...recentExpenses];
    for (final sameDayExpense in sameDayExpenses) {
      if (!recentExpenses.any((recent) => recent.id == sameDayExpense.id)) {
        combinedExpenses.add(sameDayExpense);
      }
    }

    final expenseData = combinedExpenses
        .map((expense) => ExpenseData.fromExpense(expense))
        .toList();

    final budgetData = BudgetData.fromBudget(currentBudget);

    return ExpensePredictionRequest(
      pastExpenses: expenseData,
      currentBudget: budgetData,
      currency:
          combinedExpenses.isNotEmpty ? combinedExpenses.first.currency : 'MYR',
      targetMonth: targetDate, // Reusing the field but for target date
      userProfile: userProfile,
    );
  }

  String _getDayName(int weekday) {
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return dayNames[weekday - 1];
  }

  String _generatePrompt(ExpensePredictionRequest request) {
    final targetDateStr = request.targetMonth.toIso8601String().split('T')[0];
    final targetDayOfWeek = _getDayName(request.targetMonth.weekday);

    final prompt = '''
You are an AI financial advisor specializing in daily expense prediction. Analyze the provided expense history and budget data to predict tomorrow's specific expenses.

**Current Budget Overview:**
- Total Budget: ${request.currentBudget.totalBudget} ${request.currentBudget.currency}
- Remaining Budget: ${request.currentBudget.remainingBudget} ${request.currentBudget.currency}

**Recent Expense History (Last 7 days + same weekday patterns):**
${request.pastExpenses.map((expense) => '- ${expense.date}: ${expense.amount} ${expense.currency} for ${expense.categoryName} (${expense.description ?? expense.categoryName})').join('\n')}

**Prediction Target:** $targetDateStr ($targetDayOfWeek)

**Instructions:**
1. Focus on DAILY spending patterns, not monthly totals
2. Consider the specific day of the week ($targetDayOfWeek) and typical activities for that day
3. Analyze recent expense patterns (last 7 days) and same-day-of-week historical data
4. Predict realistic individual expenses likely to occur on $targetDayOfWeek
5. Consider factors like: work days vs weekends, meal patterns, commute needs, typical $targetDayOfWeek activities
6. Provide specific, actionable predictions for tomorrow only
7. Keep predicted amounts realistic for single-day expenses (not monthly totals)

**Response Format (JSON only):**
{
  "predictions": [
    {
      "category": "Food & Dining",
      "predicted_amount": 15.50,
      "confidence": 0.85,
      "reasoning": "Typical lunch expense on $targetDayOfWeek, based on recent patterns"
    },
    {
      "category": "Transportation", 
      "predicted_amount": 8.00,
      "confidence": 0.90,
      "reasoning": "Regular commute costs for $targetDayOfWeek"
    }
  ],
  "total_predicted": 23.50,
  "budget_utilization": 0.05,
  "insights": [
    {
      "type": "info",
      "message": "Higher food spending expected on $targetDayOfWeek's",
      "priority": "low"
    }
  ],
  "recommendations": [
    {
      "action": "Pack lunch tomorrow to save on food costs",
      "expected_saving": 10.00,
      "difficulty": "easy"
    }
  ]
}

Provide ONLY the JSON response, no additional text.
''';

    debugPrint('🤖 [DAILY PROMPT GENERATED] ===============================');
    debugPrint('🤖 Prompt length: ${prompt.length} characters');
    debugPrint('🤖 Target: $targetDateStr ($targetDayOfWeek)');
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
      GenerateContentResponse response, DateTime targetDate) async {
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
      final transformedData = _transformAIResponse(jsonData, targetDate);
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
  Map<String, dynamic> _transformAIResponse(
      Map<String, dynamic> aiResponse, DateTime targetDate) {
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
          'estimatedDate': targetDate.toIso8601String(),
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
          'estimatedDate': targetDate.toIso8601String(),
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
        'predictionType': 'daily',
        'targetDate': targetDate.toIso8601String().split('T')[0],
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
    debugPrint('🤖 AIExpensePredictionService: Disposed');
  }
}
