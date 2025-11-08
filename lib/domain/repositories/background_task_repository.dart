/// Repository interface for background task operations
/// Decouples background services from direct service dependencies
abstract class BackgroundTaskRepository {
  /// Process recurring expenses
  Future<void> processRecurringExpenses();
  
  /// Sync data if connected
  Future<void> syncDataIfConnected();
  
  /// Clean up old data
  Future<void> cleanupOldData();
  
  /// Check and send reminders
  Future<void> checkAndSendReminders();
}
