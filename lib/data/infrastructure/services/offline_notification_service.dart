import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Service for handling offline notifications and user feedback
class OfflineNotificationService {
  // Singleton instance
  static final OfflineNotificationService _instance =
      OfflineNotificationService._internal();
  factory OfflineNotificationService() => _instance;
  OfflineNotificationService._internal();

  // Global scaffold messenger key for showing snackbars
  static GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  /// Set the global scaffold messenger key
  static void setScaffoldMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldMessengerKey = key;
  }

  /// Show offline notification with retry option
  void showOfflineNotification({
    String? customMessage,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = customMessage ??
        'Please connect to the internet to get the latest exchange rates';

    if (_scaffoldMessengerKey?.currentState != null) {
      _scaffoldMessengerKey!.currentState!.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.wifi_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: onRetry != null
              ? SnackBarAction(
                  label: 'RETRY',
                  textColor: Colors.white,
                  onPressed: onRetry,
                )
              : null,
        ),
      );
    } else {
      // Fallback to debug print if no scaffold messenger is available
      debugPrint('🔴 OFFLINE: $message');
    }
  }

  /// Show success notification when back online
  void showBackOnlineNotification() {
    if (_scaffoldMessengerKey?.currentState != null) {
      _scaffoldMessengerKey!.currentState!.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.wifi,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Back online! Exchange rates updated',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else {
      debugPrint('🟢 ONLINE: Exchange rates updated');
    }
  }

  /// Show information about cached data being used
  void showUsingCachedDataNotification({
    DateTime? lastUpdateTime,
    VoidCallback? onRefresh,
  }) {
    String message = 'Using cached exchange rates';

    if (lastUpdateTime != null) {
      final now = DateTime.now();
      final difference = now.difference(lastUpdateTime);

      if (difference.inDays > 0) {
        message += ' (${difference.inDays} days old)';
      } else if (difference.inHours > 0) {
        message += ' (${difference.inHours} hours old)';
      } else {
        message += ' (${difference.inMinutes} minutes old)';
      }
    }

    if (_scaffoldMessengerKey?.currentState != null) {
      _scaffoldMessengerKey!.currentState!.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.cached,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: onRefresh != null
              ? SnackBarAction(
                  label: 'REFRESH',
                  textColor: Colors.white,
                  onPressed: onRefresh,
                )
              : null,
        ),
      );
    } else {
      debugPrint('📦 CACHED: $message');
    }
  }

  /// Show error notification
  void showErrorNotification(String error) {
    if (_scaffoldMessengerKey?.currentState != null) {
      _scaffoldMessengerKey!.currentState!.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else {
      debugPrint('❌ ERROR: $error');
    }
  }

  /// Show loading notification
  void showLoadingNotification() {
    if (_scaffoldMessengerKey?.currentState != null) {
      _scaffoldMessengerKey!.currentState!.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Updating exchange rates...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.indigo.shade600,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else {
      debugPrint('🔄 LOADING: Updating exchange rates...');
    }
  }

  /// Clear any existing snackbars
  void clearNotifications() {
    _scaffoldMessengerKey?.currentState?.clearSnackBars();
  }
}
