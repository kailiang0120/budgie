import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Use case for checking if the current user is a guest user
class IsGuestUserUseCase {
  /// Execute the is guest user use case
  bool execute() {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    return firebaseUser != null && firebaseUser.isAnonymous;
  }
}
