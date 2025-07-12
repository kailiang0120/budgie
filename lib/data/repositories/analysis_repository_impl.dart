import '../../domain/repositories/analysis_repository.dart';
import '../datasources/analysis_local_data_source.dart';
import '../models/spending_behavior_models.dart';

class AnalysisRepositoryImpl implements AnalysisRepository {
  final AnalysisLocalDataSource _localDataSource;

  AnalysisRepositoryImpl(this._localDataSource);

  @override
  Future<void> saveAnalysis(
    String userId,
    SpendingBehaviorAnalysisResult analysis,
  ) {
    return _localDataSource.saveAnalysis(userId, analysis);
  }

  @override
  Future<SpendingBehaviorAnalysisResult?> getLatestAnalysis(String userId) {
    return _localDataSource.getLatestAnalysis(userId);
  }
}
