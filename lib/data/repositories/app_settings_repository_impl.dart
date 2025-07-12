import 'package:flutter/foundation.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

/// Implementation of AppSettingsRepository with local storage
class AppSettingsRepositoryImpl implements AppSettingsRepository {
  final SettingsLocalDataSource _localDataSource;

  AppSettingsRepositoryImpl({
    required SettingsLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<Map<String, dynamic>> getAppSettings() {
    return _localDataSource.getAppSettings();
  }

  @override
  Future<void> updateAppSettings(Map<String, dynamic> settings) {
    return _localDataSource.saveAppSettings(settings);
  }

  @override
  Future<String> getAppTheme() {
    return _localDataSource.getAppTheme();
  }

  @override
  Future<void> updateAppTheme(String theme) {
    return _localDataSource.updateAppTheme(theme);
  }

  @override
  Future<String> getAppCurrency() {
    return _localDataSource.getAppCurrency();
  }

  @override
  Future<void> updateAppCurrency(String currency) {
    return _localDataSource.updateAppCurrency(currency);
  }

  @override
  Future<bool> getNotificationsEnabled() {
    return _localDataSource.getNotificationsEnabled();
  }

  @override
  Future<void> updateNotificationsEnabled(bool enabled) {
    return _localDataSource.updateNotificationsEnabled(enabled);
  }

  @override
  Future<bool> getAutoBudgetEnabled() {
    return _localDataSource.getAutoBudgetEnabled();
  }

  @override
  Future<void> updateAutoBudgetEnabled(bool enabled) {
    return _localDataSource.updateAutoBudgetEnabled(enabled);
  }

  @override
  Future<bool> getImproveAccuracy() {
    return _localDataSource.getImproveAccuracyEnabled();
  }

  @override
  Future<void> updateImproveAccuracy(bool enabled) {
    return _localDataSource.updateImproveAccuracyEnabled(enabled);
  }

  @override
  Future<bool> getSyncEnabled() {
    return _localDataSource.getSyncEnabled();
  }

  @override
  Future<void> updateSyncEnabled(bool enabled) {
    return _localDataSource.updateSyncEnabled(enabled);
  }

  @override
  Future<Map<String, dynamic>> getAllSettings() {
    return _localDataSource.getAppSettings();
  }

  @override
  Future<void> updateSettings(Map<String, dynamic> settings) {
    return _localDataSource.saveAppSettings(settings);
  }
}
