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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      debugPrint('🔥 AuthViewModel: Handling user login for: $userId');

      // Step 1: Initialize settings (will handle new/existing user detection internally)
      debugPrint('🔥 AuthViewModel: Initializing settings for user');
      await _settingsService.initializeForUser(userId);
      debugPrint('🔥 AuthViewModel: Settings initialization completed');
      debugPrint(
          '🔥 AuthViewModel: Current settings - Currency: ${_settingsService.currency}, Theme: ${_settingsService.theme}, Notifications: ${_settingsService.allowNotification}');

      // Step 2: Initialize theme based on user settings (only after settings are loaded/created)
      debugPrint('🔥 AuthViewModel: Initializing theme for user');
      await _themeViewModel.initializeForUser(userId);
      debugPrint('🔥 AuthViewModel: Theme initialization completed');

      // Step 3: Initialize local data synchronization
      debugPrint('🔥 AuthViewModel: Initializing local data sync');
      await _syncService.initializeLocalDataOnLogin(userId);
      debugPrint('🔥 AuthViewModel: Local data sync initialized');

      // Step 4: Trigger a full sync to ensure offline data is merged with Firebase
      debugPrint('🔥 AuthViewModel: Triggering full data synchronization');
      // Use a slight delay to ensure everything is initialized properly
      Future.delayed(const Duration(seconds: 2), () {
        _syncService.forceFullSync();
      });

      debugPrint(
          '🔥 AuthViewModel: User login handling completed for: $userId');
    } catch (e) {
      debugPrint('🔥 AuthViewModel: Error handling user login for $userId: $e');
      _error = 'Failed to initialize user data: ${e.toString()}';
      rethrow;
    }
  }

  // Handle user logout
  Future<void> _handleUserLogout() async {
    try {
      debugPrint('🔥 AuthViewModel: Handling user logout');
      // Reset any local state if needed
      // The services will handle their own cleanup
    } catch (e) {
      debugPrint('🔥 AuthViewModel: Error handling user logout: $e');
    }
  }

  // Initialize user data (used for current user on app start)
  Future<void> _initializeUserData(String userId) async {
    try {
      debugPrint(
          '🔥 AuthViewModel: Initializing data for current user: $userId');

      // Initialize settings first
      await _settingsService.initializeForUser(userId);
      debugPrint('🔥 AuthViewModel: Settings initialized for current user');

      // Then initialize theme
      await _themeViewModel.initializeForUser(userId);
      debugPrint('🔥 AuthViewModel: Theme initialized for current user');

      // Finally initialize local data
      await _syncService.initializeLocalDataOnLogin(userId);
      debugPrint('🔥 AuthViewModel: Local data initialized for current user');

      // Trigger a full sync to ensure offline data is merged with Firebase
      debugPrint(
          '🔥 AuthViewModel: Triggering full data synchronization for current user');
      // Use a slight delay to ensure everything is initialized properly
      Future.delayed(const Duration(seconds: 2), () {
        _syncService.forceFullSync();
      });
    } catch (e) {
      debugPrint('🔥 AuthViewModel: Error initializing current user data: $e');
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

  Future<domain.User?> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _error = 'Email and password cannot be empty';
      notifyListeners();
      return null;
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

      return _currentUser;
    } catch (e) {
      // debugPrint('🔥 AuthViewModel: Sign in error: $e');
      _error = 'Failed to sign in: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<domain.User?> signUp(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _error = 'Email and password cannot be empty';
      notifyListeners();
      return null;
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

      return _currentUser;
    } catch (e) {
      //debugPrint('🔥 AuthViewModel: Sign up error: $e');
      _error = 'Failed to create account: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      //debugPrint('🔥 AuthViewModel: Starting Google sign-in');

      // Check if the current user is anonymous
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      final isAnonymous = firebaseUser != null && firebaseUser.isAnonymous;

      // If user is anonymous and in profile screen context, we link the accounts
      // The repository will handle the linking automatically

      // Call repository for Google sign-in
      try {
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

        // If we were previously anonymous, ensure we remove stored guest ID
        if (isAnonymous) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('last_guest_user_id');
          debugPrint(
              '🔥 AuthViewModel: Removed stored guest user ID after upgrade to Google account');
        }

        // Use the new user handling logic
        await _handleUserLogin(_currentUser!.id);
        //debugPrint(
        //    '🔥 AuthViewModel: Google sign-in process completed for: ${_currentUser!.id}');

        return true; // Sign-in successful
      } catch (e) {
        if (e.toString().contains('cancel') ||
            e.toString().contains('Sign-in canceled')) {
          _error = 'Sign-in was cancelled';
          debugPrint('🔥 AuthViewModel: Google sign-in was cancelled by user');
          return false; // User cancelled
        }
        // Rethrow other errors to be caught by the outer catch block
        rethrow;
      }
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
      return false; // Sign-in failed
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithApple() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('🔥 AuthViewModel: Starting Apple sign-in');

      // Check if the current user is anonymous
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      final isAnonymous = firebaseUser != null && firebaseUser.isAnonymous;

      // Call repository for Apple sign-in
      final user = await _authRepository.signInWithApple();

      // Set current user
      _currentUser = user;

      // Verify we have a valid user
      if (_currentUser == null || _currentUser!.id.isEmpty) {
        debugPrint('🔥 AuthViewModel: Invalid user returned from repository');
        throw Exception('Authentication failed - Invalid user');
      }

      debugPrint(
          '🔥 AuthViewModel: Apple sign-in successful - User ID: ${_currentUser!.id}');

      // If we were previously anonymous, ensure we remove stored guest ID
      if (isAnonymous) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('last_guest_user_id');
        debugPrint(
            '🔥 AuthViewModel: Removed stored guest user ID after upgrade to Apple account');
      }

      // Use the new user handling logic
      await _handleUserLogin(_currentUser!.id);
      debugPrint(
          '🔥 AuthViewModel: Apple sign-in process completed for: ${_currentUser!.id}');
    } catch (e) {
      debugPrint('🔥 AuthViewModel: Apple sign-in error: $e');

      // Set appropriate error message
      if (e.toString().contains('network')) {
        _error =
            'Network connection issue. Please check your internet connection and try again.';
      } else if (e.toString().contains('cancel')) {
        _error = 'Sign-in was cancelled';
      } else if (e.toString().contains('credential')) {
        _error = 'Authentication failed. Please try again.';
      } else {
        _error = 'Failed to sign in with Apple: ${e.toString()}';
      }

      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in as guest (anonymous authentication)
  /// Returns the user object if successful, or null if failed
  Future<domain.User?> signInAsGuest() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('🔥 AuthViewModel: Starting guest sign-in');

      // Check if we have a stored guest user ID in local storage
      final prefs = await SharedPreferences.getInstance();
      final storedGuestUserId = prefs.getString('last_guest_user_id');

      if (storedGuestUserId != null) {
        debugPrint(
            '🔥 AuthViewModel: Found stored guest user ID: $storedGuestUserId');

        // Try to sign in with the stored guest credentials
        try {
          // We need to check if this anonymous user still exists in Firebase
          // If the app was uninstalled and reinstalled, the local ID might be invalid
          final isValid = await _checkIfAnonymousUserExists(storedGuestUserId);

          if (isValid) {
            debugPrint('🔥 AuthViewModel: Using existing guest account');
            // Get user from local database
            final localUser =
                await _syncService.getLocalUser(storedGuestUserId);

            if (localUser != null) {
              _currentUser = localUser;
              await _handleUserLogin(localUser.id);
              debugPrint(
                  '🔥 AuthViewModel: Successfully loaded existing guest user data');
              _isLoading = false;
              notifyListeners();
              return _currentUser;
            }
          } else {
            debugPrint(
                '🔥 AuthViewModel: Stored guest user is invalid, creating new one');
            // Clear the stored ID since it's invalid
            await prefs.remove('last_guest_user_id');
          }
        } catch (e) {
          debugPrint('🔥 AuthViewModel: Error checking stored guest user: $e');
          // Continue with creating a new guest user
        }
      }

      // If we reach here, we need to create a new guest user
      // Call repository for anonymous sign-in
      final user = await _authRepository.signInAnonymously();

      // Set current user
      _currentUser = user;

      // Verify we have a valid user
      if (_currentUser == null || _currentUser!.id.isEmpty) {
        debugPrint('🔥 AuthViewModel: Invalid user returned from repository');
        throw Exception('Guest authentication failed - Invalid user');
      }

      // Store the guest user ID for future use
      await prefs.setString('last_guest_user_id', user.id);

      debugPrint(
          '🔥 AuthViewModel: Guest sign-in successful - User ID: ${_currentUser!.id}');

      // Use the same user handling logic as other auth methods
      await _handleUserLogin(_currentUser!.id);

      debugPrint(
          '🔥 AuthViewModel: Guest sign-in process completed for: ${_currentUser!.id}');

      return _currentUser;
    } catch (e) {
      debugPrint('🔥 AuthViewModel: Guest sign-in error: $e');
      _error = 'Failed to sign in as guest: ${e.toString()}';
      _currentUser = null;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if an anonymous user exists in Firebase
  Future<bool> _checkIfAnonymousUserExists(String userId) async {
    try {
      // Get the currently signed-in Firebase user
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;

      // If there's already a signed-in user with a different ID, it's likely invalid
      if (firebaseUser != null && firebaseUser.uid != userId) {
        debugPrint('🔥 AuthViewModel: Found different user ID than requested');
        return false;
      }

      // Try to see if we have this user in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        debugPrint('🔥 AuthViewModel: Found user document in Firestore');
        // The user exists in Firestore, which means it's a valid user
        return true;
      }

      // If we reach here, we couldn't verify the user exists
      debugPrint('🔥 AuthViewModel: Could not verify user existence');
      return false;
    } catch (e) {
      debugPrint(
          '🔥 AuthViewModel: Error checking if anonymous user exists: $e');
      return false;
    }
  }

  /// Upgrade guest account to permanent account
  Future<void> upgradeGuestAccount(
      {required String email, required String password}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Check if current user is anonymous
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null || !firebaseUser.isAnonymous) {
        throw Exception('No guest account to upgrade');
      }

      // Store the guest user ID to ensure data continuity
      final guestUserId = firebaseUser.uid;
      debugPrint(
          '🔥 AuthViewModel: Upgrading guest account to permanent account: $guestUserId');

      // First ensure all local data is synced to Firebase
      await _syncService.forceFullSync();
      debugPrint('🔥 AuthViewModel: Forced data sync before account upgrade');

      // Call repository to link anonymous account
      final user = await _authRepository.linkAnonymousAccount(
        email: email,
        password: password,
      );

      // Update current user
      _currentUser = user;

      debugPrint('🔥 AuthViewModel: Guest account upgraded successfully');

      // Remove the stored guest user ID since it's now a permanent account
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_guest_user_id');

      // Refresh user data
      await refreshAuthState();

      // Trigger another sync to ensure all data is properly associated with the upgraded account
      await _syncService.forceFullSync();
      debugPrint('🔥 AuthViewModel: Final data sync after account upgrade');
    } catch (e) {
      debugPrint('🔥 AuthViewModel: Error upgrading guest account: $e');

      // Set appropriate error message
      if (e.toString().contains('email-already-in-use')) {
        _error = 'This email is already in use by another account';
      } else if (e.toString().contains('weak-password')) {
        _error = 'The password is too weak';
      } else if (e.toString().contains('invalid-email')) {
        _error = 'The email address is not valid';
      } else {
        _error = 'Failed to upgrade account: ${e.toString()}';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if current user is a guest
  bool get isGuestUser {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    return firebaseUser != null && firebaseUser.isAnonymous;
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

  /// Securely sign out an anonymous user with data deletion
  Future<void> secureSignOutAnonymousUser() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Check if current user is anonymous
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null || !firebaseUser.isAnonymous) {
        throw Exception('No anonymous user to sign out');
      }

      final userId = firebaseUser.uid;
      debugPrint('Securely signing out anonymous user: $userId');

      // Clear local storage reference to guest user
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_guest_user_id');

      // Call the comprehensive function that deletes the user account and data
      try {
        await _authRepository.deleteGuestUser();
        _currentUser = null;
        debugPrint('Anonymous user securely signed out and deleted');
      } catch (e) {
        debugPrint('Warning: Error during secure sign out: $e');

        // Even if there was an error with deletion, try a normal sign out
        // to ensure the user is at least logged out
        if (firebase_auth.FirebaseAuth.instance.currentUser != null) {
          debugPrint('Attempting normal sign out as fallback');
          await _authRepository.signOut();
          _currentUser = null;
        }

        // Specific error handling for better user feedback
        if (e.toString().contains('permission-denied')) {
          _error =
              'Sign out completed, but some data could not be deleted due to permission restrictions.';
        } else {
          _error =
              'Sign out completed, but there was an issue with data deletion.';
        }
      }
    } catch (e) {
      debugPrint('Secure sign out error: $e');
      _error = 'Failed to securely sign out: ${e.toString()}';
      rethrow; // Rethrow to allow UI to handle the error
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
