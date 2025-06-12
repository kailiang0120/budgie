import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../data/models/api_response_models.dart';

/// Service responsible for detecting expenses from notification text using AI/ML models
/// Provides clean interface for expense analysis and pattern matching
class ExpenseDetector {
  static final ExpenseDetector _instance = ExpenseDetector._internal();
  factory ExpenseDetector() => _instance;
  ExpenseDetector._internal();

  // API Configuration
  static const String _baseUrl = 'http://10.0.2.2:8000';
  static const Duration _timeoutDuration = Duration(seconds: 30);

  // HTTP client
  final http.Client _httpClient = http.Client();
  bool _isInitialized = false;

  /// Initialize the expense detector service
  Future<void> initialize() async {
    try {
      debugPrint('🔍 ExpenseDetector: Initializing...');

      // Check API health on initialization
      final isHealthy = await checkHealth();
      if (!isHealthy) {
        debugPrint('⚠️ ExpenseDetector: API is not healthy');
      }

      _isInitialized = true;
      debugPrint('✅ ExpenseDetector: Initialization completed');
    } catch (e) {
      debugPrint('❌ ExpenseDetector: Initialization failed: $e');
      // Service should fail gracefully if API is not available
      _isInitialized = true;
    }
  }

  Future<Map<String, dynamic>?> analyzeNotification({
    required String text,
    required String source,
  }) async {
    if (text.trim().isEmpty) {
      return null;
    }

    try {
      debugPrint('🔍 ExpenseDetector: Analyzing notification from $source');

      // Only try API-based detection - no fallback
      final apiResult = await _detectExpenseViaApi(text);
      if (apiResult != null) {
        return _enrichExpenseData(apiResult, text, source);
      }

      debugPrint('🔍 ExpenseDetector: No expense detected via API');
      return null;
    } catch (e) {
      debugPrint('❌ ExpenseDetector: Analysis failed: $e');
      return null;
    }
  }

  /// Check if the API service is healthy
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$_baseUrl/health');

      final response = await _httpClient.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isHealthy =
            data['status'] == 'healthy' && data['model_loaded'] == true;
        debugPrint('🔍 ExpenseDetector: API health status: $isHealthy');
        return isHealthy;
      }

      return false;
    } catch (e) {
      debugPrint('🔍 ExpenseDetector: Health check failed: $e');
      return false;
    }
  }

  /// Get model information from the API
  Future<Map<String, dynamic>?> getModelInfo() async {
    try {
      final uri = Uri.parse('$_baseUrl/model-info');

      final response = await _httpClient.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      debugPrint('🔍 ExpenseDetector: Model info request failed: $e');
      return null;
    }
  }

  /// Test the detector with sample text
  Future<bool> testDetection({String? testText}) async {
    try {
      const defaultText = "Payment of RM 25.50 at Starbucks has been processed";
      final result = await analyzeNotification(
        text: testText ?? defaultText,
        source: 'test',
      );

      final success = result != null;
      debugPrint(
          '🔍 ExpenseDetector: Test detection ${success ? 'passed' : 'failed'}');
      return success;
    } catch (e) {
      debugPrint('🔍 ExpenseDetector: Test detection failed: $e');
      return false;
    }
  }

  // Private methods

  /// Detect expense using AI/ML API only
  Future<Map<String, dynamic>?> _detectExpenseViaApi(String text) async {
    try {
      final uri = Uri.parse('$_baseUrl/classify');

      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'text': text}),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final notificationResponse = NotificationResponse.fromJson(jsonData);

        // Check if classified as expense with sufficient confidence
        if (notificationResponse.isExpense &&
            notificationResponse.confidence >= 0.5) {
          return _extractExpenseFromApiResponse(text, notificationResponse);
        }
      }

      return null;
    } on TimeoutException {
      debugPrint('🔍 ExpenseDetector: API request timeout');
      return null;
    } catch (e) {
      debugPrint('🔍 ExpenseDetector: API detection failed: $e');
      return null;
    }
  }

  /// Extract expense data from API response - only amount, no merchant
  Map<String, dynamic> _extractExpenseFromApiResponse(
    String text,
    NotificationResponse response,
  ) {
    double? amount;
    String currency = 'MYR'; // Default currency

    if (response.extractedAmount != null) {
      final amountStr = response.extractedAmount!;
      amount = double.tryParse(amountStr.replaceAll(RegExp(r'[^\d.]'), ''));

      // Infer currency from extracted amount
      if (amountStr.toUpperCase().contains('RM') ||
          amountStr.toUpperCase().contains('MYR')) {
        currency = 'MYR';
      } else if (amountStr.contains('\$') ||
          amountStr.toUpperCase().contains('USD')) {
        currency = 'USD';
      } else if (amountStr.contains('€') ||
          amountStr.toUpperCase().contains('EUR')) {
        currency = 'EUR';
      }
    }

    return {
      'amount': amount,
      'currency': currency,
      'confidence': response.confidence,
      'isAutoDetected': true,
      'detectionMethod': 'ai_api',
      'originalText': text,
    };
  }

  /// Enrich expense data with additional information
  Map<String, dynamic> _enrichExpenseData(
    Map<String, dynamic> expenseData,
    String originalText,
    String source,
  ) {
    return {
      ...expenseData,
      'source': source,
      'timestamp': DateTime.now().toIso8601String(),
      'fullNotification': originalText,
      'processingVersion': '2.0', // Updated version
    };
  }

  /// Cleanup resources
  void dispose() {
    _httpClient.close();
    debugPrint('🔍 ExpenseDetector: Disposed');
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
