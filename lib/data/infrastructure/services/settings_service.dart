import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsService extends ChangeNotifier {
  static SettingsService? _instance;

  // Default values in constructor - all set to false by default
  String _currency = 'MYR';
  String _theme = 'light';
  bool _allowNotification = false;
  bool _autoBudget = false;
  bool _improveAccuracy = false;
  bool _automaticRebalanceSuggestions = false;

  // Keys for shared preferences
  static const String _themeKey = 'app_theme';
  static const String _allowNotificationKey = 'allow_notification';
  static const String _autoBudgetKey = 'auto_budget';
  static const String _improveAccuracyKey = 'improve_accuracy';
  static const String _automaticRebalanceSuggestionsKey = 'auto_rebalance';

  // Firebase instance for updating currency
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get currency => _currency;
  String get theme => _theme;
  bool get allowNotification => _allowNotification;
  bool get autoBudget => _autoBudget;
  bool get improveAccuracy => _improveAccuracy;
  bool get automaticRebalanceSuggestions => _automaticRebalanceSuggestions;

  SettingsService() {
    _instance = this;
  }

  // Static getter to access the current instance
  static SettingsService? get instance => _instance;

  // Get all current settings as a map
  Map<String, dynamic> get currentSettings => {
        'currency': _currency,
        'theme': _theme,
        'settings': {
          'allowNotification': _allowNotification,
          'autoBudget': _autoBudget,
          'improveAccuracy': _improveAccuracy,
          'automaticRebalanceSuggestions': _automaticRebalanceSuggestions,
        },
      };

  // Initialize settings for a specific user
  Future<void> initializeForUser(String userId) async {
    try {
      debugPrint('🔧 SettingsService: Initializing settings for user: $userId');

      // Load device-wide settings from shared preferences
      await _loadDeviceSettings();

      // Load user-specific currency from Firebase
      await _loadUserCurrency(userId);

      notifyListeners();
      debugPrint(
          '🔧 SettingsService: Initialization completed for user: $userId');
    } catch (e) {
      debugPrint(
          '🔧 SettingsService: Error initializing settings for user $userId: $e');
      // Use default settings if everything fails
      notifyListeners();
    }
  }

  // Load device-wide settings from SharedPreferences
  Future<void> _loadDeviceSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme and settings with defaults
      _theme = prefs.getString(_themeKey) ?? 'light';
      _allowNotification = prefs.getBool(_allowNotificationKey) ?? false;
      _autoBudget = prefs.getBool(_autoBudgetKey) ?? false;
      _improveAccuracy = prefs.getBool(_improveAccuracyKey) ?? false;
      _automaticRebalanceSuggestions =
          prefs.getBool(_automaticRebalanceSuggestionsKey) ?? false;

      debugPrint(
          '🔧 SettingsService: Loaded device settings - theme=$_theme, allowNotification=$_allowNotification, autoBudget=$_autoBudget, improveAccuracy=$_improveAccuracy, automaticRebalanceSuggestions=$_automaticRebalanceSuggestions');
    } catch (e) {
      debugPrint('🔧 SettingsService: Error loading device settings: $e');
      // Keep default values if loading fails
    }
  }

  // Load user-specific currency from Firebase
  Future<void> _loadUserCurrency(String userId) async {
    try {
      // Get user document from Firebase
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        _currency = userData['currency'] ?? 'MYR';
        debugPrint(
            '🔧 SettingsService: Loaded user currency from Firebase: $_currency');
      } else {
        _currency = 'MYR'; // Default currency
        debugPrint(
            '🔧 SettingsService: No user document found, using default currency: $_currency');
      }
    } catch (e) {
      debugPrint('🔧 SettingsService: Error loading user currency: $e');
      _currency = 'MYR'; // Default to MYR on error
    }
  }

  // Reset all settings to default
  Future<void> resetToDefaults() async {
    try {
      const defaultTheme = 'light';
      const defaultAllowNotification = false;
      const defaultAutoBudget = false;
      const defaultImproveAccuracy = false;
      const defaultAutomaticRebalanceSuggestions = false;

      // Update local state
      _theme = defaultTheme;
      _allowNotification = defaultAllowNotification;
      _autoBudget = defaultAutoBudget;
      _improveAccuracy = defaultImproveAccuracy;
      _automaticRebalanceSuggestions = defaultAutomaticRebalanceSuggestions;

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, defaultTheme);
      await prefs.setBool(_allowNotificationKey, defaultAllowNotification);
      await prefs.setBool(_autoBudgetKey, defaultAutoBudget);
      await prefs.setBool(_improveAccuracyKey, defaultImproveAccuracy);
      await prefs.setBool(_automaticRebalanceSuggestionsKey,
          defaultAutomaticRebalanceSuggestions);

      notifyListeners();
      debugPrint('🔧 SettingsService: Settings reset to defaults');
    } catch (e) {
      debugPrint('Error resetting settings: $e');
    }
  }

  // Update currency setting
  Future<void> updateCurrency(String newCurrency) async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      final oldCurrency = _currency;
      _currency = newCurrency;

      // Update currency in Firebase
      await _firestore.collection('users').doc(user.uid).update({
        'currency': newCurrency,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
          '🔧 SettingsService: Currency updated in Firebase to: $newCurrency');
      notifyListeners();

      // Notify listeners about currency change - this will allow other components
      // such as BudgetViewModel to update their data
      if (oldCurrency != newCurrency) {
        // We need to delay this call to ensure settings are fully updated
        // before other components try to access them
        Future.microtask(() {
          debugPrint(
              'Broadcasting currency change: $oldCurrency -> $newCurrency');
          notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('Error updating currency: $e');
    }
  }

  // Update theme setting
  Future<void> updateTheme(String newTheme) async {
    try {
      _theme = newTheme;

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, newTheme);

      notifyListeners();
      debugPrint('Theme updated to: $newTheme');
    } catch (e) {
      debugPrint('Error updating theme: $e');
    }
  }

  // Update notification setting
  Future<void> updateNotificationSetting(bool allowNotification) async {
    try {
      _allowNotification = allowNotification;

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_allowNotificationKey, allowNotification);

      notifyListeners();
      debugPrint('Notification setting updated to: $allowNotification');
    } catch (e) {
      debugPrint('Error updating notification setting: $e');
    }
  }

  // Update auto budget setting
  Future<void> updateAutoBudgetSetting(bool autoBudget) async {
    try {
      // Update both settings to keep them synchronized
      _autoBudget = autoBudget;
      _automaticRebalanceSuggestions = autoBudget; // Keep in sync

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoBudgetKey, autoBudget);
      await prefs.setBool(_automaticRebalanceSuggestionsKey, autoBudget);

      notifyListeners();
      debugPrint('Auto budget setting updated to: $autoBudget');
    } catch (e) {
      debugPrint('Error updating auto budget setting: $e');
    }
  }

  // Update improve accuracy setting
  Future<void> updateImproveAccuracySetting(bool improveAccuracy) async {
    try {
      _improveAccuracy = improveAccuracy;

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_improveAccuracyKey, improveAccuracy);

      notifyListeners();
      debugPrint('Improve accuracy setting updated to: $improveAccuracy');
    } catch (e) {
      debugPrint('Error updating improve accuracy setting: $e');
    }
  }

  // Update automatic budget reallocation setting
  Future<void> updateAutomaticRebalanceSuggestions(bool enabled) async {
    try {
      // Update the setting value
      _automaticRebalanceSuggestions = enabled;

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_automaticRebalanceSuggestionsKey, enabled);

      notifyListeners();
      debugPrint('Auto budget reallocation setting updated to: $enabled');
    } catch (e) {
      debugPrint('Error updating auto budget reallocation setting: $e');
    }
  }
}
