import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../data/infrastructure/services/sync_service.dart';
import '../../../data/infrastructure/services/settings_service.dart';
import '../../../presentation/viewmodels/theme_viewmodel.dart';

/// Use case for signing in as a guest (anonymous user)
class SignInAsGuestUseCase {
  final AuthRepository _authRepository;
  final SyncService _syncService;
  final ThemeViewModel _themeViewModel;
  final SettingsService _settingsService;

  SignInAsGuestUseCase({
    required AuthRepository authRepository,
    required SyncService syncService,
    required ThemeViewModel themeViewModel,
    required SettingsService settingsService,
  })  : _authRepository = authRepository,
        _syncService = syncService,
        _themeViewModel = themeViewModel,
        _settingsService = settingsService;

  /// Execute the sign in as guest use case
  Future<User> execute() async {
    // Check if we have a stored guest user ID in local storage
    final prefs = await SharedPreferences.getInstance();
    final storedGuestUserId = prefs.getString('last_guest_user_id');

    if (storedGuestUserId != null) {
      // Try to sign in with the stored guest credentials
      try {
        // Check if this anonymous user still exists in Firebase
        final isValid = await _checkIfAnonymousUserExists(storedGuestUserId);

        if (isValid) {
          // Get user from local database
          final localUser = await _syncService.getLocalUser(storedGuestUserId);

          if (localUser != null) {
            await _handleUserLogin(localUser.id);
            return localUser;
          }
        } else {
          // Clear the stored ID since it's invalid
          await prefs.remove('last_guest_user_id');
        }
      } catch (e) {
        // Continue with creating a new guest user
      }
    }

    // If we reach here, we need to create a new guest user
    final user = await _authRepository.signInAnonymously();

    // Verify we have a valid user
    if (user.id.isEmpty) {
      throw Exception('Guest authentication failed - Invalid user');
    }

    // Store the guest user ID for future use
    await prefs.setString('last_guest_user_id', user.id);

    // Handle post-login initialization
    await _handleUserLogin(user.id);

    return user;
  }

  /// Check if an anonymous user exists in Firebase
  Future<bool> _checkIfAnonymousUserExists(String userId) async {
    try {
      // Get the currently signed-in Firebase user
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;

      // If there's already a signed-in user with a different ID, it's likely invalid
      if (firebaseUser != null && firebaseUser.uid != userId) {
        return false;
      }

      // Try to see if we have this user in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc.exists;
    } catch (e) {
      return false;
    }
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
