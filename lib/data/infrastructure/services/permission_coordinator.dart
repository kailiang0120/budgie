import 'package:budgie/core/utils/app_logger.dart';
import 'package:budgie/data/infrastructure/services/permission_handler_service.dart';

/// Coordinates permission requests and checks across multiple services
/// Provides a clean interface for permission management
class PermissionCoordinator {
  static const _logger = AppLogger('PermissionCoordinator');
  
  final PermissionHandlerService _permissionHandler;
  
  PermissionCoordinator(this._permissionHandler);
  
  /// Initialize permission handler
  Future<void> initialize(dynamic settingsService) async {
    return _logger.traceAsync('initialize', () async {
      await _permissionHandler.initialize(settingsService);
      _logger.info('Permission coordinator initialized');
    });
  }
  
  /// Check if all notification-related permissions are granted
  Future<bool> hasNotificationPermissions() async {
    return _logger.traceAsync('hasNotificationPermissions', () async {
      final hasPermissions = await _permissionHandler
          .hasPermissionsForFeature(PermissionFeature.notifications);
      _logger.debug('Notification permissions: $hasPermissions');
      return hasPermissions;
    });
  }
  
  /// Request notification permissions
  Future<bool> requestNotificationPermissions({required dynamic context}) async {
    return _logger.traceAsync('requestNotificationPermissions', () async {
      final status = await _permissionHandler
          .requestPermissionsForFeature(PermissionFeature.notifications, context);
      _logger.info('Notification permissions requested: ${status.isGranted}');
      return status.isGranted;
    });
  }
  
  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    return _permissionHandler.hasLocationPermission();
  }
  
  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    return _permissionHandler.hasCameraPermission();
  }
  
  /// Check if storage permission is granted
  Future<bool> hasStoragePermission() async {
    return _permissionHandler.hasStoragePermission();
  }
  
  /// Check if ignore battery optimization permission is granted
  Future<bool> hasIgnoreBatteryOptimizationsPermission() async {
    return _permissionHandler.hasIgnoreBatteryOptimizationsPermission();
  }
  
  /// Request ignore battery optimization permission
  Future<bool> requestIgnoreBatteryOptimizationsPermission() async {
    return _logger.traceAsync('requestIgnoreBatteryOptimizations', () async {
      final granted = await _permissionHandler
          .requestIgnoreBatteryOptimizationsPermission();
      _logger.info('Battery optimization permission requested: $granted');
      return granted;
    });
  }
  
  /// Verify and sync permissions with settings
  Future<Map<String, bool>> verifyAllPermissions({
    required bool locationEnabled,
    required bool cameraEnabled,
    required bool storageEnabled,
  }) async {
    return _logger.traceAsync('verifyAllPermissions', () async {
      final results = <String, bool>{};
      
      if (locationEnabled) {
        results['location'] = await hasLocationPermission();
      }
      
      if (cameraEnabled) {
        results['camera'] = await hasCameraPermission();
      }
      
      if (storageEnabled) {
        results['storage'] = await hasStoragePermission();
      }
      
      _logger.debug('Permission verification results', data: results);
      return results;
    });
  }
}
