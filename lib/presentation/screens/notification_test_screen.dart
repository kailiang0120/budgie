import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';

import '../../data/infrastructure/services/notification_service.dart';
import '../../data/infrastructure/services/notification_listener_service.dart';
import '../../data/infrastructure/services/permission_handler_service.dart';
import '../../data/infrastructure/services/settings_service.dart';
import '../../domain/services/expense_extraction_service.dart';
import '../../data/models/expense_detection_models.dart';
import '../../di/injection_container.dart' as di;
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

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

  // State
  bool _isLoading = false;
  String _status = 'Ready to test expense detection';
  bool _isListening = false;
  bool _isServiceHealthy = false;

  // Enhanced state tracking
  bool _isInitialized = false;
  bool _hasBasicPermission = false;
  bool _hasListenerPermission = false;
  bool _isServiceEnabled = false;
  String _listenerState = 'Unknown';

  // Settings state
  bool _notificationSettingEnabled = false;

  // Logs
  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    try {
      _extractionService = di.sl<ExpenseExtractionDomainService>();
    } catch (e) {
      debugPrint('❌ NotificationTestScreen: Failed to initialize services: $e');
      _addLog('❌ Service initialization failed: $e');
    }
    _checkServiceHealth();
    _setupNotificationListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh state when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshListenerState();
      }
    });
  }

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  Future<void> _setupNotificationListener() async {
    _listenerService.setNotificationCallback((title, content, packageName) {
      _addLog(
          '🔔 Notification received: $title - $content (from $packageName)');

      // Run the full classification and extraction pipeline
      _processReceivedNotification(title, content, packageName);
    });
  }

  /// Process received notification through the full expense detection pipeline
  Future<void> _processReceivedNotification(
      String notifTitle, String notifContent, String? packageName) async {
    try {
      _addLog('🔍 Starting expense detection pipeline...');
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

    // Generate detection ID and send actionable notification
    final detectionId = DateTime.now().millisecondsSinceEpoch.toString();
    _addLog('📊 Generated detection ID: $detectionId');
    await _sendActionableNotification(result, detectionId);
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
      _addLog('🔍 Checking service health...');

      // Check notification setting from SettingsService
      try {
        final settingsService = di.sl<SettingsService>();
        _notificationSettingEnabled = settingsService.allowNotification;
        _addLog(
            '⚙️ Notification Setting: ${_notificationSettingEnabled ? '✅ Enabled' : '❌ Disabled'}');
      } catch (e) {
        _addLog('❌ Error checking notification setting: $e');
        _notificationSettingEnabled = false;
      }

      // Check if extraction service is available
      bool extractionServiceHealthy = false;
      try {
        await _extractionService.initialize();
        extractionServiceHealthy = _extractionService.isInitialized;
        _addLog(
            '🤖 ExpenseExtractionDomainService: ${extractionServiceHealthy ? '✅ Ready' : '❌ Failed'}');
      } catch (e) {
        _addLog('❌ ExpenseExtractionDomainService initialization failed: $e');
      }

      // Check notification service
      try {
        await _notificationService.initialize();
        _addLog('📱 Notification Service: ✅ Initialized');
      } catch (e) {
        _addLog('❌ Notification Service failed: $e');
      }

      // Check listener service status (SettingsService handles the rest)
      try {
        await _listenerService.initialize();
        _addLog('🔔 Listener Service: ✅ Initialized');

        // Get detailed health status
        final healthStatus = await _listenerService.getHealthStatus();
        _addLog('📊 Listener Health Status: $healthStatus');

        // Update state from the reliable health status map
        _isInitialized = healthStatus['isInitialized'] ?? false;
        _isListening = healthStatus['isActuallyListening'] ?? false;
        _hasBasicPermission = healthStatus['hasBasicPermission'] ?? false;
        _hasListenerPermission = healthStatus['hasListenerPermission'] ?? false;
        _isServiceEnabled = healthStatus['isServiceEnabled'] ?? false;

        // Determine listener state based on the new, reliable data
        _determineListenerState();

        setState(() {
          _isServiceHealthy = extractionServiceHealthy;
          _status = _getDetailedStatusMessage();
        });

        _addLog('✅ Service health check completed');
        _addLog('📋 Final Status: $_status');
      } catch (e) {
        _addLog('❌ Listener Service failed: $e');
      }

      setState(() {
        _isServiceHealthy = extractionServiceHealthy;
        _isListening = _listenerService.isListening;
        _isInitialized = _listenerService.isInitialized;
        _status = _getDetailedStatusMessage();
      });

      _addLog('✅ Service health check completed');
      _addLog('📋 Final Status: $_status');
    } catch (e) {
      _addLog('❌ Error checking service health: $e');
      setState(() => _status = 'Error initializing services: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Check if notification service is enabled at system level
  Future<bool> _checkNotificationServiceEnabled() async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('com.kai.budgie/notification_listener');
        final result =
            await platform.invokeMethod<bool>('isNotificationServiceEnabled');
        return result ?? false;
      }
      return true; // Non-Android platforms don't need this
    } catch (e) {
      _addLog('❌ Error checking notification service enabled: $e');
      return false;
    }
  }

  /// Determine the current listener state based on all checks
  void _determineListenerState() {
    // Update the listening state from the service to ensure accuracy
    _isListening = _listenerService.isListening;

    if (!_isInitialized) {
      _listenerState = 'Not Initialized';
    } else if (!_hasBasicPermission) {
      _listenerState = 'No Basic Permission';
    } else if (!_hasListenerPermission) {
      _listenerState = 'No Listener Permission';
    } else if (!_isServiceEnabled) {
      _listenerState = 'Service Not Enabled';
    } else if (!_isListening) {
      _listenerState = 'Not Listening';
    } else {
      _listenerState = 'Active & Listening';
    }

    _addLog('🎯 Listener State: $_listenerState');
    _addLog(
        '📊 Detailed State - Initialized: $_isInitialized, Listening: $_isListening, Basic: $_hasBasicPermission, Listener: $_hasListenerPermission, Service: $_isServiceEnabled');
  }

  /// Get detailed status message
  String _getDetailedStatusMessage() {
    if (!_notificationSettingEnabled) {
      return 'Notification setting is disabled - enable in Settings screen';
    }

    if (!_isServiceHealthy) {
      return 'Pipeline unavailable - check service initialization';
    }

    if (!_hasBasicPermission) {
      return 'Basic notification permission required';
    }

    if (!_hasListenerPermission) {
      return 'Notification listener permission required';
    }

    if (!_isServiceEnabled) {
      return 'Notification service not enabled in system settings';
    }

    if (!_isListening) {
      return 'Listener not started - use Start Listener button';
    }

    return 'All systems ready - listening for notifications';
  }

  Future<void> _startStopListener() async {
    // Check if notification setting is enabled
    if (!_notificationSettingEnabled) {
      _addLog('❌ Cannot start listener - notification setting is disabled');
      _addLog('💡 Please enable notification setting in Settings screen first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Always initialize the listener service before starting
      await _listenerService.initialize();
      if (_isListening) {
        _addLog('🛑 Stopping notification listener...');
        await _listenerService.stopListening();
        setState(() => _isListening = false);
        _addLog('✅ Notification listener stopped');
      } else {
        _addLog('▶️ Starting notification listener...');

        // Check permissions before starting
        if (!_hasBasicPermission || !_hasListenerPermission) {
          _addLog('⚠️ Insufficient permissions - requesting permissions first');
          await _requestPermissions();
          // Re-check permissions after request
          await _checkServiceHealth();
        }

        final success = await _listenerService.startListening();
        setState(() => _isListening = success);

        if (success) {
          _addLog('✅ Notification listener started successfully');
          _addLog('🔔 Now listening for notifications in background');
        } else {
          _addLog(
              '❌ Failed to start listener - check permissions and service status');
        }
      }

      // Update state after operation
      _determineListenerState();
    } catch (e) {
      _addLog('❌ Error toggling listener: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Force refresh the listener state specifically
  Future<void> _refreshListenerState() async {
    setState(() => _isLoading = true);

    try {
      _addLog('🔄 Force refreshing listener state...');

      // Re-check all listener-related states
      _hasBasicPermission =
          await _permissionHandler.hasNotificationPermission();
      _hasListenerPermission =
          await _permissionHandler.hasNotificationListenerPermission();
      _isServiceEnabled = await _checkNotificationServiceEnabled();

      // Force update the listening state from the service
      _isListening = _listenerService.isListening;
      _isInitialized = _listenerService.isInitialized;

      // Determine the current state
      _determineListenerState();

      setState(() {
        _status = _getDetailedStatusMessage();
      });

      _addLog('✅ Listener state refresh completed');
    } catch (e) {
      _addLog('❌ Error refreshing listener state: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    try {
      _addLog('🔐 Requesting comprehensive notification permissions...');

      final result = await _permissionHandler.requestPermissionsForFeature(
        PermissionFeature.notifications,
        context,
      );

      setState(() => _status = 'Permission result: ${result.message}');
      _addLog('📋 Permission result: ${result.message}');

      if (result.isGranted) {
        _addLog('✅ All notification permissions granted');
        _addLog('🔄 Re-checking service status...');
        await _checkServiceHealth();
      } else {
        _addLog('❌ Some permissions were denied');
        _addLog(
            '💡 You may need to manually enable notification access in system settings');
      }
    } catch (e) {
      _addLog('❌ Error requesting permissions: $e');
      setState(() => _status = 'Permission error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addLog(String log) {
    if (!mounted) return; // Prevent setState after dispose

    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $log');

      // Keep only last 50 logs
      if (_logs.length > 50) {
        _logs.removeAt(0);
      }
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _logScrollController.hasClients) {
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
          'Expense Detection Test',
          style: TextStyle(
            fontSize: AppConstants.textSizeXLarge.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleMedium?.color,
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
                  _buildDetailedStatusCard(),
                  SizedBox(height: AppConstants.spacingLarge.h),
                  _buildServiceControlCard(),
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

  Widget _buildDetailedStatusCard() {
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
                  'Detailed System Status',
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
              'Notification Setting',
              _notificationSettingEnabled ? 'Enabled' : 'Disabled',
              _notificationSettingEnabled ? Colors.green : Colors.red,
            ),
            SizedBox(height: AppConstants.spacingSmall.h),
            _buildStatusRow(
              'Detection Models',
              _isServiceHealthy ? 'Ready' : 'Unavailable',
              _isServiceHealthy ? Colors.green : Colors.red,
            ),
            SizedBox(height: AppConstants.spacingSmall.h),
            _buildStatusRow(
              'Service Initialized',
              _isInitialized ? 'Yes' : 'No',
              _isInitialized ? Colors.green : Colors.orange,
            ),
            SizedBox(height: AppConstants.spacingSmall.h),
            _buildStatusRow(
              'Basic Permission',
              _hasBasicPermission ? 'Granted' : 'Denied',
              _hasBasicPermission ? Colors.green : Colors.red,
            ),
            SizedBox(height: AppConstants.spacingSmall.h),
            _buildStatusRow(
              'Listener Permission',
              _hasListenerPermission ? 'Granted' : 'Denied',
              _hasListenerPermission ? Colors.green : Colors.red,
            ),
            SizedBox(height: AppConstants.spacingSmall.h),
            _buildStatusRow(
              'Service Enabled',
              _isServiceEnabled ? 'Yes' : 'No',
              _isServiceEnabled ? Colors.green : Colors.red,
            ),
            SizedBox(height: AppConstants.spacingSmall.h),
            _buildStatusRow(
              'Listener State',
              _listenerState,
              _getListenerStateColor(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getListenerStateColor() {
    switch (_listenerState) {
      case 'Active & Listening':
        return Colors.green;
      case 'Not Listening':
        return Colors.orange;
      case 'Service Not Enabled':
        return Colors.red;
      case 'No Listener Permission':
        return Colors.red;
      case 'No Basic Permission':
        return Colors.red;
      case 'Not Initialized':
        return Colors.grey;
      default:
        return Colors.grey;
    }
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
                    onPressed:
                        _notificationSettingEnabled ? _startStopListener : null,
                    icon: Icon(
                      _isListening ? Icons.stop : Icons.play_arrow,
                      size: AppConstants.iconSizeSmall.sp,
                    ),
                    label: Text(
                      _notificationSettingEnabled
                          ? (_isListening ? 'Stop Listener' : 'Start Listener')
                          : 'Setting Disabled',
                      style: TextStyle(fontSize: AppConstants.textSizeSmall.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _notificationSettingEnabled
                          ? (_isListening ? Colors.orange : Colors.green)
                          : Colors.grey,
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
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
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
