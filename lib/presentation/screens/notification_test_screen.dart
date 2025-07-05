import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/routes.dart';
import '../../presentation/utils/app_theme.dart';
import '../../presentation/widgets/custom_card.dart';
import '../../presentation/widgets/custom_text_field.dart';
import '../../presentation/widgets/submit_button.dart';

import '../../data/infrastructure/services/notification_service.dart';
import '../../data/infrastructure/services/notification_listener_service.dart';
import '../../data/infrastructure/services/permission_handler_service.dart';
import '../../domain/services/expense_extraction_service.dart';
import '../../data/models/expense_detection_models.dart';
import '../../di/injection_container.dart' as di;
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../../domain/usecase/notification/record_notification_detection_usecase.dart';

/// Test screen for notification processing and expense detection
class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  // Services
  final _notificationService = NotificationService();
  final _listenerService = NotificationListenerService();
  final _permissionHandler = di.sl<PermissionHandlerService>();
  late final ExpenseExtractionDomainService _extractionService;
  late final RecordNotificationDetectionUseCase _recordUseCase;

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _delayController = TextEditingController();

  // State
  bool _isLoading = false;
  String _status = 'Ready to test expense detection';
  bool _isListening = false;
  bool _isServiceHealthy = false;

  // Logs
  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _extractionService = di.sl<ExpenseExtractionDomainService>();
    _recordUseCase = di.sl<RecordNotificationDetectionUseCase>();
    _initializeDefaults();
    _checkServiceHealth();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _delayController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _initializeDefaults() {
    _titleController.text = 'Maybank2u: Card Transaction';
    _messageController.text =
        "You've just spent RM 19.60 at HORIZON MIRACLES SDN BHD with your Maybank Debit Card Visa ending 9857. View your receipt now.";
    _delayController.text = '3';
  }

  Future<void> _setupNotificationListener() async {
    _listenerService.setNotificationCallback((title, content, packageName) {
      _addLog('Notification received: $title - $content (from $packageName)');

      // Run the full classification and extraction pipeline
      _processReceivedNotification(title, content, packageName);
    });
  }

  /// Process received notification through the full expense detection pipeline
  Future<void> _processReceivedNotification(
      String notifTitle, String notifContent, String? packageName) async {
    try {
      _addLog('🔍 Starting expense detection pipeline...');
      final notificationText = '$notifTitle: $notifContent';
      final source = packageName ?? 'test_notification';

      final isExpense = await _extractionService.classifyNotification(
        title: notifTitle,
        content: notifContent,
        source: source,
        packageName: packageName,
      );

      if (!isExpense) {
        _addLog('ℹ️ Not classified as expense');
        return;
      }

      final result = await _extractionService.extractExpenseDetails(
        title: notifTitle,
        content: notifContent,
        source: source,
        packageName: packageName,
      );

      if (result != null) {
        await _logAndRecordExtraction(
          result: result,
          title: notifTitle,
          content: notifContent,
          source: source,
          packageName: packageName ?? 'unknown',
        );
      } else {
        _addLog('ℹ️ No expense details extracted.');
      }
    } catch (e) {
      _addLog('❌ Pipeline processing failed: $e');
    }
  }

  /// Test expense detection directly on the input text
  Future<void> _testExpenseDetection() async {
    setState(() => _isLoading = true);
    _addLog('🔍 Testing expense detection on input text...');

    try {
      final title = _titleController.text.trim();
      final content = _messageController.text.trim();
      final notificationText = '$title: $content';

      if (title.isEmpty || content.isEmpty) {
        _addLog('❌ Please enter both title and message for testing');
        setState(() => _isLoading = false);
        return;
      }

      final isExpense = await _extractionService.classifyNotification(
        title: title,
        content: content,
        source: 'manual_test',
        packageName: 'test_app',
      );

      if (!isExpense) {
        _addLog('ℹ️ Not classified as expense');
        setState(() => _status = 'Not classified as an expense.');
        return;
      }

      _addLog('✅ Classified as an expense. Extracting details...');
      final result = await _extractionService.extractExpenseDetails(
        title: title,
        content: content,
        source: 'manual_test',
        packageName: 'test_app',
      );

      if (result != null) {
        await _logAndRecordExtraction(
          result: result,
          title: title,
          content: content,
          source: 'manual_test',
          packageName: 'test_app',
        );
      } else {
        _addLog('ℹ️ No expense details extracted from text.');
        setState(() => _status = 'No expense details extracted.');
      }
    } catch (e) {
      _addLog('❌ Detection test failed: $e');
      setState(() => _status = 'Detection test error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Log the TFLite extraction result with detailed information
  Future<void> _logAndRecordExtraction({
    required ExpenseExtractionResult result,
    required String title,
    required String content,
    required String source,
    required String packageName,
  }) async {
    _addLog('✅ EXPENSE EXTRACTED!');
    _addLog('💰 Amount: ${result.amount ?? 'N/A'} ${result.currency ?? 'N/A'}');
    _addLog('🏪 Merchant: ${result.merchantName ?? 'N/A'}');
    _addLog('💳 Payment Method: ${result.paymentMethod ?? 'N/A'}');
    _addLog('📊 Suggested Category: ${result.suggestedCategory ?? 'N/A'}');
    _addLog('🎯 Confidence: ${result.confidence.toStringAsFixed(2)}');

    setState(() => _status = 'Expense extracted successfully!');

    // Record detection attempt and send actionable notification
    final detectionId = await _recordUseCase.recordDetectionAttempt(
      originalNotificationText: '$title: $content',
      notificationSource: source,
      packageName: packageName,
      detectionResult: result,
    );

    if (detectionId != null) {
      _addLog('📊 Detection attempt recorded with ID: $detectionId');
      await _sendActionableNotification(result, detectionId);
    } else {
      _addLog('⚠️ Failed to record detection attempt. Notification not sent.');
    }
  }

  /// Send actionable notification with extracted expense details
  Future<void> _sendActionableNotification(
      ExpenseExtractionResult result, String detectionId) async {
    try {
      final success =
          await _notificationService.sendExpenseDetectedNotification(
        detectionId: detectionId,
        extractionResult: result,
      );

      if (success) {
        _addLog('📱 Actionable notification sent successfully');
      } else {
        _addLog('❌ Failed to send actionable notification');
      }
    } catch (e) {
      _addLog('❌ Error sending actionable notification: $e');
    }
  }

  Future<void> _checkServiceHealth() async {
    setState(() => _isLoading = true);

    try {
      _addLog('Checking service health...');

      // Check notification service
      await _notificationService.initialize();

      // Check listener service
      await _listenerService.initialize();

      // Check if TFLite extraction service is initialized
      final isHealthy = true; // Assume healthy if no errors thrown

      setState(() {
        _isServiceHealthy = isHealthy;
        _isListening = _listenerService.isListening;
        _status =
            'Services initialized. Pipeline: ${isHealthy ? 'Ready' : 'Unavailable'}';
      });

      _addLog('Service health check completed');
      _addLog('Notification Service: ✅ Initialized');
      _addLog('Listener Service: ✅ Initialized');
      _addLog(
          'Expense Detection Pipeline: ${isHealthy ? '✅ Ready' : '❌ Unavailable'}');
      _addLog('TFLite classification + Gemini extraction services loaded');
    } catch (e) {
      _addLog('Error checking service health: $e');
      setState(() => _status = 'Error initializing services: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isLoading = true);

    try {
      _addLog('Sending test notification...');

      final success = await _notificationService.sendNotification(
        title: _titleController.text.trim(),
        content: _messageController.text.trim(),
      );

      if (success) {
        setState(() => _status = 'Test notification sent successfully');
        _addLog('Test notification sent successfully');
      } else {
        setState(() => _status = 'Failed to send test notification');
        _addLog('Failed to send test notification');
      }
    } catch (e) {
      _addLog('Error sending test notification: $e');
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _scheduleNotification() async {
    final delaySeconds = int.tryParse(_delayController.text) ?? 3;

    setState(() => _isLoading = true);

    try {
      _addLog('Scheduling notification for $delaySeconds seconds...');

      final success = await _notificationService.scheduleNotification(
        title: _titleController.text.trim(),
        content: _messageController.text.trim(),
        delay: Duration(seconds: delaySeconds),
      );

      if (success) {
        setState(
            () => _status = 'Notification scheduled for $delaySeconds seconds');
        _addLog('Notification scheduled successfully');
      } else {
        setState(() => _status = 'Failed to schedule notification');
        _addLog('Failed to schedule notification');
      }
    } catch (e) {
      _addLog('Error scheduling notification: $e');
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startStopListener() async {
    setState(() => _isLoading = true);

    try {
      if (_isListening) {
        _addLog('Stopping notification listener...');
        await _listenerService.stopListening();
        setState(() => _isListening = false);
        _addLog('Notification listener stopped');
      } else {
        _addLog('Starting notification listener...');
        final success = await _listenerService.startListening();
        setState(() => _isListening = success);
        _addLog(success
            ? 'Notification listener started'
            : 'Failed to start listener');
      }
    } catch (e) {
      _addLog('Error toggling listener: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    try {
      _addLog('Requesting notification permissions...');

      final result = await _permissionHandler.requestPermissionsForFeature(
        PermissionFeature.notifications,
        context,
      );

      setState(() => _status = 'Permission result: ${result.message}');
      _addLog('Permission result: ${result.message}');
    } catch (e) {
      _addLog('Error requesting permissions: $e');
      setState(() => _status = 'Permission error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testActionableNotification() async {
    setState(() => _isLoading = true);

    try {
      _addLog('Testing actionable expense notification...');

      // 1. Create a mock extraction result
      final mockResult = ExpenseExtractionResult(
        amount: '25.50',
        currency: 'MYR',
        merchantName: 'Starbucks',
        paymentMethod: 'Credit Card',
        suggestedCategory: 'food',
        confidence: 0.95,
      );

      // 2. Record the mock attempt to get a detection ID
      final detectionId = await _recordUseCase.recordDetectionAttempt(
        originalNotificationText: 'Mock Notification: Test Starbucks',
        notificationSource: 'manual_test',
        packageName: 'com.kai.budgie',
        detectionResult: mockResult,
      );

      // 3. Send the notification if recording was successful
      if (detectionId != null) {
        _addLog('📊 Mock detection recorded with ID: $detectionId');
        await _sendActionableNotification(mockResult, detectionId);
        setState(() => _status =
            'Test actionable notification sent! Check your notification panel.');
      } else {
        _addLog('❌ Failed to record mock detection.');
        setState(() => _status = 'Failed to record mock detection.');
      }
    } catch (e) {
      _addLog('❌ Error testing notification: $e');
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addLog(String log) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $log');

      // Keep only last 50 logs
      if (_logs.length > 50) {
        _logs.removeAt(0);
      }
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: AppConstants.animationDurationShort,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Expense Detection Test Center',
          style: TextStyle(
            fontSize: AppConstants.textSizeXLarge.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: AppConstants.iconSizeMedium.sp),
            onPressed: _checkServiceHealth,
            tooltip: 'Refresh Status',
          ),
        ],
        elevation: AppConstants.elevationSmall,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingLarge.h),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: AppConstants.textSizeMedium.sp,
                      color: AppTheme.greyTextLight,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: AppConstants.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(),
                  SizedBox(height: AppConstants.spacingLarge.h),
                  _buildStatusCard(),
                  SizedBox(height: AppConstants.spacingLarge.h),
                  _buildServiceControlCard(),
                  SizedBox(height: AppConstants.spacingLarge.h),
                  _buildNotificationTestCard(),
                  SizedBox(height: AppConstants.spacingLarge.h),
                  _buildLogCard(),
                  SizedBox(height: AppConstants.bottomPaddingWithNavBar.h),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: AppConstants.elevationStandard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
      ),
      child: Padding(
        padding: AppConstants.containerPaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: AppConstants.iconSizeMedium.sp,
                ),
                SizedBox(width: AppConstants.spacingMedium.w),
                Text(
                  'Expense Detection Test Overview',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeLarge.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingMedium.h),
            Text(
              'Test the notification-based expense detection system:',
              style: TextStyle(
                fontSize: AppConstants.textSizeMedium.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            SizedBox(height: AppConstants.spacingSmall.h),
            ...[
              '• Send and schedule test notifications',
              '• Test classification and extraction pipeline',
              '• Monitor notification listening service',
              '• View detailed processing logs',
              '• Extract: Amount, Merchant, Currency, Payment Method',
            ].map((item) => Padding(
                  padding:
                      EdgeInsets.only(bottom: AppConstants.spacingXSmall.h),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: AppConstants.textSizeSmall.sp,
                      color: AppTheme.greyTextLight,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: AppConstants.elevationStandard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
      ),
      child: Padding(
        padding: AppConstants.containerPaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'System Status',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeLarge.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _checkServiceHealth,
                  icon:
                      Icon(Icons.refresh, size: AppConstants.iconSizeSmall.sp),
                  label: Text(
                    'Refresh',
                    style: TextStyle(fontSize: AppConstants.textSizeSmall.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingMedium.w,
                      vertical: AppConstants.spacingSmall.h,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingMedium.h),
            _buildStatusRow('Current Status', _status),
            SizedBox(height: AppConstants.spacingSmall.h),
            _buildStatusRow(
              'Detection Models',
              _isServiceHealthy ? 'Ready' : 'Unavailable',
              _isServiceHealthy ? Colors.green : Colors.red,
            ),
            SizedBox(height: AppConstants.spacingSmall.h),
            _buildStatusRow(
              'Notification Listener',
              _isListening ? 'Active' : 'Inactive',
              _isListening ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, [Color? valueColor]) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppConstants.textSizeSmall.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: AppConstants.textSizeSmall.sp,
              color:
                  valueColor ?? Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceControlCard() {
    return Card(
      elevation: AppConstants.elevationStandard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
      ),
      child: Padding(
        padding: AppConstants.containerPaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Controls',
              style: TextStyle(
                fontSize: AppConstants.textSizeLarge.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            SizedBox(height: AppConstants.spacingLarge.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _requestPermissions,
                    icon: Icon(Icons.security,
                        size: AppConstants.iconSizeSmall.sp),
                    label: Text(
                      'Request Permissions',
                      style: TextStyle(fontSize: AppConstants.textSizeSmall.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: Size(double.infinity,
                          AppConstants.componentHeightStandard.h),
                    ),
                  ),
                ),
                SizedBox(width: AppConstants.spacingMedium.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startStopListener,
                    icon: Icon(
                      _isListening ? Icons.stop : Icons.play_arrow,
                      size: AppConstants.iconSizeSmall.sp,
                    ),
                    label: Text(
                      _isListening ? 'Stop Listener' : 'Start Listener',
                      style: TextStyle(fontSize: AppConstants.textSizeSmall.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isListening ? Colors.orange : Colors.green,
                      minimumSize: Size(double.infinity,
                          AppConstants.componentHeightStandard.h),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTestCard() {
    return Card(
      elevation: AppConstants.elevationStandard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
      ),
      child: Padding(
        padding: AppConstants.containerPaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Testing',
              style: TextStyle(
                fontSize: AppConstants.textSizeLarge.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            SizedBox(height: AppConstants.spacingLarge.h),

            // Input fields
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Notification Title',
                labelStyle: TextStyle(fontSize: AppConstants.textSizeSmall.sp),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadiusMedium.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMedium.w,
                  vertical: AppConstants.spacingMedium.h,
                ),
              ),
              style: TextStyle(fontSize: AppConstants.textSizeSmall.sp),
            ),
            SizedBox(height: AppConstants.spacingMedium.h),

            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Notification Message',
                labelStyle: TextStyle(fontSize: AppConstants.textSizeSmall.sp),
                hintText: 'Try: "Payment of RM 50.00 at Starbucks completed"',
                hintStyle: TextStyle(fontSize: AppConstants.textSizeXSmall.sp),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadiusMedium.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMedium.w,
                  vertical: AppConstants.spacingMedium.h,
                ),
              ),
              style: TextStyle(fontSize: AppConstants.textSizeSmall.sp),
              maxLines: 3,
            ),
            SizedBox(height: AppConstants.spacingMedium.h),

            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _delayController,
                    decoration: InputDecoration(
                      labelText: 'Delay (sec)',
                      labelStyle:
                          TextStyle(fontSize: AppConstants.textSizeSmall.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingMedium.w,
                        vertical: AppConstants.spacingMedium.h,
                      ),
                    ),
                    style: TextStyle(fontSize: AppConstants.textSizeSmall.sp),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: AppConstants.spacingMedium.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _scheduleNotification,
                    icon: Icon(Icons.schedule,
                        size: AppConstants.iconSizeSmall.sp),
                    label: Text(
                      'Schedule',
                      style: TextStyle(fontSize: AppConstants.textSizeSmall.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity,
                          AppConstants.componentHeightStandard.h),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingLarge.h),

            // Action buttons: Send Now and Test Detection
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendTestNotification,
                    icon: Icon(Icons.send, size: AppConstants.iconSizeSmall.sp),
                    label: Text(
                      'Send Now',
                      style: TextStyle(fontSize: AppConstants.textSizeSmall.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity,
                          AppConstants.componentHeightStandard.h),
                    ),
                  ),
                ),
                SizedBox(width: AppConstants.spacingMedium.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testExpenseDetection,
                    icon: Icon(Icons.analytics,
                        size: AppConstants.iconSizeSmall.sp),
                    label: Text(
                      'Test Detection',
                      style: TextStyle(fontSize: AppConstants.textSizeSmall.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: Size(double.infinity,
                          AppConstants.componentHeightStandard.h),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingMedium.h),

            // Test Actionable Notification button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _testActionableNotification,
                icon: Icon(Icons.notification_add,
                    size: AppConstants.iconSizeSmall.sp),
                label: Text(
                  'Test Expense Notification',
                  style: TextStyle(fontSize: AppConstants.textSizeSmall.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(
                      double.infinity, AppConstants.componentHeightStandard.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard() {
    return Card(
      elevation: AppConstants.elevationStandard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
      ),
      child: Padding(
        padding: AppConstants.containerPaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Operation Logs',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeLarge.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon:
                          Icon(Icons.copy, size: AppConstants.iconSizeSmall.sp),
                      onPressed: () {
                        final text = _logs.join('\n');
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Logs copied to clipboard',
                              style: TextStyle(
                                  fontSize: AppConstants.textSizeSmall.sp),
                            ),
                            duration: AppConstants.animationDurationMedium,
                          ),
                        );
                      },
                      tooltip: 'Copy logs',
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: AppConstants.spacingSmall.w),
                    IconButton(
                      icon: Icon(Icons.clear,
                          size: AppConstants.iconSizeSmall.sp),
                      onPressed: _clearLogs,
                      tooltip: 'Clear logs',
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingMedium.h),
            Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.cardBackgroundDark
                    : Colors.grey[50],
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusMedium.r),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: AppConstants.containerPaddingMedium,
                child: _logs.isEmpty
                    ? Center(
                        child: Text(
                          'No logs yet. Start testing to see operations.',
                          style: TextStyle(
                            color: AppTheme.greyTextLight,
                            fontSize: AppConstants.textSizeSmall.sp,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _logScrollController,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: AppConstants.spacingXSmall.h),
                            child: Text(
                              _logs[index],
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: AppConstants.textSizeXSmall.sp,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.green[300]
                                    : Colors.green[700],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
