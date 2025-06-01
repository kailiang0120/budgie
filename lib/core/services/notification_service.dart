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

  // API service for expense detection
  final NotificationDetectionApiService _apiService =
      NotificationDetectionApiService();

  // Expense card manager for showing overlays
  final ExpenseCardManager _cardManager = ExpenseCardManager();

  // Local notification service for sending notifications
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();

  // Initialize the service
  Future<void> init() async {
    debugPrint('Notification service initialized');

    // Initialize local notification service
    await _localNotificationService.initialize();

    // Check API health on initialization
    final apiHealthy = await _apiService.checkHealth();
    if (apiHealthy) {
      debugPrint('Notification detection API is healthy');
    } else {
      debugPrint('Warning: Notification detection API is not available');
    }

    // Setup background processing
    await _setupBackgroundProcessing();

    // Initialize notifications package listener
    _initNotificationsPackage();

    await _checkAndStartListener();
  }

  // Initialize the notifications package listener
  Future<void> _initNotificationsPackage() async {
    try {
      // Request notification access permission for the package
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        if (status.isGranted) {
          _startNotificationsPackageListener();
        } else {
          debugPrint(
              'Notification permission denied for notifications package');
        }
      } else {
        _startNotificationsPackageListener();
      }
    } catch (e) {
      debugPrint('Error initializing notifications package: $e');
    }
  }

  // Start the notifications package listener
  void _startNotificationsPackageListener() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription =
        _notifications.notificationStream!.listen(_onNotificationReceived);
    debugPrint('Notifications package listener started');
  }

  // Stop the notifications package listener
  void _stopNotificationsPackageListener() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
    debugPrint('Notifications package listener stopped');
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

      debugPrint(
          'Notification received via package: $title - $text from $packageName');

      // Skip empty notifications
      if (title.isEmpty && text.isEmpty) {
        debugPrint('Empty notification from package, ignoring');
        return;
      }

      // Process using our existing analysis pipeline
      final fullText = '$title $text'.trim();
      await _analyzeNotificationForExpense(fullText, packageName);
    } catch (e) {
      debugPrint('Error processing notification from package: $e');
    }
  }

  // Setup background processing to handle notifications
  Future<void> _setupBackgroundProcessing() async {
    if (Platform.isAndroid) {
      try {
        // Configure the background service to process notifications even when app is in background
        const androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: "Budgie Expense Detector",
          notificationText: "Monitoring notifications for expenses",
          notificationImportance: AndroidNotificationImportance.normal,
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
            defType: 'mipmap',
          ),
        );

        // WORKAROUND: Initialize twice to handle real device issues
        // First initialization triggers permission dialog but may return false
        bool hasPermissions = await FlutterBackground.initialize(
          androidConfig: androidConfig,
        );

        debugPrint('First background initialization result: $hasPermissions');

        // Check if we have permission but initialization still failed
        if (!hasPermissions && await FlutterBackground.hasPermissions) {
          // Second initialization should succeed now that permissions are granted
          hasPermissions = await FlutterBackground.initialize(
            androidConfig: androidConfig,
          );
          debugPrint(
              'Second background initialization result: $hasPermissions');
        }

        if (hasPermissions) {
          debugPrint('Background service initialized successfully');

          // Register method channel handler for background processing
          platform.setMethodCallHandler(_handleNotificationData);
          debugPrint('Notification listener method channel handler registered');

          // Try to enable background execution with retries
          await _tryEnableBackgroundExecution();
        } else {
          debugPrint('Failed to initialize background service');
        }
      } catch (e) {
        debugPrint('Error setting up background processing: $e');
      }
    }
  }

  // Try to enable background execution with retries
  Future<bool> _tryEnableBackgroundExecution() async {
    int retries = 0;
    const maxRetries = 3;

    while (retries < maxRetries) {
      try {
        final result = await FlutterBackground.enableBackgroundExecution();
        if (result) {
          debugPrint('Background execution enabled successfully!');
          return true;
        } else {
          debugPrint(
              'Failed to enable background execution, attempt ${retries + 1}/$maxRetries');
        }
      } catch (e) {
        debugPrint('Error enabling background execution: $e');
      }

      // Wait before retrying
      await Future.delayed(const Duration(milliseconds: 500));
      retries++;
    }

    debugPrint('All attempts to enable background execution failed');
    return false;
  }

  // Check user settings and start listener if enabled
  Future<void> _checkAndStartListener() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Use SettingsService instead of direct Firebase access
      final settingsService = SettingsService.instance;
      if (settingsService != null) {
        final allowNotification = settingsService.allowNotification;

        if (allowNotification) {
          final hasPermission = await checkNotificationPermission();
          if (hasPermission) {
            await startNotificationListener();
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking notification settings: $e');
    }
  }

  // Request notification permission using permission_handler
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    }

    // Request notification permission
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  // Check if notification permission is granted
  Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Start the notification listener
  Future<void> startNotificationListener() async {
    if (_isListening) {
      debugPrint('Notification listener already running, skipping start');
      return;
    }

    try {
      // For Android, we need to check notification access permission
      if (Platform.isAndroid) {
        final hasAccess = await _checkNotificationAccessPermission();
        if (!hasAccess) {
          debugPrint('Notification access permission not granted');
          return;
        }

        // First ensure background service is initialized properly
        const androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: "Budgie Expense Detector",
          notificationText: "Monitoring notifications for expenses",
          notificationImportance: AndroidNotificationImportance.normal,
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
            defType: 'mipmap',
          ),
        );

        // Double initialization to handle real device issues
        bool initialized =
            await FlutterBackground.initialize(androidConfig: androidConfig);
        if (!initialized && await FlutterBackground.hasPermissions) {
          // Try second initialization
          initialized =
              await FlutterBackground.initialize(androidConfig: androidConfig);
          debugPrint(
              'Re-initialization in startNotificationListener: $initialized');
        }

        if (!initialized) {
          debugPrint(
              'Failed to initialize background service in startNotificationListener');
          return;
        }

        // Enable background execution for continuous notification monitoring
        int attempts = 0;
        bool backgroundSuccess = false;

        while (!backgroundSuccess && attempts < 3) {
          backgroundSuccess =
              await FlutterBackground.enableBackgroundExecution();
          if (!backgroundSuccess) {
            debugPrint('Retrying background execution (${attempts + 1}/3)');
            await Future.delayed(const Duration(milliseconds: 500));
            attempts++;
          }
        }

        if (!backgroundSuccess) {
          debugPrint('Failed to enable background execution');
          // Continue anyway as we might still be able to listen while in foreground
        } else {
          debugPrint('Background execution enabled successfully');
        }

        // Disable background execution if it was enabled
        if (Platform.isAndroid) {
          if (await FlutterBackground.isBackgroundExecutionEnabled) {
            await FlutterBackground.disableBackgroundExecution();
            debugPrint('Background execution disabled');
          }
        }
      }

      // Set up method channel listener for notifications
      platform.setMethodCallHandler(_handleNotificationData);

      // Set the listening flag BEFORE invoking the method to avoid race conditions
      _isListening = true;

      // Start listening for notifications
      try {
        await platform.invokeMethod('startListening');
        debugPrint(
            'Notification listener started successfully via platform channel');
      } catch (e) {
        debugPrint(
            'Error starting notification listener via platform channel: $e');
        _isListening = false; // Reset flag on failure
        rethrow;
      }

      // Log success
      debugPrint('Notification listener started and is active: $_isListening');

      // Make sure the notifications package listener is also active
      _startNotificationsPackageListener();
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

      // Disable background execution if it was enabled
      if (Platform.isAndroid) {
        if (await FlutterBackground.isBackgroundExecutionEnabled) {
          await FlutterBackground.disableBackgroundExecution();
          debugPrint('Background execution disabled');
        }
      }

      // Stop notifications package listener
      _stopNotificationsPackageListener();

      debugPrint('Notification listener stopped');
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

      debugPrint('Received notification: $title - $content from $packageName');

      // Process the notification in the background
      await _processNotificationInBackground(title, content, packageName);
    }
  }

  // Process notification in background
  Future<void> _processNotificationInBackground(
      String title, String content, String packageName) async {
    try {
      // Combine title and content for analysis
      final fullText = '$title $content'.trim();

      if (fullText.isEmpty) {
        debugPrint('Empty notification text, skipping processing');
        return;
      }

      // Check if this is a notification from our own app (to capture the test notifications)
      if (packageName == 'com.kai.budgie' || packageName.contains('budgie')) {
        debugPrint(
            'Detected notification from our app - processing for expense detection');
      }

      // Analyze the notification for expense information
      await _analyzeNotificationForExpense(fullText, packageName);

      debugPrint('Notification processing completed in background');
    } catch (e) {
      debugPrint('Error processing notification in background: $e');
    }
  }

  // Analyze notification text using API to determine if it's an expense
  Future<void> _analyzeNotificationForExpense(
      String notificationText, String packageName) async {
    try {
      // Call your API service to classify the notification
      final expenseData = await _callExpenseClassificationAPI(notificationText);

      if (expenseData != null && expenseData['amount'] != null) {
        // This is an expense notification
        debugPrint(
            'Expense detected: ${expenseData['amount']} from ${expenseData['merchant'] ?? 'Unknown'}');

        // Show enhanced expense card
        await _saveAutoDetectedExpense(expenseData, packageName);
      } else {
        debugPrint('Not an expense notification');
      }
    } catch (e) {
      debugPrint('Error analyzing notification: $e');
    }
  }

  // Call the API service for expense classification
  Future<Map<String, dynamic>?> _callExpenseClassificationAPI(
      String text) async {
    try {
      // Call the actual API service
      final response = await _apiService.classifyNotification(text);

      debugPrint(
          'API Response - Is Expense: ${response.isExpense}, Confidence: ${response.confidence}');

      // Check if it's classified as an expense with sufficient confidence
      if (response.isExpense && response.confidence >= 0.5) {
        // Parse the extracted amount to get numeric value and currency
        double? amount;
        String currency = 'MYR'; // Default currency

        if (response.extractedAmount != null) {
          // Try to extract amount and currency from the response
          final amountStr = response.extractedAmount!;

          // Look for currency symbols/codes
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

        // Extract merchant from original text as fallback
        final merchantPattern = RegExp(
            r'(?:at|from|to)\s+([A-Za-z\s]+?)(?:\s|$)',
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

      return null; // Not classified as an expense or low confidence
    } on api_models.ApiException catch (e) {
      debugPrint('API error calling expense classification: $e');
      return _fallbackExpenseDetection(text);
    } catch (e) {
      debugPrint('Error calling expense classification API: $e');
      return _fallbackExpenseDetection(text);
    }
  }

  // Fallback expense detection using simple pattern matching
  Map<String, dynamic>? _fallbackExpenseDetection(String text) {
    try {
      debugPrint('Using fallback expense detection');

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

      return null; // Not an expense
    } catch (e) {
      debugPrint('Error in fallback expense detection: $e');
      return null;
    }
  }

  // Show enhanced notification expense card for user interaction
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

      debugPrint(
          'Showing enhanced expense card for user ${user.uid}: ${expenseData['amount']}');
      debugPrint('Expense data: $expenseData');

      // Show the enhanced notification card instead of auto-saving
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
        debugPrint(
            '[NotificationService] No valid context available to show expense card. Navigator state: $navigatorState');
        // Fallback: save to auto-detected collection
        await FirebaseFirestore.instance
            .collection('auto_detected_expenses')
            .add(expenseData);
        return;
      }

      debugPrint(
          'Showing enhanced expense card overlay for: ${expenseData['amount']}');

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

  // Check notification access permission (Android specific)
  Future<bool> _checkNotificationAccessPermission() async {
    try {
      final result = await platform.invokeMethod('checkNotificationAccess');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('Error checking notification access: $e');
      return false;
    }
  }

  // Request notification access permission (opens settings)
  Future<void> requestNotificationAccessPermission() async {
    try {
      await platform.invokeMethod('requestNotificationAccess');
    } catch (e) {
      debugPrint('Error requesting notification access: $e');
    }
  }

  // Get the current listening status
  bool get isListening => _isListening;

  // Test API connection
  Future<bool> testApiConnection() async {
    try {
      return await _apiService.testConnection();
    } catch (e) {
      debugPrint('Error testing API connection: $e');
      return false;
    }
  }

  // Check API health
  Future<bool> checkApiHealth() async {
    try {
      return await _apiService.checkHealth();
    } catch (e) {
      debugPrint('Error checking API health: $e');
      return false;
    }
  }

  // Directly simulate notification processing (without sending real notification)
  Future<void> simulateNotification(String text) async {
    debugPrint('Simulating notification processing with text: $text');

    // Directly trigger the notification analysis workflow
    await _analyzeNotificationForExpense(text, 'test_simulation');

    debugPrint('Notification simulation completed');
  }

  // Send test expense notification - REAL NOTIFICATION
  Future<void> sendTestExpenseNotification() async {
    debugPrint('Sending real expense notification...');
    await _localNotificationService.sendTestExpenseNotification();
  }

  // Send test non-expense notification - REAL NOTIFICATION
  Future<void> sendTestNonExpenseNotification() async {
    debugPrint('Sending real non-expense notification...');
    await _localNotificationService.sendTestNonExpenseNotification();
  }

  // Send custom test notification with user-provided text
  Future<void> sendTestCustomNotification({
    required String title,
    required String body,
  }) async {
    debugPrint('Sending custom test notification: $title - $body');
    await _localNotificationService.sendNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: 'custom_test_notification',
    );
  }

  // Simulate notification processing (for testing workflow without sending notification)
  Future<void> simulateExpenseWorkflow() async {
    debugPrint('Simulating expense notification workflow...');
    await simulateNotification(
        'Payment of RM 25.50 at Starbucks has been processed');
  }

  // Simulate non-expense workflow (for testing workflow without sending notification)
  Future<void> simulateNonExpenseWorkflow() async {
    debugPrint('Simulating non-expense notification workflow...');
    await simulateNotification('How are you recently?');
  }

  // Request local notification permissions
  Future<bool> requestLocalNotificationPermissions() async {
    return await _localNotificationService.requestPermissions();
  }

  // Request all notification related permissions (both sending and listening)
  Future<bool> requestAllNotificationPermissions() async {
    // Request local notification permissions first (for sending notifications)
    final localPermission =
        await _localNotificationService.requestPermissions();

    if (!localPermission) {
      debugPrint('Local notification permission denied');
      return false;
    }

    // For Android, we need special notification listener permission
    if (Platform.isAndroid) {
      final hasListenerAccess = await _checkNotificationAccessPermission();
      if (!hasListenerAccess) {
        debugPrint(
            'Notification listener permission not granted. Opening settings...');
        // Open system settings directly - we can't programmatically grant this permission
        await requestNotificationAccessPermission();

        // Don't check again immediately as the user needs time to grant permission
        // Return true to allow the app to continue, the user will need to manually grant permission
        debugPrint(
            'Notification access settings opened. User must manually grant permission.');
        return true;
      }
    }

    return true;
  }

  // Check if local notifications are enabled
  Future<bool> areLocalNotificationsEnabled() async {
    return await _localNotificationService.areNotificationsEnabled();
  }

  // Send custom payment notification
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

  // Send reminder notification
  Future<void> sendReminderNotification(String message) async {
    await _localNotificationService.sendReminderNotification(message);
  }

  // Clean up resources
  void dispose() {
    _notificationSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _apiService.dispose();
    _cardManager.hideCard(); // Hide any visible cards
    _localNotificationService.dispose();
    _isListening = false;
  }

  // Check if notification listener permission is granted (Android only)
  Future<bool> checkNotificationListenerPermission() async {
    if (!Platform.isAndroid) return true;
    return await _checkNotificationAccessPermission();
  }

  // Test the notification listener with background service
  Future<void> testNotificationListenerWithBackground() async {
    try {
      // First check if the background service is enabled
      bool isBackgroundEnabled = false;
      if (Platform.isAndroid) {
        isBackgroundEnabled =
            await FlutterBackground.isBackgroundExecutionEnabled;
      }

      // Check if notification listener is enabled
      final hasListenerPermission = await checkNotificationListenerPermission();

      debugPrint('Background service enabled: $isBackgroundEnabled');
      debugPrint('Notification listener permission: $hasListenerPermission');

      if (!isBackgroundEnabled || !hasListenerPermission) {
        debugPrint('Background service or notification listener not enabled');
        return;
      }

      // Send a test notification to verify the system is working
      await sendTestExpenseNotification();

      debugPrint(
          'Test notification sent, check if it was processed by the notification listener');
    } catch (e) {
      debugPrint('Error testing notification listener with background: $e');
    }
  }
}
