import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'api_models.dart';

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
        debugPrint(
            '⚠️ ExpenseDetector: API is not healthy, using fallback detection');
      }

      _isInitialized = true;
      debugPrint('✅ ExpenseDetector: Initialization completed');
    } catch (e) {
      debugPrint('❌ ExpenseDetector: Initialization failed: $e');
      // Don't throw - service should work with fallback even if API fails
      _isInitialized = true;
    }
  }

  /// Analyze notification text for potential expense information
  /// Returns expense data if expense is detected, null otherwise
  Future<Map<String, dynamic>?> analyzeNotification({
    required String text,
    required String source,
  }) async {
    if (text.trim().isEmpty) {
      return null;
    }

    try {
      debugPrint('🔍 ExpenseDetector: Analyzing notification from $source');

      // Try API-based detection first
      final apiResult = await _detectExpenseViaApi(text);
      if (apiResult != null) {
        return _enrichExpenseData(apiResult, text, source);
      }

      // Fallback to pattern-based detection
      final patternResult = _detectExpenseViaPattern(text);
      if (patternResult != null) {
        return _enrichExpenseData(patternResult, text, source);
      }

      return null;
    } catch (e) {
      debugPrint('❌ ExpenseDetector: Analysis failed: $e');

      // Try fallback detection even if API fails
      try {
        final patternResult = _detectExpenseViaPattern(text);
        if (patternResult != null) {
          return _enrichExpenseData(patternResult, text, source);
        }
      } catch (fallbackError) {
        debugPrint(
            '❌ ExpenseDetector: Fallback detection failed: $fallbackError');
      }

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

  /// Detect expense using AI/ML API
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

  /// Extract expense data from API response
  Map<String, dynamic> _extractExpenseFromApiResponse(
    String text,
    NotificationResponse response,
  ) {
    double? amount;
    String currency = 'MYR'; // Default currency

    if (response.extractedAmount != null) {
      final amountStr = response.extractedAmount!;

      // Determine currency from extracted amount
      currency = _extractCurrency(amountStr);

      // Extract numeric value
      final numericPattern = RegExp(r'(\d+(?:\.\d+)?)');
      final numericMatch = numericPattern.firstMatch(amountStr);
      if (numericMatch != null) {
        amount = double.tryParse(numericMatch.group(1) ?? '0');
      }
    }

    // Extract merchant from original text
    final merchant = _extractMerchant(text);

    return {
      'amount': amount ?? 0.0,
      'merchant': merchant,
      'currency': currency,
      'confidence': response.confidence,
      'detectionMethod': 'api',
      'extractedAmount': response.extractedAmount,
    };
  }

  /// Detect expense using pattern matching (fallback)
  Map<String, dynamic>? _detectExpenseViaPattern(String text) {
    try {
      final lowerText = text.toLowerCase();

      // Check for payment keywords
      final paymentKeywords = [
        'paid',
        'payment',
        'transaction',
        'purchase',
        'spent',
        'debit',
        'charged',
        'bill',
        'receipt',
        'checkout'
      ];

      final hasPaymentKeyword =
          paymentKeywords.any((keyword) => lowerText.contains(keyword));

      if (!hasPaymentKeyword) {
        return null;
      }

      // Extract amount and currency
      final amountPattern = RegExp(
          r'(?:RM|MYR|\$|USD|€|EUR|£|GBP)\s*(\d+(?:\.\d+)?)',
          caseSensitive: false);

      final amountMatch = amountPattern.firstMatch(text);
      if (amountMatch == null) {
        return null;
      }

      final amount = double.tryParse(amountMatch.group(1) ?? '0') ?? 0.0;
      final currency = _extractCurrency(amountMatch.group(0) ?? '');
      final merchant = _extractMerchant(text);

      return {
        'amount': amount,
        'merchant': merchant,
        'currency': currency,
        'confidence': 0.6, // Lower confidence for pattern matching
        'detectionMethod': 'pattern',
        'extractedAmount': amountMatch.group(0),
      };
    } catch (e) {
      debugPrint('🔍 ExpenseDetector: Pattern detection failed: $e');
      return null;
    }
  }

  /// Extract currency from amount string
  String _extractCurrency(String amountStr) {
    if (amountStr.contains('RM') || amountStr.contains('MYR')) {
      return 'MYR';
    } else if (amountStr.contains('\$') || amountStr.contains('USD')) {
      return 'USD';
    } else if (amountStr.contains('€') || amountStr.contains('EUR')) {
      return 'EUR';
    } else if (amountStr.contains('£') || amountStr.contains('GBP')) {
      return 'GBP';
    }
    return 'MYR'; // Default
  }

  /// Extract merchant name from text
  String _extractMerchant(String text) {
    final merchantPattern = RegExp(r'(?:at|from|to)\s+([A-Za-z\s]+?)(?:\s|$)',
        caseSensitive: false);

    final merchantMatch = merchantPattern.firstMatch(text);
    return merchantMatch?.group(1)?.trim() ?? 'Unknown';
  }

  /// Enrich expense data with additional metadata
  Map<String, dynamic> _enrichExpenseData(
    Map<String, dynamic> baseData,
    String originalText,
    String source,
  ) {
    return {
      ...baseData,
      'date': DateTime.now().toIso8601String(),
      'category': 'Auto-detected',
      'isAutoDetected': true,
      'source': source,
      'originalText': originalText,
      'detectedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Cleanup resources
  void dispose() {
    _httpClient.close();
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
