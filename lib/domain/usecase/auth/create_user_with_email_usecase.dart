import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../data/infrastructure/services/sync_service.dart';

/// Use case for creating a new user account with email and password
class CreateUserWithEmailUseCase {
  final AuthRepository _authRepository;
  final SyncService _syncService;

  CreateUserWithEmailUseCase({
    required AuthRepository authRepository,
    required SyncService syncService,
  })  : _authRepository = authRepository,
        _syncService = syncService;

  /// Execute the create user with email and password use case
  Future<User> execute(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password cannot be empty');
    }

    // Create user with repository
    final user =
        await _authRepository.createUserWithEmailAndPassword(email, password);

    // Handle post-registration initialization (new user)
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
