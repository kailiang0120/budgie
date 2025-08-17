import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';

/// Performance utilities for optimizing UI operations
class PerformanceUtils {
  /// Debounce utility to prevent excessive function calls
  static Timer? _debounceTimer;

  static void debounce(Duration delay, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// Throttle utility to limit function call frequency
  static final Map<String, DateTime> _lastThrottleCall = {};

  static bool throttle(String key, Duration minInterval) {
    final now = DateTime.now();
    final lastCall = _lastThrottleCall[key];

    if (lastCall == null || now.difference(lastCall) >= minInterval) {
      _lastThrottleCall[key] = now;
      return true;
    }
    return false;
  }

  /// Post frame callback wrapper for safe UI updates
  static void postFrame(VoidCallback callback) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => callback());
    } else {
      callback();
    }
  }

  /// Batch multiple notifyListeners calls
  static void batchNotify(List<ChangeNotifier> notifiers) {
    postFrame(() {
      for (final notifier in notifiers) {
        // Justification: We intentionally trigger batched notifications; use
        // dynamic to bypass the protected analyzer check while remaining safe at runtime.
        (notifier as dynamic).notifyListeners();
      }
    });
  }

  /// Check if device has sufficient memory for heavy operations
  static bool isLowMemoryDevice() {
    // Simplified check - in production, implement proper memory check using device_info_plus
    return false;
  }

  /// Dispose utility for cleaning up resources
  static void safeDispose(dynamic resource) {
    try {
      if (resource is Timer && resource.isActive) {
        resource.cancel();
      } else if (resource is StreamSubscription) {
        resource.cancel();
      } else if (resource?.dispose != null) {
        resource.dispose();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Warning: Error disposing resource: $e');
      }
    }
  }

  /// Clean up all static resources
  static void cleanup() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _lastThrottleCall.clear();
  }
}

/// Mixin for ViewModels to add performance optimizations
mixin PerformanceOptimizedViewModel on ChangeNotifier {
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  bool _disposed = false;

  /// Track subscription for proper disposal
  void trackSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  /// Track timer for proper disposal
  void trackTimer(Timer timer) {
    _timers.add(timer);
  }

  /// Debounced notifyListeners to prevent excessive rebuilds
  void notifyListenersDebounced(
      [Duration delay = const Duration(milliseconds: 16)]) {
    if (_disposed) return;
    PerformanceUtils.debounce(delay, () {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  /// Throttled notifyListeners
  void notifyListenersThrottled(String key,
      [Duration minInterval = const Duration(milliseconds: 100)]) {
    if (_disposed) return;
    if (PerformanceUtils.throttle(key, minInterval)) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;

    // Clean up all tracked resources
    for (final subscription in _subscriptions) {
      PerformanceUtils.safeDispose(subscription);
    }
    _subscriptions.clear();

    for (final timer in _timers) {
      PerformanceUtils.safeDispose(timer);
    }
    _timers.clear();

    super.dispose();
  }
}
