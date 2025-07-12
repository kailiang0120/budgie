import 'dart:convert';

import '../../domain/entities/user_behavior_profile.dart';
import '../../domain/repositories/user_behavior_repository.dart';
import '../datasources/user_behavior_local_data_source.dart';

/// Implementation of user behavior repository
class UserBehaviorRepositoryImpl implements UserBehaviorRepository {
  final UserBehaviorLocalDataSource _localDataSource;

  UserBehaviorRepositoryImpl(this._localDataSource);

  @override
  Future<UserBehaviorProfile?> getUserBehaviorProfile(String userId) async {
    return _localDataSource.getUserBehaviorProfile(userId);
  }

  @override
  Future<void> saveUserBehaviorProfile(UserBehaviorProfile profile) async {
    return _localDataSource.saveUserBehaviorProfile(profile);
  }

  @override
  Future<void> deleteUserBehaviorProfile(String userId) async {
    return _localDataSource.deleteUserBehaviorProfile(userId);
  }

  @override
  Future<bool> hasCompleteBehaviorProfile(String userId) async {
    final profile = await _localDataSource.getUserBehaviorProfile(userId);
    return profile?.isComplete ?? false;
  }

  @override
  Future<List<UserBehaviorProfile>> getAllUserBehaviorProfiles() async {
    return _localDataSource.getAllUserBehaviorProfiles();
  }

  @override
  Future<void> updateBehaviorProfileFields(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    return _localDataSource.updateUserBehaviorProfileFields(userId, updates);
  }

  @override
  Future<void> cleanupDuplicateProfiles(String userId) async {
    return _localDataSource.cleanupDuplicateProfiles(userId);
  }
}
