import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/recurring_expense.dart';
import '../../domain/entities/category.dart' as app_category;
import '../../domain/repositories/expenses_repository.dart';
import '../infrastructure/errors/app_error.dart';
import '../datasources/local_data_source.dart';
import '../infrastructure/network/connectivity_service.dart';
import 'package:flutter/foundation.dart';

/// Implementation of ExpensesRepository with offline support
class ExpensesRepositoryImpl implements ExpensesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;

  ExpensesRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required LocalDataSource localDataSource,
    required ConnectivityService connectivityService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _localDataSource = localDataSource,
        _connectivityService = connectivityService;

  /// Safely get user ID with null safety
  String? get _userId {
    final user = _auth.currentUser;
    return user?.uid;
  }

  /// Safely gets the current user ID, throws if not authenticated
  String _requireUserId() {
    final userId = _userId;
    if (userId == null) {
      throw AuthError.unauthenticated();
    }
    return userId;
  }

  /// Check authentication status
  void _checkAuthentication() {
    if (_userId == null) {
      throw AuthError.unauthenticated();
    }
  }

  /// Safely get expenses collection reference with proper null safety
  CollectionReference<Map<String, dynamic>> _getExpensesCollection() {
    final userId = _requireUserId();
    return _firestore.collection('users').doc(userId).collection('expenses');
  }

  @override
  Future<List<Expense>> getExpenses() async {
    try {
      _checkAuthentication();

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        // Offline mode: get expenses from local database
        return _localDataSource.getExpenses();
      }

      // Online mode: get data from Firebase and sync to local
      final collection = _getExpensesCollection();
      final snapshot = await collection.orderBy('date', descending: true).get();

      final expenses = snapshot.docs.map((doc) {
        final data = doc.data();
        final categoryString = data['category'] as String?;
        final category = categoryString != null
            ? app_category.CategoryExtension.fromId(categoryString) ??
                app_category.Category.others
            : app_category.Category.others;
        // Parse recurring details from embedded field
        RecurringDetails? recurringDetails;
        final recurringData = data['recurringDetails'] as Map<String, dynamic>?;
        if (recurringData != null) {
          try {
            recurringDetails = RecurringDetails.fromJson(recurringData);
          } catch (e) {
            debugPrint('Error parsing recurring details: $e');
          }
        }

        return Expense(
          id: doc.id,
          remark: data['remark'] as String? ?? '',
          amount: (data['amount'] as num).toDouble(),
          date: (data['date'] as Timestamp).toDate(),
          category: category,
          method: PaymentMethod.values.firstWhere(
            (e) => e.toString() == 'PaymentMethod.${data['method']}',
            orElse: () => PaymentMethod.cash,
          ),
          description: data['description'] as String?,
          currency: data['currency'] as String? ?? 'MYR',
          recurringDetails: recurringDetails,
        );
      }).toList();

      // Update local database
      for (final expense in expenses) {
        await _localDataSource.saveSyncedExpense(expense);
      }

      return expenses;
    } catch (e, stackTrace) {
      if (e is AuthError) {
        rethrow;
      }

      if (e is NetworkError) {
        // If network error, try to get data from local storage
        return _localDataSource.getExpenses();
      }

      throw DataError('Failed to get expenses: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> addExpense(Expense expense) async {
    try {
      _checkAuthentication();
      final userId = _requireUserId();
      debugPrint('Adding expense for user: $userId');

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;
      debugPrint('Network connectivity: $isConnected');

      if (isConnected) {
        // Online mode: Save directly to Firebase first, then sync to local
        debugPrint('Online mode: Saving to Firebase first');

        final collection = _getExpensesCollection();
        debugPrint('Firebase collection path: users/$userId/expenses');

        final expenseDoc = {
          'remark': expense.remark,
          'amount': expense.amount,
          'date': Timestamp.fromDate(expense.date),
          'category': expense.category.id,
          'method': expense.method.toString().split('.').last,
          'description': expense.description,
          'currency': expense.currency,
          'recurringDetails': expense.recurringDetails?.toJson(),
        };

        debugPrint('Expense document to save: $expenseDoc');

        DocumentReference docRef;
        try {
          // Add timeout to prevent hanging
          docRef = await collection.add(expenseDoc).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw NetworkError(
                  'Firebase save timeout - request took too long');
            },
          );
          debugPrint('Firebase save successful! Document ID: ${docRef.id}');
        } catch (e) {
          debugPrint('Firebase save error: $e');
          if (e is FirebaseException) {
            debugPrint('Firebase error code: ${e.code}, message: ${e.message}');
            throw NetworkError('Firebase error: ${e.message}', code: e.code);
          }
          rethrow;
        }

        // Create expense with Firebase-generated ID
        final expenseWithFirebaseId = expense.copyWith(id: docRef.id);

        // Save to local database with the Firebase ID and mark as synced
        await _localDataSource.saveSyncedExpense(expenseWithFirebaseId);
        debugPrint('Successfully saved to local database as synced');
      } else {
        // Offline mode: Save to local database and queue for sync
        debugPrint('Offline mode: Saving to local database');

        // Use timestamp-based ID for offline entries
        final offlineId = expense.id.isEmpty
            ? 'offline_${DateTime.now().millisecondsSinceEpoch}'
            : expense.id;

        final expenseWithOfflineId = expense.copyWith(id: offlineId);
        await _localDataSource.saveExpense(expenseWithOfflineId);
        debugPrint('Saved offline expense with ID: $offlineId');

        // Trigger sync immediately if we have connectivity
        _triggerManualSync();
      }

      debugPrint('addExpense completed successfully');
    } catch (e, stackTrace) {
      debugPrint('Error in addExpense: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is AuthError) {
        debugPrint('Authentication error: ${e.message}');
        rethrow;
      }

      if (e is NetworkError) {
        debugPrint('Network error, falling back to offline mode');
        // Network error: Save locally and queue for sync
        final offlineId = expense.id.isEmpty
            ? 'offline_${DateTime.now().millisecondsSinceEpoch}'
            : expense.id;

        final expenseWithOfflineId = expense.copyWith(id: offlineId);
        await _localDataSource.saveExpense(expenseWithOfflineId);
        debugPrint('Saved as offline expense due to network error: $offlineId');

        // Trigger sync immediately to try again
        _triggerManualSync();
        return;
      }

      debugPrint('Unexpected error type: ${e.runtimeType}');
      throw DataError('Failed to add expense: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  /// Trigger manual sync to process offline expenses
  void _triggerManualSync() {
    try {
      // Trigger sync in background without circular dependency
      Future.delayed(const Duration(milliseconds: 100), () async {
        try {
          final isConnected = await _connectivityService.isConnected;
          if (isConnected) {
            debugPrint(
                'Connection available, sync should be triggered automatically');
          }
        } catch (e) {
          debugPrint('Error checking connectivity for sync: $e');
        }
      });
    } catch (e) {
      debugPrint('Could not trigger sync check: $e');
      // Don't throw - this is just an optimization
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      _checkAuthentication();

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;

      // Update local database first
      await _localDataSource.updateExpense(expense);

      if (!isConnected) {
        // Offline mode: update locally only, sync later
        return;
      }

      // Online mode: update Firebase
      final collection = _getExpensesCollection();
      await collection.doc(expense.id).update({
        'remark': expense.remark,
        'amount': expense.amount,
        'date': Timestamp.fromDate(expense.date),
        'category': expense.category.id,
        'method': expense.method.toString().split('.').last,
        'description': expense.description,
        'currency': expense.currency,
        'recurringDetails': expense.recurringDetails?.toJson(),
      });

      // Mark as synced
      await _localDataSource.markExpenseAsSynced(expense.id);
    } catch (e, stackTrace) {
      if (e is AuthError) {
        rethrow;
      }

      if (e is NetworkError) {
        // Network error but already updated locally, no additional handling needed
        return;
      }

      throw DataError('Failed to update expense: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      _checkAuthentication();

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;

      // Delete from local database first
      await _localDataSource.deleteExpense(id);

      if (!isConnected) {
        // Offline mode: delete locally only, sync later
        return;
      }

      // Online mode: delete from Firebase
      final collection = _getExpensesCollection();
      await collection.doc(id).delete();
    } catch (e, stackTrace) {
      if (e is AuthError) {
        rethrow;
      }

      if (e is NetworkError) {
        // Network error but already deleted locally, no additional handling needed
        return;
      }

      throw DataError('Failed to delete expense: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }
}
