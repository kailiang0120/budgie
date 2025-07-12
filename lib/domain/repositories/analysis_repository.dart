import '../../data/models/spending_behavior_models.dart';

abstract class AnalysisRepository {
  Future<void> saveAnalysis(
    String userId,
    SpendingBehaviorAnalysisResult analysis,
  );
  Future<SpendingBehaviorAnalysisResult?> getLatestAnalysis(String userId);
}
