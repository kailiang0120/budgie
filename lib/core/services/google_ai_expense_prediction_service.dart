import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/expense.dart';
import '../../domain/entities/budget.dart';
import 'ai_models.dart';
import '../network/connectivity_service.dart';

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

    // Log budget details
    debugPrint('🤖 [CURRENT MONTH BUDGET] =============================');
    debugPrint(
        '🤖 Total Budget: ${currentBudget.total} ${currentBudget.currency}');
    debugPrint(
        '🤖 Budget Left: ${currentBudget.left} ${currentBudget.currency}');
    debugPrint('🤖 Currency: ${currentBudget.currency}');
    debugPrint('🤖 Category Budgets:');
    currentBudget.categories.forEach((categoryId, categoryBudget) {
      debugPrint(
          '🤖   - $categoryId: ${categoryBudget.budget} ${currentBudget.currency} '
          '(Remaining: ${categoryBudget.left} ${currentBudget.currency})');
    });

    final request = ExpensePredictionRequest(
      pastExpenses: expenseData,
      currentBudget: budgetData,
      currency: currentBudget.currency,
      targetMonth: targetMonth,
      userProfile: userProfile,
    );

    // Log the complete request data being sent to API
    debugPrint('🤖 [REQUEST TO API] ===================================');
    debugPrint('🤖 Request JSON: ${jsonEncode(request.toJson())}');
    debugPrint('🤖 ===================================================');

    return request;
  }

  String _generatePrompt(ExpensePredictionRequest request) {
    final buffer = StringBuffer();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowDate = tomorrow.toIso8601String().split('T')[0];

    buffer.writeln(
        'You are a financial AI assistant specializing in daily expense prediction and budget management.');
    buffer.writeln(
        'Analyze the provided user data and predict their possible expenses for TOMORROW ONLY ($tomorrowDate).');
    buffer.writeln(
        'Focus on identifying potential budget overruns and suggest budget reallocations if needed.');
    buffer.writeln('');

    buffer.writeln('## User\'s Recent Expenses (Last 14 Days):');
    for (final expense in request.pastExpenses) {
      buffer.writeln('- ${expense.date.toIso8601String().split('T')[0]}: '
          '${expense.amount} ${expense.currency} - ${expense.categoryName} '
          '${expense.description != null ? "(${expense.description})" : ""}');
    }
    buffer.writeln('');

    buffer.writeln('## Current Month Budget Status:');
    buffer.writeln(
        '- Total Budget: ${request.currentBudget.totalBudget} ${request.currency}');
    buffer.writeln(
        '- Remaining Budget: ${request.currentBudget.remainingBudget} ${request.currency}');
    buffer.writeln('- Currency: ${request.currency}');
    buffer.writeln('- Category Budget Allocation:');
    request.currentBudget.categoryBudgets.forEach((categoryId, budget) {
      buffer.writeln(
          '  - $categoryId: Budget ${budget.budget} ${request.currency}, '
          'Remaining ${budget.remaining} ${request.currency}');
    });
    buffer.writeln('');

    buffer.writeln('## Prediction Task:');
    buffer.writeln(
        'Predict possible expenses for TOMORROW ($tomorrowDate) based on:');
    buffer.writeln('1. Past 14 days spending patterns by category');
    buffer.writeln(
        '2. Day of week patterns (tomorrow is ${_getDayOfWeek(tomorrow)})');
    buffer.writeln('3. Current budget remaining in each category');
    buffer.writeln(
        '4. Identify if any predicted expense would exceed category budget');
    buffer.writeln('5. Suggest budget reallocation if overruns are detected');
    buffer.writeln('');

    buffer.writeln('## Required Response Format (JSON):');
    buffer.writeln('''{
  "predictedExpenses": [
    {
      "categoryId": "string",
      "categoryName": "string", 
      "predictedAmount": number,
      "estimatedDate": "$tomorrowDate",
      "confidence": number (0-1),
      "reasoning": "why this expense is likely tomorrow",
      "willExceedBudget": boolean,
      "budgetShortfall": number (if willExceedBudget is true)
    }
  ],
  "summary": {
    "totalPredictedSpending": number,
    "budgetUtilizationRate": number (0-1),
    "riskLevel": "low|medium|high",
    "categoriesAtRisk": ["array of category IDs that might exceed budget"],
    "totalBudgetShortfall": number
  },
  "insights": [
    {
      "type": "warning|opportunity|info|reallocation",
      "category": "category name or 'general'",
      "message": "insight message for tomorrow",
      "impact": number (financial impact),
      "recommendations": ["specific actionable recommendations for tomorrow"]
    }
  ],
  "budgetReallocationSuggestions": [
    {
      "fromCategory": "category to take budget from",
      "toCategory": "category that needs more budget", 
      "suggestedAmount": number,
      "reason": "explanation for this reallocation"
    }
  ],
  "metadata": {
    "analysisDate": "${DateTime.now().toIso8601String()}",
    "predictionDate": "$tomorrowDate",
    "predictionHorizon": "1 day",
    "currency": "${request.currency}",
    "dataQuality": "good|fair|poor"
  }
}''');

    buffer.writeln('');
    buffer.writeln(
        'IMPORTANT: Predict expenses ONLY for tomorrow ($tomorrowDate). Focus on budget overrun detection and reallocation suggestions.');
    buffer.writeln(
        'Provide ONLY the JSON response, no additional text or formatting.');

    debugPrint('🤖 [PROMPT GENERATED] =====================================');
    debugPrint('🤖 Generated prompt for API:');
    debugPrint(buffer.toString());
    debugPrint('🤖 ======================================================');

    return buffer.toString();
  }

  String _getDayOfWeek(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[date.weekday - 1];
  }

  Future<String> _callGeminiAPI(String prompt) async {
    try {
      debugPrint('🤖 [API CALL] ========================================');
      debugPrint('🤖 Calling Gemini API with model: $_modelName');
      debugPrint('🤖 API Key: ${_apiKey.substring(0, 10)}...');
      debugPrint('🤖 Timeout: ${_timeoutDuration.inSeconds} seconds');

      final content = [Content.text(prompt)];
      final startTime = DateTime.now();

      final response =
          await _model!.generateContent(content).timeout(_timeoutDuration);

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      debugPrint('🤖 API call completed in ${duration.inMilliseconds}ms');

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        debugPrint('🤖 [ERROR] Empty response from Gemini API');
        throw AIApiException(
          'Empty response from Gemini API',
          code: 'EMPTY_RESPONSE',
        );
      }

      debugPrint('🤖 [API RESPONSE] ====================================');
      debugPrint('🤖 Response length: ${responseText.length} characters');
      debugPrint('🤖 Raw response:');
      debugPrint(responseText);
      debugPrint('🤖 ================================================');

      return responseText;
    } on TimeoutException {
      debugPrint(
          '🤖 [ERROR] API request timed out after ${_timeoutDuration.inSeconds} seconds');
      throw AIApiException(
        'Gemini API request timed out after ${_timeoutDuration.inSeconds} seconds',
        code: 'TIMEOUT',
      );
    } catch (e) {
      if (e is AIApiException) rethrow;

      debugPrint('🤖 [ERROR] Gemini API call failed: $e');
      throw AIApiException(
        'Gemini API call failed: $e',
        code: 'API_ERROR',
        details: {'originalError': e.toString()},
      );
    }
  }

  Future<ExpensePredictionResponse> _parseResponse(String responseText) async {
    try {
      debugPrint('🤖 [RESPONSE PARSING] =================================');
      debugPrint('🤖 Starting response parsing...');

      String cleanedResponse = responseText.trim();
      debugPrint('🤖 Original response length: ${responseText.length}');

      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
        debugPrint('🤖 Removed ```json prefix');
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse =
            cleanedResponse.substring(0, cleanedResponse.length - 3);
        debugPrint('🤖 Removed ``` suffix');
      }
      cleanedResponse = cleanedResponse.trim();

      debugPrint('🤖 Cleaned response length: ${cleanedResponse.length}');
      debugPrint('🤖 Cleaned response:');
      debugPrint(cleanedResponse);

      final Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(cleanedResponse);
        debugPrint('🤖 JSON parsing successful');
        debugPrint('🤖 Parsed JSON keys: ${jsonData.keys.toList()}');
      } catch (e) {
        debugPrint('🤖 [ERROR] JSON parsing failed: $e');
        throw AIApiException(
          'Invalid JSON response from AI: $e',
          code: 'INVALID_JSON',
          details: {'rawResponse': responseText},
        );
      }

      _validateResponseStructure(jsonData);

      if (!jsonData.containsKey('metadata')) {
        jsonData['metadata'] = {
          'analysisDate': DateTime.now().toIso8601String(),
          'dataQuality': 'good',
          'predictionHorizon': '1 day',
        };
        debugPrint('🤖 Added default metadata');
      }

      if (!jsonData.containsKey('confidenceScore')) {
        jsonData['confidenceScore'] = _calculateOverallConfidence(jsonData);
        debugPrint(
            '🤖 Calculated overall confidence: ${jsonData['confidenceScore']}');
      }

      // Log key response details
      final predictedExpenses = jsonData['predictedExpenses'] as List?;
      final summary = jsonData['summary'] as Map<String, dynamic>?;

      debugPrint('🤖 [PARSED RESULTS] ===================================');
      debugPrint(
          '🤖 Number of predicted expenses: ${predictedExpenses?.length ?? 0}');
      if (predictedExpenses != null) {
        for (int i = 0; i < predictedExpenses.length; i++) {
          final expense = predictedExpenses[i];
          debugPrint('🤖 Expense ${i + 1}: ${expense['categoryName']} - '
              '${expense['predictedAmount']} ${jsonData['metadata']['currency']} '
              '(Confidence: ${expense['confidence']})');
        }
      }

      if (summary != null) {
        debugPrint(
            '🤖 Total predicted spending: ${summary['totalPredictedSpending']}');
        debugPrint('🤖 Risk level: ${summary['riskLevel']}');
        debugPrint('🤖 Categories at risk: ${summary['categoriesAtRisk']}');
      }

      final reallocationSuggestions =
          jsonData['budgetReallocationSuggestions'] as List?;
      if (reallocationSuggestions != null &&
          reallocationSuggestions.isNotEmpty) {
        debugPrint('🤖 Budget reallocation suggestions:');
        for (int i = 0; i < reallocationSuggestions.length; i++) {
          final suggestion = reallocationSuggestions[i];
          debugPrint(
              '🤖   ${i + 1}. Move ${suggestion['suggestedAmount']} from '
              '${suggestion['fromCategory']} to ${suggestion['toCategory']}');
        }
      }
      debugPrint('🤖 ================================================');

      return ExpensePredictionResponse.fromJson(jsonData);
    } catch (e) {
      if (e is AIApiException) rethrow;

      debugPrint('🤖 [ERROR] Response parsing failed: $e');
      throw AIApiException(
        'Failed to parse AI response: $e',
        code: 'PARSE_ERROR',
        details: {'rawResponse': responseText, 'originalError': e.toString()},
      );
    }
  }

  void _validateResponseStructure(Map<String, dynamic> jsonData) {
    final requiredFields = ['predictedExpenses', 'summary', 'insights'];

    for (final field in requiredFields) {
      if (!jsonData.containsKey(field)) {
        throw AIApiException(
          'Missing required field in AI response: $field',
          code: 'INVALID_RESPONSE_STRUCTURE',
        );
      }
    }
  }

  double _calculateOverallConfidence(Map<String, dynamic> jsonData) {
    try {
      final expenses = jsonData['predictedExpenses'] as List?;
      if (expenses == null || expenses.isEmpty) {
        return 0.5;
      }

      double totalConfidence = 0.0;
      int validCount = 0;

      for (final expense in expenses) {
        final confidence = (expense['confidence'] as num?)?.toDouble();
        if (confidence != null) {
          totalConfidence += confidence;
          validCount++;
        }
      }

      return validCount > 0 ? totalConfidence / validCount : 0.5;
    } catch (e) {
      return 0.5;
    }
  }

  Future<bool> testConnection() async {
    try {
      await _ensureInitialized();

      final testPrompt = '''
        Test the expense prediction API. Respond with valid JSON:
        {
          "status": "connected",
          "model": "$_modelName",
          "timestamp": "${DateTime.now().toIso8601String()}"
        }
      ''';

      final content = [Content.text(testPrompt)];
      final response = await _model!
          .generateContent(content)
          .timeout(const Duration(seconds: 10));

      final responseText = response.text;
      return responseText != null && responseText.contains('connected');
    } catch (e) {
      debugPrint('🤖 Connection test failed: $e');
      return false;
    }
  }

  Map<String, dynamic> getModelInfo() {
    return {
      'modelName': _modelName,
      'isInitialized': _isInitialized,
      'features': [
        'Expense Prediction',
        'Budget Analysis',
        'Spending Insights',
        'Risk Assessment',
      ],
    };
  }

  Future<bool> isAvailable() async {
    try {
      if (_connectivityService != null) {
        await _checkConnectivity();
      }
      return _isInitialized;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _model = null;
    _isInitialized = false;
  }
}
