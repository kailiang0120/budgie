class NotificationResponse {
  final bool isExpense;
  final double confidence;
  final int predictedClass;
  final String? extractedAmount;
  final String message;

  NotificationResponse({
    required this.isExpense,
    required this.confidence,
    required this.predictedClass,
    this.extractedAmount,
    required this.message,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      isExpense: json['is_expense'] ?? false,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      predictedClass: json['predicted_class'] ?? 0,
      extractedAmount: json['extracted_amount'],
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_expense': isExpense,
      'confidence': confidence,
      'predicted_class': predictedClass,
      'extracted_amount': extractedAmount,
      'message': message,
    };
  }
}

class BatchNotificationResponse {
  final List<NotificationResponse> results;
  final int totalProcessed;

  BatchNotificationResponse({
    required this.results,
    required this.totalProcessed,
  });

  factory BatchNotificationResponse.fromJson(Map<String, dynamic> json) {
    return BatchNotificationResponse(
      results: (json['results'] as List? ?? [])
          .map((item) => NotificationResponse.fromJson(item))
          .toList(),
      totalProcessed: json['total_processed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results.map((result) => result.toJson()).toList(),
      'total_processed': totalProcessed,
    };
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
