/// Models for notification classification and expense extraction using TFLite v2
///
/// These models handle binary classification of notifications and structured
/// expense data extraction using TFLite services following BudgieAI Mobile Model Integration v2 specifications.

/// Simple response model for binary notification classification
/// Used by TFLite classification model to determine if a notification contains expense data
class NotificationClassificationResponse {
  final bool isExpense;
  final String? message;

  NotificationClassificationResponse({
    required this.isExpense,
    this.message,
  });

  factory NotificationClassificationResponse.fromJson(
      Map<String, dynamic> json) {
    return NotificationClassificationResponse(
      isExpense: json['is_expense'] ?? false,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_expense': isExpense,
      'message': message,
    };
  }
}

/// Batch classification response for multiple notifications
class BatchNotificationClassificationResponse {
  final List<bool> results;
  final int totalProcessed;

  BatchNotificationClassificationResponse({
    required this.results,
    required this.totalProcessed,
  });

  factory BatchNotificationClassificationResponse.fromJson(
      Map<String, dynamic> json) {
    return BatchNotificationClassificationResponse(
      results: (json['results'] as List? ?? [])
          .map((item) => item as bool? ?? false)
          .toList(),
      totalProcessed: json['total_processed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results,
      'total_processed': totalProcessed,
    };
  }
}

/// Exception for classification errors
class NotificationClassificationException implements Exception {
  final String message;
  final int? statusCode;

  NotificationClassificationException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'NotificationClassificationException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Enhanced model for TFLite v2 expense extraction results
/// Used for extracting detailed expense information from notifications
/// that have already been classified as containing expense data
///
/// Simplified to only include the 4 fields extracted by TFLite NER model
class ExpenseExtractionResult {
  final String? amount; // Extracted amount value
  final String? currency; // Extracted currency (defaults to MYR if null)
  final String? merchantName; // Extracted merchant name
  final String? paymentMethod; // Extracted payment method
  final String? suggestedCategory; // Suggested category from AI
  final double confidence; // Model confidence score
  /// Constructor for ExpenseExtractionResult
  /// Uses named parameters with required confidence
  /// Optional fields are nullable to allow flexibility
  ExpenseExtractionResult({
    this.amount,
    this.currency,
    this.merchantName,
    this.paymentMethod,
    this.suggestedCategory,
    required this.confidence,
  });

  factory ExpenseExtractionResult.fromJson(Map<String, dynamic> json) {
    return ExpenseExtractionResult(
      amount: json['amount']?.toString(),
      currency: json['currency']?.toString(),
      merchantName:
          json['merchant']?.toString() ?? json['merchantName']?.toString(),
      paymentMethod: json['payment_method']?.toString() ??
          json['paymentMethod']?.toString(),
      suggestedCategory: json['suggested_category']?.toString() ??
          json['suggestedCategory']?.toString(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'merchantName': merchantName,
      'payment_method': paymentMethod,
      'suggested_category': suggestedCategory,
      'confidence': confidence,
    };
  }

  /// Parse amount as double
  double? get parsedAmount {
    if (amount == null || amount!.isEmpty) return null;
    final cleanAmount = amount!.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanAmount);
  }

  /// Check if extraction result has valid data
  bool get hasValidData {
    final parsed = parsedAmount;
    return parsed != null && parsed > 0 && confidence >= 0.5;
  }

  /// Enhanced validation for API extraction
  bool get isValidForExpenseEntry {
    return hasValidData &&
        merchantName?.isNotEmpty == true &&
        merchantName != 'Unknown' &&
        confidence >= 0.6; // Slightly higher threshold for auto-entry
  }

  /// Get extraction confidence level category
  String get confidenceLevel {
    if (confidence >= 0.8) return 'high';
    if (confidence >= 0.6) return 'medium';
    return 'low';
  }

  /// Check if we have at least the essential data (amount or merchant)
  bool get hasEssentialData {
    final parsed = parsedAmount;
    return (parsed != null && parsed > 0) ||
        (merchantName?.isNotEmpty == true && merchantName != 'Unknown');
  }
}

/// Hybrid detection quality metrics for monitoring and improvement
class DetectionQualityMetrics {
  final int totalDetections;
  final int truePositives;
  final int falsePositives;
  final int trueNegatives;
  final int falseNegatives;
  final double averageConfidence;
  final double averageResponseTime;
  final String modelVersion; // Added model version tracking

