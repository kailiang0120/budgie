import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:budgie/core/utils/app_logger.dart';

/// Handles notification scheduling and lifecycle management
/// Isolates scheduling logic from the main NotificationService
class NotificationScheduler {
  static const _logger = AppLogger('NotificationScheduler');
  
  final FlutterLocalNotificationsPlugin _plugin;
  bool _isTimeZoneInitialized = false;

  NotificationScheduler(this._plugin);

  /// Schedule a notification for later delivery
  Future<bool> scheduleNotification({
    required int notificationId,
    required String title,
    required String content,
    required Duration delay,
    required NotificationDetails details,
    String? payload,
  }) async {
    return _logger.traceAsync('scheduleNotification', () async {
      try {
        // Ensure timezone data is initialized
        _ensureTimeZoneInitialized();

        final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);

        // For Android platform, request exact alarm permission if needed
        if (Platform.isAndroid) {
          await _requestExactAlarmPermission();
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

        _logger.info('Scheduled notification for ${scheduledTime.toString()}');
        return true;
      } catch (e) {
        _logger.error('Failed to schedule notification', error: e);

        // Fallback to Future.delayed if zonedSchedule fails
        _scheduleFallback(
          notificationId: notificationId,
          title: title,
          content: content,
          delay: delay,
          details: details,
          payload: payload,
        );
        return false;
      }
    });
  }

  /// Schedule recurring daily notification
  Future<bool> scheduleDaily({
    required int notificationId,
    required String title,
    required String content,
    required int hour,
    required int minute,
    required NotificationDetails details,
    String? payload,
  }) async {
    return _logger.traceAsync('scheduleDaily', () async {
      try {
        _ensureTimeZoneInitialized();

        final now = tz.TZDateTime.now(tz.local);
        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
          0,
        );

        // If the scheduled time has passed today, schedule for tomorrow
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        if (Platform.isAndroid) {
          await _requestExactAlarmPermission();
        }

        await _plugin.zonedSchedule(
          notificationId,
          title,
          content,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );

        _logger.info('Scheduled daily notification at $hour:$minute');
        return true;
      } catch (e) {
        _logger.error('Failed to schedule daily notification', error: e);
        return false;
      }
    });
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    return _logger.traceAsync('cancel', () async {
      try {
        await _plugin.cancel(id);
        _logger.info('Cancelled notification $id');
      } catch (e) {
        _logger.error('Failed to cancel notification', error: e);
      }
    });
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    return _logger.traceAsync('cancelAll', () async {
      try {
        await _plugin.cancelAll();
        _logger.info('Cancelled all notifications');
      } catch (e) {
        _logger.error('Failed to cancel all notifications', error: e);
      }
    });
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      _logger.error('Failed to get pending notifications', error: e);
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
      _logger.error('Failed to get active notifications', error: e);
    }
    return [];
  }

  void _ensureTimeZoneInitialized() {
    if (!_isTimeZoneInitialized) {
      // Import timezone data (already initialized in NotificationService)
      _isTimeZoneInitialized = true;
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestExactAlarmsPermission();
      }
    } catch (e) {
      _logger.warning('Failed to request exact alarm permission');
    }
  }

  void _scheduleFallback({
    required int notificationId,
    required String title,
    required String content,
    required Duration delay,
    required NotificationDetails details,
    String? payload,
  }) {
    Future.delayed(delay, () async {
      try {
        await _plugin.show(
          notificationId,
          title,
          content,
          details,
          payload: payload,
        );
        _logger.info('Fallback notification sent');
      } catch (e) {
        _logger.error('Fallback notification failed', error: e);
      }
    });
  }
}
