import 'package:flutter/material.dart';
import 'dart:io';

import 'permission_handler_service.dart';
import 'notification_manager_service.dart';
import 'settings_service.dart';

/// Comprehensive service for managing notification permissions with user-friendly workflows.
/// Provides high-level methods that handle the complete permission flow, including user guidance.
/// This class is the single source of truth for enabling and disabling notification services.
class NotificationPermissionService {
  final PermissionHandlerService _permissionHandler;
  final NotificationManagerService _notificationManager;
  final SettingsService _settingsService;

  /// Constructs a NotificationPermissionService with required dependencies.
  NotificationPermissionService({
    required PermissionHandlerService permissionHandler,
    required NotificationManagerService notificationManager,
    required SettingsService settingsService,
  })  : _permissionHandler = permissionHandler,
        _notificationManager = notificationManager,
        _settingsService = settingsService;

  /// Enables notifications with a complete, robust workflow and user guidance.
  /// This is the primary entry point for turning on notification features.
  Future<NotificationPermissionResult> enableNotifications(
      BuildContext context) async {
    try {
      debugPrint(
          '🔔 NotificationPermissionService: Starting robust enable workflow...');

      // Step 1: Verify the user's in-app setting. This is the master switch.
      if (!_settingsService.allowNotification) {
        debugPrint(
            '⚠️ NotificationPermissionService: Aborting. User has not enabled notifications in app settings.');
        return NotificationPermissionResult.cancelled(
            'User has not enabled notifications in app settings.');
      }

      // Step 2: Check if services are already running.
      if (_notificationManager.isListening) {
        debugPrint('✅ NotificationPermissionService: Already listening.');
        return NotificationPermissionResult.success(
            'Notifications already enabled and running.');
      }

      // Step 3: Request necessary OS-level permissions.
      final permissionsGranted =
          await _requestAllPermissionsWithGuidance(context);
      if (!permissionsGranted) {
        // If permissions were denied, update the setting to reflect this.
        await _settingsService.updateNotificationSetting(false);
        return NotificationPermissionResult.denied(
            'OS-level permissions were denied.');
      }

      // Step 4: All checks passed, initialize and start the service.
      await _notificationManager.initialize();
      await _notificationManager.startListening();

      debugPrint(
          '✅ NotificationPermissionService: Enable workflow completed successfully.');
      return NotificationPermissionResult.success(
          'Notifications enabled successfully.');
    } catch (e, stackTrace) {
      debugPrint(
          '❌ NotificationPermissionService: Error enabling notifications: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      // Ensure setting is turned off on failure.
      await _settingsService.updateNotificationSetting(false);
      return NotificationPermissionResult.error(
          'A critical error occurred while enabling notifications.');
    }
  }

  /// Disables notifications and stops all related services.
  Future<NotificationPermissionResult> disableNotifications(
      BuildContext context) async {
    try {
      debugPrint(
          '🔔 NotificationPermissionService: Starting disable workflow...');

      // Step 1: Stop the notification listening service immediately.
      await _notificationManager.stopListening();

      // Step 2: For Android, offer to guide the user to revoke system permissions for complete privacy.
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
          }
        }
      }

      debugPrint(
          '✅ NotificationPermissionService: Disable workflow completed.');
      return NotificationPermissionResult.success(
          'Notifications disabled successfully.');
    } catch (e, stackTrace) {
      debugPrint(
          '❌ NotificationPermissionService: Error disabling notifications: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return NotificationPermissionResult.error(
          'An error occurred while disabling notifications.');
    }
  }

  /// Requests all necessary permissions with user-friendly dialogs for guidance.
  Future<bool> _requestAllPermissionsWithGuidance(BuildContext context) async {
    // Request basic notification permission first.
    final basicGranted =
        await _permissionHandler.requestNotificationPermission();
    if (!basicGranted) {
      debugPrint('❌ Basic notification permission denied by user.');
      return false;
    }

    // For Android, handle the special notification listener permission.
    if (Platform.isAndroid) {
      final hasListenerPermission =
          await _permissionHandler.hasNotificationListenerPermission();
      if (!hasListenerPermission) {
        if (!context.mounted) return false;
        final shouldProceed = await _showListenerPermissionDialog(context);
        if (!shouldProceed) {
          debugPrint('❌ User cancelled the listener permission flow.');
          return false;
        }

        // Open settings and provide guidance. We cannot await the result here.
        await _permissionHandler.requestNotificationListenerPermission();
        if (context.mounted) {
          _showPermissionGuidance(context, isEnabling: true);
        }
        // The app must re-check permission status upon resuming.
        // For this flow, we assume the user will grant it and proceed.
      }
    }

    // Final check. In a real-world scenario, you might want to await user returning from settings.
    return _permissionHandler.hasAllPermissions();
  }

  /// Check current permission status.
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    try {
      final hasBasic = await _permissionHandler.hasNotificationPermission();
      final hasListener =
          await _permissionHandler.hasNotificationListenerPermission();
      final isListening = _notificationManager.isListening;
      final isEnabledInSettings = _settingsService.allowNotification;

      return NotificationPermissionStatus(
        hasBasicPermission: hasBasic,
        hasListenerPermission: hasListener,
        isListening: isListening,
        isFullyEnabled:
            isEnabledInSettings && hasBasic && hasListener && isListening,
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

  // Private helper methods for UI dialogs

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