  DetectionQualityMetrics({
    required this.totalDetections,
    required this.truePositives,
    required this.falsePositives,
    required this.trueNegatives,
    required this.falseNegatives,
    required this.averageConfidence,
    required this.averageResponseTime,
    this.modelVersion = '2.0', // Default to v2.0
  });

  /// Calculate precision (true positives / (true positives + false positives))
  double get precision {
    final totalPredictedPositives = truePositives + falsePositives;
    return totalPredictedPositives > 0
        ? truePositives / totalPredictedPositives
        : 0.0;
  }

  /// Calculate recall (true positives / (true positives + false negatives))
  double get recall {
    final totalActualPositives = truePositives + falseNegatives;
    return totalActualPositives > 0
        ? truePositives / totalActualPositives
        : 0.0;
  }

  /// Calculate F1 score (harmonic mean of precision and recall)
  double get f1Score {
    final p = precision;
    final r = recall;
    return (p + r) > 0 ? 2 * (p * r) / (p + r) : 0.0;
  }

  /// Calculate accuracy
  double get accuracy {
    return totalDetections > 0
        ? (truePositives + trueNegatives) / totalDetections
        : 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'total_detections': totalDetections,
      'true_positives': truePositives,
      'false_positives': falsePositives,
      'true_negatives': trueNegatives,
      'false_negatives': falseNegatives,
      'average_confidence': averageConfidence,
      'average_response_time': averageResponseTime,
      'model_version': modelVersion, // Added model version to metrics
      'precision': precision,
      'recall': recall,
      'f1_score': f1Score,
      'accuracy': accuracy,
    };
  }
}

/// Enhanced record of a notification detection attempt for hybrid model training and improvement
class NotificationDetectionRecord {
  final String id;
  final String originalNotificationText;
  final String notificationSource;
  final String packageName;
  final DateTime timestamp;
  final ExpenseExtractionResult detectionResult;
  final bool userConfirmed;
  final Map<String, dynamic>? userFeedback;
  final String? userSelectedCategory;
  final double? userCorrectedAmount;
  final String? userCorrectedCurrency;
  final String? userSelectedPaymentMethod; // Added payment method feedback
  final String extractionVersion; // Added extraction version tracking

  NotificationDetectionRecord({
    required this.id,
    required this.originalNotificationText,
    required this.notificationSource,
    required this.packageName,
    required this.timestamp,
    required this.detectionResult,
    required this.userConfirmed,
    this.userFeedback,
    this.userSelectedCategory,
    this.userCorrectedAmount,
    this.userCorrectedCurrency,
    this.userSelectedPaymentMethod, // Added payment method parameter
    this.extractionVersion = '2.0', // Default to hybrid v2.0
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'original_notification_text': originalNotificationText,
      'notification_source': notificationSource,
      'package_name': packageName,
      'timestamp': timestamp.toIso8601String(),
      'detection_result': detectionResult.toJson(),
      'user_confirmed': userConfirmed,
      'user_feedback': userFeedback,
      'user_selected_category': userSelectedCategory,
      'user_corrected_amount': userCorrectedAmount,
      'user_corrected_currency': userCorrectedCurrency,
      'user_selected_payment_method':
          userSelectedPaymentMethod, // Added to JSON
      'extraction_version': extractionVersion, // Added version tracking
    };
  }

  /// Check if user corrections were made
  bool get hasUserCorrections {
    return userCorrectedAmount != null ||
        userCorrectedCurrency != null ||
        userSelectedPaymentMethod != null ||
        userSelectedCategory != null;
  }

  /// Get correction type for analytics
  String get correctionType {
    if (!userConfirmed) return 'rejected';
    if (!hasUserCorrections) return 'accepted_as_is';
    return 'accepted_with_corrections';
  }
}

/// Request model for notification data sent to API backend
/// Used when sending raw notification data to the API for expense extraction
class NotificationApiRequest {
  final String title;
  final String content;
  final DateTime timestamp;
  final String? source;
  final String? packageName;

  NotificationApiRequest({
    required this.title,
    required this.content,
    required this.timestamp,
    this.source,
    this.packageName,
  });

