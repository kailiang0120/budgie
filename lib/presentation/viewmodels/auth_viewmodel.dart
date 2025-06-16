import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../domain/entities/user.dart' as domain;
import '../../domain/repositories/auth_repository.dart';

import '../../domain/usecase/auth/sign_in_with_email_usecase.dart';
import '../../domain/usecase/auth/create_user_with_email_usecase.dart';
import '../../domain/usecase/auth/sign_in_with_google_usecase.dart';
import '../../domain/usecase/auth/sign_in_with_apple_usecase.dart';
import '../../domain/usecase/auth/sign_in_as_guest_usecase.dart';
import '../../domain/usecase/auth/upgrade_guest_account_usecase.dart';
import '../../domain/usecase/auth/secure_sign_out_anonymous_user_usecase.dart';
import '../../domain/usecase/auth/refresh_auth_state_usecase.dart';
import '../../domain/usecase/auth/update_profile_usecase.dart';
import '../../domain/usecase/auth/update_user_settings_usecase.dart';
import '../../domain/usecase/auth/initialize_user_data_usecase.dart';
import '../../domain/usecase/auth/is_guest_user_usecase.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SignInWithEmailUseCase _signInWithEmailUseCase;
  final CreateUserWithEmailUseCase _createUserWithEmailUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignInWithAppleUseCase _signInWithAppleUseCase;
  final SignInAsGuestUseCase _signInAsGuestUseCase;
  final UpgradeGuestAccountUseCase _upgradeGuestAccountUseCase;
  final SecureSignOutAnonymousUserUseCase _secureSignOutAnonymousUserUseCase;
  final RefreshAuthStateUseCase _refreshAuthStateUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final UpdateUserSettingsUseCase _updateUserSettingsUseCase;
  final InitializeUserDataUseCase _initializeUserDataUseCase;
  final IsGuestUserUseCase _isGuestUserUseCase;

  domain.User? _currentUser;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<domain.User?>? _authSubscription;

  AuthViewModel({
    required AuthRepository authRepository,
    required SignInWithEmailUseCase signInWithEmailUseCase,
    required CreateUserWithEmailUseCase createUserWithEmailUseCase,
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required SignInWithAppleUseCase signInWithAppleUseCase,
    required SignInAsGuestUseCase signInAsGuestUseCase,
    required UpgradeGuestAccountUseCase upgradeGuestAccountUseCase,
    required SecureSignOutAnonymousUserUseCase
        secureSignOutAnonymousUserUseCase,
    required RefreshAuthStateUseCase refreshAuthStateUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required UpdateUserSettingsUseCase updateUserSettingsUseCase,
    required InitializeUserDataUseCase initializeUserDataUseCase,
    required IsGuestUserUseCase isGuestUserUseCase,
  })  : _authRepository = authRepository,
        _signInWithEmailUseCase = signInWithEmailUseCase,
        _createUserWithEmailUseCase = createUserWithEmailUseCase,
        _signInWithGoogleUseCase = signInWithGoogleUseCase,
        _signInWithAppleUseCase = signInWithAppleUseCase,
        _signInAsGuestUseCase = signInAsGuestUseCase,
        _upgradeGuestAccountUseCase = upgradeGuestAccountUseCase,
        _secureSignOutAnonymousUserUseCase = secureSignOutAnonymousUserUseCase,
        _refreshAuthStateUseCase = refreshAuthStateUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _updateUserSettingsUseCase = updateUserSettingsUseCase,
        _initializeUserDataUseCase = initializeUserDataUseCase,
        _isGuestUserUseCase = isGuestUserUseCase {
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
        await _initializeUserDataUseCase.execute(_currentUser!.id);
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
              await _initializeUserDataUseCase.execute(user.id);
            } else {
              debugPrint('🔥 AuthViewModel: User logged out');
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

  /// Refresh authentication state to ensure current user info is up-to-date
  Future<void> refreshAuthState() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentUser = await _refreshAuthStateUseCase.execute();
    } catch (e) {
      debugPrint('🔥 Error refreshing auth state: $e');
      _error = 'Failed to refresh authentication state';
      _currentUser = null;
    } finally {
      _isLoading = false;
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

      final user = await _signInWithEmailUseCase.execute(email, password);
      _currentUser = user;
      return _currentUser;
    } catch (e) {
      debugPrint('🔥 AuthViewModel: Sign in error: $e');
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

      final user = await _createUserWithEmailUseCase.execute(email, password);
      _currentUser = user;
      return _currentUser;
    } catch (e) {
      debugPrint('🔥 AuthViewModel: Sign up error: $e');
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

      // Call use case for Google sign-in
      try {
        final user = await _signInWithGoogleUseCase.execute();
        _currentUser = user;
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
      debugPrint('🔥 AuthViewModel: Google sign-in error: $e');

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

      final user = await _signInWithAppleUseCase.execute();
      _currentUser = user;
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
  Future<domain.User?> signInAsGuest() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await _signInAsGuestUseCase.execute();
      _currentUser = user;
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

  /// Upgrade guest account to permanent account
  Future<void> upgradeGuestAccount(
      {required String email, required String password}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await _upgradeGuestAccountUseCase.execute(
        email: email,
        password: password,
      );

      _currentUser = user;

      // Refresh user data
      await refreshAuthState();
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
  bool get isGuestUser => _isGuestUserUseCase.execute();

  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authRepository.signOut();
      _currentUser = null;
      debugPrint('Successfully signed out');
    } catch (e) {
      debugPrint('Sign out error: $e');
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

      await _secureSignOutAnonymousUserUseCase.execute();
      _currentUser = null;
      debugPrint('Anonymous user securely signed out and deleted');
    } catch (e) {
      debugPrint('Secure sign out error: $e');
      _error = e.toString();
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

      await _authRepository.resetPassword(email);
      debugPrint('Password reset email sent');
    } catch (e) {
      debugPrint('Password reset error: $e');
      _error = 'Failed to reset password: ${e.toString()}';
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

      final updatedUser = await _updateProfileUseCase.execute(
        displayName: displayName,
        photoUrl: photoUrl,
      );

      _currentUser = updatedUser;
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
  Future<void> updateUserSettings(
      {String? currency, String? theme, String? displayName}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedUser = await _updateUserSettingsUseCase.execute(
        currency: currency,
        theme: theme,
        displayName: displayName,
      );

      _currentUser = updatedUser;
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
