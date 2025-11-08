import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:developer' as developer;

/// Performance tracking utility for dependency injection and service initialization
/// Integrates with Flutter's Timeline for actionable traces in DevTools
class PerformanceTracker {
  static final Map<String, int> _initializationTimes = {};
  static final Map<String, Stopwatch> _activeTimers = {};
  static final List<String> _initializationOrder = [];
  static int _totalInitializationTime = 0;
  static int _appStartTime = 0;

  /// Start tracking app startup
  static void startAppTracking() {
    _appStartTime = DateTime.now().millisecondsSinceEpoch;
    developer.Timeline.startSync('App Startup');
    if (kDebugMode) {
      developer.log('App startup tracking started', name: 'PerformanceTracker');
    }
  }

  /// Start timing a service initialization
  static void startServiceInit(String serviceName) {
    if (_activeTimers.containsKey(serviceName)) {
      if (kDebugMode) {
        developer.log('Timer already running for $serviceName', 
          name: 'PerformanceTracker',
          level: 900,
        );
      }
      return;
    }

    _activeTimers[serviceName] = Stopwatch()..start();
    developer.Timeline.startSync('Init: $serviceName');
    if (kDebugMode) {
      developer.log('Started timing $serviceName', name: 'PerformanceTracker');
    }
  }

  /// Stop timing a service initialization
  static void stopServiceInit(String serviceName) {
    final timer = _activeTimers.remove(serviceName);
    if (timer == null) {
      if (kDebugMode) {
        developer.log('No timer found for $serviceName', 
          name: 'PerformanceTracker',
          level: 900,
        );
      }
      return;
    }

    timer.stop();
    developer.Timeline.finishSync();
    
    final elapsedMs = timer.elapsedMilliseconds;
    _initializationTimes[serviceName] = elapsedMs;
    _initializationOrder.add(serviceName);
    _totalInitializationTime += elapsedMs;

    if (kDebugMode) {
      developer.log(
        '$serviceName initialized in ${elapsedMs}ms',
        name: 'PerformanceTracker',
        time: DateTime.now(),
      );
    }
    
    // Add instant event to timeline for easier visualization
    developer.Timeline.instantSync('$serviceName: ${elapsedMs}ms');
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

    developer.Timeline.finishSync(); // Finish app startup tracking
    
    if (kDebugMode) {
      developer.log(
        '===== DEPENDENCY INJECTION PERFORMANCE REPORT =====',
        name: 'PerformanceTracker',
      );
      developer.log(
        'Total app startup time: ${report['totalAppStartupTime']}ms',
        name: 'PerformanceTracker',
      );
      developer.log(
        'Total service init time: ${report['totalServiceInitTime']}ms',
        name: 'PerformanceTracker',
      );
      developer.log(
        'Services initialized: ${report['servicesInitialized']}',
        name: 'PerformanceTracker',
      );
      
      final avgTime = report['averageServiceTime'];
      if (avgTime != null && avgTime > 0) {
        developer.log(
          'Average service time: ${avgTime.toDouble().toStringAsFixed(1)}ms',
          name: 'PerformanceTracker',
        );
      }

      developer.log('Slowest services:', name: 'PerformanceTracker');
      for (final service in report['slowestServices'] as List) {
        developer.log('  - ${service['name']}: ${service['time']}ms', 
          name: 'PerformanceTracker');
      }

      developer.log('Fastest services:', name: 'PerformanceTracker');
      for (final service in report['fastestServices'] as List) {
        developer.log('  - ${service['name']}: ${service['time']}ms', 
          name: 'PerformanceTracker');
      }

      developer.log('Initialization order:', name: 'PerformanceTracker');
      for (int i = 0; i < _initializationOrder.length; i++) {
        final serviceName = _initializationOrder[i];
        final time = _initializationTimes[serviceName] ?? 0;
        developer.log('  ${i + 1}. $serviceName (${time}ms)', 
          name: 'PerformanceTracker');
      }

      if (_activeTimers.isNotEmpty) {
        developer.log('Still initializing:', name: 'PerformanceTracker', level: 900);
        for (final serviceName in _activeTimers.keys) {
          final elapsed = _activeTimers[serviceName]?.elapsedMilliseconds ?? 0;
          developer.log('  - $serviceName (${elapsed}ms so far)', 
            name: 'PerformanceTracker', level: 900);
        }
      }

      developer.log(
        '===== END PERFORMANCE REPORT =====',
        name: 'PerformanceTracker',
      );
    }
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
    if (kDebugMode) {
      developer.log('Reset all tracking data', name: 'PerformanceTracker');
    }
  }

  /// Benchmark a function execution
  static Future<T> benchmark<T>(
      String name, Future<T> Function() function) async {
    developer.Timeline.startSync(name);
    startServiceInit(name);
    try {
      final result = await function();
      stopServiceInit(name);
      return result;
    } catch (e) {
      stopServiceInit(name);
      rethrow;
    } finally {
      developer.Timeline.finishSync();
    }
  }

  /// Benchmark a synchronous function execution
  static T benchmarkSync<T>(String name, T Function() function) {
    developer.Timeline.startSync(name);
    startServiceInit(name);
    try {
      final result = function();
      stopServiceInit(name);
      return result;
    } catch (e) {
      stopServiceInit(name);
      rethrow;
    } finally {
      developer.Timeline.finishSync();
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
