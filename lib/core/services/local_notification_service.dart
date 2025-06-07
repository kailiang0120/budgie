import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';

/// Service for handling local notifications across different platforms
class LocalNotificationService {
  // Singleton implementation
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  // Plugin instance
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Service state
  bool _isInitialized = false;
  bool _isTimeZoneInitialized = false;

  // Notification channels
  static const String _expenseChannelId = 'expense_notifications';
  static const String _testChannelId = 'test_notifications';
  static const String _reminderChannelId = 'reminder_notifications';

  /// Initialize the local notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone data for scheduled notifications
      if (!_isTimeZoneInitialized) {
        tz_data.initializeTimeZones();
        _isTimeZoneInitialized = true;
      }

      // Platform-specific initialization settings
      final initializationSettings = _createInitializationSettings();

      // Initialize the plugin
      await _flutterLocalNotificationsPlugin.initialize(
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
      debugPrint('Local notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing local notification service: $e');
      // Re-throw if this is critical to app functionality
      // throw e;
    }
  }

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
    final androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Define channels
    const AndroidNotificationChannel expenseChannel =
        AndroidNotificationChannel(
      _expenseChannelId,
      'Expense Notifications',
      description: 'Notifications for expense detection and reminders',
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

  /// Handle notification response when app is in foreground
  void _onNotificationResponse(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    debugPrint('Notification tapped: $payload');

    // Add specific handling based on payload if needed
  }

  /// Handle notification response when app is in background
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(
      NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    debugPrint('Background notification tapped: $payload');

    // Add specific handling based on payload if needed
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    bool? result = false;

    try {
      if (Platform.isIOS || Platform.isMacOS) {
        final iosImplementation = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();

        if (iosImplementation != null) {
          result = await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
        }
      } else if (Platform.isAndroid) {
        final androidImplementation = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        // For Android 13+, request notification permission
        if (await Permission.notification.isDenied) {
          final status = await Permission.notification.request();
          result = status.isGranted;
        } else {
          result = await Permission.notification.isGranted;
        }

        // Also request exact alarm permission for scheduled notifications
        if (androidImplementation != null) {
          await androidImplementation.requestExactAlarmsPermission();
        }
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }

    return result ?? false;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        return await Permission.notification.isGranted;
      } else if (Platform.isIOS || Platform.isMacOS) {
        final iosImplementation = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();

        if (iosImplementation != null) {
          final result = await iosImplementation.checkPermissions();
          return result?.isEnabled ?? false;
        }
      }
    } catch (e) {
      debugPrint('Error checking notification permissions: $e');
    }

    return true; // Default to true for other platforms
  }

  /// Get notification details based on channel ID
  NotificationDetails _getNotificationDetails(String channelId) {
    // Android notification details
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelId == _expenseChannelId
          ? 'Expense Notifications'
          : channelId == _reminderChannelId
              ? 'Reminder Notifications'
              : 'Test Notifications',
      channelDescription: 'Notifications for Budgie app',
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

  /// Send a simple notification
  Future<void> sendNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = _expenseChannelId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final NotificationDetails details = _getNotificationDetails(channelId);

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      debugPrint('Notification sent: $title - $body');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Send expense notification (for testing)
  Future<void> sendTestExpenseNotification() async {
    await sendNotification(
      id: 1001,
      title: 'Payment Processed',
      body: 'Payment of RM 25.50 at Starbucks has been processed',
      payload: 'expense_notification',
      channelId: _testChannelId,
    );
  }

  /// Send payment notification with custom amount and merchant
  Future<void> sendPaymentNotification({
    required double amount,
    required String merchant,
    String currency = 'RM',
  }) async {
    await sendNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Payment Processed',
      body: 'Payment of $currency $amount at $merchant has been processed',
      payload: 'payment_notification',
      channelId: _expenseChannelId,
    );
  }

  /// Send reminder notification
  Future<void> sendReminderNotification(String message) async {
    await sendNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Budgie Reminder',
      body: message,
      payload: 'reminder_notification',
      channelId: _reminderChannelId,
    );
  }

  /// Schedule a notification for later
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
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

      final NotificationDetails details = _getNotificationDetails(channelId);
      final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);

      // For Android platform
      if (Platform.isAndroid) {
        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          // Request exact alarm permission if needed
          await androidPlugin.requestExactAlarmsPermission();
        }
      }

      // Schedule the notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      debugPrint('Notification scheduled for ${scheduledTime.toString()}');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');

      // Fallback to Future.delayed if zonedSchedule fails
      Future.delayed(delay, () async {
        await sendNotification(
          id: id,
          title: title,
          body: body,
          payload: payload,
          channelId: channelId,
        );
      });
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }

  /// Get active notifications (Android only)
  Future<List<ActiveNotification>> getActiveNotifications() async {
    try {
      if (Platform.isAndroid) {
        return await _flutterLocalNotificationsPlugin.getActiveNotifications();
      }
    } catch (e) {
      debugPrint('Error getting active notifications: $e');
    }
    return [];
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}
