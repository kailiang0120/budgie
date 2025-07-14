import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../../data/infrastructure/services/settings_service.dart';

class ThemeViewModel extends ChangeNotifier {
  bool _isDarkMode = false;
  String _currentTheme = 'light';
  final SettingsService _settingsService;

  bool get isDarkMode => _isDarkMode;
  String get currentTheme => _currentTheme;

  ThemeData get theme => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  ThemeViewModel({required SettingsService settingsService})
      : _settingsService = settingsService {
    // Initialize theme from settings service
    _refreshThemeFromSettings();
  }

  /// Refresh theme from settings service (in case settings were loaded after construction)
  void _refreshThemeFromSettings() {
    final settingsTheme = _settingsService.theme;
    if (settingsTheme != _currentTheme) {
      _currentTheme = settingsTheme;
      _isDarkMode = _currentTheme == 'dark';
      debugPrint(
          '🎨 ThemeViewModel: Refreshed theme from settings: $_currentTheme');
    }
  }

  Future<void> setTheme(String theme) async {
    if (theme == _currentTheme) return;

    _currentTheme = theme;
    _isDarkMode = theme == 'dark';
    notifyListeners();

    // Save theme setting to local settings service
    await _settingsService.updateTheme(theme);
    debugPrint('🎨 ThemeViewModel: Theme set to: $theme');
  }

  Future<void> toggleTheme() async {
    final newTheme = _isDarkMode ? 'light' : 'dark';
    await setTheme(newTheme);
  }

  // Initialize theme for a specific user (called when user logs in)
  // This is kept for API compatibility but now just refreshes from global settings
  Future<void> initializeForUser(String userId) async {
    try {
      // Get theme from SettingsService which manages device settings
      _refreshThemeFromSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('🎨 ThemeViewModel: Error refreshing theme: $e');
      // Don't rethrow - just keep the default theme
    }
  }

  /// Force refresh theme from settings (called after settings are loaded)
  void refreshFromSettings() {
    _refreshThemeFromSettings();
    notifyListeners();
  }

  // Get theme color based on current theme mode
  Color getThemeColor(Color lightColor, Color darkColor) {
    return _isDarkMode ? darkColor : lightColor;
  }
}
