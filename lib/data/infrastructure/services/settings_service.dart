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
  bool _hasLoadedPersistedSettings = false;
  bool _hasCompletedInitialization = false;

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
  SharedPreferences? _prefs;

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
    _theme = 'light';
    _allowNotification = false;
    _autoBudget = false;
    _syncEnabled = false;
    _currency = 'MYR';
    _locationEnabled = false;
    _cameraEnabled = false;
    _storageEnabled = false;
    _biometricEnabled = false;
  }

  static SettingsService? get instance => _instance;

  /// Static getter for allowNotification for global access
  static bool get notificationsEnabled =>
      _instance?._allowNotification ?? false;

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

  Future<SharedPreferences> _getPrefs() async {
    final cached = _prefs;
    if (cached != null) {
      return cached;
    }

    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    return prefs;
  }

  Future<void> loadPersistedSettings() async {
    if (_hasLoadedPersistedSettings) {
      return;
    }

    try {
      await _loadSettings();
      _hasLoadedPersistedSettings = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Error loading persisted settings: $e');
      }
    }
  }

  Future<void> initialize({PermissionHandlerService? permissionHandler}) async {
    if (_hasCompletedInitialization) {
      if (permissionHandler != null && _permissionHandler == null) {
        _permissionHandler = permissionHandler;
      }
      return;
    }

    await loadPersistedSettings();

    try {
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Initializing settings');
      }

      if (permissionHandler != null) {
        _permissionHandler = permissionHandler;
        await permissionHandler.initialize(this);
      }

      try {
        _notificationListenerService = NotificationListenerService();
        await _notificationListenerService!.initialize();
        if (kDebugMode) {
          debugPrint(
              '🔧 SettingsService: NotificationListenerService initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '🔧 SettingsService: Error initializing NotificationListenerService: $e');
        }
      }

      await _verifyPermissionSettings();

      // Auto-start notification listener if setting is enabled
      if (_allowNotification) {
        if (kDebugMode) {
          debugPrint(
              '🔧 SettingsService: Notification setting is enabled - auto-starting listener...');
        }
        await _startNotificationListener();
      } else {
        if (kDebugMode) {
          debugPrint(
              '🔧 SettingsService: Notification setting is disabled - listener will not start');
        }
      }

      notifyListeners();
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Initialization completed');
      }
      _hasCompletedInitialization = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Error initializing settings: $e');
      }
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await _getPrefs();
      _theme = prefs.getString(_themeKey) ?? 'light';
      _allowNotification = prefs.getBool(_allowNotificationKey) ?? false;
      _autoBudget = prefs.getBool(_autoBudgetKey) ?? false;
      _syncEnabled = prefs.getBool(_syncEnabledKey) ?? false;
      _currency = prefs.getString(_currencyKey) ?? 'MYR';
      _locationEnabled = prefs.getBool(_locationEnabledKey) ?? false;
      _cameraEnabled = prefs.getBool(_cameraEnabledKey) ?? false;
      _storageEnabled = prefs.getBool(_storageEnabledKey) ?? false;
      _biometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;

      if (kDebugMode) {
        debugPrint(
            '🔧 SettingsService: Loaded settings - theme=$_theme, currency=$_currency, allowNotification=$_allowNotification, autoBudget=$_autoBudget, syncEnabled=$_syncEnabled, locationEnabled=$_locationEnabled, cameraEnabled=$_cameraEnabled, storageEnabled=$_storageEnabled, biometricEnabled=$_biometricEnabled');
      }
      _hasLoadedPersistedSettings = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Error loading settings: $e');
      }
    }
  }

  Future<void> _verifyPermissionSettings() async {
    if (_permissionHandler == null) return;
    try {
      // The notification permission check has been moved to _startNotificationListener
      // to avoid race conditions on app startup. This method will now only
      // verify other permissions if needed in the future.

      if (_locationEnabled) {
        final hasPermission = await _permissionHandler!.hasLocationPermission();
        if (!hasPermission) {
          if (kDebugMode) {
            debugPrint(
                '🔧 SettingsService: Location permission mismatch, updating setting');
          }
          await updateLocationSetting(false);
        }
      }
      if (_cameraEnabled) {
        final hasPermission = await _permissionHandler!.hasCameraPermission();
        if (!hasPermission) {
          if (kDebugMode) {
            debugPrint(
                '🔧 SettingsService: Camera permission mismatch, updating setting');
          }
          await updateCameraSetting(false);
        }
      }
      if (_storageEnabled) {
        final hasPermission = await _permissionHandler!.hasStoragePermission();
        if (!hasPermission) {
          if (kDebugMode) {
            debugPrint(
                '🔧 SettingsService: Storage permission mismatch, updating setting');
          }
          await updateStorageSetting(false);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔧 SettingsService: Error verifying permission settings: $e');
      }
    }
  }

  Future<void> resetToDefaults() async {
    try {
      final prefs = await _getPrefs();
      await prefs.clear();
      _hasLoadedPersistedSettings = false;
      await loadPersistedSettings();
      notifyListeners();
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Settings reset to defaults');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error resetting settings: $e');
      }
    }
  }

  Future<void> updateCurrency(String newCurrency) async {
    try {
      final oldCurrency = _currency;
      _currency = newCurrency;
      final prefs = await _getPrefs();
      await prefs.setString(_currencyKey, newCurrency);
      if (kDebugMode) {
        debugPrint(
            '🔧 SettingsService: Currency updated from $oldCurrency to $newCurrency');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Error updating currency: $e');
      }
      _currency = 'MYR';
    }
  }

  Future<void> updateTheme(String newTheme) async {
    try {
      _theme = newTheme;
      final prefs = await _getPrefs();
      await prefs.setString(_themeKey, newTheme);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Theme updated to: $newTheme');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Error updating theme: $e');
      }
    }
  }

  Future<bool> updateNotificationSetting(bool enabled) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🔧 SettingsService: Updating notification setting to: $enabled');
      }

      // Check permissions if enabling
      if (enabled && _permissionHandler != null) {
        final hasPermissions = await _permissionHandler!
            .hasPermissionsForFeature(PermissionFeature.notifications);
        if (!hasPermissions) {
          if (kDebugMode) {
            debugPrint(
                '🔧 SettingsService: Cannot enable notifications without permissions');
          }
          return false;
        }
      }

      final previousValue = _allowNotification;

      // Update the setting
      _allowNotification = enabled;
      final prefs = await _getPrefs();
      await prefs.setBool(_allowNotificationKey, enabled);

      // Manage notification listener based on setting
      if (enabled && !previousValue) {
        if (kDebugMode) {
          debugPrint(
              '🔧 SettingsService: Notification enabled - starting listener...');
        }
        await _startNotificationListener();
      } else if (!enabled && previousValue) {
        if (kDebugMode) {
          debugPrint(
              '🔧 SettingsService: Notification disabled - stopping listener...');
        }
        await _stopNotificationListener();
      } else if (enabled && previousValue) {
        if (kDebugMode) {
          debugPrint(
              '🔧 SettingsService: Notification already enabled - ensuring listener is running...');
        }
        // Ensure listener is running if it should be
        if (_notificationListenerService != null &&
            !_notificationListenerService!.isListening) {
          await _startNotificationListener();
        }
      }

      notifyListeners();
      if (kDebugMode) {
        debugPrint(
            '🔧 SettingsService: Notification setting updated to: $enabled');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔧 SettingsService: Error updating notification setting: $e');
      }
      return false;
    }
  }

  Future<void> updateAutoBudgetSetting(bool enabled) async {
    try {
      _autoBudget = enabled;
      final prefs = await _getPrefs();
      await prefs.setBool(_autoBudgetKey, enabled);
      notifyListeners();
      if (kDebugMode) {
        debugPrint(
            '🔧 SettingsService: Auto budget setting updated to: $enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔧 SettingsService: Error updating auto budget setting: $e');
      }
    }
  }

  Future<void> updateSyncSetting(bool enabled) async {
    try {
      _syncEnabled = enabled;
      final prefs = await _getPrefs();
      await prefs.setBool(_syncEnabledKey, enabled);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Sync setting updated to: $enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Error updating sync setting: $e');
      }
    }
  }

  Future<bool> updateLocationSetting(bool enabled) async {
    try {
      if (enabled && _permissionHandler != null) {
        final hasPermission = await _permissionHandler!.hasLocationPermission();
        if (!hasPermission) {
          if (kDebugMode) {
            debugPrint(
                '🔧 SettingsService: Cannot enable location without permission');
          }
          return false;
        }
      }
      _locationEnabled = enabled;
      final prefs = await _getPrefs();
      await prefs.setBool(_locationEnabledKey, enabled);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Location setting updated to: $enabled');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Error updating location setting: $e');
      }
      return false;
    }
  }

  Future<bool> updateCameraSetting(bool enabled) async {
    try {
      if (enabled && _permissionHandler != null) {
        final hasPermission = await _permissionHandler!.hasCameraPermission();
        if (!hasPermission) {
          if (kDebugMode) {
            debugPrint(
                '🔧 SettingsService: Cannot enable camera without permission');
          }
          return false;
        }
      }
      _cameraEnabled = enabled;
      final prefs = await _getPrefs();
      await prefs.setBool(_cameraEnabledKey, enabled);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Camera setting updated to: $enabled');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Error updating camera setting: $e');
      }
      return false;
    }
  }

  Future<bool> updateStorageSetting(bool enabled) async {
    try {
      if (enabled && _permissionHandler != null) {
        final hasPermission = await _permissionHandler!.hasStoragePermission();
        if (!hasPermission) {
          if (kDebugMode) {
            debugPrint(
                '🔧 SettingsService: Cannot enable storage without permission');
          }
          return false;
        }
      }
      _storageEnabled = enabled;
      final prefs = await _getPrefs();
      await prefs.setBool(_storageEnabledKey, enabled);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Storage setting updated to: $enabled');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Error updating storage setting: $e');
      }
      return false;
    }
  }

  Future<void> updateBiometricSetting(bool enabled) async {
    try {
      _biometricEnabled = enabled;
      final prefs = await _getPrefs();
      await prefs.setBool(_biometricEnabledKey, enabled);
      notifyListeners();
      if (kDebugMode) {
        debugPrint(
            '🔧 SettingsService: Biometric setting updated to: $enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Error updating biometric setting: $e');
      }
    }
  }

  Future<void> _startNotificationListener() async {
    try {
      // First, verify that we have the necessary permissions before proceeding.
      // This is the correct place to check, right before execution.
      if (_permissionHandler != null) {
        final hasPermissions = await _permissionHandler!
            .hasPermissionsForFeature(PermissionFeature.notifications);
        if (!hasPermissions) {
          if (kDebugMode) {
            debugPrint(
                '❌ SettingsService: Cannot start listener, required permissions are missing. The user setting remains ON.');
          }
          return; // Abort starting the listener
        }
      }

      if (_notificationListenerService == null) {
        if (kDebugMode) {
          debugPrint(
              '🔧 SettingsService: Creating notification listener service...');
        }
        _notificationListenerService = NotificationListenerService();
        await _notificationListenerService!.initialize();
      }

      // Proactively check for "run in background" permission
      if (_permissionHandler != null) {
        final hasIgnoreBatteryPermission =
            await _permissionHandler!.hasIgnoreBatteryOptimizationsPermission();
        if (!hasIgnoreBatteryPermission) {
          if (kDebugMode) {
            debugPrint(
                '🔧 SettingsService: Missing "run in background" permission, requesting...');
          }
          await _permissionHandler!
              .requestIgnoreBatteryOptimizationsPermission();
        }
      }

      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Starting notification listener...');
      }

      // Ensure expense extraction service is ready
      try {
        final extractionService = di.sl<ExpenseExtractionDomainService>();
        if (!extractionService.isInitialized) {
          if (kDebugMode) {
            debugPrint(
                '🔧 SettingsService: Initializing expense extraction service...');
          }
          await extractionService.initialize();
          if (kDebugMode) {
            debugPrint(
                '✅ SettingsService: Expense extraction service initialized');
          }
        } else {
          if (kDebugMode) {
            debugPrint(
                '✅ SettingsService: Expense extraction service already initialized');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ SettingsService: Failed to initialize expense extraction service: $e');
        }
      }

      // Set up notification callback
      _notificationListenerService!
          .setNotificationCallback((title, content, packageName) {
        _notificationListenerService!.processNotificationWithHybridDetection(
          title: title,
          content: content,
          packageName: packageName,
          timestamp: DateTime.now(),
        );
      });

      // Start listening with retry logic
      bool started = false;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          started = await _notificationListenerService!.startListening();
          if (started) {
            if (kDebugMode) {
              debugPrint(
                  '✅ SettingsService: Notification listener started successfully on attempt $attempt');
            }
            break;
          } else {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ SettingsService: Failed to start listener on attempt $attempt');
            }
            if (attempt < 3) {
              await Future.delayed(Duration(milliseconds: 500 * attempt));
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '❌ SettingsService: Error starting listener on attempt $attempt: $e');
          }
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
          }
        }
      }

      if (!started) {
        if (kDebugMode) {
          debugPrint(
              '❌ SettingsService: Failed to start notification listener after all attempts');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ SettingsService: Error starting notification listener: $e');
      }
    }
  }

  Future<void> _stopNotificationListener() async {
    try {
      if (_notificationListenerService == null) return;

      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Stopping notification listener...');
      }

      // Stop listening with retry logic
      bool stopped = false;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          await _notificationListenerService!.stopListening();
          stopped = true;
          if (kDebugMode) {
            debugPrint(
                '✅ SettingsService: Notification listener stopped successfully on attempt $attempt');
          }
          break;
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '❌ SettingsService: Error stopping listener on attempt $attempt: $e');
          }
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 200 * attempt));
          }
        }
      }

      if (!stopped) {
        if (kDebugMode) {
          debugPrint(
              '❌ SettingsService: Failed to stop notification listener after all attempts');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ SettingsService: Error stopping notification listener: $e');
      }
    }
  }

  /// Synchronizes service states with stored settings on app resume.
  /// This is crucial for handling permissions that were changed while the app
  /// was in the background.
  Future<void> syncServicesOnResume() async {
    if (kDebugMode) {
      debugPrint('🔄 SettingsService: Syncing services on app resume...');
    }
    try {
      // 1. Reload the user's intended settings from storage to get the true state.
      await _loadSettings();

      // 2. Attempt to start services based on the reloaded settings.
      // The _startNotificationListener method already contains the necessary logic
      // to check for OS permissions before it runs.
      if (_allowNotification) {
        if (kDebugMode) {
          debugPrint(
              '🔄 SettingsService: Notification setting is ON, attempting to ensure listener is running.');
        }
        await _startNotificationListener();
      } else {
        if (kDebugMode) {
          debugPrint(
              '🔄 SettingsService: Notification setting is OFF, ensuring listener is stopped.');
        }
        await _stopNotificationListener();
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SettingsService: Error during on-resume sync: $e');
      }
    }
  }
}
