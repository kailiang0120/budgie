import '../entities/user_behavior_profile.dart';

/// Repository interface for user behavior profile management
abstract class UserBehaviorRepository {
  /// Get user behavior profile by user ID
  Future<UserBehaviorProfile?> getUserBehaviorProfile(String userId);

  /// Save or update user behavior profile
  Future<void> saveUserBehaviorProfile(UserBehaviorProfile profile);

  /// Delete user behavior profile
  Future<void> deleteUserBehaviorProfile(String userId);

  /// Check if user has a complete behavior profile
  Future<bool> hasCompleteBehaviorProfile(String userId);

  /// Get all user behavior profiles (for admin/analytics)
  Future<List<UserBehaviorProfile>> getAllUserBehaviorProfiles();

  /// Update specific fields of the behavior profile
  Future<void> updateBehaviorProfileFields(
    String userId,
    Map<String, dynamic> updates,
  );
}
