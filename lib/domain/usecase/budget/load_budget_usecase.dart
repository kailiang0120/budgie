import 'package:flutter/foundation.dart';
import '../../entities/budget.dart';
import '../../repositories/budget_repository.dart';
import '../../../data/infrastructure/errors/app_error.dart';

import '../../../data/infrastructure/services/settings_service.dart';
import '../../../di/injection_container.dart' as di;
import 'convert_budget_currency_usecase.dart';

/// Use case for loading budget for a specific month
class LoadBudgetUseCase {
  final BudgetRepository _budgetRepository;
  final SettingsService _settingsService;

  LoadBudgetUseCase({
    required BudgetRepository budgetRepository,
    required SettingsService settingsService,
  })  : _budgetRepository = budgetRepository,
        _settingsService = settingsService;

  /// Execute the load budget use case
  Future<Budget?> execute(String monthId, {bool checkCurrency = false}) async {
    try {
      final loadedBudget = await _budgetRepository.getBudget(monthId);

      if (loadedBudget != null) {
        // Log the currency for debugging
        debugPrint('Budget loaded with currency: ${loadedBudget.currency}, '
            'App preferred currency: ${_settingsService.currency}');

        // Check if currency conversion is needed
        if (checkCurrency &&
            loadedBudget.currency != _settingsService.currency) {
          // Trigger currency conversion use case
          final convertUseCase = di.sl<ConvertBudgetCurrencyUseCase>();
          Future.microtask(
              () => convertUseCase.execute(monthId, _settingsService.currency));
        }
      }

      return loadedBudget;
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      rethrow;
    }
  }
}
