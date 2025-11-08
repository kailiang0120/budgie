import 'package:shared_preferences/shared_preferences.dart';

/// Isolated storage layer for application settings
/// Handles all SharedPreferences operations for settings data
class SettingsStorage {
  static const String _themeKey = 'app_theme';
  static const String _allowNotificationKey = 'allow_notification';
  static const String _autoBudgetKey = 'auto_budget';
  static const String _syncEnabledKey = 'sync_enabled';
  static const String _currencyKey = 'user_currency';
  static const String _locationEnabledKey = 'location_enabled';
  static const String _cameraEnabledKey = 'camera_enabled';
  static const String _storageEnabledKey = 'storage_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled';

  SharedPreferences? _prefs;

  /// Get SharedPreferences instance (cached)
  Future<SharedPreferences> _getPrefs() async {
    final cached = _prefs;
    if (cached != null) {
      return cached;
    }
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    return prefs;
  }

  /// Load all settings from storage
  Future<Map<String, dynamic>> loadAll() async {
    final prefs = await _getPrefs();
    return {
      'theme': prefs.getString(_themeKey) ?? 'light',
      'allowNotification': prefs.getBool(_allowNotificationKey) ?? false,
      'autoBudget': prefs.getBool(_autoBudgetKey) ?? false,
      'syncEnabled': prefs.getBool(_syncEnabledKey) ?? false,
      'currency': prefs.getString(_currencyKey) ?? 'MYR',
      'locationEnabled': prefs.getBool(_locationEnabledKey) ?? false,
      'cameraEnabled': prefs.getBool(_cameraEnabledKey) ?? false,
      'storageEnabled': prefs.getBool(_storageEnabledKey) ?? false,
      'biometricEnabled': prefs.getBool(_biometricEnabledKey) ?? false,
    };
  }

  /// Save theme setting
  Future<void> saveTheme(String theme) async {
    final prefs = await _getPrefs();
    await prefs.setString(_themeKey, theme);
  }

  /// Save notification setting
  Future<void> saveNotificationEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_allowNotificationKey, enabled);
  }

  /// Save auto budget setting
  Future<void> saveAutoBudget(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_autoBudgetKey, enabled);
  }

  /// Save sync setting
  Future<void> saveSyncEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_syncEnabledKey, enabled);
  }

  /// Save currency setting
  Future<void> saveCurrency(String currency) async {
    final prefs = await _getPrefs();
    await prefs.setString(_currencyKey, currency);
  }

  /// Save location setting
  Future<void> saveLocationEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_locationEnabledKey, enabled);
  }

  /// Save camera setting
  Future<void> saveCameraEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_cameraEnabledKey, enabled);
  }

  /// Save storage setting
  Future<void> saveStorageEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_storageEnabledKey, enabled);
  }

  /// Save biometric setting
  Future<void> saveBiometricEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  /// Clear all settings
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
    _prefs = null;
  }
}
