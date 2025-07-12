import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../local/database/app_database.dart';
import '../models/spending_behavior_models.dart';

abstract class AnalysisLocalDataSource {
  Future<void> saveAnalysis(
    String userId,
    SpendingBehaviorAnalysisResult analysis,
  );
  Future<SpendingBehaviorAnalysisResult?> getLatestAnalysis(String userId);
}

class AnalysisLocalDataSourceImpl implements AnalysisLocalDataSource {
  final AnalysisResultDao _dao;
  final Uuid _uuid;

  AnalysisLocalDataSourceImpl(this._dao, this._uuid);

  @override
  Future<void> saveAnalysis(
    String userId,
    SpendingBehaviorAnalysisResult analysis,
  ) async {
    final result = AnalysisResult(
      id: _uuid.v4(),
      userId: userId,
      analysisData:
          json.encode(analysis.toJson()), // Correctly encode to JSON string
      createdAt: DateTime.now(),
    );
    await _dao.saveAnalysisResult(result);
  }

  @override
  Future<SpendingBehaviorAnalysisResult?> getLatestAnalysis(
      String userId) async {
    final result = await _dao.getLatestAnalysisResult(userId);
    if (result != null) {
      return SpendingBehaviorAnalysisResult.fromJson(
          json.decode(result.analysisData)
              as Map<String, dynamic>); // Decode from JSON string
    }
    return null;
  }
}
