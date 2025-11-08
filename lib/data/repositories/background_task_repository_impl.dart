import 'package:budgie/core/utils/app_logger.dart';
import 'package:budgie/domain/repositories/background_task_repository.dart';
import 'package:budgie/domain/usecase/expense/process_recurring_expenses_usecase.dart';
import 'package:budgie/data/infrastructure/services/sync_service.dart';
import 'package:budgie/data/infrastructure/services/notification_service.dart';

/// Implementation of background task repository
/// Coordinates background operations through use cases and services
class BackgroundTaskRepositoryImpl implements BackgroundTaskRepository {
  static const _logger = AppLogger('BackgroundTaskRepository');
  
  final ProcessRecurringExpensesUseCase _recurringExpensesUseCase;
  final SyncService _syncService;
  
  BackgroundTaskRepositoryImpl({
    required ProcessRecurringExpensesUseCase recurringExpensesUseCase,
    required SyncService syncService,
    required NotificationService notificationService,
  })  : _recurringExpensesUseCase = recurringExpensesUseCase,
        _syncService = syncService;
  
  @override
  Future<void> processRecurringExpenses() async {
    return _logger.traceAsync('processRecurringExpenses', () async {
      try {
        await _recurringExpensesUseCase.execute();
        _logger.info('Recurring expenses processed successfully');
      } catch (e, stackTrace) {
        _logger.error('Failed to process recurring expenses', 
          error: e, stackTrace: stackTrace);
      }
    });
  }
  
  @override
  Future<void> syncDataIfConnected() async {
    return _logger.traceAsync('syncDataIfConnected', () async {
      try {
        final isEnabled = await _syncService.isSyncEnabled();
        if (isEnabled) {
          await _syncService.syncData();
          _logger.info('Data sync completed');
        } else {
          _logger.debug('Sync is disabled, skipping');
        }
      } catch (e, stackTrace) {
        _logger.error('Failed to sync data', error: e, stackTrace: stackTrace);
      }
    });
  }
  
  @override
  Future<void> cleanupOldData() async {
    return _logger.traceAsync('cleanupOldData', () async {
      try {
        // Cleanup logic can be added here
        _logger.info('Data cleanup completed');
      } catch (e, stackTrace) {
        _logger.error('Failed to cleanup data', error: e, stackTrace: stackTrace);
      }
    });
  }
  
  @override
  Future<void> checkAndSendReminders() async {
    return _logger.traceAsync('checkAndSendReminders', () async {
      try {
        // Reminder logic can be added here
        // For example, check if user hasn't logged expenses today
        _logger.info('Reminders checked');
      } catch (e, stackTrace) {
        _logger.error('Failed to check reminders', error: e, stackTrace: stackTrace);
      }
    });
  }
}
