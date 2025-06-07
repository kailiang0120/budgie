import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:notifications/notifications.dart';

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'settings_service.dart';
import 'notification_detection_api_service.dart';
import 'api_models.dart' as api_models;
import 'expense_card_managing_service.dart';
import 'local_notification_service.dart';
import '../router/app_router.dart';

/// Helper class to handle notification permissions
class NotificationPermissionHandler {
  static const platform = MethodChannel('com.kai.budgie/notification_listener');

  /// Request notification permission using permission_handler
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Check if notification permission is granted
  static Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Check notification access permission (Android specific)
  static Future<bool> checkNotificationAccessPermission() async {
    try {
      if (!Platform.isAndroid) return true;

      final result = await platform.invokeMethod('checkNotificationAccess');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('Error checking notification access: $e');
      return false;
    }
  }

  /// Request notification access permission (opens settings)
  static Future<void> requestNotificationAccessPermission() async {
    try {
      await platform.invokeMethod('requestNotificationAccess');
    } catch (e) {
      debugPrint('Error requesting notification access: $e');
    }
  }

  /// Request all notification related permissions
  static Future<bool> requestAllNotificationPermissions(
      LocalNotificationService localNotificationService) async {
    // Request local notification permissions first (for sending notifications)
    final localPermission = await localNotificationService.requestPermissions();

    if (!localPermission) {
      debugPrint('Local notification permission denied');
      return false;
    }

    // For Android, we need special notification listener permission
    if (Platform.isAndroid) {
      final hasListenerAccess = await checkNotificationAccessPermission();
      if (!hasListenerAccess) {
        debugPrint(
            'Notification listener permission not granted. Opening settings...');
        await requestNotificationAccessPermission();
        return true; // Let user manually grant permission
      }
    }

    return true;
  }
}

