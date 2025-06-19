import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

/// Use case for updating user settings
class UpdateUserSettingsUseCase {
  final AuthRepository _authRepository;

  UpdateUserSettingsUseCase({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

  /// Execute the update user settings use case
  Future<User> execute({
    String? currency,
    String? displayName,
  }) async {
    await _authRepository.updateUserSettings(
      currency: currency,
      displayName: displayName,
    );

    // Get updated user data
    final updatedUser = await _authRepository.getCurrentUser();
    if (updatedUser == null) {
      throw Exception('Failed to get updated user data');
    }

    return updatedUser;
  }
}
