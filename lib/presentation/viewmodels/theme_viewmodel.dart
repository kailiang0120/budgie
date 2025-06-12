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
  }

  Future<void> setTheme(String theme) async {
    if (theme == _currentTheme) return;

    _currentTheme = theme;
    _isDarkMode = theme == 'dark';
    notifyListeners();

    debugPrint('🎨 Theme changed to: $theme');

    // Save theme setting to user settings
    await _settingsService.updateTheme(theme);
  }

  Future<void> toggleTheme() async {
    final newTheme = _isDarkMode ? 'light' : 'dark';
    await setTheme(newTheme);
  }

  // Initialize theme for a specific user (called when user logs in)
  Future<void> initializeForUser(String userId) async {
    try {
      debugPrint('🎨 ThemeViewModel: Initializing theme for user: $userId');

      // Get theme from SettingsService which manages user settings
      final userTheme = _settingsService.theme;
      debugPrint('🎨 ThemeViewModel: Found user theme: $userTheme');

      _currentTheme = userTheme;
      _isDarkMode = userTheme == 'dark';
      notifyListeners();

      debugPrint(
          '🎨 ThemeViewModel: Theme initialization completed for user: $userId');
    } catch (e) {
      debugPrint(
          '🎨 ThemeViewModel: Error initializing theme for user $userId: $e');
      // Don't rethrow - just keep the default theme
    }
  }

  // 根据具体主题模式返回相应颜色
  Color getThemeColor(Color lightColor, Color darkColor) {
    return _isDarkMode ? darkColor : lightColor;
  }
}
