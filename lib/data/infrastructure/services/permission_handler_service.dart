import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'notification_sender_service.dart';

/// Service responsible for managing all notification-related permissions
/// Provides centralized permission handling with proper platform support
class PermissionHandlerService {
  static final PermissionHandlerService _instance =
      PermissionHandlerService._internal();
  factory PermissionHandlerService() => _instance;
  PermissionHandlerService._internal();

  // Method channel for native permission operations
  static const platform = MethodChannel('com.kai.budgie/notification_listener');

  /// Check if basic notification permission is granted
  Future<bool> hasNotificationPermission() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.notification.status;
        return status.isGranted;
      }
      return true; // Default to true for other platforms
    } catch (e) {
      debugPrint(
          '🔐 PermissionHandlerService: Error checking notification permission: $e');
      return false;
    }
  }

  /// Check if notification listener permission is granted (Android only)
  Future<bool> hasNotificationListenerPermission() async {
    try {
      if (!Platform.isAndroid) return true;

      final result = await platform.invokeMethod('checkNotificationAccess');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint(
          '🔐 PermissionHandlerService: Error checking notification listener permission: $e');
      return false;
    }
  }

  /// Check if all required permissions are granted
  Future<bool> hasAllPermissions() async {
    try {
      final hasBasic = await hasNotificationPermission();
      final hasListener = await hasNotificationListenerPermission();

      debugPrint(
          '🔐 PermissionHandlerService: Basic permission: $hasBasic, Listener permission: $hasListener');
      return hasBasic && hasListener;
    } catch (e) {
      debugPrint(
          '🔐 PermissionHandlerService: Error checking all permissions: $e');
      return false;
    }
  }

  /// Request basic notification permission
  Future<bool> requestNotificationPermission() async {
    try {
      debugPrint(
          '🔐 PermissionHandlerService: Requesting notification permission...');

      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.notification.request();
        final granted = status.isGranted;

        debugPrint(
            '🔐 PermissionHandlerService: Notification permission ${granted ? 'granted' : 'denied'}');
        return granted;
      }

      return true; // Default to true for other platforms
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Failed to request notification permission: $e');
      return false;
    }
  }

  /// Request notification listener permission (Android only)
  Future<bool> requestNotificationListenerPermission() async {
    try {
      if (!Platform.isAndroid) return true;

      debugPrint(
          '🔐 PermissionHandlerService: Requesting notification listener permission...');

      // Check if already granted
      final alreadyGranted = await hasNotificationListenerPermission();
      if (alreadyGranted) {
        debugPrint(
            '🔐 PermissionHandlerService: Notification listener permission already granted');
        return true;
      }

      // Open settings for user to grant permission manually
      await platform.invokeMethod('requestNotificationAccess');

      // Note: This opens settings, so we can't immediately know if permission was granted
      // The app will need to check again when user returns
      debugPrint(
          '🔐 PermissionHandlerService: Opened settings for notification listener permission');
      return true; // Return true to indicate request was initiated
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Failed to request notification listener permission: $e');
      return false;
    }
  }

  /// Request all required permissions
  Future<bool> requestAllPermissions() async {
    try {
      debugPrint('🔐 PermissionHandlerService: Requesting all permissions...');

      // Step 1: Request basic notification permission
      final basicGranted = await requestNotificationPermission();
      if (!basicGranted) {
        debugPrint(
            '❌ PermissionHandlerService: Basic notification permission denied');
        return false;
      }

      // Step 2: Request notification listener permission (Android only)
      if (Platform.isAndroid) {
        final listenerRequested = await requestNotificationListenerPermission();
        if (!listenerRequested) {
          debugPrint(
              '❌ PermissionHandlerService: Failed to request notification listener permission');
          return false;
        }

        // For Android, we need to check if the permission was actually granted
        // Note: This might return false if user just opened settings but hasn't granted yet
        final listenerGranted = await hasNotificationListenerPermission();
        if (!listenerGranted) {
          debugPrint(
              '⚠️ PermissionHandlerService: Notification listener permission not yet granted (user may need to grant in settings)');
          // Return true anyway to indicate the request process was initiated
          return true;
        }
      }

      debugPrint('✅ PermissionHandlerService: All permissions granted');
      return true;
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Failed to request all permissions: $e');
      return false;
    }
  }

  /// Request permissions with notification sender integration
  Future<bool> requestAllPermissionsWithSender(
      NotificationSenderService sender) async {
    try {
      debugPrint(
          '🔐 PermissionHandlerService: Requesting all permissions with sender integration...');

      // First request basic permissions through the sender
      // This ensures proper initialization of the notification system
      final senderPermissions = await _requestSenderPermissions(sender);
      if (!senderPermissions) {
        debugPrint('❌ PermissionHandlerService: Sender permissions denied');
        return false;
      }

      // Then request listener permissions
      if (Platform.isAndroid) {
        final listenerGranted = await hasNotificationListenerPermission();
        if (!listenerGranted) {
          debugPrint(
              '🔐 PermissionHandlerService: Requesting notification listener permission via settings...');
          await requestNotificationListenerPermission();
          return true; // User will grant manually
        }
      }

      debugPrint(
          '✅ PermissionHandlerService: All permissions with sender granted');
      return true;
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Failed to request permissions with sender: $e');
      return false;
    }
  }

  /// Check permission status for debugging
  Future<Map<String, dynamic>> getPermissionStatus() async {
    try {
      return {
        'platform': Platform.operatingSystem,
        'hasNotificationPermission': await hasNotificationPermission(),
        'hasNotificationListenerPermission':
            await hasNotificationListenerPermission(),
        'hasAllPermissions': await hasAllPermissions(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint(
          '🔐 PermissionHandlerService: Error getting permission status: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Open notification settings (Android only)
  Future<void> openNotificationSettings() async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('openNotificationSettings');
        debugPrint('🔐 PermissionHandlerService: Opened notification settings');
      }
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Failed to open notification settings: $e');
    }
  }

  /// Open notification listener settings specifically for disabling access
  Future<void> openNotificationListenerSettingsForDisabling() async {
    try {
      if (!Platform.isAndroid) return;

      debugPrint(
          '🔐 PermissionHandlerService: Opening notification listener settings for disabling...');

      // Use the same method as enabling, but user intent is to disable
      await platform.invokeMethod('requestNotificationAccess');
      debugPrint(
          '🔐 PermissionHandlerService: Opened notification listener settings for user to disable');
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Failed to open notification listener settings for disabling: $e');
    }
  }

  /// Check if notification access can be revoked (Android only)
  Future<bool> canRevokeNotificationAccess() async {
    try {
      if (!Platform.isAndroid) return false;

      final hasAccess = await hasNotificationListenerPermission();
      debugPrint(
          '🔐 PermissionHandlerService: Can revoke notification access: $hasAccess');
      return hasAccess;
    } catch (e) {
      debugPrint(
          '🔐 PermissionHandlerService: Error checking if notification access can be revoked: $e');
      return false;
    }
  }

  /// Request to revoke notification listener permission (opens settings for user action)
  Future<void> requestRevokeNotificationListenerPermission() async {
    try {
      if (!Platform.isAndroid) return;

      debugPrint(
          '🔐 PermissionHandlerService: Requesting user to revoke notification listener permission...');

      // Check if permission is currently granted
      final hasPermission = await hasNotificationListenerPermission();
      if (!hasPermission) {
        debugPrint(
            '🔐 PermissionHandlerService: Notification listener permission already not granted');
        return;
      }

      // Open settings for user to manually revoke permission
      await openNotificationListenerSettingsForDisabling();

      debugPrint(
          '🔐 PermissionHandlerService: User should now disable notification access in settings');
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Failed to request revoke notification listener permission: $e');
    }
  }

  // Private helper methods

  /// Request permissions through the notification sender
  Future<bool> _requestSenderPermissions(
      NotificationSenderService sender) async {
    try {
      // This is a placeholder for integration with notification sender
      // The actual implementation would depend on the sender's API
      debugPrint(
          '🔐 PermissionHandlerService: Requesting sender permissions...');

      // For now, just request basic permissions
      return await requestNotificationPermission();
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Failed to request sender permissions: $e');
      return false;
    }
  }
}
