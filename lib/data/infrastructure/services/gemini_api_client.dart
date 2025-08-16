import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/exceptions.dart';
import '../network/connectivity_service.dart';
import '../../models/expense_detection_models.dart';
import '../../models/budget_reallocation_models.dart';
import '../../models/spending_behavior_models.dart';

/// HTTP client for communicating with BudgieAI FastAPI backend
///
/// This service handles all communication with the BudgieAI FastAPI backend following clean architecture principles.
/// It provides a centralized, type-safe way to interact with AI-powered services through RESTful APIs.
class GeminiApiClient {
  static final GeminiApiClient _instance = GeminiApiClient._internal();
  factory GeminiApiClient() => _instance;
  GeminiApiClient._internal();

  //         ? 'http://10.0.2.2:8000'
  //         : 'http://localhost:8000'

  static const String _baseUrl = 'https://budgiefastapi.onrender.com';
  static const String _apiVersion = 'v1';
  static const String _apiBaseUrl = '$_baseUrl/$_apiVersion';

  // Timeouts
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 180);
  static const Duration _sendTimeout = Duration(seconds: 60);

  // HTTP Client
  late http.Client _client;
  ConnectivityService? _connectivityService;
  bool _isInitialized = false;

  /// Set the connectivity service for dependency injection
  void setConnectivityService(ConnectivityService connectivityService) {
    _connectivityService = connectivityService;
  }

  /// Initialize the HTTP client service
  Future<void> initialize({
    String? modelPreset,
    Map<String, dynamic>? customConfig,
    List<Map<String, dynamic>>? customSafetySettings,
  }) async {
    if (_isInitialized) return;

    try {
      debugPrint('🤖 BudgieApiClient: Initializing HTTP client...');
      _client = http.Client();
      _isInitialized = true;
      debugPrint('🤖 BudgieApiClient: Initialized successfully');
    } catch (e) {
      debugPrint('🤖 BudgieApiClient: Initialization error: $e');
      throw AIApiException(
        'Failed to initialize BudgieAI API client: $e',
        code: 'CLIENT_INIT_ERROR',
      );
    }
  }

  /// Check network connectivity
  Future<bool> _hasConnection() async {
    if (_connectivityService == null) return true;
    return await _connectivityService!.isConnected;
  }

  /// Generic API request handler with error handling
  Future<Map<String, dynamic>> _makeRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    // Check connectivity
    if (!await _hasConnection()) {
      throw AIApiException('No internet connection available',
          code: 'NO_CONNECTIVITY');
    }

    final url = Uri.parse('$_apiBaseUrl$endpoint');
    debugPrint(
        '🤖 [API CALL] $method $url'); // <-- Add this line to log the full API URL and method
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    // Log the request body in debug mode
    if (kDebugMode && body != null) {
      try {
        final requestBodyJson =
            const JsonEncoder.withIndent('  ').convert(body);
        debugPrint('🤖 Request to $endpoint:\n$requestBodyJson');
      } catch (e) {
        debugPrint('🤖 Could not format request body for logging: $e');
      }
    }

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client
              .get(url, headers: defaultHeaders)
              .timeout(timeout ?? _receiveTimeout);
          break;
        case 'POST':
          response = await _client
              .post(
                url,
                headers: defaultHeaders,
                body: body != null ? json.encode(body) : null,
              )
              .timeout(timeout ?? _receiveTimeout);
          break;
        default:
          throw AIApiException('Unsupported HTTP method: $method');
      }
    } on SocketException {
      throw AIApiException('Network error: Unable to connect to server',
          code: 'NETWORK_ERROR');
    } on HttpException catch (e) {
      throw AIApiException('HTTP error: ${e.message}', code: 'HTTP_ERROR');
    } on TimeoutException {
      throw AIApiException('Request timeout: Server took too long to respond',
          code: 'TIMEOUT');
    } catch (e) {
      throw AIApiException('Unexpected error: ${e.toString()}',
          code: 'UNKNOWN_ERROR');
    }

    return _handleResponse(response);
  }

  /// Handle API response and errors
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    try {
      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (statusCode >= 200 && statusCode < 300) {
        return responseData;
      } else {
        throw AIApiException(
          _extractErrorMessage(responseData, statusCode),
          code: 'API_ERROR',
          statusCode: statusCode,
          details: responseData, // Log the full response body for debugging
        );
      }
    } catch (e) {
      if (e is AIApiException) rethrow;
      throw AIApiException('Failed to parse server response',
          code: 'PARSE_ERROR');
    }
  }

  String _extractErrorMessage(Map<String, dynamic> data, int statusCode) {
    if (data.containsKey('detail')) {
      if (data['detail'] is String) {
        return data['detail'];
      } else if (data['detail'] is List) {
        return (data['detail'] as List).map((e) => e['msg']).join(', ');
      }
    }
    return 'Server error (HTTP $statusCode)';
  }

  /// Extract expense from notification using FastAPI backend
  Future<Map<String, dynamic>> extractExpenseFromNotification({
    required NotificationApiRequest request,
  }) async {
    try {
      await _ensureInitialized();

      debugPrint('🤖 BudgieApiClient: Extracting expense from notification...');
      debugPrint(
          '🤖 Notification content: "${request.title}: ${request.content}"');

      // Use the structured request model directly
      final requestBody = request.toJson();

      final response = await _makeRequest(
        '/expense-detection/extract',
        'POST',
        body: requestBody,
        timeout: const Duration(seconds: 30),
      );

      debugPrint(
          '🤖 BudgieApiClient: Expense extraction response received successfully');
      return response;
    } catch (e) {
      debugPrint('🤖 BudgieApiClient: Error extracting expense: $e');
      rethrow;
    }
  }

  /// Analyze budget reallocation using FastAPI backend
  Future<Map<String, dynamic>> analyzeBudgetReallocation({
    required BudgetReallocationRequest request,
  }) async {
    try {
      await _ensureInitialized();

      debugPrint('🤖 BudgieApiClient: Analyzing budget reallocation...');

      final response = await _makeRequest(
        '/budget-reallocation/analyze',
        'POST',
        body: request.toJson(),
        timeout: const Duration(seconds: 120),
      );

      debugPrint(
          '🤖 BudgieApiClient: Budget reallocation response received successfully');
      return response;
    } catch (e) {
      debugPrint('🤖 BudgieApiClient: Error analyzing budget reallocation: $e');
      rethrow;
    }
  }

  /// Analyze spending behavior using FastAPI backend
  Future<Map<String, dynamic>> analyzeSpendingBehavior({
    required SpendingBehaviorAnalysisRequest request,
  }) async {
    try {
      await _ensureInitialized();

      debugPrint('🤖 BudgieApiClient: Analyzing spending behavior...');

      final response = await _makeRequest(
        '/spending-behavior/analyze',
        'POST',
        body: request.toJson(),
        timeout: const Duration(seconds: 90),
      );

      debugPrint(
          '🤖 BudgieApiClient: Spending behavior response received successfully');
      return response;
    } catch (e) {
      debugPrint('🤖 BudgieApiClient: Error analyzing spending behavior: $e');
      rethrow;
    }
  }

  /// Check service health for all endpoints
  Future<Map<String, bool>> checkServicesHealth() async {
    try {
      await _ensureInitialized();

      final healthStatus = <String, bool>{};

      // Check expense detection health
      try {
        final expenseHealthResponse = await _makeRequest(
          '/expense-detection/health',
          'GET',
          timeout: const Duration(seconds: 10),
        );
        healthStatus['expense_detection'] =
            expenseHealthResponse['status'] == 'healthy';
      } catch (e) {
        healthStatus['expense_detection'] = false;
      }

      // Check budget reallocation health
      try {
        final budgetHealthResponse = await _makeRequest(
          '/budget-reallocation/health',
          'GET',
          timeout: const Duration(seconds: 10),
        );
        healthStatus['budget_reallocation'] =
            budgetHealthResponse['status'] == 'healthy';
      } catch (e) {
        healthStatus['budget_reallocation'] = false;
      }

      // Check spending behavior health
      try {
        final behaviorHealthResponse = await _makeRequest(
          '/spending-behavior/health',
          'GET',
          timeout: const Duration(seconds: 10),
        );
        healthStatus['spending_behavior'] =
            behaviorHealthResponse['status'] == 'healthy';
      } catch (e) {
        healthStatus['spending_behavior'] = false;
      }

      return healthStatus;
    } catch (e) {
      debugPrint('🤖 BudgieApiClient: Error checking services health: $e');
      return {
        'expense_detection': false,
        'budget_reallocation': false,
        'spending_behavior': false,
      };
    }
  }

  /// Generate structured response (maintained for backward compatibility)
  @Deprecated('Use specific endpoint methods instead')
  Future<Map<String, dynamic>> generateStructuredResponse({
    required String prompt,
    required Map<String, dynamic> responseSchema,
    List<dynamic>? additionalParts,
    String? modelPreset,
    Duration? timeout,
  }) async {
    throw UnsupportedError(
        'generateStructuredResponse is deprecated. Use specific endpoint methods like extractExpenseFromNotification, analyzeBudgetReallocation, or analyzeSpendingBehavior instead.');
  }

  /// Check if the service is properly initialized
  bool get isInitialized => _isInitialized;

  /// Get the current API base URL
  String get currentApiUrl => _apiBaseUrl;

  /// Reset the service (useful for testing or changing configurations)
  void reset() {
    _client.close();
    _client = http.Client();
    _isInitialized = false;
    debugPrint('🤖 BudgieApiClient: Service reset');
  }

  // Private helper methods

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
    _connectivityService = null;
    _isInitialized = false;
    debugPrint('🤖 BudgieApiClient: Disposed');
  }
}
