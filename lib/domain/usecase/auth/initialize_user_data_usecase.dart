import '../../../data/infrastructure/services/sync_service.dart';
import '../../../data/infrastructure/services/settings_service.dart';
import '../../../presentation/viewmodels/theme_viewmodel.dart';

/// Use case for initializing user data (used for current user on app start)
class InitializeUserDataUseCase {
  final SyncService _syncService;
  final ThemeViewModel _themeViewModel;
  final SettingsService _settingsService;

  InitializeUserDataUseCase({
    required SyncService syncService,
    required ThemeViewModel themeViewModel,
    required SettingsService settingsService,
  })  : _syncService = syncService,
        _themeViewModel = themeViewModel,
        _settingsService = settingsService;

  /// Execute the initialize user data use case
  Future<void> execute(String userId) async {
    try {
      // Initialize settings first
      await _settingsService.initializeForUser(userId);

      // Then initialize theme
      await _themeViewModel.initializeForUser(userId);

      // Finally initialize local data
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
