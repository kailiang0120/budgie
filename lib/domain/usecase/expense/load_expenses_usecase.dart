import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../entities/expense.dart';
import '../../entities/category.dart' as app_category;
import '../../repositories/expenses_repository.dart';
import '../../../data/infrastructure/errors/app_error.dart';
import '../../../data/infrastructure/monitoring/performance_monitor.dart';
import '../../../data/infrastructure/network/connectivity_service.dart';
import '../../../data/infrastructure/services/sync_service.dart';
import '../../../di/injection_container.dart' as di;

/// Use case for loading expenses from various sources
class LoadExpensesUseCase {
  final ExpensesRepository _expensesRepository;
  final ConnectivityService _connectivityService;

  LoadExpensesUseCase({
    required ExpensesRepository expensesRepository,
    required ConnectivityService connectivityService,
  })  : _expensesRepository = expensesRepository,
        _connectivityService = connectivityService;

  /// Load expenses from local database
  Future<List<Expense>> loadFromLocalDatabase() async {
    try {
      PerformanceMonitor.startTimer('load_local_expenses');
      final localExpenses = await _expensesRepository.getExpenses();
      PerformanceMonitor.stopTimer('load_local_expenses');
      return localExpenses;
    } catch (e, stackTrace) {
      final appError = AppError.from(e, stackTrace);
      appError.log();
      rethrow;
    }
  }

  /// Load expenses from Firestore with pagination
  Future<List<Expense>> loadFromFirestore({int pageSize = 50}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw AuthError.unauthenticated();
      }

      final userId = currentUser.uid;

      PerformanceMonitor.startTimer('load_expenses');

      Query expensesQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .limit(pageSize);

      final snapshot = await expensesQuery.get();
      final expenses = processExpensesDocs(snapshot.docs);

      PerformanceMonitor.stopTimer('load_expenses');
      return expenses;
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

          return Expense(
            id: doc.id,
            remark: documentData['remark'] as String? ?? '',
            amount: amount,
            date: date,
            category: category,
            method: method,
            currency: documentData['currency'] as String? ?? 'MYR',
          );
        })
        .whereType<Expense>()
        .toList(); // Filter out null expenses
  }

  /// Trigger data synchronization
  Future<void> triggerSync() async {
    try {
      debugPrint('🔄 LoadExpensesUseCase: Triggering data synchronization');
      final syncService = di.sl<SyncService>();
      await syncService.syncData(fullSync: true);
      debugPrint('🔄 LoadExpensesUseCase: Data synchronization completed');
    } catch (e) {
      debugPrint(
          '🔄 LoadExpensesUseCase: Error during data synchronization: $e');
    }
  }

  /// Check if device is offline
  Future<bool> get isOffline async {
    return !await _connectivityService.isConnected;
  }
}
