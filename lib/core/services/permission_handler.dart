import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'notification_sender.dart';

/// Service responsible for managing all notification-related permissions
/// Provides centralized permission handling with proper platform support
class PermissionHandler {
  static final PermissionHandler _instance = PermissionHandler._internal();
  factory PermissionHandler() => _instance;
  PermissionHandler._internal();

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
          '🔐 PermissionHandler: Error checking notification permission: $e');
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
          '🔐 PermissionHandler: Error checking notification listener permission: $e');
      return false;
    }
  }

  /// Check if all required permissions are granted
  Future<bool> hasAllPermissions() async {
    try {
      final hasBasic = await hasNotificationPermission();
      final hasListener = await hasNotificationListenerPermission();

      debugPrint(
          '🔐 PermissionHandler: Basic permission: $hasBasic, Listener permission: $hasListener');
      return hasBasic && hasListener;
    } catch (e) {
      debugPrint('🔐 PermissionHandler: Error checking all permissions: $e');
      return false;
    }
  }

  /// Request basic notification permission
  Future<bool> requestNotificationPermission() async {
    try {
      debugPrint('🔐 PermissionHandler: Requesting notification permission...');

      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.notification.request();
        final granted = status.isGranted;

        debugPrint(
            '🔐 PermissionHandler: Notification permission ${granted ? 'granted' : 'denied'}');
        return granted;
      }

      return true; // Default to true for other platforms
    } catch (e) {
      debugPrint(
          '❌ PermissionHandler: Failed to request notification permission: $e');
      return false;
    }
  }

  /// Request notification listener permission (Android only)
  Future<bool> requestNotificationListenerPermission() async {
    try {
      if (!Platform.isAndroid) return true;

      debugPrint(
          '🔐 PermissionHandler: Requesting notification listener permission...');

      // Check if already granted
      final alreadyGranted = await hasNotificationListenerPermission();
      if (alreadyGranted) {
        debugPrint(
            '🔐 PermissionHandler: Notification listener permission already granted');
        return true;
      }

      // Open settings for user to grant permission manually
      await platform.invokeMethod('requestNotificationAccess');

      // Note: This opens settings, so we can't immediately know if permission was granted
      // The app will need to check again when user returns
      debugPrint(
          '🔐 PermissionHandler: Opened settings for notification listener permission');
      return true; // Return true to indicate request was initiated
    } catch (e) {
      debugPrint(
          '❌ PermissionHandler: Failed to request notification listener permission: $e');
      return false;
    }
  }

  /// Request all required permissions
  Future<bool> requestAllPermissions() async {
    try {
      debugPrint('🔐 PermissionHandler: Requesting all permissions...');

      // Step 1: Request basic notification permission
      final basicGranted = await requestNotificationPermission();
      if (!basicGranted) {
        debugPrint('❌ PermissionHandler: Basic notification permission denied');
        return false;
      }

      // Step 2: Request notification listener permission (Android only)
      if (Platform.isAndroid) {
        final listenerRequested = await requestNotificationListenerPermission();
        if (!listenerRequested) {
          debugPrint(
              '❌ PermissionHandler: Failed to request notification listener permission');
          return false;
        }

        // For Android, we need to check if the permission was actually granted
        // Note: This might return false if user just opened settings but hasn't granted yet
        final listenerGranted = await hasNotificationListenerPermission();
        if (!listenerGranted) {
          debugPrint(
              '⚠️ PermissionHandler: Notification listener permission not yet granted (user may need to grant in settings)');
          // Return true anyway to indicate the request process was initiated
          return true;
        }
      }

      debugPrint('✅ PermissionHandler: All permissions granted');
      return true;
    } catch (e) {
      debugPrint('❌ PermissionHandler: Failed to request all permissions: $e');
      return false;
    }
  }

  /// Request permissions with notification sender integration
  Future<bool> requestAllPermissionsWithSender(
      NotificationSender sender) async {
    try {
      debugPrint(
          '🔐 PermissionHandler: Requesting all permissions with sender integration...');

      // First request basic permissions through the sender
      // This ensures proper initialization of the notification system
      final senderPermissions = await _requestSenderPermissions(sender);
      if (!senderPermissions) {
        debugPrint('❌ PermissionHandler: Sender permissions denied');
        return false;
      }

      // Then request listener permissions
      if (Platform.isAndroid) {
        final listenerGranted = await hasNotificationListenerPermission();
        if (!listenerGranted) {
          debugPrint(
              '🔐 PermissionHandler: Requesting notification listener permission via settings...');
          await requestNotificationListenerPermission();
          return true; // User will grant manually
        }
      }

      debugPrint('✅ PermissionHandler: All permissions with sender granted');
      return true;
    } catch (e) {
      debugPrint(
          '❌ PermissionHandler: Failed to request permissions with sender: $e');
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
      debugPrint('❌ PermissionHandler: Failed to get permission status: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Open app settings for manual permission management
  Future<bool> openAppSettings() async {
    try {
      debugPrint('🔐 PermissionHandler: Opening app settings...');
      return await openAppSettings();
    } catch (e) {
      debugPrint('❌ PermissionHandler: Failed to open app settings: $e');
      return false;
    }
  }

  /// Show permission rationale to user
  String getPermissionRationale() {
    return '''
To detect expenses from your notifications, Budgie needs:

1. Notification Permission: To send you alerts and reminders
2. Notification Access: To read payment notifications from banking apps

Your privacy is protected:
• Only payment-related notifications are analyzed
• No personal data is stored without your consent
• You can disable this feature anytime in settings
''';
  }

  /// Get platform-specific permission instructions
  String getPlatformSpecificInstructions() {
    if (Platform.isAndroid) {
      return '''
Android Instructions:
1. Grant notification permission when prompted
2. For notification access: Settings > Apps > Special Access > Notification Access > Enable Budgie
3. Return to the app to continue
''';
    } else if (Platform.isIOS) {
      return '''
iOS Instructions:
1. Grant notification permission when prompted
2. Ensure notifications are enabled in Settings > Notifications > Budgie
''';
    } else {
      return 'Please grant notification permissions when prompted.';
    }
  }

  // Private methods

  /// Request permissions through the notification sender
  Future<bool> _requestSenderPermissions(NotificationSender sender) async {
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        // For iOS/macOS, use the sender's permission system
        // This ensures proper integration with the notification plugin
        debugPrint(
            '🔐 PermissionHandler: Using sender permission system for iOS/macOS');
        return true; // Sender will handle this during initialization
      } else if (Platform.isAndroid) {
        // For Android, request basic notification permission
        final status = await Permission.notification.request();
        return status.isGranted;
      }

      return true; // Default for other platforms
    } catch (e) {
      debugPrint('❌ PermissionHandler: Sender permission request failed: $e');
      return false;
    }
  }
}
