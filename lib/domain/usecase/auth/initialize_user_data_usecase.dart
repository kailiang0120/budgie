import '../../../data/infrastructure/services/sync_service.dart';

/// Use case for initializing user data (used for current user on app start)
class InitializeUserDataUseCase {
  final SyncService _syncService;

  InitializeUserDataUseCase({
    required SyncService syncService,
  }) : _syncService = syncService;

  /// Execute the initialize user data use case
  Future<void> execute(String userId) async {
    try {
      // Initialize local data
      await _syncService.initializeLocalDataOnLogin(userId);

      // Trigger a full sync to ensure offline data is merged with Firebase
      Future.delayed(const Duration(seconds: 2), () {
        _syncService.forceFullSync();
      });
    } catch (e) {
      throw Exception('Failed to initialize user data: $e');
    }
  }
}
