import 'dart:developer' as developer;
import 'dart:async';

class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<int>> _historicalData = {};

  static void startTimer(String key) {
    _timers[key] = Stopwatch()..start();
  }

  static int stopTimer(String key, {bool logResult = true}) {
    final timer = _timers[key];
    if (timer == null) {
      if (logResult) {
        developer.log('Timer "$key" not found', name: 'PerformanceMonitor');
      }
      return 0;
    }

    timer.stop();
    final elapsed = timer.elapsedMilliseconds;
    _timers.remove(key);

    if (!_historicalData.containsKey(key)) {
      _historicalData[key] = [];
    }
    _historicalData[key]!.add(elapsed);

    if (logResult) {
      developer.log('$key took ${elapsed}ms', name: 'PerformanceMonitor');
    }

    return elapsed;
  }

  static double getAverageTime(String key) {
    final data = _historicalData[key];
    if (data == null || data.isEmpty) {
      return 0;
    }

    final sum = data.fold(0, (sum, time) => sum + time);
    return sum / data.length;
  }

  static int getMaxTime(String key) {
    final data = _historicalData[key];
    if (data == null || data.isEmpty) {
      return 0;
    }

    return data.reduce((max, time) => max > time ? max : time);
  }

  static void logPerformance(String message, int elapsedTime) {
    developer.log('$message: ${elapsedTime}ms', name: 'PerformanceMonitor');
  }

  static T measure<T>(String key, T Function() function) {
    startTimer(key);
    final result = function();
    stopTimer(key);
    return result;
  }

  static Future<T> measureAsync<T>(
      String key, Future<T> Function() function) async {
    startTimer(key);
    try {
      final result = await function();
      stopTimer(key);
      return result;
    } catch (e) {
      stopTimer(key);
      rethrow;
    }
  }

  static void clearHistoricalData() {
    _historicalData.clear();
  }
}
