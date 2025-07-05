import 'dart:convert';
import 'package:drift/drift.dart';

import '../../domain/entities/user_behavior_profile.dart';
import '../local/database/app_database.dart';

/// Abstract class for user behavior local data source
abstract class UserBehaviorLocalDataSource {
  /// Get user behavior profile from local database
  Future<UserBehaviorProfile?> getUserBehaviorProfile(String userId);

  /// Save user behavior profile to local database
  Future<void> saveUserBehaviorProfile(UserBehaviorProfile profile);

  /// Delete user behavior profile from local database
  Future<void> deleteUserBehaviorProfile(String userId);

  /// Update specific fields of the user behavior profile
  Future<void> updateUserBehaviorProfileFields(
    String userId,
    Map<String, dynamic> updates,
  );
}

/// Implementation of user behavior local data source
class UserBehaviorLocalDataSourceImpl implements UserBehaviorLocalDataSource {
  final AppDatabase _database;

  UserBehaviorLocalDataSourceImpl(this._database);

  @override
  Future<UserBehaviorProfile?> getUserBehaviorProfile(String userId) async {
    final profileData = await (_database.select(_database.userProfiles)
          ..where((tbl) => tbl.userId.equals(userId)))
        .getSingleOrNull();

    return profileData != null ? _mapDataToEntity(profileData) : null;
  }

  @override
  Future<void> saveUserBehaviorProfile(UserBehaviorProfile profile) async {
    final profileData = _mapEntityToCompanion(profile);
    await _database
        .into(_database.userProfiles)
        .insertOnConflictUpdate(profileData);
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
      primaryFinancialGoal: updates.containsKey('primaryFinancialGoal')
          ? Value(updates['primaryFinancialGoal'])
          : const Value.absent(),
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
      aiPreferencesJson: updates.containsKey('aiPreferences')
          ? Value(json.encode(updates['aiPreferences']))
          : const Value.absent(),
      categoryPreferencesJson: updates.containsKey('categoryPreferences')
          ? Value(json.encode(updates['categoryPreferences']))
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

  /// Map UserProfileData from Drift to UserBehaviorProfile entity
  UserBehaviorProfile _mapDataToEntity(UserProfile data) {
    return UserBehaviorProfile(
      id: data.id,
      userId: data.userId,
      primaryFinancialGoal:
          FinancialGoalType.values.byName(data.primaryFinancialGoal),
      incomeStability: IncomeStability.values.byName(data.incomeStability),
      spendingMentality:
          SpendingMentality.values.byName(data.spendingMentality),
      riskAppetite: RiskAppetite.values.byName(data.riskAppetite),
      monthlyIncome: data.monthlyIncome,
      emergencyFundTarget: data.emergencyFundTarget,
      aiPreferences:
          AIAutomationPreferences.fromMap(json.decode(data.aiPreferencesJson)),
      categoryPreferences: CategoryPreferences.fromMap(
          json.decode(data.categoryPreferencesJson)),
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      isComplete: data.isComplete,
    );
  }

  /// Map UserBehaviorProfile entity to UserProfilesCompanion for Drift
  UserProfilesCompanion _mapEntityToCompanion(UserBehaviorProfile entity) {
    return UserProfilesCompanion(
      id: Value(entity.id),
      userId: Value(entity.userId),
      primaryFinancialGoal: Value(entity.primaryFinancialGoal.name),
      incomeStability: Value(entity.incomeStability.name),
      spendingMentality: Value(entity.spendingMentality.name),
      riskAppetite: Value(entity.riskAppetite.name),
      monthlyIncome: Value(entity.monthlyIncome),
      emergencyFundTarget: Value(entity.emergencyFundTarget),
      aiPreferencesJson: Value(json.encode(entity.aiPreferences.toMap())),
      categoryPreferencesJson:
          Value(json.encode(entity.categoryPreferences.toMap())),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
      isComplete: Value(entity.isComplete),
    );
  }
}
