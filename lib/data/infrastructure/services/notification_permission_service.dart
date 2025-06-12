import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import 'permission_handler_service.dart';
import 'notification_manager_service.dart';

/// Comprehensive service for managing notification permissions with user-friendly workflows
/// Provides high-level methods that handle the complete permission flow including user guidance
class NotificationPermissionService {
  static final NotificationPermissionService _instance =
      NotificationPermissionService._internal();
  factory NotificationPermissionService() => _instance;
  NotificationPermissionService._internal();

  final PermissionHandlerService _permissionHandler =
      PermissionHandlerService();
  late final NotificationManagerService _notificationManager;

  /// Initialize the service with notification manager dependency
  void initialize(NotificationManagerService notificationManager) {
    _notificationManager = notificationManager;
  }

  /// Enable notifications with complete workflow and user guidance
  Future<NotificationPermissionResult> enableNotifications(
      BuildContext context) async {
    try {
      debugPrint(
          '🔔 NotificationPermissionService: Starting enable workflow...');

      // Step 1: Check if already enabled
      final alreadyEnabled = await _permissionHandler.hasAllPermissions();
      if (alreadyEnabled) {
        await _notificationManager.startListening();
        return NotificationPermissionResult.success(
            'Notifications already enabled');
      }

      // Step 2: Request basic notification permission
      final basicGranted =
          await _permissionHandler.requestNotificationPermission();
      if (!basicGranted) {
        return NotificationPermissionResult.denied(
            'Basic notification permission denied');
      }

      // Step 3: For Android, handle notification listener permission
      if (Platform.isAndroid) {
        final hasListenerPermission =
            await _permissionHandler.hasNotificationListenerPermission();

        if (!hasListenerPermission) {
          // Show explanation dialog
          final shouldProceed = await _showListenerPermissionDialog(context);
          if (!shouldProceed) {
            return NotificationPermissionResult.cancelled(
                'User cancelled listener permission');
          }

          // Open settings for user to grant permission
          await _permissionHandler.requestNotificationListenerPermission();

          // Show guidance
          if (context.mounted) {
            _showPermissionGuidance(context, isEnabling: true);
          }

          return NotificationPermissionResult.pending(
              'Notification listener permission pending user action');
        }
      }

      // Step 4: Start listening if all permissions are granted
      final allGranted = await _permissionHandler.hasAllPermissions();
      if (allGranted) {
        await _notificationManager.startListening();
        return NotificationPermissionResult.success(
            'Notifications enabled successfully');
      }

      return NotificationPermissionResult.pending(
          'Some permissions still pending');
    } catch (e) {
      debugPrint(
          '❌ NotificationPermissionService: Error enabling notifications: $e');
      return NotificationPermissionResult.error(
          'Failed to enable notifications: $e');
    }
  }

  /// Disable notifications with complete workflow and user guidance
  Future<NotificationPermissionResult> disableNotifications(
      BuildContext context) async {
    try {
      debugPrint(
          '🔔 NotificationPermissionService: Starting disable workflow...');

      // Step 1: Stop notification listening
      await _notificationManager.stopListening();

      // Step 2: For Android, offer to revoke system permissions
      if (Platform.isAndroid) {
        final canRevoke =
            await _permissionHandler.canRevokeNotificationAccess();

        if (canRevoke && context.mounted) {
          final shouldRevoke = await _showRevokePermissionDialog(context);
          if (shouldRevoke) {
            await _permissionHandler
                .requestRevokeNotificationListenerPermission();

            if (context.mounted) {
              _showPermissionGuidance(context, isEnabling: false);
            }

            return NotificationPermissionResult.success(
                'Notifications disabled, system permission revocation pending');
          }
        }
      }

      return NotificationPermissionResult.success(
          'Notifications disabled successfully');
    } catch (e) {
      debugPrint(
          '❌ NotificationPermissionService: Error disabling notifications: $e');
      return NotificationPermissionResult.error(
          'Failed to disable notifications: $e');
    }
  }

  /// Check current permission status
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    try {
      final hasBasic = await _permissionHandler.hasNotificationPermission();
      final hasListener =
          await _permissionHandler.hasNotificationListenerPermission();
      final isListening = _notificationManager.isListening;

      return NotificationPermissionStatus(
        hasBasicPermission: hasBasic,
        hasListenerPermission: hasListener,
        isListening: isListening,
        isFullyEnabled: hasBasic && hasListener && isListening,
      );
    } catch (e) {
      debugPrint('❌ NotificationPermissionService: Error checking status: $e');
      return NotificationPermissionStatus(
        hasBasicPermission: false,
        hasListenerPermission: false,
        isListening: false,
        isFullyEnabled: false,
      );
    }
  }

  // Private helper methods

  Future<bool> _showListenerPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Special Permission Required'),
            content: const Text(
                'To detect expenses from notifications, Budgie needs access to read your notifications. '
                'You will be redirected to system settings where you need to enable "Notification Access" '
                'for Budgie.\n\n'
                'Look for "Budgie Notification Listener" in the list and toggle it ON.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('CONTINUE'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showRevokePermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Revoke Notification Access?'),
            content: const Text(
                'For complete privacy, you should also revoke notification access permission in system settings.\n\n'
                'Would you like to open system settings to revoke notification access?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('SKIP'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('OPEN SETTINGS'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showPermissionGuidance(BuildContext context,
      {required bool isEnabling}) {
    final message = isEnabling
        ? 'Please enable "Budgie Notification Listener" in the list and come back to the app.'
        : 'Please DISABLE "Budgie Notification Listener" in the list to completely revoke access.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isEnabling ? Colors.green : Colors.orange,
      ),
    );
  }
}

/// Result of notification permission operations
class NotificationPermissionResult {
  final bool isSuccess;
  final String message;
  final NotificationPermissionResultType type;

  NotificationPermissionResult._(this.isSuccess, this.message, this.type);

  factory NotificationPermissionResult.success(String message) =>
      NotificationPermissionResult._(
          true, message, NotificationPermissionResultType.success);

  factory NotificationPermissionResult.denied(String message) =>
      NotificationPermissionResult._(
          false, message, NotificationPermissionResultType.denied);

  factory NotificationPermissionResult.cancelled(String message) =>
      NotificationPermissionResult._(
          false, message, NotificationPermissionResultType.cancelled);

  factory NotificationPermissionResult.pending(String message) =>
      NotificationPermissionResult._(
          true, message, NotificationPermissionResultType.pending);

  factory NotificationPermissionResult.error(String message) =>
      NotificationPermissionResult._(
          false, message, NotificationPermissionResultType.error);
}

enum NotificationPermissionResultType {
  success,
  denied,
  cancelled,
  pending,
  error,
}

/// Current status of notification permissions
class NotificationPermissionStatus {
  final bool hasBasicPermission;
  final bool hasListenerPermission;
  final bool isListening;
  final bool isFullyEnabled;

  NotificationPermissionStatus({
    required this.hasBasicPermission,
    required this.hasListenerPermission,
    required this.isListening,
    required this.isFullyEnabled,
  });

  @override
  String toString() {
    return 'NotificationPermissionStatus(basic: $hasBasicPermission, listener: $hasListenerPermission, listening: $isListening, enabled: $isFullyEnabled)';
  }
}
