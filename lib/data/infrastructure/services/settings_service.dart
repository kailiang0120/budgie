import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'permission_handler_service.dart';
import 'notification_listener_service.dart';
import '../../../domain/services/expense_extraction_service.dart';
import '../../../di/injection_container.dart' as di;

/// Service responsible for managing all app settings and preferences
/// Acts as the single source of truth for user settings
class SettingsService extends ChangeNotifier {
  static SettingsService? _instance;

  // Keys for shared preferences
  final String _themeKey = 'app_theme';
  final String _allowNotificationKey = 'allow_notification';
  final String _autoBudgetKey = 'auto_budget';

  final String _syncEnabledKey = 'sync_enabled';
  final String _currencyKey = 'user_currency';
  final String _locationEnabledKey = 'location_enabled';
  final String _cameraEnabledKey = 'camera_enabled';
  final String _storageEnabledKey = 'storage_enabled';
  final String _biometricEnabledKey = 'biometric_enabled';

  // Settings values
  late String _theme;
  late bool _allowNotification;
  late bool _autoBudget;
  late bool _syncEnabled;
  late String _currency;
  late bool _locationEnabled;
  late bool _cameraEnabled;
  late bool _storageEnabled;
  late bool _biometricEnabled;

  // Services
  PermissionHandlerService? _permissionHandler;
  NotificationListenerService? _notificationListenerService;

  // Getters
  String get theme => _theme;
  bool get allowNotification => _allowNotification;
  bool get autoBudget => _autoBudget;
  bool get syncEnabled => _syncEnabled;
  String get currency => _currency;
  bool get locationEnabled => _locationEnabled;
  bool get cameraEnabled => _cameraEnabled;
  bool get storageEnabled => _storageEnabled;
  bool get biometricEnabled => _biometricEnabled;

  SettingsService() {
    _instance = this;
  }

  static SettingsService? get instance => _instance;

  Map<String, dynamic> get currentSettings => {
        'currency': _currency,
        'theme': _theme,
        'settings': {
          'allowNotification': _allowNotification,
          'autoBudget': _autoBudget,
          'syncEnabled': _syncEnabled,
          'locationEnabled': _locationEnabled,
          'cameraEnabled': _cameraEnabled,
          'storageEnabled': _storageEnabled,
          'biometricEnabled': _biometricEnabled,
        },
      };

  Future<void> initialize({PermissionHandlerService? permissionHandler}) async {
    try {
      debugPrint('🔧 SettingsService: Initializing settings');
      await _loadSettings();

      if (permissionHandler != null) {
        _permissionHandler = permissionHandler;
        await permissionHandler.initialize(this);
      }

      try {
        _notificationListenerService = NotificationListenerService();
        await _notificationListenerService!.initialize();
        debugPrint(
            '🔧 SettingsService: NotificationListenerService initialized');
      } catch (e) {
        debugPrint(
            '🔧 SettingsService: Error initializing NotificationListenerService: $e');
      }

      await _verifyPermissionSettings();

      if (_allowNotification && _notificationListenerService != null) {
        await _startNotificationListener();
      }

      notifyListeners();
      debugPrint('🔧 SettingsService: Initialization completed');
    } catch (e) {
      debugPrint('🔧 SettingsService: Error initializing settings: $e');
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _theme = prefs.getString(_themeKey) ?? 'light';
      _allowNotification = prefs.getBool(_allowNotificationKey) ?? false;
      _autoBudget = prefs.getBool(_autoBudgetKey) ?? false;
      _syncEnabled = prefs.getBool(_syncEnabledKey) ?? false;
      _currency = prefs.getString(_currencyKey) ?? 'MYR';
      _locationEnabled = prefs.getBool(_locationEnabledKey) ?? false;
      _cameraEnabled = prefs.getBool(_cameraEnabledKey) ?? false;
      _storageEnabled = prefs.getBool(_storageEnabledKey) ?? false;
      _biometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;

      debugPrint(
          '🔧 SettingsService: Loaded settings - theme=$_theme, currency=$_currency, allowNotification=$_allowNotification, autoBudget=$_autoBudget, syncEnabled=$_syncEnabled, locationEnabled=$_locationEnabled, cameraEnabled=$_cameraEnabled, storageEnabled=$_storageEnabled, biometricEnabled=$_biometricEnabled');
    } catch (e) {
      debugPrint('🔧 SettingsService: Error loading settings: $e');
    }
  }

