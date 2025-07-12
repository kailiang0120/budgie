import 'dart:convert';
import 'package:drift/drift.dart';

import '../../domain/entities/user_behavior_profile.dart';
import '../local/database/app_database.dart';

/// Abstract class for user behavior local data source
abstract class UserBehaviorLocalDataSource {
  /// Get user behavior profile from local database
  Future<UserBehaviorProfile?> getUserBehaviorProfile(String userId);

  /// Get all user behavior profiles from local database
  Future<List<UserBehaviorProfile>> getAllUserBehaviorProfiles();

  /// Save user behavior profile to local database
  Future<void> saveUserBehaviorProfile(UserBehaviorProfile profile);

  /// Delete user behavior profile from local database
  Future<void> deleteUserBehaviorProfile(String userId);

  /// Update specific fields of the user behavior profile
  Future<void> updateUserBehaviorProfileFields(
    String userId,
    Map<String, dynamic> updates,
  );

  /// Clean up any duplicate profiles for a user
  Future<void> cleanupDuplicateProfiles(String userId);
}

/// Implementation of user behavior local data source
class UserBehaviorLocalDataSourceImpl implements UserBehaviorLocalDataSource {
  final AppDatabase _database;

  UserBehaviorLocalDataSourceImpl(this._database);

  @override
  Future<UserBehaviorProfile?> getUserBehaviorProfile(String userId) async {
    final profilesData = await (_database.select(_database.userProfiles)
          ..where((tbl) => tbl.userId.equals(userId)))
        .get();

    if (profilesData.isEmpty) {
      return null;
    }

    // If there are multiple profiles for the same user, clean them up
    if (profilesData.length > 1) {
      await _cleanupDuplicateProfiles(userId, profilesData);

      // Get the remaining profile after cleanup
      final cleanedProfile = await (_database.select(_database.userProfiles)
            ..where((tbl) => tbl.userId.equals(userId)))
          .getSingleOrNull();

      return cleanedProfile != null ? _mapDataToEntity(cleanedProfile) : null;
    }

    return _mapDataToEntity(profilesData.first);
  }

  /// Clean up duplicate profiles for a user, keeping the most recent one
  Future<void> _cleanupDuplicateProfiles(
      String userId, List<UserProfile> profiles) async {
    // Sort by updatedAt descending to keep the most recent one
    profiles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Keep the first (most recent) profile and delete the rest
    final profilesToDelete = profiles.skip(1).toList();

    for (final profile in profilesToDelete) {
      await (_database.delete(_database.userProfiles)
            ..where((tbl) => tbl.id.equals(profile.id)))
          .go();
    }
  }

  @override
  Future<List<UserBehaviorProfile>> getAllUserBehaviorProfiles() async {
    final allProfilesData =
        await _database.select(_database.userProfiles).get();
    return allProfilesData.map((data) => _mapDataToEntity(data)).toList();
  }

  @override
  Future<void> saveUserBehaviorProfile(UserBehaviorProfile profile) async {
    // First, check if a profile already exists for this user
    final existingProfile = await (_database.select(_database.userProfiles)
          ..where((tbl) => tbl.userId.equals(profile.userId)))
        .getSingleOrNull();

    if (existingProfile != null) {
      // Update existing profile
      final updatedProfile = profile.copyWith(
        id: existingProfile.id, // Keep the existing ID
        createdAt: DateTime.parse(existingProfile.createdAt
            .toIso8601String()), // Keep original creation time
        updatedAt: DateTime.now(), // Update the modification time
      );

      final profileData = _mapEntityToCompanion(updatedProfile);

      await (_database.update(_database.userProfiles)
            ..where((tbl) => tbl.userId.equals(profile.userId)))
          .write(profileData);
    } else {
      // Insert new profile
      final newProfile = profile.copyWith(
        id: profile.id.isEmpty
            ? DateTime.now().millisecondsSinceEpoch.toString()
            : profile.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final profileData = _mapEntityToCompanion(newProfile);
      await _database.into(_database.userProfiles).insert(profileData);
    }
  }

  @override
  Future<void> deleteUserBehaviorProfile(String userId) async {
    await (_database.delete(_database.userProfiles)
          ..where((tbl) => tbl.userId.equals(userId)))
        .go();
  }

  @override
  Future<void> updateUserBehaviorProfileFields(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    final companion = UserProfilesCompanion(
      incomeStability: updates.containsKey('incomeStability')
          ? Value(updates['incomeStability'])
          : const Value.absent(),
      spendingMentality: updates.containsKey('spendingMentality')
          ? Value(updates['spendingMentality'])
          : const Value.absent(),
      riskAppetite: updates.containsKey('riskAppetite')
          ? Value(updates['riskAppetite'])
          : const Value.absent(),
      monthlyIncome: updates.containsKey('monthlyIncome')
          ? Value(updates['monthlyIncome'])
          : const Value.absent(),
      emergencyFundTarget: updates.containsKey('emergencyFundTarget')
          ? Value(updates['emergencyFundTarget'])
          : const Value.absent(),
      financialLiteracy: updates.containsKey('financialLiteracyLevel')
          ? Value(updates['financialLiteracyLevel'])
          : const Value.absent(),
      dataConsentAcceptedAt: updates.containsKey('dataConsentAcceptedAt')
          ? Value(updates['dataConsentAcceptedAt'])
          : const Value.absent(),
      isComplete: updates.containsKey('isComplete')
          ? Value(updates['isComplete'])
          : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

    await (_database.update(_database.userProfiles)
          ..where((tbl) => tbl.userId.equals(userId)))
        .write(companion);
  }

  /// Clean up any duplicate profiles for a user
  @override
  Future<void> cleanupDuplicateProfiles(String userId) async {
    final profilesData = await (_database.select(_database.userProfiles)
          ..where((tbl) => tbl.userId.equals(userId)))
        .get();

    if (profilesData.length > 1) {
      await _cleanupDuplicateProfiles(userId, profilesData);
    }
  }

  /// Map UserProfileData from Drift to UserBehaviorProfile entity
  UserBehaviorProfile _mapDataToEntity(UserProfile data) {
    return UserBehaviorProfile(
      id: data.id,
      userId: data.userId,
      incomeStability: IncomeStability.values.byName(data.incomeStability),
      spendingMentality:
          SpendingMentality.values.byName(data.spendingMentality),
      riskAppetite: RiskAppetite.values.byName(data.riskAppetite),
      monthlyIncome: data.monthlyIncome,
      emergencyFundTarget: data.emergencyFundTarget,
      financialLiteracyLevel:
          FinancialLiteracyLevel.values.byName(data.financialLiteracy),
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      dataConsentAcceptedAt: data.dataConsentAcceptedAt,
      isComplete: data.isComplete,
    );
  }

  /// Map UserBehaviorProfile entity to UserProfilesCompanion for Drift
  UserProfilesCompanion _mapEntityToCompanion(UserBehaviorProfile entity) {
    return UserProfilesCompanion(
      id: Value(entity.id),
      userId: Value(entity.userId),
      incomeStability: Value(entity.incomeStability.name),
      spendingMentality: Value(entity.spendingMentality.name),
      riskAppetite: Value(entity.riskAppetite.name),
      monthlyIncome: Value(entity.monthlyIncome),
      emergencyFundTarget: Value(entity.emergencyFundTarget),
      financialLiteracy: Value(entity.financialLiteracyLevel.name),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
      dataConsentAcceptedAt: Value(entity.dataConsentAcceptedAt),
      isComplete: Value(entity.isComplete),
    );
  }
}
