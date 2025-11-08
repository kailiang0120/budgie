import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Scoped logger that replaces emoji-heavy debugPrint with structured logging
/// Uses dart:developer for timeline events that can be viewed in DevTools
class AppLogger {
  final String scope;
  
  const AppLogger(this.scope);
  
  /// Log info level message
  void info(String message, {Map<String, dynamic>? data}) {
    _log('INFO', message, data: data);
  }
  
  /// Log warning level message
  void warning(String message, {Map<String, dynamic>? data}) {
    _log('WARN', message, data: data);
  }
  
  /// Log error level message
  void error(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    _log('ERROR', message, data: data, error: error, stackTrace: stackTrace);
  }
  
  /// Log debug level message (only in debug mode)
  void debug(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      _log('DEBUG', message, data: data);
    }
  }
  
  /// Start a timeline event for performance tracking
  void startEvent(String name) {
    developer.Timeline.startSync('$scope: $name');
  }
  
  /// Finish a timeline event
  void finishEvent() {
    developer.Timeline.finishSync();
  }
  
  /// Execute a function with automatic timeline tracking
  T trace<T>(String name, T Function() function) {
    startEvent(name);
    try {
      return function();
    } finally {
      finishEvent();
    }
  }
  
  /// Execute an async function with automatic timeline tracking
  Future<T> traceAsync<T>(String name, Future<T> Function() function) async {
    startEvent(name);
    try {
      return await function();
    } finally {
      finishEvent();
    }
  }
  
  void _log(
    String level, 
    String message, {
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp][$level][$scope] $message';
    
    // Use dart:developer log for structured logging
    developer.log(
      logMessage,
      name: scope,
      time: DateTime.now(),
      level: _getLevelValue(level),
      error: error,
      stackTrace: stackTrace,
    );
    
    // Also print to console in debug mode for convenience
    if (kDebugMode) {
      debugPrint(logMessage);
      if (data != null && data.isNotEmpty) {
        debugPrint('  Data: $data');
      }
      if (error != null) {
        debugPrint('  Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('  StackTrace: $stackTrace');
      }
    }
  }
  
  int _getLevelValue(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARN':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 0;
    }
  }
}
