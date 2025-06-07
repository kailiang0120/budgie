import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the local notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
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

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        macOS: initializationSettingsMacOS,
        linux: initializationSettingsLinux,
        windows: initializationSettingsWindows,
      );

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
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel expenseChannel =
        AndroidNotificationChannel(
      'expense_notifications',
      'Expense Notifications',
      description: 'Notifications for expense detection and reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
      'test_notifications',
      'Test Notifications',
      description: 'Test notifications for development',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(expenseChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(testChannel);
  }

  /// Handle notification response when app is in foreground
  void _onNotificationResponse(NotificationResponse notificationResponse) {
    debugPrint('Notification tapped: ${notificationResponse.payload}');
    // Handle notification tap actions here
    // You can navigate to specific screens or trigger actions
  }

  /// Handle notification response when app is in background
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(
      NotificationResponse notificationResponse) {
    debugPrint(
        'Background notification tapped: ${notificationResponse.payload}');
    // Handle background notification tap actions here
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    bool? result = false;

    if (Platform.isIOS || Platform.isMacOS) {
      result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
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
      await androidImplementation?.requestExactAlarmsPermission();
    }

    return result ?? false;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    } else if (Platform.isIOS || Platform.isMacOS) {
      final result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return result?.isEnabled ?? false;
    }
    return true; // Default to true for other platforms
  }

  /// Send a simple notification
  Future<void> sendNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'expense_notifications',
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'expense_notifications',
      'Expense Notifications',
      channelDescription: 'Notifications for expense detection and reminders',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );

    debugPrint('Notification sent: $title - $body');
  }

  /// Send expense notification (for testing)
  Future<void> sendTestExpenseNotification() async {
    await sendNotification(
      id: 1001,
      title: 'Payment Processed',
      body: 'Payment of RM 25.50 at Starbucks has been processed',
      payload: 'expense_notification',
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
    );
  }

  /// Send reminder notification
  Future<void> sendReminderNotification(String message) async {
    await sendNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Budgie Reminder',
      body: message,
      payload: 'reminder_notification',
    );
  }

  /// Schedule a notification for later (simplified version)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    debugPrint('Scheduling notification in ${delay.inSeconds} seconds: $title');

    // For now, we'll use a simple delay-based approach
    // In a production app, you might want to use timezone-based scheduling
    Future.delayed(delay, () async {
      await sendNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
      );
    });

    debugPrint('Notification scheduled with delay: ${delay.inSeconds} seconds');
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  /// Get active notifications (Android only)
  Future<List<ActiveNotification>> getActiveNotifications() async {
    if (Platform.isAndroid) {
      return await _flutterLocalNotificationsPlugin.getActiveNotifications();
    }
    return [];
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}