  factory NotificationApiRequest.fromJson(Map<String, dynamic> json) {
    return NotificationApiRequest(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: json['source'],
      packageName: json['package_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'package_name': packageName,
    };
  }
}

/// Response model for API expense extraction
/// Contains structured expense data returned from the API backend
/// Note: Classification (is_expense) is handled by local TensorFlow model, not API
class NotificationApiResponse {
  final double? amount;
  final String? currency;
  final String? merchant;
  final String? paymentMethod;
  final String? suggestedCategory;
  final double confidence;
  final bool success;
  final String? errorMessage;

  NotificationApiResponse({
    this.amount,
    this.currency,
    this.merchant,
    this.paymentMethod,
    this.suggestedCategory,
    required this.confidence,
    required this.success,
    this.errorMessage,
  });

  factory NotificationApiResponse.fromJson(Map<String, dynamic> json) {
    return NotificationApiResponse(
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency']?.toString(),
      merchant: json['merchant']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      suggestedCategory: json['suggested_category']?.toString(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      success: json['success'] ?? false,
      errorMessage: json['error_message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'merchant': merchant,
      'payment_method': paymentMethod,
      'suggested_category': suggestedCategory,
      'confidence': confidence,
      'success': success,
      'error_message': errorMessage,
    };
  }

  /// Convert to ExpenseExtractionResult for backward compatibility
  ExpenseExtractionResult toExtractionResult() {
    return ExpenseExtractionResult(
      amount: amount?.toString(),
      currency: currency,
      merchantName: merchant,
      paymentMethod: paymentMethod,
      suggestedCategory: suggestedCategory,
      confidence: confidence,
    );
  }
}

/// Model for recording API extraction data to Firebase
/// Used for model improvement and analytics
class ExtractedExpenseRecord {
  final String id;
  final NotificationApiRequest originalRequest;
  final NotificationApiResponse apiResponse;
  final DateTime extractionTimestamp;
  final String extractionMethod; // 'api' or 'tflite'

  // User interaction data
  final bool? userAccepted;
  final double? userCorrectedAmount;
  final String? userCorrectedCurrency;
  final String? userSelectedCategory;
  final String? userSelectedPaymentMethod;
  final String? userRemark;
  final DateTime? userInteractionTimestamp;

  ExtractedExpenseRecord({
    required this.id,
    required this.originalRequest,
    required this.apiResponse,
    required this.extractionTimestamp,
    this.extractionMethod = 'api',
    this.userAccepted,
    this.userCorrectedAmount,
    this.userCorrectedCurrency,
    this.userSelectedCategory,
    this.userSelectedPaymentMethod,
    this.userRemark,
    this.userInteractionTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'original_request': originalRequest.toJson(),
      'api_response': apiResponse.toJson(),
      'extraction_timestamp': extractionTimestamp.toIso8601String(),
      'extraction_method': extractionMethod,
      'user_accepted': userAccepted,
      'user_corrected_amount': userCorrectedAmount,
      'user_corrected_currency': userCorrectedCurrency,
      'user_selected_category': userSelectedCategory,
      'user_selected_payment_method': userSelectedPaymentMethod,
      'user_remark': userRemark,
      'user_interaction_timestamp': userInteractionTimestamp?.toIso8601String(),
    };
  }

  /// Create a copy with user feedback data
  ExtractedExpenseRecord withUserFeedback({
    required bool userAccepted,
    double? userCorrectedAmount,
    String? userCorrectedCurrency,
    String? userSelectedCategory,
    String? userSelectedPaymentMethod,
    String? userRemark,
  }) {
    return ExtractedExpenseRecord(
      id: id,
      originalRequest: originalRequest,
      apiResponse: apiResponse,
      extractionTimestamp: extractionTimestamp,
      extractionMethod: extractionMethod,
      userAccepted: userAccepted,
      userCorrectedAmount: userCorrectedAmount,
      userCorrectedCurrency: userCorrectedCurrency,
      userSelectedCategory: userSelectedCategory,
      userSelectedPaymentMethod: userSelectedPaymentMethod,
      userRemark: userRemark,
      userInteractionTimestamp: DateTime.now(),
    );
  }
}
