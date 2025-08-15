import 'package:flutter/foundation.dart';

abstract class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() =>
      'AppError: $message${code != null ? ' (code: $code)' : ''}';

  /// convert error to AppError
  static AppError from(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppError) {
      return error;
    }

    if (error is Exception) {
      return DataError(
        error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // for other unknown errors, return DataError
    return DataError(
      error?.toString() ?? 'Unknown error',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// print error log
  void log() {
    debugPrint('[$code] $message');
    if (kDebugMode && stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}

/// network error
class NetworkError extends AppError {
  NetworkError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: code ?? 'NETWORK_ERROR',
        );

  static NetworkError connectionTimeout() {
    return NetworkError('Connection timeout', code: 'CONNECTION_TIMEOUT');
  }

  static NetworkError serverError() {
    return NetworkError('Server error', code: 'SERVER_ERROR');
  }

  factory NetworkError.noConnection() =>
      NetworkError('No internet connection available');
  factory NetworkError.timeout() => NetworkError('Connection timed out');
}

/// authentication error
class AuthError extends AppError {
  AuthError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: code ?? 'AUTH_ERROR',
        );

  static AuthError unauthenticated() {
    return AuthError('User not authenticated', code: 'UNAUTHENTICATED');
  }

  static AuthError invalidCredentials() {
    return AuthError('Invalid credentials', code: 'INVALID_CREDENTIALS');
  }
}

/// data error
class DataError extends AppError {
  DataError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: code ?? 'DATA_ERROR',
        );

  static DataError notFound() {
    return DataError('Data not found', code: 'NOT_FOUND');
  }

  static DataError invalidFormat() {
    return DataError('Invalid data format', code: 'INVALID_FORMAT');
  }
}
