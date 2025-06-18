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
    // Start with light theme as default to match SettingsService defaults
    debugPrint('🎨 ThemeViewModel created with default light theme');

    // Initialize theme from settings service
    _currentTheme = _settingsService.theme;
    _isDarkMode = _currentTheme == 'dark';
  }

  Future<void> setTheme(String theme) async {
    if (theme == _currentTheme) return;

    _currentTheme = theme;
    _isDarkMode = theme == 'dark';
    notifyListeners();

    debugPrint('🎨 Theme changed to: $theme');

    // Save theme setting to local settings service
    await _settingsService.updateTheme(theme);
  }

  Future<void> toggleTheme() async {
    final newTheme = _isDarkMode ? 'light' : 'dark';
    await setTheme(newTheme);
  }

  // Initialize theme for a specific user (called when user logs in)
  // This is kept for API compatibility but now just refreshes from global settings
  Future<void> initializeForUser(String userId) async {
    try {
      debugPrint('🎨 ThemeViewModel: Refreshing theme from settings service');

      // Get theme from SettingsService which manages device settings
      final userTheme = _settingsService.theme;
      debugPrint('🎨 ThemeViewModel: Found theme: $userTheme');

      _currentTheme = userTheme;
      _isDarkMode = userTheme == 'dark';
      notifyListeners();

      debugPrint('🎨 ThemeViewModel: Theme refresh completed');
    } catch (e) {
      debugPrint('🎨 ThemeViewModel: Error refreshing theme: $e');
      // Don't rethrow - just keep the default theme
    }
  }

  // Get theme color based on current theme mode
  Color getThemeColor(Color lightColor, Color darkColor) {
    return _isDarkMode ? darkColor : lightColor;
  }
}
