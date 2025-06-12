import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../data/infrastructure/services/sync_service.dart';

/// Use case for upgrading a guest account to a permanent account
class UpgradeGuestAccountUseCase {
  final AuthRepository _authRepository;
  final SyncService _syncService;

  UpgradeGuestAccountUseCase({
    required AuthRepository authRepository,
    required SyncService syncService,
  })  : _authRepository = authRepository,
        _syncService = syncService;

  /// Execute the upgrade guest account use case
  Future<User> execute(
      {required String email, required String password}) async {
    // Check if current user is anonymous
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || !firebaseUser.isAnonymous) {
      throw Exception('No guest account to upgrade');
    }

    // First ensure all local data is synced to Firebase
    await _syncService.forceFullSync();

    // Call repository to link anonymous account
    final user = await _authRepository.linkAnonymousAccount(
      email: email,
      password: password,
    );

    // Remove the stored guest user ID since it's now a permanent account
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_guest_user_id');

    // Trigger another sync to ensure all data is properly associated with the upgraded account
    await _syncService.forceFullSync();

    return user;
  }
}