/// Service responsible for handling notification processing and expense detection
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const platform = MethodChannel('com.kai.budgie/notification_listener');
  bool _isListening = false;
  StreamSubscription<dynamic>? _notificationSubscription;

  // Notifications package instance and subscription
  final Notifications _notifications = Notifications();
  StreamSubscription<NotificationEvent>? _notificationsSubscription;

  // Services
  final NotificationDetectionApiService _apiService =
      NotificationDetectionApiService();
  final ExpenseCardManager _cardManager = ExpenseCardManager();
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();

  // Initialize the service
  Future<void> init() async {
    debugPrint('Notification service initialized');

    await _localNotificationService.initialize();
    await _setupBackgroundProcessing();
    await _initNotificationsPackage();
    await _checkAndStartListener();

    // Check API health on initialization
    final apiHealthy = await _apiService.checkHealth();
    if (!apiHealthy) {
      debugPrint('Warning: Notification detection API is not available');
    }
  }

  // Initialize the notifications package listener
  Future<void> _initNotificationsPackage() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        if (status.isGranted) {
          _startNotificationsPackageListener();
        }
      } else {
        _startNotificationsPackageListener();
      }
    } catch (e) {
      debugPrint('Error initializing notifications package: $e');
    }
  }

  // Start/stop the notifications package listener
  void _startNotificationsPackageListener() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription =
        _notifications.notificationStream!.listen(_onNotificationReceived);
  }

  void _stopNotificationsPackageListener() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
  }

  // Handle notification events from the notifications package
  Future<void> _onNotificationReceived(NotificationEvent event) async {
    try {
      // Only process notifications when allowed
      final settingsService = SettingsService.instance;
      if (settingsService == null || !settingsService.allowNotification) {
        return;
      }

      final String title = event.title ?? '';
      final String text = event.message ?? '';
      final String packageName = event.packageName ?? '';

      // Skip empty notifications
      if (title.isEmpty && text.isEmpty) return;

      // Process using our existing analysis pipeline
      final fullText = '$title $text'.trim();
      await _analyzeNotificationForExpense(fullText, packageName);
    } catch (e) {
      debugPrint('Error processing notification from package: $e');
    }
  }

  // Setup background processing to handle notifications
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

      // Try to initialize background service
      bool hasPermissions = await _initializeBackgroundService(androidConfig);

      if (hasPermissions) {
        platform.setMethodCallHandler(_handleNotificationData);
        await _tryEnableBackgroundExecution();
      }
    } catch (e) {
      debugPrint('Error setting up background processing: $e');
    }
  }

  // Initialize background service with retry
  Future<bool> _initializeBackgroundService(
      FlutterBackgroundAndroidConfig config) async {
    // First initialization triggers permission dialog
    bool hasPermissions =
        await FlutterBackground.initialize(androidConfig: config);

    // If we have permissions but initialization failed, try again
    if (!hasPermissions && await FlutterBackground.hasPermissions) {
      hasPermissions =
          await FlutterBackground.initialize(androidConfig: config);
    }

    return hasPermissions;
  }

  // Try to enable background execution with retries
  Future<bool> _tryEnableBackgroundExecution() async {
    int retries = 0;
    const maxRetries = 3;

    while (retries < maxRetries) {
      try {
        final result = await FlutterBackground.enableBackgroundExecution();
        if (result) return true;
      } catch (e) {
        debugPrint('Error enabling background execution: $e');
      }

      await Future.delayed(const Duration(milliseconds: 500));
      retries++;
    }

    return false;
  }

  // Check user settings and start listener if enabled
  Future<void> _checkAndStartListener() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final settingsService = SettingsService.instance;
      if (settingsService != null && settingsService.allowNotification) {
        final hasPermission =
            await NotificationPermissionHandler.checkNotificationPermission();
        if (hasPermission) {
          await startNotificationListener();
        }
      }
    } catch (e) {
      debugPrint('Error checking notification settings: $e');
    }
  }

  // Start the notification listener
  Future<void> startNotificationListener() async {
    if (_isListening) return;

    try {
      // For Android, check notification access permission
      if (Platform.isAndroid) {
        final hasAccess = await NotificationPermissionHandler
            .checkNotificationAccessPermission();
        if (!hasAccess) {
          debugPrint('Notification access permission not granted');
          return;
        }

        // Initialize background service
        const androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: "Budgie Expense Detector",
          notificationText: "Monitoring notifications for expenses",
          notificationImportance: AndroidNotificationImportance.normal,
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
            defType: 'mipmap',
          ),
        );

        if (!await _initializeBackgroundService(androidConfig)) {
          debugPrint('Failed to initialize background service');
          return;
        }

        // Enable background execution
        await _tryEnableBackgroundExecution();
      }

      // Set up method channel listener
      platform.setMethodCallHandler(_handleNotificationData);
      _isListening = true;

      try {
        await platform.invokeMethod('startListening');
        _startNotificationsPackageListener();
      } catch (e) {
        _isListening = false;
        debugPrint('Error starting notification listener: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('Error starting notification listener: $e');
      _isListening = false;
      rethrow;
    }
  }

  // Stop the notification listener
  Future<void> stopNotificationListener() async {
    if (!_isListening) return;

    try {
      await platform.invokeMethod('stopListening');
      _isListening = false;

      // Disable background execution if enabled
      if (Platform.isAndroid &&
          FlutterBackground.isBackgroundExecutionEnabled) {
        await FlutterBackground.disableBackgroundExecution();
      }

      _stopNotificationsPackageListener();
    } catch (e) {
      debugPrint('Error stopping notification listener: $e');
    }
  }

  // Handle incoming notification data
  Future<void> _handleNotificationData(MethodCall call) async {
    if (call.method == 'onNotificationReceived') {
      final Map<dynamic, dynamic> data = call.arguments;
      final String title = data['title'] ?? '';
      final String content = data['content'] ?? '';
      final String packageName = data['packageName'] ?? '';

      await _processNotificationInBackground(title, content, packageName);
    }
  }

  // Process notification in background
  Future<void> _processNotificationInBackground(
      String title, String content, String packageName) async {
    try {
      final fullText = '$title $content'.trim();
      if (fullText.isEmpty) return;

      await _analyzeNotificationForExpense(fullText, packageName);
    } catch (e) {
      debugPrint('Error processing notification in background: $e');
    }
  }

  // Analyze notification text using API to determine if it's an expense
  Future<void> _analyzeNotificationForExpense(
      String notificationText, String packageName) async {
    try {
      final expenseData = await _callExpenseClassificationAPI(notificationText);

      if (expenseData != null && expenseData['amount'] != null) {
        await _saveAutoDetectedExpense(expenseData, packageName);
      }
    } catch (e) {
      debugPrint('Error analyzing notification: $e');
    }
  }

  // Call the API service for expense classification
  Future<Map<String, dynamic>?> _callExpenseClassificationAPI(
      String text) async {
    try {
      final response = await _apiService.classifyNotification(text);

      // Check if it's classified as an expense with sufficient confidence
      if (response.isExpense && response.confidence >= 0.5) {
        return _extractExpenseData(text, response);
      }

      return null;
    } on api_models.ApiException catch (e) {
      debugPrint('API error calling expense classification: $e');
      return _fallbackExpenseDetection(text);
    } catch (e) {
      debugPrint('Error calling expense classification API: $e');
      return _fallbackExpenseDetection(text);
    }
  }

  // Extract expense data from API response
  Map<String, dynamic> _extractExpenseData(
      String text, api_models.NotificationResponse response) {
    double? amount;
    String currency = 'MYR'; // Default currency

    if (response.extractedAmount != null) {
      final amountStr = response.extractedAmount!;

      // Determine currency
      if (amountStr.contains('RM') || amountStr.contains('MYR')) {
        currency = 'MYR';
      } else if (amountStr.contains('\$') || amountStr.contains('USD')) {
        currency = 'USD';
      } else if (amountStr.contains('€') || amountStr.contains('EUR')) {
        currency = 'EUR';
      } else if (amountStr.contains('£') || amountStr.contains('GBP')) {
        currency = 'GBP';
      }

      // Extract numeric value
      final numericPattern = RegExp(r'(\d+(?:\.\d+)?)');
      final numericMatch = numericPattern.firstMatch(amountStr);
      if (numericMatch != null) {
        amount = double.tryParse(numericMatch.group(1) ?? '0');
      }
    }

    // Extract merchant from text
    final merchantPattern = RegExp(r'(?:at|from|to)\s+([A-Za-z\s]+?)(?:\s|$)',
        caseSensitive: false);
    final merchantMatch = merchantPattern.firstMatch(text);
    final merchant = merchantMatch?.group(1)?.trim();

    return {
      'amount': amount ?? 0.0,
      'merchant': merchant ?? 'Unknown',
      'date': DateTime.now().toIso8601String(),
      'category': 'Auto-detected',
      'currency': currency,
      'confidence': response.confidence,
      'extractedAmount': response.extractedAmount,
    };
  }

  // Fallback expense detection using simple pattern matching
  Map<String, dynamic>? _fallbackExpenseDetection(String text) {
    try {
      RegExp amountPattern =
          RegExp(r'(?:RM|MYR|\$|USD)\s*(\d+(?:\.\d+)?)', caseSensitive: false);
      RegExp merchantPattern = RegExp(
          r'(?:at|from|to)\s+([A-Za-z\s]+?)(?:\s|$)',
          caseSensitive: false);

      final amountMatch = amountPattern.firstMatch(text);
      final merchantMatch = merchantPattern.firstMatch(text);

      // Check if this looks like a payment notification
      final paymentKeywords = [
        'paid',
        'payment',
        'transaction',
        'purchase',
        'spent',
        'debit',
        'charged'
      ];
      final hasPaymentKeyword = paymentKeywords
          .any((keyword) => text.toLowerCase().contains(keyword));

      if (amountMatch != null && hasPaymentKeyword) {
        return {
          'amount': double.tryParse(amountMatch.group(1) ?? '0') ?? 0,
          'merchant': merchantMatch?.group(1)?.trim() ?? 'Unknown',
          'date': DateTime.now().toIso8601String(),
          'category': 'Auto-detected (Fallback)',
          'currency': 'MYR', // Default currency
          'confidence': 0.6, // Lower confidence for fallback
          'extractedAmount': amountMatch.group(0),
        };
      }

      return null;
    } catch (e) {
      debugPrint('Error in fallback expense detection: $e');
      return null;
    }
  }

  // Save auto-detected expense and show UI card
  Future<void> _saveAutoDetectedExpense(
      Map<String, dynamic> expenseData, String source) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found - cannot show expense card');
        return;
      }

      // Add metadata about auto-detection
      expenseData['isAutoDetected'] = true;
      expenseData['source'] = source;
      expenseData['userId'] = user.uid;

      await _showEnhancedExpenseCard(expenseData);
    } catch (e) {
      debugPrint('Error showing enhanced expense card: $e');
    }
  }

  // Show enhanced expense card using overlay
  Future<void> _showEnhancedExpenseCard(
      Map<String, dynamic> expenseData) async {
    try {
      // Get the current context from the navigator
      final navigatorState = navigatorKey.currentState;
      final BuildContext? context =
          navigatorState?.overlay?.context ?? navigatorState?.context;

      if (context == null) {
        // Fallback: save to auto-detected collection
        await FirebaseFirestore.instance
            .collection('auto_detected_expenses')
            .add(expenseData);
        return;
      }

      // Show the enhanced expense card as overlay
      _cardManager.showExpenseCard(
        context,
        expenseData,
        onExpenseSaved: () {
          debugPrint('Expense saved successfully from notification');
        },
        onDismissed: () {
          debugPrint('Expense card dismissed by user');
        },
      );
    } catch (e) {
      debugPrint('Error showing enhanced expense card: $e');
      // Fallback: save to auto-detected collection
      await FirebaseFirestore.instance
          .collection('auto_detected_expenses')
          .add(expenseData);
    }
  }

  // Public API

  /// Get the current listening status
  bool get isListening => _isListening;

  /// Request notification permission
  Future<bool> requestNotificationPermission() =>
      NotificationPermissionHandler.requestNotificationPermission();

  /// Check if notification permission is granted
  Future<bool> checkNotificationPermission() =>
      NotificationPermissionHandler.checkNotificationPermission();

  /// Request notification access permission (opens settings)
  Future<void> requestNotificationAccessPermission() =>
      NotificationPermissionHandler.requestNotificationAccessPermission();

  /// Test API connection
  Future<bool> testApiConnection() async {
    try {
      return await _apiService.testConnection();
    } catch (e) {
      debugPrint('Error testing API connection: $e');
      return false;
    }
  }

  /// Check API health
  Future<bool> checkApiHealth() async {
    try {
      return await _apiService.checkHealth();
    } catch (e) {
      debugPrint('Error checking API health: $e');
      return false;
    }
  }

  /// Directly simulate notification processing (without sending real notification)
  Future<void> simulateNotification(String text) async {
    await _analyzeNotificationForExpense(text, 'test_simulation');
  }

  /// Send test expense notification - REAL NOTIFICATION
  Future<void> sendTestExpenseNotification() async {
    await _localNotificationService.sendTestExpenseNotification();
  }

  /// Send custom test notification with user-provided text
  Future<void> sendTestCustomNotification({
    required String title,
    required String body,
  }) async {
    await _localNotificationService.sendNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: 'custom_test_notification',
    );
  }

  /// Simulate notification processing (for testing workflow without sending notification)
  Future<void> simulateExpenseWorkflow() async {
    await simulateNotification(
        'Payment of RM 25.50 at Starbucks has been processed');
  }

  /// Request local notification permissions
  Future<bool> requestLocalNotificationPermissions() async {
    return await _localNotificationService.requestPermissions();
  }

  /// Request all notification related permissions (both sending and listening)
  Future<bool> requestAllNotificationPermissions() async {
    return await NotificationPermissionHandler
        .requestAllNotificationPermissions(_localNotificationService);
  }

  /// Check if local notifications are enabled
  Future<bool> areLocalNotificationsEnabled() async {
    return await _localNotificationService.areNotificationsEnabled();
  }

  /// Send custom payment notification
  Future<void> sendPaymentNotification({
    required double amount,
    required String merchant,
    String currency = 'RM',
  }) async {
    await _localNotificationService.sendPaymentNotification(
      amount: amount,
      merchant: merchant,
      currency: currency,
    );
  }

  /// Send reminder notification
  Future<void> sendReminderNotification(String message) async {
    await _localNotificationService.sendReminderNotification(message);
  }

  /// Clean up resources
  void dispose() {
    _notificationSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _apiService.dispose();
    _cardManager.hideCard();
    _localNotificationService.dispose();
    _isListening = false;
  }

  /// Check if notification listener permission is granted (Android only)
  Future<bool> checkNotificationListenerPermission() async {
    return await NotificationPermissionHandler
        .checkNotificationAccessPermission();
  }

  /// Test the notification listener with background service
  Future<void> testNotificationListenerWithBackground() async {
    try {
      // Check if the background service and listener are enabled
      bool isBackgroundEnabled = Platform.isAndroid
          ? FlutterBackground.isBackgroundExecutionEnabled
          : false;
      final hasListenerPermission = await checkNotificationListenerPermission();

      if (!isBackgroundEnabled || !hasListenerPermission) {
        debugPrint('Background service or notification listener not enabled');
        return;
      }

      await sendTestExpenseNotification();
    } catch (e) {
      debugPrint('Error testing notification listener with background: $e');
    }
  }
}
