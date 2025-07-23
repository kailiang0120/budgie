import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';
import 'dart:convert';
import 'dart:async';

import '../../models/expense_detection_models.dart';
import 'package:budgie/core/constants/routes.dart';
import 'package:budgie/main.dart'; // for navigatorKey
import 'settings_service.dart'; // For SettingsService.notificationsEnabled

/// Data class for navigation events triggered by notifications
class NotificationNavigationAction {
  final String route;
  final dynamic arguments;

  NotificationNavigationAction({required this.route, this.arguments});
}

/// Temporary storage for extracted expense data from notifications
class _TempExpenseData {
  final String detectionId;
  final ExpenseExtractionResult extractionResult;
  final DateTime timestamp;

  _TempExpenseData({
    required this.detectionId,
    required this.extractionResult,
    required this.timestamp,
  });
}

/// Callback function type for expense refresh
typedef ExpenseRefreshCallback = Future<void> Function();

/// Unified notification service for sending local notifications
/// Provides a clean interface for all notification sending functionality
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Temporary storage for extracted expense data
  final Map<String, _TempExpenseData> _tempExpenseStorage = {};
  static const Duration _tempStorageTimeout = Duration(hours: 1);

  // Plugin instance
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Service state
  bool _isInitialized = false;
  bool _isTimeZoneInitialized = false;

  // Notification channels
  static const String _generalChannelId = 'general_notifications';
  static const String _expenseChannelId = 'expense_notifications';
  static const String _reminderChannelId = 'reminder_notifications';

  // Callback for refreshing app data when expenses are added
  ExpenseRefreshCallback? _expenseRefreshCallback;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        debugPrint('📤 NotificationService: Initializing...');
      }

      // Initialize timezone data for scheduled notifications
      if (!_isTimeZoneInitialized) {
        tz_data.initializeTimeZones();
        _isTimeZoneInitialized = true;
      }

      // Platform-specific initialization settings
      final initializationSettings = _createInitializationSettings();

      // Initialize the plugin
      await _plugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Create notification channels for Android
      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('✅ NotificationService: Initialization completed');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ NotificationService: Initialization failed: $e');
        debugPrint('📍 Stack trace: $stackTrace');
      }
      // Don't throw - app should continue working even if notifications fail
    }
  }

  /// Send a general notification
  Future<bool> sendNotification({
    required String title,
    required String content,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
    String? channelId,
  }) async {
    // Check if notifications are enabled before sending
    if (!SettingsService.notificationsEnabled) {
      if (kDebugMode) {
        debugPrint(
            '📤 NotificationService: Notifications are disabled in settings. Skipping sendNotification.');
      }
      return false;
    }
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final effectiveChannelId = channelId ?? _generalChannelId;
      final details = _getNotificationDetails(effectiveChannelId, priority);

      await _plugin.show(
        notificationId,
        title,
        content,
        details,
        payload: payload,
      );

      if (kDebugMode) {
        debugPrint('📤 NotificationService: Sent notification - $title');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ NotificationService: Failed to send notification: $e');
      }
      return false;
    }
  }

  /// Send an expense detected notification with actions to record or dismiss
  Future<bool> sendExpenseDetectedNotification({
    required String detectionId,
    required ExpenseExtractionResult extractionResult,
  }) async {
    // Check if notifications are enabled before sending
    if (!SettingsService.notificationsEnabled) {
      if (kDebugMode) {
        debugPrint(
            '📤 NotificationService: Notifications are disabled in settings. Skipping sendExpenseDetectedNotification.');
      }
      return false;
    }
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Store the extracted data temporarily
      _tempExpenseStorage[detectionId] = _TempExpenseData(
        detectionId: detectionId,
        extractionResult: extractionResult,
        timestamp: DateTime.now(),
      );

      // Clean up old entries
      _cleanupTempStorage();

      final payload = jsonEncode({
        'type': 'expense_detected',
        'detectionId': detectionId,
      });

      final androidActions = <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'record_expense',
          'Record',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'dismiss',
          'Dismiss',
          cancelNotification: true,
        ),
      ];

      final details = _getNotificationDetails(
        _expenseChannelId,
        NotificationPriority.high,
        actions: androidActions,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final merchantName = extractionResult.merchantName ?? 'a recent purchase';

      await _plugin.show(
        notificationId,
        'Expense Detected',
        'Record expense from $merchantName?',
        details,
        payload: payload,
      );

      if (kDebugMode) {
        debugPrint(
            '📤 NotificationService: Sent actionable expense notification');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ NotificationService: Failed to send actionable notification: $e');
      }
      return false;
    }
  }

  /// Clean up old temporary storage entries
  void _cleanupTempStorage() {
    final now = DateTime.now();
    _tempExpenseStorage.removeWhere((key, value) {
      return now.difference(value.timestamp) > _tempStorageTimeout;
    });
  }

  /// Get stored expense data by detection ID
  ExpenseExtractionResult? getStoredExpenseData(String detectionId) {
    final tempData = _tempExpenseStorage[detectionId];
    if (tempData != null) {
      // Check if data is still valid
      if (DateTime.now().difference(tempData.timestamp) <=
          _tempStorageTimeout) {
        return tempData.extractionResult;
      } else {
        // Remove expired data
        _tempExpenseStorage.remove(detectionId);
      }
    }
    return null;
  }

  /// Clear stored expense data by detection ID
  void clearStoredExpenseData(String detectionId) {
    _tempExpenseStorage.remove(detectionId);
    if (kDebugMode) {
      debugPrint(
          '📤 NotificationService: Cleared stored data for detection ID: $detectionId');
    }
  }

  /// Send a reminder notification
  Future<bool> sendReminderNotification({
    required String message,
    String? title,
    String? payload,
  }) async {
    // Check if notifications are enabled before sending
    if (!SettingsService.notificationsEnabled) {
      if (kDebugMode) {
        debugPrint(
            '📤 NotificationService: Notifications are disabled in settings. Skipping sendReminderNotification.');
      }
      return false;
    }
    return await sendNotification(
      title: title ?? 'Budgie Reminder',
      content: message,
      payload: payload ?? 'reminder_notification',
      priority: NotificationPriority.normal,
      channelId: _reminderChannelId,
    );
  }

  /// Schedule a notification for later delivery
  Future<bool> scheduleNotification({
    required String title,
    required String content,
    required Duration delay,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
    String? channelId,
  }) async {
    // Check if notifications are enabled before scheduling
    if (!SettingsService.notificationsEnabled) {
      if (kDebugMode) {
        debugPrint(
            '📤 NotificationService: Notifications are disabled in settings. Skipping scheduleNotification.');
      }
      return false;
    }
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Ensure timezone data is initialized
      if (!_isTimeZoneInitialized) {
        tz_data.initializeTimeZones();
        _isTimeZoneInitialized = true;
      }

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final effectiveChannelId = channelId ?? _reminderChannelId;
      final details = _getNotificationDetails(effectiveChannelId, priority);
      final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);

      // For Android platform, request exact alarm permission if needed
      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.requestExactAlarmsPermission();
        }
      }

      // Schedule the notification
      await _plugin.zonedSchedule(
        notificationId,
        title,
        content,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      if (kDebugMode) {
        debugPrint(
            '📤 NotificationService: Scheduled notification for ${scheduledTime.toString()}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ NotificationService: Failed to schedule notification: $e');
      }

      // Fallback to Future.delayed if zonedSchedule fails
      Future.delayed(delay, () async {
        await sendNotification(
          title: title,
          content: content,
          payload: payload,
          priority: priority,
          channelId: channelId,
        );
      });
      return false;
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
      if (kDebugMode) {
        debugPrint('📤 NotificationService: Cancelled notification $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ NotificationService: Failed to cancel notification: $e');
      }
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
      if (kDebugMode) {
        debugPrint('📤 NotificationService: Cancelled all notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ NotificationService: Failed to cancel all notifications: $e');
      }
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ NotificationService: Failed to get pending notifications: $e');
      }
      return [];
    }
  }

  /// Get active notifications (Android only)
  Future<List<ActiveNotification>> getActiveNotifications() async {
    try {
      if (Platform.isAndroid) {
        return await _plugin.getActiveNotifications();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ NotificationService: Failed to get active notifications: $e');
      }
    }
    return [];
  }

  /// Set callback function to refresh app data after expense is added via notifications
  void setExpenseRefreshCallback(ExpenseRefreshCallback callback) {
    _expenseRefreshCallback = callback;
    if (kDebugMode) {
      debugPrint('📤 NotificationService: Expense refresh callback registered');
    }
  }

  /// Cleanup after expense is successfully added via notification
  Future<void> cleanupAfterExpenseAdded(String detectionId) async {
    try {
      // Clear the temporary storage
      clearStoredExpenseData(detectionId);

      // Trigger app data refresh
      if (_expenseRefreshCallback != null) {
        if (kDebugMode) {
          debugPrint(
              '📤 NotificationService: Triggering app data refresh after expense addition');
        }
        await _expenseRefreshCallback!();
        if (kDebugMode) {
          debugPrint('✅ NotificationService: App data refresh completed');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ NotificationService: No refresh callback registered');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ NotificationService: Error during cleanup after expense addition: $e');
      }
    }
  }

  // Private methods

  /// Create platform-specific initialization settings
  InitializationSettings _createInitializationSettings() {
    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // macOS initialization settings
    const DarwinInitializationSettings initializationSettingsMacOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Linux initialization settings
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    // Windows initialization settings
    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
      appName: 'Budgie',
      appUserModelId: 'com.kai.budgie',
      guid: 'a7a8d8e8-f8f8-4e4e-a8a8-d8e8f8f8e8f8',
    );

    return const InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS,
      linux: initializationSettingsLinux,
      windows: initializationSettingsWindows,
    );
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Define channels
    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
      _generalChannelId,
      'General Notifications',
      description: 'General notifications from Budgie',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel expenseChannel =
        AndroidNotificationChannel(
      _expenseChannelId,
      'Expense Notifications',
      description: 'Notifications for expense detection and alerts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel reminderChannel =
        AndroidNotificationChannel(
      _reminderChannelId,
      'Reminder Notifications',
      description: 'Reminders for budget and expense tracking',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: false,
    );

    // Create channels
    await androidPlugin.createNotificationChannel(generalChannel);
    await androidPlugin.createNotificationChannel(expenseChannel);
    await androidPlugin.createNotificationChannel(reminderChannel);
  }

  /// Get notification details based on channel ID and priority
  NotificationDetails _getNotificationDetails(
      String channelId, NotificationPriority priority,
      {List<AndroidNotificationAction>? actions}) {
    // Determine importance and priority based on enum
    final importance = priority == NotificationPriority.high
        ? Importance.high
        : priority == NotificationPriority.low
            ? Importance.low
            : Importance.defaultImportance;

    final androidPriority = priority == NotificationPriority.high
        ? Priority.high
        : priority == NotificationPriority.low
            ? Priority.low
            : Priority.defaultPriority;

    // Android notification details
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: 'Notifications for Budgie expense tracking app',
      importance: importance,
      priority: androidPriority,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      actions: actions,
    );

    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Get channel name from channel ID
  String _getChannelName(String channelId) {
    switch (channelId) {
      case _expenseChannelId:
        return 'Expense Notifications';
      case _reminderChannelId:
        return 'Reminder Notifications';
      case _generalChannelId:
        return 'General Notifications';
      default:
        return 'General Notifications';
    }
  }

  /// Handle notification response when app is in foreground
  void _onNotificationResponse(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    final String? actionId = notificationResponse.actionId;
    if (kDebugMode) {
      debugPrint(
          '📤 NotificationService: Notification tapped with payload: $payload, action: $actionId');
    }

    if (payload == null) return;

    try {
      final payloadMap = jsonDecode(payload) as Map<String, dynamic>;
      final type = payloadMap['type'] as String?;

      // Handle expense detection notifications
      if (type == 'expense_detected') {
        _handleExpenseNotificationResponse(actionId, payload);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '📤 NotificationService: Error handling notification response: $e');
      }
    }
  }

  /// Handle expense detection notification responses
  void _handleExpenseNotificationResponse(String? actionId, String payload) {
    try {
      final payloadMap = jsonDecode(payload) as Map<String, dynamic>;
      final detectionId = payloadMap['detectionId'] as String?;

      if (detectionId == null) {
        if (kDebugMode) {
          debugPrint('📤 NotificationService: Missing detectionId in payload');
        }
        return;
      }

      // Handle different action types
      if (actionId == 'record_expense' || actionId == null) {
        // Queue navigation to add expense screen with stored data
        _queueNavigationFromStoredData(detectionId);
      } else if (actionId == 'dismiss') {
        // User dismissed - clear the stored data
        if (kDebugMode) {
          debugPrint(
              '📤 NotificationService: Expense notification dismissed by user.');
        }

        // Clear the temporary storage
        clearStoredExpenseData(detectionId);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '📤 NotificationService: Error handling expense notification: $e');
      }
    }
  }

  /// Queues navigation using stored expense data
  void _queueNavigationFromStoredData(String detectionId) {
    try {
      final extractionResult = getStoredExpenseData(detectionId);

      final arguments = extractionResult != null
          ? {
              'amount': extractionResult.parsedAmount,
              'currency': extractionResult.currency,
              'remarks': extractionResult.merchantName,
              'category': extractionResult.suggestedCategory,
              'paymentMethod': extractionResult.paymentMethod,
              'detectionId': detectionId,
            }
          : null;

      // Always ensure the home route is present before navigating to add expense
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        Routes.home,
        (route) => false,
      );
      // Then push the add expense screen
      navigatorKey.currentState?.pushNamed(
        '/add_expense',
        arguments: arguments,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error navigating from notification: $e');
      }
    }
  }

  /// Cleanup resources
  void dispose() {
    _tempExpenseStorage.clear();
    if (kDebugMode) {
      debugPrint('📤 NotificationService: Service disposed');
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}

/// Notification priority levels
enum NotificationPriority {
  low,
  normal,
  high,
}
