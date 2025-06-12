import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../../repositories/auth_repository.dart';

/// Use case for securely signing out an anonymous user with data deletion
class SecureSignOutAnonymousUserUseCase {
  final AuthRepository _authRepository;

  SecureSignOutAnonymousUserUseCase({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

  /// Execute the secure sign out anonymous user use case
  Future<void> execute() async {
    // Check if current user is anonymous
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || !firebaseUser.isAnonymous) {
      throw Exception('No anonymous user to sign out');
    }

    // Clear local storage reference to guest user
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_guest_user_id');

    // Call the comprehensive function that deletes the user account and data
    try {
      await _authRepository.deleteGuestUser();
    } catch (e) {
      // Even if there was an error with deletion, try a normal sign out
      if (firebase_auth.FirebaseAuth.instance.currentUser != null) {
        await _authRepository.signOut();
      }

      // Specific error handling for better user feedback
      if (e.toString().contains('permission-denied')) {
        throw Exception(
            'Sign out completed, but some data could not be deleted due to permission restrictions.');
      } else {
        throw Exception(
            'Sign out completed, but there was an issue with data deletion.');
      }
    }
  }
}
