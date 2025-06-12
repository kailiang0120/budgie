import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../data/infrastructure/services/sync_service.dart';
import '../../../data/infrastructure/services/settings_service.dart';
import '../../../presentation/viewmodels/theme_viewmodel.dart';

/// Use case for signing in with email and password
class SignInWithEmailUseCase {
  final AuthRepository _authRepository;
  final SyncService _syncService;
  final ThemeViewModel _themeViewModel;
  final SettingsService _settingsService;

  SignInWithEmailUseCase({
    required AuthRepository authRepository,
    required SyncService syncService,
    required ThemeViewModel themeViewModel,
    required SettingsService settingsService,
  })  : _authRepository = authRepository,
        _syncService = syncService,
        _themeViewModel = themeViewModel,
        _settingsService = settingsService;

  /// Execute the sign in with email and password use case
  Future<User> execute(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password cannot be empty');
    }

    // Sign in with repository
    final user =
        await _authRepository.signInWithEmailAndPassword(email, password);

    // Handle post-login initialization
    await _handleUserLogin(user.id);

    return user;
  }

  /// Handle user login initialization process
  Future<void> _handleUserLogin(String userId) async {
    try {
      // Step 1: Initialize settings
      await _settingsService.initializeForUser(userId);

      // Step 2: Initialize theme based on user settings
      await _themeViewModel.initializeForUser(userId);

      // Step 3: Initialize local data synchronization
      await _syncService.initializeLocalDataOnLogin(userId);

      // Step 4: Trigger a full sync with a delay
      Future.delayed(const Duration(seconds: 2), () {
        _syncService.forceFullSync();
      });
    } catch (e) {
      throw Exception('Failed to initialize user data: $e');
    }
  }
}
