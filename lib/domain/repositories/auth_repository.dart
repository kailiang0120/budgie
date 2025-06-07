import '../entities/user.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;

  /// Gets the currently authenticated user
  Future<User?> getCurrentUser();

  /// Signs in a user with email and password
  Future<User> signInWithEmailAndPassword(String email, String password);

  /// Creates a new user account with email and password
  Future<User> createUserWithEmailAndPassword(String email, String password);

  /// Signs out the current user
  Future<void> signOut();

  /// Sends a password reset email
  Future<void> resetPassword(String email);

  /// Updates the user's profile information
  Future<void> updateProfile({String? displayName, String? photoUrl});

  /// Signs in a user with Google
  Future<User> signInWithGoogle();

  /// Signs in a user with Apple
  Future<User> signInWithApple();

  /// Updates user settings
  Future<void> updateUserSettings({String? currency, String? theme});

  /// Signs in a user anonymously (as guest)
  Future<User> signInAnonymously();

  /// Links anonymous account to permanent credentials
  Future<User> linkAnonymousAccount(
      {required String email, required String password});

  /// Delete anonymous user and all associated data
  Future<void> deleteGuestUser();
}
