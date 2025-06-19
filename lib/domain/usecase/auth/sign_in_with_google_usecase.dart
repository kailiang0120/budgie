import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../data/infrastructure/services/sync_service.dart';

/// Use case for signing in with Google
class SignInWithGoogleUseCase {
  final AuthRepository _authRepository;
  final SyncService _syncService;

  SignInWithGoogleUseCase({
    required AuthRepository authRepository,
    required SyncService syncService,
  })  : _authRepository = authRepository,
        _syncService = syncService;

  /// Execute the sign in with Google use case
  Future<User> execute() async {
    // Call repository for Google sign-in
    final user = await _authRepository.signInWithGoogle();

    // Verify we have a valid user
    if (user.id.isEmpty) {
      throw Exception('Authentication failed - Invalid user');
    }

    // Make sure we reload the firebase user to get fresh data
    try {
      final currentFirebaseUser =
          firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentFirebaseUser != null) {
        await currentFirebaseUser.reload();
      }
    } catch (e) {
      // Non-fatal, just log it
      print('Error reloading Firebase user after Google sign-in: $e');
    }

    // Handle post-login initialization
    await _handleUserLogin(user.id);

    return user;
  }

  /// Handle user login initialization process
  Future<void> _handleUserLogin(String userId) async {
    try {
      // Initialize local data synchronization
      await _syncService.initializeLocalDataOnLogin(userId);

      // Trigger a full sync with a delay
      Future.delayed(const Duration(seconds: 2), () {
        _syncService.forceFullSync();
      });
    } catch (e) {
      throw Exception('Failed to initialize user data: $e');
    }
  }
}
