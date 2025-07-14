import '../local/database/app_database.dart';

abstract class SettingsLocalDataSource {
  Future<Map<String, dynamic>> getAppSettings();
  Future<void> saveAppSettings(Map<String, dynamic> settings);
  Future<String> getAppTheme();
  Future<void> updateAppTheme(String theme);
  Future<String> getAppCurrency();
  Future<void> updateAppCurrency(String currency);
  Future<bool> getNotificationsEnabled();
  Future<void> updateNotificationsEnabled(bool enabled);
  Future<bool> getAutoBudgetEnabled();
  Future<void> updateAutoBudgetEnabled(bool enabled);

  Future<bool> getSyncEnabled();
  Future<void> updateSyncEnabled(bool enabled);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final AppSettingsDao _appSettingsDao;

  SettingsLocalDataSourceImpl(this._appSettingsDao);

  @override
  Future<Map<String, dynamic>> getAppSettings() {
    // This should be implemented to fetch all settings at once
    throw UnimplementedError();
  }

  @override
  Future<void> saveAppSettings(Map<String, dynamic> settings) {
    // This should be implemented to save all settings at once
    throw UnimplementedError();
  }

  @override
  Future<String> getAppTheme() {
    throw UnimplementedError();
  }

  @override
  Future<void> updateAppTheme(String theme) {
    throw UnimplementedError();
  }

  @override
  Future<String> getAppCurrency() {
    throw UnimplementedError();
  }

  @override
  Future<void> updateAppCurrency(String currency) {
    throw UnimplementedError();
  }

  @override
  Future<bool> getNotificationsEnabled() {
    throw UnimplementedError();
  }

  @override
  Future<void> updateNotificationsEnabled(bool enabled) {
    throw UnimplementedError();
  }

  @override
  Future<bool> getAutoBudgetEnabled() {
    throw UnimplementedError();
  }

  @override
  Future<void> updateAutoBudgetEnabled(bool enabled) {
    throw UnimplementedError();
  }

  @override
  Future<bool> getSyncEnabled() {
    throw UnimplementedError();
  }

  @override
  Future<void> updateSyncEnabled(bool enabled) {
    throw UnimplementedError();
  }
}
