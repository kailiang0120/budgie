import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../data/infrastructure/services/sync_service.dart';
import '../../../data/infrastructure/services/settings_service.dart';
import '../../../presentation/viewmodels/theme_viewmodel.dart';

/// Use case for signing in with Google
class SignInWithGoogleUseCase {
  final AuthRepository _authRepository;
  final SyncService _syncService;
  final ThemeViewModel _themeViewModel;
  final SettingsService _settingsService;

  SignInWithGoogleUseCase({
    required AuthRepository authRepository,
    required SyncService syncService,
    required ThemeViewModel themeViewModel,
    required SettingsService settingsService,
  })  : _authRepository = authRepository,
        _syncService = syncService,
        _themeViewModel = themeViewModel,
        _settingsService = settingsService;

  /// Execute the sign in with Google use case
  Future<User> execute() async {
    // Check if the current user is anonymous
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    final isAnonymous = firebaseUser != null && firebaseUser.isAnonymous;

    // Call repository for Google sign-in
    final user = await _authRepository.signInWithGoogle();

    // Verify we have a valid user
    if (user.id.isEmpty) {
      throw Exception('Authentication failed - Invalid user');
    }

    // If we were previously anonymous, ensure we remove stored guest ID
    if (isAnonymous) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_guest_user_id');
    }

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
