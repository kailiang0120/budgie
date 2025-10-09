import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/infrastructure/services/sync_service.dart';
import '../../di/injection_container.dart' as di;

/// Handles application lifecycle transitions that require service coordination.
class AppLifecycleHandler {
  void handleResume() {
    try {
      if (!di.sl.isRegistered<SyncService>()) {
        return;
      }

      final syncService = di.sl<SyncService>();
      if (kDebugMode) {
        debugPrint('?? App resumed - checking for pending syncs');
      }

      unawaited(Future.delayed(const Duration(seconds: 1), () {
        syncService.syncData(fullSync: false);
      }));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('?? Resume sync failed: $e');
      }
    }
  }

  void handleDetached() {
    try {
      if (!di.sl.isRegistered<SyncService>()) {
        return;
      }

      di.sl<SyncService>().dispose();
      if (kDebugMode) {
        debugPrint('?? App detached: disposed SyncService');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('?? Cleanup failed: $e');
      }
    }
  }
}