  Future<void> _verifyPermissionSettings() async {
    if (_permissionHandler == null) return;
    try {
      if (_allowNotification) {
        final hasPermissions = await _permissionHandler!
            .hasPermissionsForFeature(PermissionFeature.notifications);
        if (!hasPermissions) {
          debugPrint(
              '🔧 SettingsService: Notification permission mismatch, updating setting');
          await updateNotificationSetting(false);
        }
      }
      if (_locationEnabled) {
        final hasPermission = await _permissionHandler!.hasLocationPermission();
        if (!hasPermission) {
          debugPrint(
              '🔧 SettingsService: Location permission mismatch, updating setting');
          await updateLocationSetting(false);
        }
      }
      if (_cameraEnabled) {
        final hasPermission = await _permissionHandler!.hasCameraPermission();
        if (!hasPermission) {
          debugPrint(
              '🔧 SettingsService: Camera permission mismatch, updating setting');
          await updateCameraSetting(false);
        }
      }
      if (_storageEnabled) {
        final hasPermission = await _permissionHandler!.hasStoragePermission();
        if (!hasPermission) {
          debugPrint(
              '🔧 SettingsService: Storage permission mismatch, updating setting');
          await updateStorageSetting(false);
        }
      }
    } catch (e) {
      debugPrint('🔧 SettingsService: Error verifying permission settings: $e');
    }
  }

  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _loadSettings();
      notifyListeners();
      debugPrint('🔧 SettingsService: Settings reset to defaults');
    } catch (e) {
      debugPrint('Error resetting settings: $e');
    }
  }

  Future<void> updateCurrency(String newCurrency) async {
    try {
      final oldCurrency = _currency;
      _currency = newCurrency;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, newCurrency);
      debugPrint(
          '🔧 SettingsService: Currency updated from $oldCurrency to $newCurrency');
      notifyListeners();
    } catch (e) {
      debugPrint('🔧 SettingsService: Error updating currency: $e');
      _currency = 'MYR';
    }
  }

  Future<void> updateTheme(String newTheme) async {
    try {
      _theme = newTheme;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, newTheme);
      notifyListeners();
      debugPrint('🔧 SettingsService: Theme updated to: $newTheme');
    } catch (e) {
      debugPrint('🔧 SettingsService: Error updating theme: $e');
    }
  }

  Future<bool> updateNotificationSetting(bool enabled) async {
    try {
      if (enabled && _permissionHandler != null) {
        final hasPermissions = await _permissionHandler!
            .hasPermissionsForFeature(PermissionFeature.notifications);
        if (!hasPermissions) {
          debugPrint(
              '🔧 SettingsService: Cannot enable notifications without permissions');
          return false;
        }
      }

      final previousValue = _allowNotification;
      _allowNotification = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_allowNotificationKey, enabled);

      if (_notificationListenerService != null) {
        if (enabled && !previousValue) {
          await _startNotificationListener();
        } else if (!enabled && previousValue) {
          await _stopNotificationListener();
        }
      }

      notifyListeners();
      debugPrint(
          '🔧 SettingsService: Notification setting updated to: $enabled');
      return true;
    } catch (e) {
      debugPrint('🔧 SettingsService: Error updating notification setting: $e');
      return false;
    }
  }

  Future<void> updateAutoBudgetSetting(bool enabled) async {
    try {
      _autoBudget = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoBudgetKey, enabled);
      notifyListeners();
      debugPrint(
          '🔧 SettingsService: Auto budget setting updated to: $enabled');
    } catch (e) {
      debugPrint('🔧 SettingsService: Error updating auto budget setting: $e');
    }
  }

  Future<void> updateSyncSetting(bool enabled) async {
    try {
      _syncEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_syncEnabledKey, enabled);
      notifyListeners();
      debugPrint('🔧 SettingsService: Sync setting updated to: $enabled');
    } catch (e) {
      debugPrint('🔧 SettingsService: Error updating sync setting: $e');
    }
  }

  Future<bool> updateLocationSetting(bool enabled) async {
    try {
      if (enabled && _permissionHandler != null) {
        final hasPermission = await _permissionHandler!.hasLocationPermission();
        if (!hasPermission) {
          debugPrint(
              '🔧 SettingsService: Cannot enable location without permission');
          return false;
        }
      }
      _locationEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_locationEnabledKey, enabled);
      notifyListeners();
      debugPrint('🔧 SettingsService: Location setting updated to: $enabled');
      return true;
    } catch (e) {
      debugPrint('🔧 SettingsService: Error updating location setting: $e');
      return false;
    }
  }

  Future<bool> updateCameraSetting(bool enabled) async {
    try {
      if (enabled && _permissionHandler != null) {
        final hasPermission = await _permissionHandler!.hasCameraPermission();
        if (!hasPermission) {
          debugPrint(
              '🔧 SettingsService: Cannot enable camera without permission');
          return false;
        }
      }
      _cameraEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cameraEnabledKey, enabled);
      notifyListeners();
      debugPrint('🔧 SettingsService: Camera setting updated to: $enabled');
      return true;
    } catch (e) {
      debugPrint('🔧 SettingsService: Error updating camera setting: $e');
      return false;
    }
  }

  Future<bool> updateStorageSetting(bool enabled) async {
    try {
      if (enabled && _permissionHandler != null) {
        final hasPermission = await _permissionHandler!.hasStoragePermission();
        if (!hasPermission) {
          debugPrint(
              '🔧 SettingsService: Cannot enable storage without permission');
          return false;
        }
      }
      _storageEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storageEnabledKey, enabled);
      notifyListeners();
      debugPrint('🔧 SettingsService: Storage setting updated to: $enabled');
      return true;
    } catch (e) {
      debugPrint('🔧 SettingsService: Error updating storage setting: $e');
      return false;
    }
  }

  Future<void> updateBiometricSetting(bool enabled) async {
    try {
      _biometricEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
      notifyListeners();
      debugPrint('🔧 SettingsService: Biometric setting updated to: $enabled');
    } catch (e) {
      debugPrint('🔧 SettingsService: Error updating biometric setting: $e');
    }
  }

  Future<void> _startNotificationListener() async {
    try {
      if (_notificationListenerService == null) return;

      debugPrint('🔧 SettingsService: Starting notification listener...');
      try {
        final extractionService = di.sl<ExpenseExtractionDomainService>();
        if (!extractionService.isInitialized) {
          debugPrint(
              '🔧 SettingsService: Initializing expense extraction service...');
          await extractionService.initialize();
          debugPrint(
              '✅ SettingsService: Expense extraction service initialized');
        } else {
          debugPrint(
              '✅ SettingsService: Expense extraction service already initialized');
        }
      } catch (e) {
        debugPrint(
            '⚠️ SettingsService: Failed to initialize expense extraction service: $e');
      }

      _notificationListenerService!
          .setNotificationCallback((title, content, packageName) {
        _notificationListenerService!.processNotificationWithHybridDetection(
          title: title,
          content: content,
          packageName: packageName,
          timestamp: DateTime.now(),
        );
      });

      final started = await _notificationListenerService!.startListening();
      if (started) {
        debugPrint(
            '✅ SettingsService: Notification listener started successfully');
      } else {
        debugPrint('❌ SettingsService: Failed to start notification listener');
      }
    } catch (e) {
      debugPrint('❌ SettingsService: Error starting notification listener: $e');
    }
  }

  Future<void> _stopNotificationListener() async {
    try {
      if (_notificationListenerService == null) return;
      debugPrint('🔧 SettingsService: Stopping notification listener...');
      await _notificationListenerService!.stopListening();
      debugPrint(
          '✅ SettingsService: Notification listener stopped successfully');
    } catch (e) {
      debugPrint('❌ SettingsService: Error stopping notification listener: $e');
    }
  }
}
