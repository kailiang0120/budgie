import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'api_models.dart';

class NotificationDetectionApiService {
  static final NotificationDetectionApiService _instance =
      NotificationDetectionApiService._internal();
  factory NotificationDetectionApiService() => _instance;
  NotificationDetectionApiService._internal();

  // API Configuration
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const Duration timeoutDuration = Duration(seconds: 30);

  // HTTP client with timeout
  final http.Client _client = http.Client();

  /// Predict if a single notification text represents an expense
  Future<NotificationResponse> classifyNotification(String text) async {
    if (text.trim().isEmpty) {
      throw ApiException('Text cannot be empty');
    }

    try {
      final uri = Uri.parse('$baseUrl/classify');

      debugPrint('Making API request to: $uri');
      debugPrint('Request body: {"text": "$text"}');

      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'text': text,
            }),
          )
          .timeout(timeoutDuration);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return NotificationResponse.fromJson(jsonData);
      } else {
        // Try to parse error message from response
        String errorMessage = 'Failed to predict notification';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? errorMessage;
        } catch (e) {
          // If can't parse error, use default message
        }
        throw ApiException(errorMessage, response.statusCode);
      }
    } on TimeoutException {
      throw ApiException(
          'Request timeout - please check your network connection');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('Invalid response format: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  /// Predict multiple notification texts in batch
  Future<BatchNotificationResponse> predictBatch(List<String> texts) async {
    if (texts.isEmpty) {
      throw ApiException('Text list cannot be empty');
    }

    if (texts.length > 100) {
      throw ApiException('Maximum 100 texts allowed per batch');
    }

    // Filter out empty texts
    final validTexts = texts.where((text) => text.trim().isNotEmpty).toList();
    if (validTexts.isEmpty) {
      throw ApiException('No valid texts provided');
    }

    try {
      final uri = Uri.parse('$baseUrl/classify-batch');

      debugPrint('Making batch API request to: $uri');
      debugPrint('Request body: {"texts": ${validTexts.length} items}');

      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'texts': validTexts,
            }),
          )
          .timeout(timeoutDuration);

      debugPrint('Batch API Response Status: ${response.statusCode}');
      debugPrint('Batch API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return BatchNotificationResponse.fromJson(jsonData);
      } else {
        String errorMessage = 'Failed to classify batch notifications';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? errorMessage;
        } catch (e) {
          // If can't parse error, use default message
        }
        throw ApiException(errorMessage, response.statusCode);
      }
    } on TimeoutException {
      throw ApiException(
          'Request timeout - please check your network connection');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('Invalid response format: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  /// Check if the API server is healthy and the model is loaded
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');

      debugPrint('Checking API health at: $uri');

      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      debugPrint('Health check response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isHealthy =
            data['status'] == 'healthy' && data['model_loaded'] == true;
        debugPrint('API health status: $isHealthy');
        return isHealthy;
      }

      debugPrint('Health check failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Health check error: $e');
      return false;
    }
  }

  /// Get model information
  Future<Map<String, dynamic>?> getModelInfo() async {
    try {
      final uri = Uri.parse('$baseUrl/model-info');

      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      debugPrint('Model info error: $e');
      return null;
    }
  }

  /// Test the API connection with a simple text
  Future<bool> testConnection() async {
    try {
      const testText = "Test payment RM 10.00";
      final result = await classifyNotification(testText);
      debugPrint('API test successful: ${result.message}');
      return true;
    } catch (e) {
      debugPrint('API test failed: $e');
      return false;
    }
  }

  /// Dispose of resources
  void dispose() {
    _client.close();
  }
}
