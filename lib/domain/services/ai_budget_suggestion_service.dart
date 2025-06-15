import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../data/infrastructure/services/secure_storage_service.dart';
import '../entities/budget.dart';
import '../../data/infrastructure/errors/app_error.dart';

/// Service for generating budget reallocation suggestions using Google's Generative AI.
class AIBudgetSuggestionService {
  final SecureStorageService _secureStorageService;
  GenerativeModel? _model;

  AIBudgetSuggestionService(
      {required SecureStorageService secureStorageService})
      : _secureStorageService = secureStorageService;

  /// Initializes the AI model. Returns true if successful, false otherwise.
  Future<bool> initialize() async {
    try {
      final apiKey = await _secureStorageService.getGoogleApiKey();
      if (apiKey == null) {
        debugPrint(
            '❌ AIBudgetSuggestionService: Google AI API key is not set.');
        const simulatedApiKey =
            'AIzaSyDiAw4ef91-wUbu9bOZoZLpfEVzBAebBRA'; // Replace this
        if (simulatedApiKey == 'AIzaSyDiAw4ef91-wUbu9bOZoZLpfEVzBAebBRA') {
          debugPrint(
              '⚠️ AIBudgetSuggestionService: Using a placeholder API key. Please replace it.');
          return false;
        }
        _model = GenerativeModel(
            model: 'gemini-2.5-flash-preview-05-20', apiKey: simulatedApiKey);
        return true;
      }
      _model = GenerativeModel(
          model: 'gemini-2.5-flash-preview-05-20', apiKey: apiKey);
      debugPrint('✅ AIBudgetSuggestionService: Initialized successfully.');
      return true;
    } catch (e) {
      debugPrint('❌ AIBudgetSuggestionService: Initialization failed: $e');
      return false;
    }
  }

  /// Generates budget suggestions based on the provided budget data.
  Future<String> getBudgetSuggestions(Budget budget) async {
    if (_model == null) {
      final initialized = await initialize();
      if (!initialized) {
        throw AIException(
            'AI model is not initialized. Please set the API key.');
      }
    }

    try {
      final prompt = _buildPrompt(budget);
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      if (response.text == null) {
        throw AIException('Received an empty response from the AI model.');
      }

      debugPrint(
          '💡 AIBudgetSuggestionService: Successfully received suggestions from AI.');
      return response.text!;
    } catch (e) {
      debugPrint(
          '❌ AIBudgetSuggestionService: Error generating suggestions: $e');
      throw AIException('Failed to get suggestions from the AI model.',
          originalError: e);
    }
  }

  /// Constructs the prompt to be sent to the AI model.
  String _buildPrompt(Budget budget) {
    final budgetJson = jsonEncode(budget.toMap());
    return '''
As a financial advisor, analyze the following monthly budget data for a user.
Based on their allocated amounts versus their current spending (the 'left' amount), provide a suggested budget reallocation to help them better achieve their financial goals, such as increasing savings or optimizing spending.

Present the suggestions in a clear, itemized list with a brief justification for each change. The response should be formatted as a simple string, suitable for direct display in a mobile app. Do not use Markdown formatting like headers or bold text.

If no reallocations are necessary, simply state that the budget looks well-balanced.

Budget Data (in ${budget.currency}):
$budgetJson
''';
  }
}

/// Custom exception for AI service-related errors.
class AIException extends AppError {
  AIException(
    String message, {
    dynamic originalError,
  }) : super(
          message,
          code: 'AI_SERVICE_ERROR',
          originalError: originalError,
        );
}
