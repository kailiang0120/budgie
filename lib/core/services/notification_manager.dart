import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:notifications/notifications.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

import 'settings_service.dart';
import 'expense_detector.dart';
import 'notification_sender.dart';
import 'permission_handler.dart';
import 'data_collector.dart';
import 'expense_card_managing_service.dart';
import '../router/app_router.dart';

/// Main notification management service that orchestrates all notification-related functionality
/// Follows enterprise-standard single responsibility principle
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  // Method channel for native communication
  static const platform = MethodChannel('com.kai.budgie/notification_listener');

  // Service state
  bool _isListening = false;
  StreamSubscription<NotificationEvent>? _notificationSubscription;

  // Service dependencies
  late final ExpenseDetector _expenseDetector;
  late final NotificationSender _notificationSender;
  late final PermissionHandler _permissionHandler;
  late final DataCollector _dataCollector;
  late final ExpenseCardManager _cardManager;

  // Notifications package instance
  final Notifications _notifications = Notifications();

  /// Initialize the notification manager and all its dependencies
  Future<void> initialize() async {
    try {
      debugPrint('🔔 NotificationManager: Initializing...');

      // Initialize service dependencies
      _expenseDetector = ExpenseDetector();
      _notificationSender = NotificationSender();
      _permissionHandler = PermissionHandler();
      _dataCollector = DataCollector();
      _cardManager = ExpenseCardManager();

      // Initialize all services
      await _notificationSender.initialize();
      await _expenseDetector.initialize();
      await _dataCollector.initialize();

      // Setup background processing
      await _setupBackgroundProcessing();

      // Setup notification listener
      await _setupNotificationListener();

      // Auto-start if user has enabled notifications
      await _checkAndStartIfEnabled();

      debugPrint('✅ NotificationManager: Initialization completed');
    } catch (e, stackTrace) {
      debugPrint('❌ NotificationManager: Initialization failed: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Start notification listening service
  Future<bool> startListening() async {
    if (_isListening) {
      debugPrint('⚠️ NotificationManager: Already listening');
      return true;
    }

    try {
      debugPrint('🔔 NotificationManager: Starting notification listener...');

      // Check permissions first
      final hasPermissions = await _permissionHandler.requestAllPermissions();
      if (!hasPermissions) {
        debugPrint('❌ NotificationManager: Insufficient permissions');
        return false;
      }

      // Setup background service for Android
      if (Platform.isAndroid) {
        await _enableBackgroundService();
      }

      // Start platform-specific listeners
      await _startPlatformListener();
      _startNotificationPackageListener();

      _isListening = true;
      debugPrint('✅ NotificationManager: Notification listening started');
      return true;
    } catch (e) {
      debugPrint('❌ NotificationManager: Failed to start listening: $e');
      _isListening = false;
      return false;
    }
  }

  /// Stop notification listening service
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      debugPrint('🔔 NotificationManager: Stopping notification listener...');

      // Stop all listeners
      _notificationSubscription?.cancel();
      _notificationSubscription = null;

      // Stop platform listener
      await platform.invokeMethod('stopListening');

      // Disable background execution
      if (Platform.isAndroid &&
          FlutterBackground.isBackgroundExecutionEnabled) {
        await FlutterBackground.disableBackgroundExecution();
      }

      _isListening = false;
      debugPrint('✅ NotificationManager: Notification listening stopped');
    } catch (e) {
      debugPrint('❌ NotificationManager: Error stopping listener: $e');
    }
  }

  /// Process a notification for potential expense detection
  Future<void> processNotification({
    required String title,
    required String content,
    required String packageName,
  }) async {
    try {
      // Check if notifications are enabled in settings
      final settingsService = SettingsService.instance;
      if (settingsService == null || !settingsService.allowNotification) {
        return;
      }

      final fullText = '$title $content'.trim();
      if (fullText.isEmpty) return;

      debugPrint(
          '🔍 NotificationManager: Processing notification from $packageName');

      // Analyze for expense
      final expenseData = await _expenseDetector.analyzeNotification(
        text: fullText,
        source: packageName,
      );

      if (expenseData != null) {
        debugPrint('💰 NotificationManager: Expense detected, showing card');
        await _showExpenseCard(expenseData);

        // Record data for analytics if enabled
        await _dataCollector.recordNotificationExpense(expenseData);
      }
    } catch (e) {
      debugPrint('❌ NotificationManager: Error processing notification: $e');
    }
  }

  /// Send a test notification (for development/testing)
  Future<void> sendTestNotification({
    String? title,
    String? content,
  }) async {
    await _notificationSender.sendTestNotification(
      title: title ?? 'Test Payment',
      content: content ?? 'Payment of RM 25.50 at Starbucks has been processed',
    );
  }

  /// Send a custom notification
  Future<void> sendNotification({
    required String title,
    required String content,
    String? payload,
  }) async {
    await _notificationSender.sendNotification(
      title: title,
      content: content,
      payload: payload,
    );
  }

  /// Simulate notification processing workflow (for testing)
  Future<void> simulateExpenseWorkflow({
    String? notificationText,
  }) async {
    final text = notificationText ??
        'Payment of RM 25.50 at Starbucks has been processed';
    await processNotification(
      title: 'Test Payment',
      content: text,
      packageName: 'test_simulation',
    );
  }

  /// Check service health status
  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'isListening': _isListening,
      'hasPermissions': await _permissionHandler.hasAllPermissions(),
      'detectorHealth': await _expenseDetector.checkHealth(),
      'backgroundServiceEnabled': Platform.isAndroid
          ? FlutterBackground.isBackgroundExecutionEnabled
          : true,
    };
  }

  // Private methods

  Future<void> _setupBackgroundProcessing() async {
    if (!Platform.isAndroid) return;

    try {
      const androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: "Budgie Expense Detector",
        notificationText: "Monitoring notifications for expenses",
        notificationImportance: AndroidNotificationImportance.normal,
        notificationIcon: AndroidResource(
          name: 'ic_launcher',
          defType: 'mipmap',
        ),
      );

      await FlutterBackground.initialize(androidConfig: androidConfig);
      platform.setMethodCallHandler(_handleNotificationData);
    } catch (e) {
      debugPrint('❌ NotificationManager: Background setup failed: $e');
    }
  }

  Future<void> _setupNotificationListener() async {
    try {
      if (Platform.isAndroid) {
        final hasPermission =
            await _permissionHandler.hasNotificationPermission();
        if (hasPermission) {
          _startNotificationPackageListener();
        }
      } else {
        _startNotificationPackageListener();
      }
    } catch (e) {
      debugPrint('❌ NotificationManager: Listener setup failed: $e');
    }
  }

  Future<void> _checkAndStartIfEnabled() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final settingsService = SettingsService.instance;
      if (settingsService != null && settingsService.allowNotification) {
        final hasPermissions = await _permissionHandler.hasAllPermissions();
        if (hasPermissions) {
          await startListening();
        }
      }
    } catch (e) {
      debugPrint('❌ NotificationManager: Auto-start check failed: $e');
    }
  }

  Future<void> _enableBackgroundService() async {
    try {
      final hasBackgroundPermissions = await FlutterBackground.hasPermissions;
      if (!hasBackgroundPermissions) {
        debugPrint('❌ NotificationManager: No background permissions');
        return;
      }

      await FlutterBackground.enableBackgroundExecution();
    } catch (e) {
      debugPrint('❌ NotificationManager: Background service failed: $e');
    }
  }

  Future<void> _startPlatformListener() async {
    try {
      await platform.invokeMethod('startListening');
    } catch (e) {
      debugPrint('❌ NotificationManager: Platform listener failed: $e');
    }
  }

  void _startNotificationPackageListener() {
    try {
      _notificationSubscription?.cancel();
      _notificationSubscription =
          _notifications.notificationStream?.listen(_onNotificationReceived);
    } catch (e) {
      debugPrint('❌ NotificationManager: Package listener failed: $e');
    }
  }

  Future<void> _onNotificationReceived(NotificationEvent event) async {
    await processNotification(
      title: event.title ?? '',
      content: event.message ?? '',
      packageName: event.packageName ?? '',
    );
  }

  Future<void> _handleNotificationData(MethodCall call) async {
    if (call.method == 'onNotificationReceived') {
      final Map<dynamic, dynamic> data = call.arguments;
      await processNotification(
        title: data['title'] ?? '',
        content: data['content'] ?? '',
        packageName: data['packageName'] ?? '',
      );
    }
  }

  Future<void> _showExpenseCard(Map<String, dynamic> expenseData) async {
    try {
      final navigatorState = navigatorKey.currentState;
      final BuildContext? context =
          navigatorState?.overlay?.context ?? navigatorState?.context;

      if (context == null) {
        debugPrint(
            '❌ NotificationManager: No context available for expense card');
        return;
      }

      _cardManager.showExpenseCard(
        context,
        expenseData,
        onExpenseSaved: () {
          debugPrint('✅ NotificationManager: Expense saved from notification');
        },
        onDismissed: () {
          debugPrint('ℹ️ NotificationManager: Expense card dismissed');
        },
      );
    } catch (e) {
      debugPrint('❌ NotificationManager: Error showing expense card: $e');
    }
  }

  // Delegation methods for permission management

  /// Check if notification permission is granted
  Future<bool> checkNotificationPermission() async {
    return await _permissionHandler.hasNotificationPermission();
  }

  /// Check if notification listener permission is granted (Android only)
  Future<bool> checkNotificationListenerPermission() async {
    return await _permissionHandler.hasNotificationListenerPermission();
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    return await _permissionHandler.requestAllPermissions();
  }

  /// Request basic notification permission only
  Future<bool> requestLocalNotificationPermissions() async {
    return await _permissionHandler.requestNotificationPermission();
  }

  /// Request notification listener permission (opens settings on Android)
  Future<bool> requestNotificationListenerPermission() async {
    return await _permissionHandler.requestNotificationListenerPermission();
  }

  /// Request notification access permission (alias for requestNotificationListenerPermission)
  Future<void> requestNotificationAccessPermission() async {
    await _permissionHandler.requestNotificationListenerPermission();
  }

  /// Get permission status for debugging
  Future<Map<String, dynamic>> getPermissionStatus() async {
    return await _permissionHandler.getPermissionStatus();
  }

  /// Check if all required permissions are granted
  Future<bool> hasAllPermissions() async {
    return await _permissionHandler.hasAllPermissions();
  }

  // Compatibility methods for older API

  /// Request all notification permissions (compatibility method)
  Future<bool> requestAllNotificationPermissions() async {
    return await _permissionHandler.requestAllPermissions();
  }

  /// Send test expense notification (compatibility method)
  Future<void> sendTestExpenseNotification() async {
    await sendTestNotification(
      title: 'Test Payment',
      content: 'Payment of RM 25.50 at Starbucks has been processed',
    );
  }

  /// Send test custom notification (compatibility method)
  Future<void> sendTestCustomNotification({
    required String title,
    required String body,
  }) async {
    await sendNotification(
      title: title,
      content: body,
    );
  }

  /// Start notification listener (compatibility method)
  Future<void> startNotificationListener() async {
    await startListening();
  }

  /// Stop notification listener (compatibility method)
  Future<void> stopNotificationListener() async {
    await stopListening();
  }

  /// Getters for service state
  bool get isListening => _isListening;

  /// Cleanup resources
  void dispose() {
    _notificationSubscription?.cancel();
    _expenseDetector.dispose();
    _notificationSender.dispose();
    _cardManager.hideCard();
    _isListening = false;
  }
}
