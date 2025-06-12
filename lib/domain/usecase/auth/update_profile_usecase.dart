import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

/// Use case for updating user profile information
class UpdateProfileUseCase {
  final AuthRepository _authRepository;

  UpdateProfileUseCase({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

  /// Execute the update profile use case
  Future<User> execute({String? displayName, String? photoUrl}) async {
    await _authRepository.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
    );

    // Get updated user data
    final updatedUser = await _authRepository.getCurrentUser();
    if (updatedUser == null) {
      throw Exception('Failed to get updated user data');
    }

    return updatedUser;
  }
}
