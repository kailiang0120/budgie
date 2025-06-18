import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Use case for checking if the current user is a guest user
class IsGuestUserUseCase {
  /// Execute the is guest user use case
  bool execute() {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;

    // Consider a user as non-guest if they have a valid email, regardless of anonymous status
    // This handles cases where the anonymous flag might not update correctly
    if (firebaseUser != null &&
        firebaseUser.email != null &&
        firebaseUser.email!.isNotEmpty) {
      return false;
    }

    // Otherwise, rely on the isAnonymous flag
    return firebaseUser != null && firebaseUser.isAnonymous;
  }
}
