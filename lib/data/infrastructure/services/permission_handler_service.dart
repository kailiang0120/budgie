import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

  // Track if method channel is ready
  bool _isMethodChannelReady = false;

  // Settings service reference
  late final SettingsService _settingsService;

  // Permission request tracking
  final Map<Permission, Completer<bool>> _pendingPermissions = {};
  bool _isWaitingForPermission = false;

  /// Initialize the service with required dependencies
  Future<void> initialize(SettingsService settingsService) async {
    _settingsService = settingsService;

    // Test method channel availability
    await _testMethodChannel();

    if (kDebugMode) {
      debugPrint('🔐 PermissionHandlerService: Initialized');
    }
  }

  /// Test if method channel is ready and working
  Future<void> _testMethodChannel() async {
    if (!Platform.isAndroid) {
      _isMethodChannelReady = true;
      return;
    }

    try {
      // Add a small delay to ensure method channel is initialized
      await Future.delayed(const Duration(milliseconds: 100));

      // Test with a simple method call
      final sdkVersion =
          await platform.invokeMethod<int>('getAndroidSdkVersion');
      _isMethodChannelReady = sdkVersion != null;
      if (kDebugMode) {
        debugPrint(
            '🔐 PermissionHandlerService: Method channel test successful, SDK version: $sdkVersion');
      }
    } catch (e) {
      _isMethodChannelReady = false;
      if (kDebugMode) {
        debugPrint(
            '⚠️ PermissionHandlerService: Method channel not ready yet: $e');
      }
    }
  }

  /// Retry method channel initialization with exponential backoff
  Future<void> _retryMethodChannel() async {
    if (!Platform.isAndroid) return;

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        await Future.delayed(Duration(milliseconds: 100 * attempt));
        await _testMethodChannel();

        if (_isMethodChannelReady) {
          if (kDebugMode) {
            debugPrint(
                '✅ PermissionHandlerService: Method channel ready after retry attempt $attempt');
          }
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ PermissionHandlerService: Retry attempt $attempt failed: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
          '❌ PermissionHandlerService: Method channel failed to initialize after all retries');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForPermission) {
      if (kDebugMode) {
        debugPrint('📱 App resumed - checking for pending permissions');
      }
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
      if (kDebugMode) {
        debugPrint(
            '🔐 PermissionHandlerService: Error checking notification permission: $e');
      }
      return false;
    }
  }

  /// Check if notification listener permission is granted (Android only)
  Future<bool> hasNotificationListenerPermission() async {
    try {
      if (!Platform.isAndroid) return true;

      // Check if method channel is ready
      if (!_isMethodChannelReady) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ PermissionHandlerService: Method channel not ready, retrying...');
        }
        await _retryMethodChannel();
      }

      if (!_isMethodChannelReady) {
        if (kDebugMode) {
          debugPrint(
              '❌ PermissionHandlerService: Method channel still not ready, returning false');
        }
        return false;
      }

      final result = await platform.invokeMethod('checkNotificationAccess');
      return result as bool? ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 PermissionHandlerService: Error checking notification listener permission: $e');
      }
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
      if (kDebugMode) {
        debugPrint(
            '🔐 PermissionHandlerService: Error checking storage permission: $e');
      }
      return false;
    }
  }

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 PermissionHandlerService: Error checking camera permission: $e');
      }
      return false;
    }
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    try {
      final status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 PermissionHandlerService: Error checking location permission: $e');
      }
      return false;
    }
  }

  /// Check if permission to ignore battery optimizations is granted (Android only)
  Future<bool> hasIgnoreBatteryOptimizationsPermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.ignoreBatteryOptimizations.status;
        return status.isGranted;
      }
      return true; // Not applicable on other platforms
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 PermissionHandlerService: Error checking battery optimization permission: $e');
      }
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
      if (kDebugMode) {
        debugPrint(
            '🔐 PermissionHandlerService: Requesting notification permission...');
      }

      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.notification.request();
        final granted = status.isGranted;

        if (kDebugMode) {
          debugPrint(
              '🔐 PermissionHandlerService: Notification permission ${granted ? 'granted' : 'denied'}');
        }
        return granted;
      }

      return true; // Default to true for other platforms
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ PermissionHandlerService: Failed to request notification permission: $e');
      }
      return false;
    }
  }

  /// Request notification listener permission (Android only)
  Future<bool> requestNotificationListenerPermission(
      BuildContext? context) async {
    try {
      if (!Platform.isAndroid) return true;

      if (kDebugMode) {
        debugPrint(
            '🔐 PermissionHandlerService: Requesting notification listener permission...');
      }

      // Check if already granted
      final alreadyGranted = await hasNotificationListenerPermission();
      if (alreadyGranted) {
        if (kDebugMode) {
          debugPrint(
              '🔐 PermissionHandlerService: Notification listener permission already granted');
        }
        return true;
      }

      if (kDebugMode) {
        debugPrint(
            '🔐 PermissionHandlerService: Notification listener permission not granted, opening settings...');
      }

      // Set up completer to wait for permission
      if (context != null && context.mounted) {
        final completer = Completer<bool>();
        _pendingPermissions[Permission.notification] = completer;
        _isWaitingForPermission = true;

        // Open settings for user to grant permission manually
        await platform.invokeMethod('requestNotificationAccess');
        if (kDebugMode) {
          debugPrint(
              '🔐 PermissionHandlerService: Opened notification listener settings, waiting for user action...');
        }

        return await completer.future.timeout(
          const Duration(minutes: 2),
          onTimeout: () {
            if (kDebugMode) {
              debugPrint('⏱️ Permission request timed out');
            }
            _isWaitingForPermission = false;
            return false;
          },
        );
      }

      // If context is null or not mounted, we can still request
      if (kDebugMode) {
        debugPrint(
            '🔐 PermissionHandlerService: No context available, opening settings without waiting...');
      }
      await platform.invokeMethod('requestNotificationAccess');
      return true; // We can't know the result without context, assume success
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ PermissionHandlerService: Failed to request notification listener permission: $e');
      }
      return false;
    }
  }

  /// Request permission to ignore battery optimizations (Android only)
  Future<bool> requestIgnoreBatteryOptimizationsPermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.ignoreBatteryOptimizations.request();
        return status.isGranted;
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ PermissionHandlerService: Error requesting battery optimization permission: $e');
      }
      return false;
    }
  }

  /// Request storage permission
  Future<bool> requestStoragePermission() async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🔐 PermissionHandlerService: Requesting storage permission...');
      }

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
      if (kDebugMode) {
        debugPrint(
            '❌ PermissionHandlerService: Failed to request storage permission: $e');
      }
      return false;
    }
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🔐 PermissionHandlerService: Requesting camera permission...');
      }

      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ PermissionHandlerService: Failed to request camera permission: $e');
      }
      return false;
    }
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🔐 PermissionHandlerService: Requesting location permission...');
      }

      final status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ PermissionHandlerService: Failed to request location permission: $e');
      }
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
      if (kDebugMode) {
        debugPrint(
            '❌ PermissionHandlerService: Failed to request permissions for $feature: $e');
      }
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
      if (kDebugMode) {
        debugPrint(
            '❌ PermissionHandlerService: Failed to open app settings: $e');
      }
    }
  }

  /// Open notification settings
  Future<void> openNotificationSettings() async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('openNotificationSettings');
        if (kDebugMode) {
          debugPrint(
              '🔐 PermissionHandlerService: Opened notification settings');
        }
      } else {
        await openAppSettings();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ PermissionHandlerService: Failed to open notification settings: $e');
      }
    }
  }

  /// Open notification listener settings for disabling
  Future<void> openNotificationListenerSettingsForDisabling() async {
    try {
      if (!Platform.isAndroid) return;

      await platform.invokeMethod('requestNotificationAccess');
      if (kDebugMode) {
        debugPrint(
            '🔐 PermissionHandlerService: Opened notification listener settings for disabling');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ PermissionHandlerService: Failed to open notification listener settings: $e');
      }
    }
  }

  /// Check if notification access can be revoked
  Future<bool> canRevokeNotificationAccess() async {
    try {
      if (!Platform.isAndroid) return false;

      return await hasNotificationListenerPermission();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ PermissionHandlerService: Error checking if notification access can be revoked: $e');
      }
      return false;
    }
  }

  /// Request to revoke notification listener permission
  Future<void> requestRevokeNotificationListenerPermission() async {
    try {
      if (!Platform.isAndroid) return;

      final hasPermission = await hasNotificationListenerPermission();
      if (!hasPermission) {
        if (kDebugMode) {
          debugPrint(
              '🔐 PermissionHandlerService: Notification listener permission already not granted');
        }
        return;
      }

      await openNotificationListenerSettingsForDisabling();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ PermissionHandlerService: Failed to request revoke notification listener permission: $e');
      }
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
      if (kDebugMode) {
        debugPrint(
            '❌ PermissionHandlerService: Error getting permission status: $e');
      }
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // HELPER METHODS

  /// Check pending permissions after returning from settings
  Future<void> _checkPendingPermissions() async {
    _isWaitingForPermission = false;
    final permissionsToCheck =
        Map<Permission, Completer<bool>>.from(_pendingPermissions);
    _pendingPermissions.clear();

    for (var entry in permissionsToCheck.entries) {
      final permission = entry.key;
      final completer = entry.value;

      if (!completer.isCompleted) {
        final status = await permission.status;
        completer.complete(status.isGranted);
        if (kDebugMode) {
          debugPrint(
              '📱 Resumed and completed permission check for $permission: ${status.isGranted}');
        }
      }
    }
  }

  /// Unified permission request logic
  Future<bool> _handlePermissionRequest(
      BuildContext context, Permission permission) async {
    final status = await permission.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      await showPermissionPermanentlyDeniedDialog(context, permission);
      return false;
    }

    if (status.isDenied) {
      if (!context.mounted) return false;
      await showPermissionDeniedDialog(context, permission);
    }

    return false;
  }

  /// Show a dialog explaining why the permission is needed (for permanently denied)
  Future<void> showPermissionPermanentlyDeniedDialog(
      BuildContext context, Permission permission) async {
    final permissionName = permission.toString().split('.').last;
    final message =
        'Permission for $permissionName is permanently denied. Please enable it from the app settings to use this feature.';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Open Settings'),
            onPressed: () async {
              await openAppSettings();
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  /// Show a dialog explaining why the permission is needed (for denied)
  Future<void> showPermissionDeniedDialog(
      BuildContext context, Permission permission) async {
    final permissionName = permission.toString().split('.').last;
    final message =
        'Permission for $permissionName is required for this feature to work correctly. Please grant the permission when prompted.';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Denied'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Request a single permission and handle the UI flow
  Future<bool> _requestPermission(
      BuildContext context, Permission permission) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🔐 PermissionHandlerService: Requesting ${permission.toString()} permission...');
      }

      if (!context.mounted) return false;
      final bool isGranted =
          await _handlePermissionRequest(context, permission);

      if (isGranted) {
        if (kDebugMode) {
          debugPrint(
              '🔐 PermissionHandlerService: ${permission.toString()} permission granted');
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '🔐 PermissionHandlerService: ${permission.toString()} permission denied');
        }
      }
      return isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ PermissionHandlerService: Failed to request ${permission.toString()} permission: $e');
      }
      return false;
    }
  }

  /// Check if notification listener service is enabled at OS level
  Future<bool> _checkNotificationListenerServiceEnabled() async {
    try {
      if (Platform.isAndroid) {
        // Check if method channel is ready
        if (!_isMethodChannelReady) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ PermissionHandlerService: Method channel not ready for service check, retrying...');
          }
          await _retryMethodChannel();
        }

        if (!_isMethodChannelReady) {
          if (kDebugMode) {
            debugPrint(
                '❌ PermissionHandlerService: Method channel still not ready for service check, returning false');
          }
          return false;
        }

        final result =
            await platform.invokeMethod<bool>('isNotificationServiceEnabled');
        return result ?? false;
      }
      return true; // Non-Android platforms don't need this special permission
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ PermissionHandlerService: Error checking notification service status: $e');
      }
      return false;
    }
  }

  /// Check if device is running Android 13 or higher
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;

    try {
      // Check if method channel is ready
      if (!_isMethodChannelReady) {
        debugPrint(
            '⚠️ PermissionHandlerService: Method channel not ready for version check, retrying...');
        await _retryMethodChannel();
      }

      if (_isMethodChannelReady) {
        final sdkVersion =
            await platform.invokeMethod<int>('getAndroidSdkVersion');
        return (sdkVersion ?? 0) >= 33; // Android 13 is API level 33
      }
    } catch (e) {
      debugPrint(
          '❌ PermissionHandlerService: Error checking Android version via method channel: $e');
    }

    // Fallback: try to get Android version using Platform.operatingSystemVersion
    try {
      final versionString = Platform.operatingSystemVersion;
      debugPrint(
          '🔧 PermissionHandlerService: Using fallback version check: $versionString');

      // Parse version string like "Android 14.0.0"
      if (versionString.contains('Android')) {
        final versionMatch = RegExp(r'Android (\d+)').firstMatch(versionString);
        if (versionMatch != null) {
          final version = int.tryParse(versionMatch.group(1) ?? '0') ?? 0;
          debugPrint(
              '🔧 PermissionHandlerService: Parsed Android version: $version');
          return version >= 13; // Android 13 is version 13
        }
      }
    } catch (fallbackError) {
      debugPrint(
          '❌ PermissionHandlerService: Fallback version check also failed: $fallbackError');
    }

    // Default to false if we can't determine the version
    debugPrint(
        '⚠️ PermissionHandlerService: Could not determine Android version, defaulting to false');
    return false;
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
