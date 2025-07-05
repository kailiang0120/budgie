import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../entities/expense.dart';
import '../../entities/recurring_expense.dart';
import '../../entities/category.dart' as app_category;
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

  /// Load expenses from Firestore with pagination (deprecated - use local database instead)
  @deprecated
  Future<List<Expense>> loadFromFirestore({int pageSize = 50}) async {
    try {
      // This method is deprecated - use local database instead
      debugPrint(
          'loadFromFirestore is deprecated, loading from local database instead');
      return await loadFromLocalDatabase();
    } catch (e, stackTrace) {
      final appError = AppError.from(e, stackTrace);
      appError.log();
      rethrow;
    }
  }

  /// Process expense documents from Firestore
  static List<Expense> processExpensesDocs(List<QueryDocumentSnapshot> docs) {
    return docs
        .map((doc) {
          final data = doc.data();
          if (data == null) {
            // Skip null documents
            return null;
          }

          final documentData = data as Map<String, dynamic>;

          // Handle potential null or missing data safely
          final amount = (documentData['amount'] as num?)?.toDouble() ?? 0.0;
          final timestamp = documentData['date'] as Timestamp?;
          final date = timestamp?.toDate() ?? DateTime.now();
          final categoryString = documentData['category'] as String?;
          final category = categoryString != null
              ? app_category.CategoryExtension.fromId(categoryString) ??
                  app_category.Category.others
              : app_category.Category.others;
          final methodString = documentData['method'] as String?;
          final method = PaymentMethod.values.firstWhere(
            (e) => e.toString().split('.').last == methodString,
            orElse: () => PaymentMethod.cash,
          );

          // Parse recurring details from embedded field
          RecurringDetails? recurringDetails;
          final recurringData =
              documentData['recurringDetails'] as Map<String, dynamic>?;
          if (recurringData != null) {
            try {
              recurringDetails = RecurringDetails.fromJson(recurringData);
            } catch (e) {
              debugPrint(
                  'Error parsing recurring details in LoadExpensesUseCase: $e');
            }
          }

          return Expense(
            id: doc.id,
            remark: documentData['remark'] as String? ?? '',
            amount: amount,
            date: date,
            category: category,
            method: method,
            description: documentData['description'] as String?,
            currency: documentData['currency'] as String? ?? 'MYR',
            recurringDetails: recurringDetails,
          );
        })
        .whereType<Expense>()
        .toList(); // Filter out null expenses
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
