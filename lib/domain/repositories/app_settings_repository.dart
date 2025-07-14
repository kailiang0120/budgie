/// Repository interface for app settings operations
abstract class AppSettingsRepository {
  /// Gets the current app settings
  Future<Map<String, dynamic>> getAppSettings();

  /// Updates app settings
  Future<void> updateAppSettings(Map<String, dynamic> settings);

  /// Gets the current app theme
  Future<String> getAppTheme();

  /// Updates the app theme
  Future<void> updateAppTheme(String theme);

  /// Gets the current currency
  Future<String> getAppCurrency();

  /// Updates the app currency
  Future<void> updateAppCurrency(String currency);

  /// Gets notification settings
  Future<bool> getNotificationsEnabled();

  /// Updates notification settings
  Future<void> updateNotificationsEnabled(bool enabled);

  /// Gets auto budget settings
  Future<bool> getAutoBudgetEnabled();

  /// Updates auto budget settings
  Future<void> updateAutoBudgetEnabled(bool enabled);

  /// Gets sync settings
  Future<bool> getSyncEnabled();

  /// Updates sync settings
  Future<void> updateSyncEnabled(bool enabled);

  /// Gets all settings as a map
  Future<Map<String, dynamic>> getAllSettings();

  /// Updates all settings from a map
  Future<void> updateSettings(Map<String, dynamic> settings);
}
