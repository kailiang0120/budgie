/// Common exception classes used throughout the application

/// Exception class for AI API errors
class AIApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, dynamic>? details;

  AIApiException(
    this.message, {
    this.code,
    this.statusCode,
    this.details,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AIApiException: $message');
    if (code != null) buffer.write(' (Code: $code)');
    if (statusCode != null) buffer.write(' (Status: $statusCode)');
    return buffer.toString();
  }
}

/// Exception class for API-related errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
