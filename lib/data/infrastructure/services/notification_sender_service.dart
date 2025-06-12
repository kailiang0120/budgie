import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';

/// Service responsible for sending local notifications across different platforms
/// Handles all outgoing notification functionality with proper platform support
class NotificationSenderService {
  static final NotificationSenderService _instance =
      NotificationSenderService._internal();
  factory NotificationSenderService() => _instance;
  NotificationSenderService._internal();

  // Plugin instance
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Service state
  bool _isInitialized = false;
  bool _isTimeZoneInitialized = false;

  // Notification channels
  static const String _expenseChannelId = 'expense_notifications';
  static const String _testChannelId = 'test_notifications';
  static const String _reminderChannelId = 'reminder_notifications';

  /// Initialize the notification sender service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('📤 NotificationSenderService: Initializing...');

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
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationResponse,
      );

      // Create notification channels for Android
      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      _isInitialized = true;
      debugPrint('✅ NotificationSenderService: Initialization completed');
    } catch (e, stackTrace) {
      debugPrint('❌ NotificationSenderService: Initialization failed: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      // Don't throw - app should continue working even if notifications fail
    }
  }

  /// Send a general notification
  Future<bool> sendNotification({
    required String title,
    required String content,
    String? payload,
    String channelId = _expenseChannelId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final details = _getNotificationDetails(channelId);

      await _plugin.show(
        notificationId,
        title,
        content,
        details,
        payload: payload,
      );

      debugPrint('📤 NotificationSenderService: Sent notification - $title');
      return true;
    } catch (e) {
      debugPrint(
          '❌ NotificationSenderService: Failed to send notification: $e');
      return false;
    }
  }

  /// Send a test notification for development/testing
  Future<bool> sendTestNotification({
    String? title,
    String? content,
  }) async {
    return await sendNotification(
      title: title ?? 'Test Notification',
      content: content ?? 'This is a test notification from Budgie',
      payload: 'test_notification',
      channelId: _testChannelId,
    );
  }

  /// Send an expense-related notification
  Future<bool> sendExpenseNotification({
    required double amount,
    required String merchant,
    String currency = 'RM',
  }) async {
    return await sendNotification(
      title: 'Payment Processed',
      content: 'Payment of $currency $amount at $merchant has been processed',
      payload: 'expense_notification',
      channelId: _expenseChannelId,
    );
  }

  /// Send a reminder notification
  Future<bool> sendReminderNotification({
    required String message,
    String? title,
  }) async {
    return await sendNotification(
      title: title ?? 'Budgie Reminder',
      content: message,
      payload: 'reminder_notification',
      channelId: _reminderChannelId,
    );
  }

  /// Schedule a notification for later delivery
  Future<bool> scheduleNotification({
    required String title,
    required String content,
    required Duration delay,
    String? payload,
    String channelId = _reminderChannelId,
  }) async {
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
      final details = _getNotificationDetails(channelId);
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

      debugPrint(
          '📤 NotificationSenderService: Scheduled notification for ${scheduledTime.toString()}');
      return true;
    } catch (e) {
      debugPrint(
          '❌ NotificationSenderService: Failed to schedule notification: $e');

      // Fallback to Future.delayed if zonedSchedule fails
      Future.delayed(delay, () async {
        await sendNotification(
          title: title,
          content: content,
          payload: payload,
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
      debugPrint('📤 NotificationSenderService: Cancelled notification $id');
    } catch (e) {
      debugPrint(
          '❌ NotificationSenderService: Failed to cancel notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
      debugPrint('📤 NotificationSenderService: Cancelled all notifications');
    } catch (e) {
      debugPrint(
          '❌ NotificationSenderService: Failed to cancel all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint(
          '❌ NotificationSenderService: Failed to get pending notifications: $e');
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
      debugPrint(
          '❌ NotificationSenderService: Failed to get active notifications: $e');
    }
    return [];
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
    const AndroidNotificationChannel expenseChannel =
        AndroidNotificationChannel(
      _expenseChannelId,
      'Expense Notifications',
      description: 'Notifications for expense detection and alerts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
      _testChannelId,
      'Test Notifications',
      description: 'Test notifications for development',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel reminderChannel =
        AndroidNotificationChannel(
      _reminderChannelId,
      'Reminder Notifications',
      description: 'Reminders for budget and expense tracking',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Create channels
    await androidPlugin.createNotificationChannel(expenseChannel);
    await androidPlugin.createNotificationChannel(testChannel);
    await androidPlugin.createNotificationChannel(reminderChannel);
  }

  /// Get notification details based on channel ID
  NotificationDetails _getNotificationDetails(String channelId) {
    // Android notification details
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: 'Notifications for Budgie expense tracking app',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
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
      case _testChannelId:
        return 'Test Notifications';
      default:
        return 'General Notifications';
    }
  }

  /// Handle notification response when app is in foreground
  void _onNotificationResponse(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    debugPrint(
        '📤 NotificationSenderService: Notification tapped with payload: $payload');

    // Additional handling can be added here based on payload
  }

  /// Handle notification response when app is in background
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(
      NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    debugPrint(
        '📤 NotificationSenderService: Background notification tapped with payload: $payload');

    // Additional handling can be added here based on payload
  }

  /// Cleanup resources
  void dispose() {
    // Clean up any resources if needed
    debugPrint('📤 NotificationSenderService: Service disposed');
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
