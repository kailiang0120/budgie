import 'package:flutter/foundation.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local_data_source.dart';

/// Implementation of AppSettingsRepository with local storage
class AppSettingsRepositoryImpl implements AppSettingsRepository {
  final LocalDataSource _localDataSource;

  AppSettingsRepositoryImpl({
    required LocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      return await _localDataSource.getAppSettings();
    } catch (e) {
      debugPrint('Error getting app settings: $e');
      return {
        'theme': 'light',
        'currency': 'MYR',
        'allow_notification': false,
        'auto_budget': false,
        'improve_accuracy': false,
      };
    }
  }

  @override
  Future<void> updateAppSettings(Map<String, dynamic> settings) async {
    try {
      await _localDataSource.saveAppSettings(settings);
    } catch (e) {
      debugPrint('Error updating app settings: $e');
      throw Exception('Failed to update app settings: $e');
    }
  }

  @override
  Future<String> getAppTheme() async {
    try {
      return await _localDataSource.getAppTheme();
    } catch (e) {
      debugPrint('Error getting app theme: $e');
      return 'light';
    }
  }

  @override
  Future<void> updateAppTheme(String theme) async {
    try {
      await _localDataSource.updateAppTheme(theme);
    } catch (e) {
      debugPrint('Error updating app theme: $e');
      throw Exception('Failed to update app theme: $e');
    }
  }

  @override
  Future<String> getAppCurrency() async {
    try {
      return await _localDataSource.getAppCurrency();
    } catch (e) {
      debugPrint('Error getting app currency: $e');
      return 'MYR';
    }
  }

  @override
  Future<void> updateAppCurrency(String currency) async {
    try {
      await _localDataSource.updateAppCurrency(currency);
    } catch (e) {
      debugPrint('Error updating app currency: $e');
      throw Exception('Failed to update app currency: $e');
    }
  }

  @override
  Future<bool> getNotificationsEnabled() async {
    try {
      return await _localDataSource.getNotificationsEnabled();
    } catch (e) {
      debugPrint('Error getting notifications setting: $e');
      return false;
    }
  }

  @override
  Future<void> updateNotificationsEnabled(bool enabled) async {
    try {
      await _localDataSource.updateNotificationsEnabled(enabled);
    } catch (e) {
      debugPrint('Error updating notifications setting: $e');
      throw Exception('Failed to update notifications setting: $e');
    }
  }

  @override
  Future<bool> getAutoBudgetEnabled() async {
    try {
      return await _localDataSource.getAutoBudgetEnabled();
    } catch (e) {
      debugPrint('Error getting auto budget setting: $e');
      return false;
    }
  }

  @override
  Future<void> updateAutoBudgetEnabled(bool enabled) async {
    try {
      await _localDataSource.updateAutoBudgetEnabled(enabled);
    } catch (e) {
      debugPrint('Error updating auto budget setting: $e');
      throw Exception('Failed to update auto budget setting: $e');
    }
  }

  @override
  Future<bool> getImproveAccuracy() async {
    return await _localDataSource.getImproveAccuracyEnabled();
  }

  @override
  Future<void> updateImproveAccuracy(bool enabled) async {
    await _localDataSource.updateImproveAccuracyEnabled(enabled);
  }

  @override
  Future<bool> getSyncEnabled() async {
    return await _localDataSource.getSyncEnabled();
  }

  @override
  Future<void> updateSyncEnabled(bool enabled) async {
    await _localDataSource.updateSyncEnabled(enabled);
  }

  @override
  Future<Map<String, dynamic>> getAllSettings() async {
    return await _localDataSource.getAppSettings();
  }

  @override
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    await _localDataSource.saveAppSettings(settings);
  }
}
