import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';

import 'settings_service.dart';

/// Comprehensive service for managing all app permissions
/// Provides centralized permission handling with proper platform support
/// This is the single source of truth for all permission-related operations
class PermissionHandlerService with WidgetsBindingObserver {
  // Singleton instance
  static final PermissionHandlerService _instance =
      PermissionHandlerService._internal();
  factory PermissionHandlerService() => _instance;
  PermissionHandlerService._internal() {
    // Add app lifecycle observer to detect when app returns from settings
    WidgetsBinding.instance.addObserver(this);
  }

  // Method channel for native permission operations
  static const platform = MethodChannel('com.kai.budgie/notification_listener');

  // Settings service reference
  late final SettingsService _settingsService;

  // Permission request tracking
  final Map<Permission, Completer<bool>> _pendingPermissions = {};
  bool _isWaitingForPermission = false;

  /// Initialize the service with required dependencies
  Future<void> initialize(SettingsService settingsService) async {
    _settingsService = settingsService;
    debugPrint('🔐 PermissionHandlerService: Initialized');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForPermission) {
      debugPrint('📱 App resumed - checking for pending permissions');
      _checkPendingPermissions();
    }
  }

  /// Clean up resources when service is no longer needed
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isWaitingForPermission = false;
    _pendingPermissions.forEach((_, completer) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });
    _pendingPermissions.clear();
  }

  // PERMISSION STATUS CHECKS

  /// Check if notification permission is granted
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

  /// Check if storage permission is granted
  Future<bool> hasStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        if (await _isAndroid13OrHigher()) {
          final photos = await Permission.photos.status;
          final videos = await Permission.videos.status;
          return photos.isGranted && videos.isGranted;
        } else {
          final storage = await Permission.storage.status;
          return storage.isGranted;
        }
      } else if (Platform.isIOS) {
        final photos = await Permission.photos.status;
        return photos.isGranted;
      }
      return true; // Default to true for other platforms
    } catch (e) {
      debugPrint(
          '🔐 PermissionHandlerService: Error checking storage permission: $e');
      return false;
    }
  }

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      debugPrint(
          '🔐 PermissionHandlerService: Error checking camera permission: $e');
      return false;
    }
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    try {
      final status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      debugPrint(
          '🔐 PermissionHandlerService: Error checking location permission: $e');
      return false;
    }
  }

  /// Check if all required permissions for a specific feature are granted
  Future<bool> hasPermissionsForFeature(PermissionFeature feature) async {
    switch (feature) {
      case PermissionFeature.notifications:
        final hasBasic = await hasNotificationPermission();
        final hasListener = Platform.isAndroid
            ? await hasNotificationListenerPermission()
            : true;
        return hasBasic && hasListener;

      case PermissionFeature.storage:
        return await hasStoragePermission();

      case PermissionFeature.camera:
        return await hasCameraPermission();

      case PermissionFeature.location:
        return await hasLocationPermission();

      case PermissionFeature.all:
        final notificationPermission =
            await hasPermissionsForFeature(PermissionFeature.notifications);
        final storagePermission =
            await hasPermissionsForFeature(PermissionFeature.storage);
        final cameraPermission =
            await hasPermissionsForFeature(PermissionFeature.camera);
        final locationPermission =
            await hasPermissionsForFeature(PermissionFeature.location);

        return notificationPermission &&
            storagePermission &&
            cameraPermission &&
            locationPermission;
    }
  }

  // PERMISSION REQUESTS

  /// Request notification permission
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
  Future<bool> requestNotificationListenerPermission(
      BuildContext? context) async {
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

      // Set up completer to wait for permission
      if (context != null && context.mounted) {
        final completer = Completer<bool>();
        _pendingPermissions[Permission.notification] = completer;
        _isWaitingForPermission = true;
      }

      // Open settings for user to grant permission manually
      await platform.invokeMethod('requestNotificationAccess');

      // If we're tracking this permission with a completer, wait for result
      if (_pendingPermissions.containsKey(Permission.notification)) {
        // Wait for the user to return from settings with a timeout
        return await _pendingPermissions[Permission.notification]!
            .future
            .timeout(
          const Duration(minutes: 2),
          onTimeout: () {
            debugPrint('⏱️ Permission request timed out');
            _isWaitingForPermission = false;
            return false;
          },
        );
      }

      // Default case - we can't know the result yet
      return true;
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Failed to request notification listener permission: $e');
      return false;
    }
  }

  /// Request storage permission
  Future<bool> requestStoragePermission() async {
    try {
      debugPrint(
          '🔐 PermissionHandlerService: Requesting storage permission...');

      if (Platform.isAndroid) {
        if (await _isAndroid13OrHigher()) {
          // For Android 13+, we need to request photos and videos permissions
          final photosStatus = await Permission.photos.request();
          final videosStatus = await Permission.videos.request();
          return photosStatus.isGranted && videosStatus.isGranted;
        } else {
          // For older Android versions, request storage permission
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        return status.isGranted;
      }

      return true; // Default to true for other platforms
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Failed to request storage permission: $e');
      return false;
    }
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      debugPrint(
          '🔐 PermissionHandlerService: Requesting camera permission...');

      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Failed to request camera permission: $e');
      return false;
    }
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      debugPrint(
          '🔐 PermissionHandlerService: Requesting location permission...');

      final status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Failed to request location permission: $e');
      return false;
    }
  }

  /// Request all permissions for a specific feature
  Future<PermissionStatus> requestPermissionsForFeature(
      PermissionFeature feature, BuildContext? context) async {
    try {
      switch (feature) {
        case PermissionFeature.notifications:
          final basicGranted = await requestNotificationPermission();
          if (!basicGranted) {
            return PermissionStatus(
              isGranted: false,
              feature: feature,
              message: 'Basic notification permission denied',
            );
          }

          if (Platform.isAndroid) {
            final listenerGranted =
                await requestNotificationListenerPermission(context);
            if (!listenerGranted) {
              return PermissionStatus(
                isGranted: false,
                feature: feature,
                message: 'Notification listener permission denied',
              );
            }
          }

          return PermissionStatus(
            isGranted: true,
            feature: feature,
            message: 'All notification permissions granted',
          );

        case PermissionFeature.storage:
          final granted = await requestStoragePermission();
          return PermissionStatus(
            isGranted: granted,
            feature: feature,
            message: granted
                ? 'Storage permission granted'
                : 'Storage permission denied',
          );

        case PermissionFeature.camera:
          final granted = await requestCameraPermission();
          return PermissionStatus(
            isGranted: granted,
            feature: feature,
            message: granted
                ? 'Camera permission granted'
                : 'Camera permission denied',
          );

        case PermissionFeature.location:
          final granted = await requestLocationPermission();
          return PermissionStatus(
            isGranted: granted,
            feature: feature,
            message: granted
                ? 'Location permission granted'
                : 'Location permission denied',
          );

        case PermissionFeature.all:
          final notifications = await requestPermissionsForFeature(
              PermissionFeature.notifications, context);
          final storage = await requestPermissionsForFeature(
              PermissionFeature.storage, context);
          final camera = await requestPermissionsForFeature(
              PermissionFeature.camera, context);
          final location = await requestPermissionsForFeature(
              PermissionFeature.location, context);

          final allGranted = notifications.isGranted &&
              storage.isGranted &&
              camera.isGranted &&
              location.isGranted;

          return PermissionStatus(
            isGranted: allGranted,
            feature: feature,
            message: allGranted
                ? 'All permissions granted'
                : 'Some permissions were denied',
          );
      }
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Failed to request permissions for $feature: $e');
      return PermissionStatus(
        isGranted: false,
        feature: feature,
        message: 'Error requesting permissions: $e',
      );
    }
  }

  // PERMISSION MANAGEMENT

  /// Open app settings
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('❌ PermissionHandlerService: Failed to open app settings: $e');
    }
  }

  /// Open notification settings
  Future<void> openNotificationSettings() async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('openNotificationSettings');
        debugPrint('🔐 PermissionHandlerService: Opened notification settings');
      } else {
        await openAppSettings();
      }
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Failed to open notification settings: $e');
    }
  }

  /// Open notification listener settings for disabling
  Future<void> openNotificationListenerSettingsForDisabling() async {
    try {
      if (!Platform.isAndroid) return;

      await platform.invokeMethod('requestNotificationAccess');
      debugPrint(
          '🔐 PermissionHandlerService: Opened notification listener settings for disabling');
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Failed to open notification listener settings: $e');
    }
  }

  /// Check if notification access can be revoked
  Future<bool> canRevokeNotificationAccess() async {
    try {
      if (!Platform.isAndroid) return false;

      return await hasNotificationListenerPermission();
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Error checking if notification access can be revoked: $e');
      return false;
    }
  }

  /// Request to revoke notification listener permission
  Future<void> requestRevokeNotificationListenerPermission() async {
    try {
      if (!Platform.isAndroid) return;

      final hasPermission = await hasNotificationListenerPermission();
      if (!hasPermission) {
        debugPrint(
            '🔐 PermissionHandlerService: Notification listener permission already not granted');
        return;
      }

      await openNotificationListenerSettingsForDisabling();
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Failed to request revoke notification listener permission: $e');
    }
  }

  /// Get detailed permission status for debugging
  Future<Map<String, dynamic>> getDetailedPermissionStatus() async {
    try {
      return {
        'platform': Platform.operatingSystem,
        'notifications': {
          'basic': await hasNotificationPermission(),
          'listener': await hasNotificationListenerPermission(),
        },
        'storage': await hasStoragePermission(),
        'camera': await hasCameraPermission(),
        'location': await hasLocationPermission(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Error getting permission status: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // HELPER METHODS

  /// Check pending permissions after returning from settings
  Future<void> _checkPendingPermissions() async {
    if (_pendingPermissions.isEmpty) return;

    debugPrint('🔄 Checking permissions after returning from settings...');

    // Small delay to ensure system has updated permissions
    await Future.delayed(const Duration(milliseconds: 500));

    // Check notification listener permission if it's pending
    if (_pendingPermissions.containsKey(Permission.notification)) {
      final hasListener = await hasNotificationListenerPermission();

      debugPrint('🔐 Notification listener permission check: $hasListener');

      // For Android, also check if the service is actually enabled
      bool isServiceEnabled = true;
      if (Platform.isAndroid) {
        isServiceEnabled = await _checkNotificationListenerServiceEnabled();
        debugPrint(
            '🔐 Notification service enabled at system level: $isServiceEnabled');
      }

      // Complete the pending permission request
      final completer = _pendingPermissions[Permission.notification]!;
      if (!completer.isCompleted) {
        final granted = hasListener && isServiceEnabled;

        // Update settings based on permission result
        if (_settingsService.allowNotification != granted) {
          await _settingsService.updateNotificationSetting(granted);
        }

        completer.complete(granted);
      }

      _pendingPermissions.remove(Permission.notification);
    }

    // Reset waiting state if all permissions are processed
    if (_pendingPermissions.isEmpty) {
      _isWaitingForPermission = false;
    }
  }

  /// Check if notification listener service is enabled at OS level
  Future<bool> _checkNotificationListenerServiceEnabled() async {
    try {
      if (Platform.isAndroid) {
        final result =
            await platform.invokeMethod<bool>('isNotificationServiceEnabled');
        return result ?? false;
      }
      return true; // Non-Android platforms don't need this special permission
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Error checking notification service status: $e');
      return false;
    }
  }

  /// Check if device is running Android 13 or higher
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;

    try {
      final sdkVersion =
          await platform.invokeMethod<int>('getAndroidSdkVersion');
      return (sdkVersion ?? 0) >= 33; // Android 13 is API level 33
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Error checking Android version: $e');
      return false;
    }
  }
}

/// Enum for different permission features
enum PermissionFeature {
  notifications,
  storage,
  camera,
  location,
  all,
}

/// Permission status result class
class PermissionStatus {
  final bool isGranted;
  final PermissionFeature feature;
  final String message;

  PermissionStatus({
    required this.isGranted,
    required this.feature,
    required this.message,
  });

  @override
  String toString() =>
      'PermissionStatus(feature: $feature, granted: $isGranted, message: $message)';
}
