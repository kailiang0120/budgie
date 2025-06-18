import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';

import 'permission_handler_service.dart';
import 'notification_manager_service.dart';
import 'settings_service.dart';

/// Comprehensive service for managing notification permissions with user-friendly workflows.
/// Provides high-level methods that handle the complete permission flow, including user guidance.
/// This class is the single source of truth for enabling and disabling notification services.
class NotificationPermissionService with WidgetsBindingObserver {
  final PermissionHandlerService _permissionHandler;
  final NotificationManagerService _notificationManager;
  final SettingsService _settingsService;

  // Add completer for async permission waiting
  Completer<bool>? _permissionCompleter;
  bool _isWaitingForPermission = false;
  BuildContext? _currentContext;

  /// Constructs a NotificationPermissionService with required dependencies.
  NotificationPermissionService({
    required PermissionHandlerService permissionHandler,
    required NotificationManagerService notificationManager,
    required SettingsService settingsService,
  })  : _permissionHandler = permissionHandler,
        _notificationManager = notificationManager,
        _settingsService = settingsService {
    // Add app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  /// Clean up resources when service is no longer needed
  void cleanup() {
    WidgetsBinding.instance.removeObserver(this);
    _isWaitingForPermission = false;
    _currentContext = null;
    if (_permissionCompleter != null && !_permissionCompleter!.isCompleted) {
      _permissionCompleter!.complete(false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App resumed - checking for pending permissions');

      // If we were waiting for permissions, check them
      if (_isWaitingForPermission) {
        _checkPermissionsAfterSettings();
      } else if (_settingsService.allowNotification) {
        // Even if we weren't explicitly waiting, verify permissions match settings
        // This handles cases where user might have revoked permissions while app was in background
        _verifyPermissionsMatchSettings();
      }
    }
  }

  /// Verify that the current permissions match the settings
  Future<void> _verifyPermissionsMatchSettings() async {
    try {
      // Check both basic and listener permissions explicitly
      final hasBasicPermission =
          await _permissionHandler.hasNotificationPermission();
      final hasListenerPermission =
          await _permissionHandler.hasNotificationListenerPermission();

      debugPrint(
          '🔐 Verifying permissions - Basic: $hasBasicPermission, Listener: $hasListenerPermission');

      // For Android, also check if the service is actually enabled at OS level
      bool isServiceEnabled = true;
      if (Platform.isAndroid) {
        isServiceEnabled = await _checkNotificationListenerServiceEnabled();
        debugPrint(
            '🔐 Notification service enabled at system level: $isServiceEnabled');
      }

      // If settings say notifications are enabled but any permission is missing,
      // update the settings to match reality
      if (_settingsService.allowNotification &&
          (!hasBasicPermission ||
              !hasListenerPermission ||
              !isServiceEnabled)) {
        debugPrint(
            '⚠️ Permissions don\'t match settings - updating settings to match reality');
        await _settingsService.updateNotificationSetting(false);
      }
    } catch (e) {
      debugPrint('❌ Error verifying permissions: $e');
      // On error, disable notifications to be safe
      if (_settingsService.allowNotification) {
        await _settingsService.updateNotificationSetting(false);
      }
    }
  }

  /// Check permissions after user returns from settings
  Future<void> _checkPermissionsAfterSettings() async {
    if (_permissionCompleter == null || _permissionCompleter!.isCompleted) {
      return;
    }

    try {
      debugPrint('🔄 Checking permissions after returning from settings...');

      // Small delay to ensure system has updated permissions
      await Future.delayed(const Duration(milliseconds: 500));

      // Check both basic and listener permissions explicitly
      final hasBasicPermission =
          await _permissionHandler.hasNotificationPermission();
      final hasListenerPermission =
          await _permissionHandler.hasNotificationListenerPermission();

      debugPrint(
          '🔐 Permission check results - Basic: $hasBasicPermission, Listener: $hasListenerPermission');

      // Both permissions must be granted
      if (hasBasicPermission && hasListenerPermission) {
        debugPrint('✅ All permissions granted after returning from settings!');

        // Double-check with a direct OS check for Android
        if (Platform.isAndroid) {
          final isReallyEnabled =
              await _checkNotificationListenerServiceEnabled();
          if (!isReallyEnabled) {
            debugPrint(
                '⚠️ Permission appears granted but service is not enabled in system');
            await _settingsService.updateNotificationSetting(false);
            _permissionCompleter!.complete(false);
            return;
          }
        }

        _permissionCompleter!.complete(true);
      } else {
        // Check again after a longer delay
        await Future.delayed(const Duration(seconds: 2));

        final hasBasicPermissionDelayed =
            await _permissionHandler.hasNotificationPermission();
        final hasListenerPermissionDelayed =
            await _permissionHandler.hasNotificationListenerPermission();

        debugPrint(
            '🔐 Delayed permission check - Basic: $hasBasicPermissionDelayed, Listener: $hasListenerPermissionDelayed');

        if (hasBasicPermissionDelayed && hasListenerPermissionDelayed) {
          // Double-check with a direct OS check for Android
          if (Platform.isAndroid) {
            final isReallyEnabled =
                await _checkNotificationListenerServiceEnabled();
            if (!isReallyEnabled) {
              debugPrint(
                  '⚠️ Permission appears granted but service is not enabled in system');
              await _settingsService.updateNotificationSetting(false);
              _permissionCompleter!.complete(false);
              return;
            }
          }

          debugPrint('✅ All permissions granted after delayed check!');
          _permissionCompleter!.complete(true);
        } else {
          debugPrint(
              '❌ Permissions still not granted after returning from settings');

          // Update the setting to reflect that permissions were denied
          await _settingsService.updateNotificationSetting(false);

          _showPermissionNotGrantedMessage();
          _permissionCompleter!.complete(false);
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking permissions after settings: $e');

      // Also update settings on error
      await _settingsService.updateNotificationSetting(false);

      _permissionCompleter!.complete(false);
    } finally {
      _isWaitingForPermission = false;
      _currentContext = null;
    }
  }

  /// Direct check with the OS if notification listener service is enabled
  Future<bool> _checkNotificationListenerServiceEnabled() async {
    try {
      if (Platform.isAndroid) {
        final result =
            await const MethodChannel('com.kai.budgie/notification_listener')
                .invokeMethod<bool>('isNotificationServiceEnabled');
        return result ?? false;
      }
      return true; // Non-Android platforms don't need this special permission
    } catch (e) {
      debugPrint('❌ Error checking notification service status: $e');
      return false; // Assume not enabled on error
    }
  }

  /// Show message when permissions are not granted
  void _showPermissionNotGrantedMessage() {
    if (_currentContext != null && _currentContext!.mounted) {
      ScaffoldMessenger.of(_currentContext!).showSnackBar(
        const SnackBar(
          content: Text(
              'Notification permissions were not granted. Please try again and enable the notification listener.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Enables notifications with a complete, robust workflow and user guidance.
  /// This is the primary entry point for turning on notification features.
  Future<NotificationPermissionResult> enableNotifications(
      BuildContext context) async {
    try {
      _currentContext = context;
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

      // Step 3: Request necessary OS-level permissions with proper await.
      final permissionsGranted =
          await _requestAllPermissionsWithGuidance(context);
      if (!permissionsGranted) {
        // If permissions were denied, update the setting to reflect this.
        // This is now handled in _requestAllPermissionsWithGuidance for each specific case
        // but we'll add a final safety check here
        if (_settingsService.allowNotification) {
          await _settingsService.updateNotificationSetting(false);
        }
        return NotificationPermissionResult.denied(
            'OS-level permissions were denied.');
      }

      // Step 4: All checks passed, initialize and start the service.
      try {
        await _notificationManager.initialize();
        await _notificationManager.startListening();
      } catch (initError) {
        debugPrint(
            '! NotificationPermissionService: Error initializing notification manager: $initError');
        // If the error is about already being initialized, try to continue with starting the listener
        if (initError.toString().contains('already been initialized')) {
          try {
            await _notificationManager.startListening();
            debugPrint(
                '✅ NotificationPermissionService: Successfully started listening after initialization error');
            return NotificationPermissionResult.success(
                'Notifications enabled successfully.');
          } catch (startError) {
            debugPrint(
                '❌ NotificationPermissionService: Error starting listener after initialization error: $startError');
            await _settingsService.updateNotificationSetting(false);
            return NotificationPermissionResult.error(
                'Failed to start notification listener.');
          }
        } else {
          // For other errors, propagate the failure
          await _settingsService.updateNotificationSetting(false);
          return NotificationPermissionResult.error(
              'Failed to initialize notification services.');
        }
      }

      // Final verification that everything is working
      final isListening = _notificationManager.isListening;
      if (!isListening) {
        debugPrint(
            '❌ NotificationPermissionService: Service not listening after setup');
        await _settingsService.updateNotificationSetting(false);
        return NotificationPermissionResult.error(
            'Service failed to start listening');
      }

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
            // Set up completer for async waiting
            _permissionCompleter = Completer<bool>();
            _isWaitingForPermission = true;
            _currentContext = context;

            await _permissionHandler
                .requestRevokeNotificationListenerPermission();

            if (context.mounted) {
              _showPermissionGuidance(context, isEnabling: false);
            }

            // Wait briefly for user to return from settings
            try {
              await Future.delayed(const Duration(seconds: 3));
              // We don't actually care about the result here, just making sure
              // we wait a bit for the user to potentially return
            } catch (e) {
              debugPrint('Error waiting for permission revocation: $e');
            } finally {
              // Clean up the completer if it's still pending
              if (_permissionCompleter != null &&
                  !_permissionCompleter!.isCompleted) {
                _permissionCompleter!.complete(false);
              }
              _isWaitingForPermission = false;
              _currentContext = null;
            }
          }
        }
      }

      // Ensure the setting is turned off regardless of what happened with the revocation
      if (_settingsService.allowNotification) {
        await _settingsService.updateNotificationSetting(false);
      }

      debugPrint(
          '✅ NotificationPermissionService: Disable workflow completed.');
      return NotificationPermissionResult.success(
          'Notifications disabled successfully.');
    } catch (e, stackTrace) {
      debugPrint(
          '❌ NotificationPermissionService: Error disabling notifications: $e');
      debugPrint('📍 Stack trace: $stackTrace');

      // Ensure setting is turned off even if there was an error
      if (_settingsService.allowNotification) {
        await _settingsService.updateNotificationSetting(false);
      }

      return NotificationPermissionResult.error(
          'An error occurred while disabling notifications.');
    }
  }

  /// Requests all necessary permissions with user-friendly dialogs for guidance.
  /// Now properly awaits permission changes when user goes to settings.
  Future<bool> _requestAllPermissionsWithGuidance(BuildContext context) async {
    // Request basic notification permission first.
    final basicGranted =
        await _permissionHandler.requestNotificationPermission();
    if (!basicGranted) {
      debugPrint('❌ Basic notification permission denied by user.');
      // Update settings to reflect permission denial
      await _settingsService.updateNotificationSetting(false);
      return false;
    }

    // For Android, handle the special notification listener permission.
    if (Platform.isAndroid) {
      // Check both the permission and if the service is actually enabled
      final hasListenerPermission =
          await _permissionHandler.hasNotificationListenerPermission();
      final isServiceEnabled = await _checkNotificationListenerServiceEnabled();

      debugPrint(
          '🔐 Notification listener permission check: Permission=$hasListenerPermission, ServiceEnabled=$isServiceEnabled');

      if (!hasListenerPermission || !isServiceEnabled) {
        if (!context.mounted) {
          await _settingsService.updateNotificationSetting(false);
          return false;
        }
        final shouldProceed = await _showListenerPermissionDialog(context);
        if (!shouldProceed) {
          debugPrint('❌ User cancelled the listener permission flow.');
          // Update settings when user cancels
          await _settingsService.updateNotificationSetting(false);
          return false;
        }

        // Show loading and guidance while waiting for permission
        if (context.mounted) {
          _showPermissionGuidance(context, isEnabling: true);
        }

        // Set up completer for async waiting
        _permissionCompleter = Completer<bool>();
        _isWaitingForPermission = true;

        // Open settings
        await _permissionHandler.requestNotificationListenerPermission();

        debugPrint(
            '⏳ Waiting for user to grant notification listener permission...');

        // Wait for user to return and grant permission (with timeout)
        final permissionGranted = await _permissionCompleter!.future.timeout(
          const Duration(minutes: 5), // Timeout after 5 minutes
          onTimeout: () {
            debugPrint('⏱️ Permission request timed out');
            _isWaitingForPermission = false;
            _settingsService
                .updateNotificationSetting(false); // Update on timeout
            return false;
          },
        );

        if (!permissionGranted) {
          debugPrint('❌ Notification listener permission was not granted.');
          // Setting is already updated in _checkPermissionsAfterSettings
          return false;
        }
      }
    }

    // Final check to ensure all permissions are granted
    final hasBasicPermission =
        await _permissionHandler.hasNotificationPermission();
    final hasListenerPermission = Platform.isAndroid
        ? await _permissionHandler.hasNotificationListenerPermission()
        : true;
    final isServiceEnabled = Platform.isAndroid
        ? await _checkNotificationListenerServiceEnabled()
        : true;

    final allPermissionsGranted =
        hasBasicPermission && hasListenerPermission && isServiceEnabled;

    if (!allPermissionsGranted) {
      // Final safety check - update settings if permissions are not granted
      await _settingsService.updateNotificationSetting(false);
    }
    return allPermissionsGranted;
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
        duration: const Duration(seconds: 1),
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
