import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

/// Use case for refreshing authentication state
class RefreshAuthStateUseCase {
  final AuthRepository _authRepository;

  RefreshAuthStateUseCase({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

  /// Execute the refresh auth state use case
  Future<User?> execute() async {
    debugPrint('🔥 Refreshing auth state');

    try {
      // Get fresh user data
      final currentUser = await _authRepository.getCurrentUser();

      // Additional debug info
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      debugPrint('🔥 Firebase user: ${firebaseUser?.uid ?? 'Not logged in'}');

      // Handle potential state mismatch
      if (firebaseUser != null && currentUser == null) {
        debugPrint(
            '🔥 State mismatch detected: Firebase user exists but domain user is null');
        await firebaseUser.reload();
        final refreshedUser = await _authRepository.getCurrentUser();

        return refreshedUser;
      }

      return currentUser;
    } catch (e) {
      debugPrint('🔥 Error refreshing auth state: $e');
      throw Exception('Failed to refresh authentication state');
    }
  }
}
