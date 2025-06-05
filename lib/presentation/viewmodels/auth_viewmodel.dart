import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../domain/entities/user.dart' as domain;
import '../../domain/repositories/auth_repository.dart';
import '../../core/utils/performance_monitor.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/settings_service.dart';
import '../viewmodels/theme_viewmodel.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SyncService _syncService;
  final ThemeViewModel _themeViewModel;
  final SettingsService _settingsService;
  domain.User? _currentUser;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<domain.User?>? _authSubscription;

  AuthViewModel({
    required AuthRepository authRepository,
    required SyncService syncService,
    required ThemeViewModel themeViewModel,
    required SettingsService settingsService,
  })  : _authRepository = authRepository,
        _syncService = syncService,
        _themeViewModel = themeViewModel,
        _settingsService = settingsService {
    _initAuth();
  }

  domain.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<void> _initAuth() async {
    try {
      debugPrint('🔥 AuthViewModel: Initializing authentication');
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current user
      _currentUser = await _authRepository.getCurrentUser();

      // If user is already authenticated, initialize their data
      if (_currentUser != null) {
        debugPrint('🔥 AuthViewModel: Current user found: ${_currentUser!.id}');
        await _initializeUserData(_currentUser!.id);
      } else {
        debugPrint('🔥 AuthViewModel: No current user found');
      }

      // Listen for auth state changes
      _authSubscription = _authRepository.authStateChanges.listen(
        (user) async {
          debugPrint(
              '🔥 AuthViewModel: Auth state changed - User: ${user?.id ?? 'null'}');

          try {
            _currentUser = user;

            if (user != null) {
              debugPrint(
                  '🔥 AuthViewModel: User logged in, initializing data for: ${user.id}');
              await _handleUserLogin(user.id);
            } else {
              debugPrint('🔥 AuthViewModel: User logged out');
              await _handleUserLogout();
            }

            notifyListeners();
          } catch (e) {
            debugPrint(
                '🔥 AuthViewModel: Error in auth state change handler: $e');
            _error = 'Failed to process authentication change: ${e.toString()}';
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('🔥 AuthViewModel: Auth state stream error: $error');
          _error = 'Authentication stream error: ${error.toString()}';
          notifyListeners();
        },
      );

      debugPrint('🔥 AuthViewModel: Authentication initialization complete');
    } catch (e) {
      debugPrint('🔥 AuthViewModel: Error initializing auth: $e');
      _error = 'Failed to initialize authentication: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Handle user login with new/existing user detection
  Future<void> _handleUserLogin(String userId) async {
    try {
      //debugPrint('🔥 AuthViewModel: Handling user login for: $userId');

      // Step 1: Initialize settings (will handle new/existing user detection internally)
      // debugPrint('🔥 AuthViewModel: Initializing settings for user');
      await _settingsService.initializeForUser(userId);
      //debugPrint('🔥 AuthViewModel: Settings initialization completed');
      //debugPrint(
      //    '🔥 AuthViewModel: Current settings - Currency: ${_settingsService.currency}, Theme: ${_settingsService.theme}, Notifications: ${_settingsService.allowNotification}');

      // Step 2: Initialize theme based on user settings (only after settings are loaded/created)
      //debugPrint('🔥 AuthViewModel: Initializing theme for user');
      await _themeViewModel.initializeForUser(userId);
      //debugPrint('🔥 AuthViewModel: Theme initialization completed');

      // Step 3: Initialize local data synchronization
      //debugPrint('🔥 AuthViewModel: Initializing local data sync');
      await _syncService.initializeLocalDataOnLogin(userId);
      //debugPrint('🔥 AuthViewModel: Local data sync initialized');

      //debugPrint(
      //    '🔥 AuthViewModel: User login handling completed for: $userId');
    } catch (e) {
      //debugPrint('🔥 AuthViewModel: Error handling user login for $userId: $e');
      _error = 'Failed to initialize user data: ${e.toString()}';
      rethrow;
    }
  }

  // Handle user logout
  Future<void> _handleUserLogout() async {
    try {
      //debugPrint('🔥 AuthViewModel: Handling user logout');
      // Reset any local state if needed
      // The services will handle their own cleanup
    } catch (e) {
      //debugPrint('🔥 AuthViewModel: Error handling user logout: $e');
    }
  }

  // Initialize user data (used for current user on app start)
  Future<void> _initializeUserData(String userId) async {
    try {
      //debugPrint(
      //    '🔥 AuthViewModel: Initializing data for current user: $userId');

      // Initialize settings first
      await _settingsService.initializeForUser(userId);
      //debugPrint('🔥 AuthViewModel: Settings initialized for current user');

      // Then initialize theme
      await _themeViewModel.initializeForUser(userId);
      //debugPrint('🔥 AuthViewModel: Theme initialized for current user');

      // Finally initialize local data
      await _syncService.initializeLocalDataOnLogin(userId);
      //debugPrint('🔥 AuthViewModel: Local data initialized for current user');
    } catch (e) {
      //debugPrint('🔥 AuthViewModel: Error initializing current user data: $e');
      _error = 'Failed to initialize user data: ${e.toString()}';
      rethrow;
    }
  }

  // Refresh authentication state to ensure current user info is up-to-date
  Future<void> refreshAuthState() async {
    try {
      //debugPrint('🔥 Refreshing auth state');
      PerformanceMonitor.startTimer('refresh_auth_state');
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get fresh user data
      _currentUser = await _authRepository.getCurrentUser();

      // Additional debug info
      //debugPrint('🔥 Refreshed user: ${_currentUser?.id ?? 'Not logged in'}');
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      //debugPrint('🔥 Firebase user: ${firebaseUser?.uid ?? 'Not logged in'}');

      // Handle potential state mismatch
      if (firebaseUser != null && _currentUser == null) {
        //debugPrint(
        //    '🔥 State mismatch detected: Firebase user exists but domain user is null');
        await firebaseUser.reload();
        _currentUser = await _authRepository.getCurrentUser();
      }

      // Initialize theme if user is authenticated
      if (_currentUser != null) {
        //debugPrint(
        //    '🔥 Initializing theme for authenticated user: ${_currentUser!.id}');
        await _themeViewModel.initializeForUser(_currentUser!.id);
        //debugPrint('🔥 Theme initialization completed for refreshed user');
      }
    } catch (e) {
      //debugPrint('🔥 Error refreshing auth state: $e');
      _error = 'Failed to refresh authentication state';
      _currentUser = null;
    } finally {
      _isLoading = false;
      PerformanceMonitor.stopTimer('refresh_auth_state');
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _error = 'Email and password cannot be empty';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      //debugPrint('🔥 AuthViewModel: Signing in with email: $email');
      final user =
          await _authRepository.signInWithEmailAndPassword(email, password);
      _currentUser = user;
      //debugPrint('🔥 AuthViewModel: Successfully signed in: ${user.id}');

      // Use the new user handling logic
      await _handleUserLogin(user.id);
      // debugPrint('🔥 AuthViewModel: Sign-in process completed for: ${user.id}');
    } catch (e) {
      // debugPrint('🔥 AuthViewModel: Sign in error: $e');
      _error = 'Failed to sign in: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _error = 'Email and password cannot be empty';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      //debugPrint('🔥 AuthViewModel: Creating account with email: $email');
      final user =
          await _authRepository.createUserWithEmailAndPassword(email, password);
      _currentUser = user;
      //debugPrint('🔥 AuthViewModel: Successfully created account: ${user.id}');

      // Use the new user handling logic (will detect this as a new user)
      await _handleUserLogin(user.id);
      //debugPrint('🔥 AuthViewModel: Sign-up process completed for: ${user.id}');
    } catch (e) {
      //debugPrint('🔥 AuthViewModel: Sign up error: $e');
      _error = 'Failed to create account: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      //debugPrint('🔥 AuthViewModel: Starting Google sign-in');

      // Call repository for Google sign-in
      final user = await _authRepository.signInWithGoogle();

      // Set current user
      _currentUser = user;

      // Verify we have a valid user
      if (_currentUser == null || _currentUser!.id.isEmpty) {
        //debugPrint('🔥 AuthViewModel: Invalid user returned from repository');
        throw Exception('Authentication failed - Invalid user');
      }

      //debugPrint(
      //    '🔥 AuthViewModel: Google sign-in successful - User ID: ${_currentUser!.id}');

      // Use the new user handling logic
      await _handleUserLogin(_currentUser!.id);
      //debugPrint(
      //    '🔥 AuthViewModel: Google sign-in process completed for: ${_currentUser!.id}');
    } catch (e) {
      //debugPrint('🔥 AuthViewModel: Google sign-in error: $e');

      // Set appropriate error message
      if (e.toString().contains('network')) {
        _error =
            'Network connection issue. Please check your internet connection and try again.';
      } else if (e.toString().contains('cancel')) {
        _error = 'Sign-in was cancelled';
      } else if (e.toString().contains('credential')) {
        _error = 'Authentication failed. Please try again.';
      } else {
        _error = 'Failed to sign in with Google: ${e.toString()}';
      }

      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      //debugPrint('Signing out');
      await _authRepository.signOut();
      _currentUser = null;
      //debugPrint('Successfully signed out');
    } catch (e) {
      //debugPrint('Sign out error: $e');
      _error = 'Failed to sign out: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty) {
      _error = 'Email cannot be empty';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      //debugPrint('Sending password reset email to: $email');
      await _authRepository.resetPassword(email);
      //debugPrint('Password reset email sent');
    } catch (e) {
      //debugPrint('Password reset error: $e');
      _error = 'Failed to reset password: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Manually trigger data synchronization
  Future<void> syncData() async {
    if (_currentUser == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _syncService.syncData();
    } catch (e) {
      debugPrint('Sync error: $e');
      _error = 'Failed to sync data: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('Updating profile: name=$displayName, photo=$photoUrl');
      await _authRepository.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );

      // Refresh user data after update
      _currentUser = await _authRepository.getCurrentUser();
      debugPrint('Profile updated successfully');
    } catch (e) {
      debugPrint('Profile update error: $e');
      _error = 'Failed to update profile: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user settings
  Future<void> updateUserSettings({String? currency, String? theme}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('Updating user settings: currency=$currency, theme=$theme');
      await _authRepository.updateUserSettings(
        currency: currency,
        theme: theme,
      );

      // Refresh user data
      _currentUser = await _authRepository.getCurrentUser();
      debugPrint('User settings updated successfully');
    } catch (e) {
      debugPrint('User settings update error: $e');
      _error = 'Failed to update user settings: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Force refresh user settings (useful for debugging)
  Future<void> forceRefreshUserSettings() async {
    try {
      if (_currentUser != null) {
        debugPrint(
            '🔥 AuthViewModel: Force refreshing user settings for: ${_currentUser!.id}');
        await _settingsService.forceReloadFromFirebase();
        debugPrint('🔥 AuthViewModel: Settings force refresh completed');
      } else {
        debugPrint('🔥 AuthViewModel: No current user for settings refresh');
      }
    } catch (e) {
      debugPrint('🔥 AuthViewModel: Error refreshing user settings: $e');
    }
  }

  // Clear any errors
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
