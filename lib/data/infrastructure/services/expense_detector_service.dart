import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../models/api_models.dart';

/// Service responsible for detecting expenses from notification text using AI/ML API
/// Simplified to only extract amounts - always uses API service
class ExpenseDetectorService {
  static final ExpenseDetectorService _instance =
      ExpenseDetectorService._internal();
  factory ExpenseDetectorService() => _instance;
  ExpenseDetectorService._internal();

  // API Configuration
  static const String _baseUrl = 'http://10.0.2.2:8000';
  static const Duration _timeoutDuration = Duration(seconds: 30);

  // HTTP client
  final http.Client _httpClient = http.Client();

  /// Initialize the expense detector service
  Future<void> initialize() async {
    try {
      debugPrint('🔍 ExpenseDetectorService: Initializing...');

      // Check API health on initialization
      final isHealthy = await checkHealth();
      if (!isHealthy) {
        debugPrint('⚠️ ExpenseDetectorService: API is not healthy');
      }

      debugPrint('✅ ExpenseDetectorService: Initialization completed');
    } catch (e) {
      debugPrint('❌ ExpenseDetectorService: Initialization failed: $e');
      // Service should fail gracefully if API is not available
    }
  }

  /// Analyze notification text for potential expense information
  /// Returns expense data if expense is detected via API, null otherwise
  /// Only extracts amount - no fallback pattern detection
  Future<Map<String, dynamic>?> analyzeNotification({
    required String text,
    required String source,
  }) async {
    if (text.trim().isEmpty) {
      return null;
    }

    try {
      debugPrint(
          '🔍 ExpenseDetectorService: Analyzing notification from $source');

      // Only try API-based detection - no fallback
      final apiResult = await _detectExpenseViaApi(text);
      if (apiResult != null) {
        return _enrichExpenseData(apiResult, text, source);
      }

      debugPrint('🔍 ExpenseDetectorService: No expense detected via API');
      return null;
    } catch (e) {
      debugPrint('❌ ExpenseDetectorService: Analysis failed: $e');
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
        debugPrint('🔍 ExpenseDetectorService: API health status: $isHealthy');
        return isHealthy;
      }

      return false;
    } catch (e) {
      debugPrint('🔍 ExpenseDetectorService: Health check failed: $e');
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
      debugPrint('🔍 ExpenseDetectorService: Model info request failed: $e');
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
          '🔍 ExpenseDetectorService: Test detection ${success ? 'passed' : 'failed'}');
      return success;
    } catch (e) {
      debugPrint('🔍 ExpenseDetectorService: Test detection failed: $e');
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
      debugPrint('🔍 ExpenseDetectorService: API request timeout');
      return null;
    } catch (e) {
      debugPrint('🔍 ExpenseDetectorService: API detection failed: $e');
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

  /// Clean up resources
  void dispose() {
    _httpClient.close();
    debugPrint('🔍 ExpenseDetectorService: Disposed');
  }
}
