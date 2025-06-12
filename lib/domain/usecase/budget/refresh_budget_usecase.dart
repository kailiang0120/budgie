import '../../entities/budget.dart';
import '../../../data/infrastructure/network/connectivity_service.dart';
import '../../../data/infrastructure/services/sync_service.dart';
import 'load_budget_usecase.dart';

/// Use case for refreshing budget data
class RefreshBudgetUseCase {
  final ConnectivityService _connectivityService;
  final SyncService _syncService;
  final LoadBudgetUseCase _loadBudgetUseCase;

  RefreshBudgetUseCase({
    required ConnectivityService connectivityService,
    required SyncService syncService,
    required LoadBudgetUseCase loadBudgetUseCase,
  })  : _connectivityService = connectivityService,
        _syncService = syncService,
        _loadBudgetUseCase = loadBudgetUseCase;

  /// Execute the refresh budget use case
  Future<Budget?> execute(String monthId) async {
    try {
      print('Manual budget refresh requested');

      // Check connectivity
      final isConnected = await _connectivityService.isConnected;

      if (isConnected) {
        // If online, trigger sync first
        await _syncService.syncData(fullSync: true, skipBudgets: false);
      }

      // Then reload budget
      return await _loadBudgetUseCase.execute(monthId, checkCurrency: true);
    } catch (e) {
      print('Error refreshing budget: $e');
      rethrow;
    }
  }
}
