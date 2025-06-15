import 'package:flutter/foundation.dart';
import 'dart:async';

/// Performance tracking utility for dependency injection and service initialization
class PerformanceTracker {
  static final Map<String, int> _initializationTimes = {};
  static final Map<String, Stopwatch> _activeTimers = {};
  static final List<String> _initializationOrder = [];
  static int _totalInitializationTime = 0;
  static int _appStartTime = 0;

  /// Start tracking app startup
  static void startAppTracking() {
    _appStartTime = DateTime.now().millisecondsSinceEpoch;
    debugPrint('📱 PerformanceTracker: App startup tracking started');
  }

  /// Start timing a service initialization
  static void startServiceInit(String serviceName) {
    if (_activeTimers.containsKey(serviceName)) {
      debugPrint(
          '⚠️ PerformanceTracker: Timer already running for $serviceName');
      return;
    }

    _activeTimers[serviceName] = Stopwatch()..start();
    debugPrint('⏱️ PerformanceTracker: Started timing $serviceName');
  }

  /// Stop timing a service initialization
  static void stopServiceInit(String serviceName) {
    final timer = _activeTimers.remove(serviceName);
    if (timer == null) {
      debugPrint('⚠️ PerformanceTracker: No timer found for $serviceName');
      return;
    }

    timer.stop();
    final elapsedMs = timer.elapsedMilliseconds;
    _initializationTimes[serviceName] = elapsedMs;
    _initializationOrder.add(serviceName);
    _totalInitializationTime += elapsedMs;

    debugPrint(
        '✅ PerformanceTracker: $serviceName initialized in ${elapsedMs}ms');
  }

  /// Get performance report
  static Map<String, dynamic> getPerformanceReport() {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final totalAppTime = _appStartTime > 0 ? currentTime - _appStartTime : 0;

    return {
      'totalAppStartupTime': totalAppTime,
      'totalServiceInitTime': _totalInitializationTime,
      'servicesInitialized': _initializationTimes.length,
      'activeTimers': _activeTimers.keys.toList(),
      'initializationOrder': _initializationOrder,
      'serviceDetails': _initializationTimes,
      'averageServiceTime': _initializationTimes.isNotEmpty
          ? _totalInitializationTime / _initializationTimes.length
          : 0,
      'slowestServices': _getSlowestServices(),
      'fastestServices': _getFastestServices(),
    };
  }

  /// Get slowest services (top 5)
  static List<Map<String, dynamic>> _getSlowestServices() {
    final sorted = _initializationTimes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(5)
        .map((entry) => {
              'name': entry.key,
              'time': entry.value,
            })
        .toList();
  }

  /// Get fastest services (top 5)
  static List<Map<String, dynamic>> _getFastestServices() {
    final sorted = _initializationTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return sorted
        .take(5)
        .map((entry) => {
              'name': entry.key,
              'time': entry.value,
            })
        .toList();
  }

  /// Print detailed performance report
  static void printPerformanceReport() {
    final report = getPerformanceReport();

    debugPrint('📊 ===== DEPENDENCY INJECTION PERFORMANCE REPORT =====');
    debugPrint('📱 Total app startup time: ${report['totalAppStartupTime']}ms');
    debugPrint(
        '🔧 Total service init time: ${report['totalServiceInitTime']}ms');
    debugPrint('📈 Services initialized: ${report['servicesInitialized']}');
    debugPrint(
        '⚡ Average service time: ${(report['averageServiceTime'] as double).toStringAsFixed(1)}ms');

    debugPrint('\n🐌 Slowest services:');
    for (final service in report['slowestServices'] as List) {
      debugPrint('   - ${service['name']}: ${service['time']}ms');
    }

    debugPrint('\n⚡ Fastest services:');
    for (final service in report['fastestServices'] as List) {
      debugPrint('   - ${service['name']}: ${service['time']}ms');
    }

    debugPrint('\n🔄 Initialization order:');
    for (int i = 0; i < _initializationOrder.length; i++) {
      final serviceName = _initializationOrder[i];
      final time = _initializationTimes[serviceName] ?? 0;
      debugPrint('   ${i + 1}. $serviceName (${time}ms)');
    }

    if (_activeTimers.isNotEmpty) {
      debugPrint('\n⏳ Still initializing:');
      for (final serviceName in _activeTimers.keys) {
        final elapsed = _activeTimers[serviceName]?.elapsedMilliseconds ?? 0;
        debugPrint('   - $serviceName (${elapsed}ms so far)');
      }
    }

    debugPrint('===== END PERFORMANCE REPORT =====\n');
  }

  /// Check for potential performance issues
  static List<String> getPerformanceWarnings() {
    final warnings = <String>[];

    // Check for slow services (>500ms)
    for (final entry in _initializationTimes.entries) {
      if (entry.value > 500) {
        warnings.add('Slow service: ${entry.key} took ${entry.value}ms');
      }
    }

    // Check for stuck initializations (>30 seconds)
    for (final entry in _activeTimers.entries) {
      if (entry.value.elapsedMilliseconds > 30000) {
        warnings.add(
            'Stuck initialization: ${entry.key} running for ${entry.value.elapsedMilliseconds}ms');
      }
    }

    // Check total initialization time
    if (_totalInitializationTime > 3000) {
      warnings
          .add('High total initialization time: ${_totalInitializationTime}ms');
    }

    return warnings;
  }

  /// Reset all tracking data
  static void reset() {
    _initializationTimes.clear();
    _activeTimers.clear();
    _initializationOrder.clear();
    _totalInitializationTime = 0;
    _appStartTime = 0;
    debugPrint('🔄 PerformanceTracker: Reset all tracking data');
  }

  /// Benchmark a function execution
  static Future<T> benchmark<T>(
      String name, Future<T> Function() function) async {
    startServiceInit(name);
    try {
      final result = await function();
      stopServiceInit(name);
      return result;
    } catch (e) {
      stopServiceInit(name);
      rethrow;
    }
  }

  /// Benchmark a synchronous function execution
  static T benchmarkSync<T>(String name, T Function() function) {
    startServiceInit(name);
    try {
      final result = function();
      stopServiceInit(name);
      return result;
    } catch (e) {
      stopServiceInit(name);
      rethrow;
    }
  }
}

/// Mixin for services to automatically track their initialization
mixin PerformanceTracked {
  String get serviceName;

  /// Call this at the start of service initialization
  void startPerformanceTracking() {
    PerformanceTracker.startServiceInit(serviceName);
  }

  /// Call this at the end of service initialization
  void stopPerformanceTracking() {
    PerformanceTracker.stopServiceInit(serviceName);
  }
}

/// Decorator to automatically track service initialization
class PerformanceTrackedService<T> {
  final String serviceName;
  final T Function() _factory;
  T? _instance;
  bool _isInitializing = false;

  PerformanceTrackedService(this.serviceName, this._factory);

  T get instance {
    if (_instance != null) return _instance!;

    if (_isInitializing) {
      throw Exception('Circular dependency detected for $serviceName');
    }

    _isInitializing = true;
    PerformanceTracker.startServiceInit(serviceName);

    try {
      _instance = _factory();
      PerformanceTracker.stopServiceInit(serviceName);
      return _instance!;
    } catch (e) {
      PerformanceTracker.stopServiceInit(serviceName);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  bool get isInitialized => _instance != null;
}
