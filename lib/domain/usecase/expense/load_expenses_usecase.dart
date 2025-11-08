import 'package:flutter/foundation.dart';

import '../../entities/expense.dart';
import '../../repositories/expenses_repository.dart';
import '../../../data/infrastructure/errors/app_error.dart';

/// Use case for loading expenses from various sources
class LoadExpensesUseCase {
  final ExpensesRepository _expensesRepository;

  LoadExpensesUseCase({
    required ExpensesRepository expensesRepository,
  }) : _expensesRepository = expensesRepository;

  /// Load expenses from local database
  Future<List<Expense>> loadFromLocalDatabase() async {
    try {
      final localExpenses = await _expensesRepository.getExpenses();
      return localExpenses;
    } catch (e, stackTrace) {
      final appError = AppError.from(e, stackTrace);
      appError.log();
      rethrow;
    }
  }

  /// Execute the load expenses use case
  Future<List<Expense>> execute() async {
    try {
      debugPrint(
          '🔄 LoadExpensesUseCase: Loading expenses from local database');

      // Load expenses from repository directly
      return await _expensesRepository.getExpenses();
    } catch (e) {
      debugPrint('Error loading expenses: $e');
      // If there's an error, try to load from local data
      return await _expensesRepository.getExpenses();
    }
  }
}
