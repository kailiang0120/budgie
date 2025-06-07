import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ThemeViewModel extends ChangeNotifier {
  bool _isDarkMode = false;
  String _currentTheme = 'light';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isDarkMode => _isDarkMode;
  String get currentTheme => _currentTheme;

  ThemeData get theme => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  ThemeViewModel() {
    // Start with light theme as default to match SettingsService defaults
    debugPrint('🎨 ThemeViewModel created with default light theme');
  }

  Future<void> setTheme(String theme) async {
    if (theme == _currentTheme) return;

    _currentTheme = theme;
    _isDarkMode = theme == 'dark';
    notifyListeners();

    debugPrint('🎨 Theme changed to: $theme');

    // 保存主题设置到用户记录
    await _saveThemeToUser();
  }

  Future<void> _saveThemeToUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'theme': _currentTheme,
        }, SetOptions(merge: true));
        debugPrint('🎨 Theme saved to user record');
      }
    } catch (e) {
      debugPrint('🎨 Error saving theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    final newTheme = _isDarkMode ? 'light' : 'dark';
    await setTheme(newTheme);
  }

  // Initialize theme for a specific user (called when user logs in)
  Future<void> initializeForUser(String userId) async {
    try {
      debugPrint('🎨 ThemeViewModel: Initializing theme for user: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final userData = doc.data();
        if (userData != null && userData.containsKey('theme')) {
          final userTheme = userData['theme'] as String;
          debugPrint('🎨 ThemeViewModel: Found user theme: $userTheme');
          await setTheme(userTheme);
        } else {
          debugPrint(
              '🎨 ThemeViewModel: User document exists but no theme found, using defaults');
          // Don't create settings here - let SettingsService handle it
        }
      } else {
        debugPrint('🎨 ThemeViewModel: User document does not exist yet');
        // Don't create settings here - let SettingsService handle it
        // Keep current default theme
      }

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
