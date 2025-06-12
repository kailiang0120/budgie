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

  /// 将异常转换为 AppError
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

    // 对于其他未知错误，也返回DataError
    return DataError(
      error?.toString() ?? 'Unknown error',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// 打印错误日志
  void log() {
    debugPrint('[$code] $message');
    if (kDebugMode && stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}

/// 网络错误
class NetworkError extends AppError {
  NetworkError(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code ?? 'NETWORK_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
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

/// 认证错误
class AuthError extends AppError {
  AuthError(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code ?? 'AUTH_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
        );

  static AuthError unauthenticated() {
    return AuthError('User not authenticated', code: 'UNAUTHENTICATED');
  }

  static AuthError invalidCredentials() {
    return AuthError('Invalid credentials', code: 'INVALID_CREDENTIALS');
  }
}

/// 数据错误
class DataError extends AppError {
  DataError(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code ?? 'DATA_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
        );

  static DataError notFound() {
    return DataError('Data not found', code: 'NOT_FOUND');
  }

  static DataError invalidFormat() {
    return DataError('Invalid data format', code: 'INVALID_FORMAT');
  }
}
