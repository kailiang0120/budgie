import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/recurring_expense.dart';
import '../../domain/repositories/recurring_expenses_repository.dart';
import '../infrastructure/errors/app_error.dart';
import '../datasources/local_data_source.dart';
import '../infrastructure/network/connectivity_service.dart';

/// Implementation of RecurringExpensesRepository with offline support
class RecurringExpensesRepositoryImpl implements RecurringExpensesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;

  RecurringExpensesRepositoryImpl({
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

  /// Safely get recurring expenses collection reference
  CollectionReference<Map<String, dynamic>> _getRecurringExpensesCollection() {
    final userId = _requireUserId();
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recurring_expenses');
  }

  @override
  Future<List<RecurringExpense>> getRecurringExpenses() async {
    try {
      _checkAuthentication();

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        // Offline mode: get from local database
        return _localDataSource.getRecurringExpenses();
      }

      // Online mode: get from Firebase and sync to local
      final collection = _getRecurringExpensesCollection();
      final snapshot =
          await collection.orderBy('startDate', descending: true).get();

      final recurringExpenses = snapshot.docs.map((doc) {
        final data = doc.data();
        return _mapFirebaseDocToRecurringExpense(doc.id, data);
      }).toList();

      // Update local database
      for (final recurringExpense in recurringExpenses) {
        await _localDataSource.saveSyncedRecurringExpense(recurringExpense);
      }

      return recurringExpenses;
    } catch (e, stackTrace) {
      if (e is AuthError) {
        rethrow;
      }

      if (e is NetworkError) {
        // If network error, try to get data from local storage
        return _localDataSource.getRecurringExpenses();
      }

      throw DataError('Failed to get recurring expenses: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<RecurringExpense> addRecurringExpense(
      RecurringExpense recurringExpense) async {
    try {
      _checkAuthentication();
      final userId = _requireUserId();
      debugPrint('Adding recurring expense for user: $userId');

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;

      if (isConnected) {
        // Online mode: Save to Firebase first, then sync to local
        final collection = _getRecurringExpensesCollection();
        final recurringExpenseDoc =
            _mapRecurringExpenseToFirebaseDoc(recurringExpense);

        DocumentReference docRef;
        try {
          docRef = await collection.add(recurringExpenseDoc).timeout(
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
            throw NetworkError('Firebase error: ${e.message}', code: e.code);
          }
          rethrow;
        }

        // Create recurring expense with Firebase-generated ID
        final recurringExpenseWithFirebaseId =
            recurringExpense.copyWith(id: docRef.id);

        // Save to local database with the Firebase ID and mark as synced
        await _localDataSource
            .saveSyncedRecurringExpense(recurringExpenseWithFirebaseId);

        return recurringExpenseWithFirebaseId;
      } else {
        // Offline mode: Save to local database and queue for sync
        final offlineId = recurringExpense.id.isEmpty
            ? 'offline_${DateTime.now().millisecondsSinceEpoch}'
            : recurringExpense.id;

        final recurringExpenseWithOfflineId =
            recurringExpense.copyWith(id: offlineId);
        await _localDataSource
            .saveRecurringExpense(recurringExpenseWithOfflineId);

        return recurringExpenseWithOfflineId;
      }
    } catch (e, stackTrace) {
      if (e is AuthError) {
        rethrow;
      }

      if (e is NetworkError) {
        // Network error: Save locally and queue for sync
        final offlineId = recurringExpense.id.isEmpty
            ? 'offline_${DateTime.now().millisecondsSinceEpoch}'
            : recurringExpense.id;

        final recurringExpenseWithOfflineId =
            recurringExpense.copyWith(id: offlineId);
        await _localDataSource
            .saveRecurringExpense(recurringExpenseWithOfflineId);
        return recurringExpenseWithOfflineId;
      }

      throw DataError('Failed to add recurring expense: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> updateRecurringExpense(RecurringExpense recurringExpense) async {
    try {
      _checkAuthentication();

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;

      // Update local database first
      await _localDataSource.updateRecurringExpense(recurringExpense);

      if (!isConnected) {
        // Offline mode: update locally only, sync later
        return;
      }

      // Online mode: update Firebase
      final collection = _getRecurringExpensesCollection();
      final recurringExpenseDoc =
          _mapRecurringExpenseToFirebaseDoc(recurringExpense);
      await collection.doc(recurringExpense.id).update(recurringExpenseDoc);

      // Mark as synced
      await _localDataSource.markRecurringExpenseAsSynced(recurringExpense.id);
    } catch (e, stackTrace) {
      if (e is AuthError) {
        rethrow;
      }

      if (e is NetworkError) {
        // Network error but already updated locally
        return;
      }

      throw DataError('Failed to update recurring expense: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> deleteRecurringExpense(String id) async {
    try {
      _checkAuthentication();

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;

      // Delete from local database first
      await _localDataSource.deleteRecurringExpense(id);

      if (!isConnected) {
        // Offline mode: delete locally only, sync later
        return;
      }

      // Online mode: delete from Firebase
      final collection = _getRecurringExpensesCollection();
      await collection.doc(id).delete();
    } catch (e, stackTrace) {
      if (e is AuthError) {
        rethrow;
      }

      if (e is NetworkError) {
        // Network error but already deleted locally
        return;
      }

      throw DataError('Failed to delete recurring expense: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<List<RecurringExpense>> getActiveRecurringExpenses() async {
    try {
      _checkAuthentication();

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        // Offline mode: get from local database
        return _localDataSource.getActiveRecurringExpenses();
      }

      // Online mode: get from Firebase
      final collection = _getRecurringExpensesCollection();
      final snapshot = await collection
          .where('isActive', isEqualTo: true)
          .orderBy('startDate', descending: false)
          .get();

      final activeRecurringExpenses = snapshot.docs.map((doc) {
        final data = doc.data();
        return _mapFirebaseDocToRecurringExpense(doc.id, data);
      }).toList();

      return activeRecurringExpenses;
    } catch (e, stackTrace) {
      if (e is AuthError) {
        rethrow;
      }

      if (e is NetworkError) {
        // If network error, try to get data from local storage
        return _localDataSource.getActiveRecurringExpenses();
      }

      throw DataError(
          'Failed to get active recurring expenses: ${e.toString()}',
          originalError: e,
          stackTrace: stackTrace);
    }
  }

  @override
  Future<void> updateLastProcessedDate(
      String id, DateTime lastProcessedDate) async {
    try {
      _checkAuthentication();

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;

      // Update local database first
      await _localDataSource.updateRecurringExpenseLastProcessed(
          id, lastProcessedDate);

      if (!isConnected) {
        // Offline mode: update locally only, sync later
        return;
      }

      // Online mode: update Firebase
      final collection = _getRecurringExpensesCollection();
      await collection.doc(id).update({
        'lastProcessedDate': Timestamp.fromDate(lastProcessedDate),
      });
    } catch (e, stackTrace) {
      if (e is AuthError) {
        rethrow;
      }

      if (e is NetworkError) {
        // Network error but already updated locally
        return;
      }

      throw DataError('Failed to update last processed date: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  /// Convert Firebase document to RecurringExpense entity
  RecurringExpense _mapFirebaseDocToRecurringExpense(
      String id, Map<String, dynamic> data) {
    return RecurringExpense(
      id: id,
      frequency: RecurringFrequencyExtension.fromId(data['frequency']) ??
          RecurringFrequency.oneTime,
      dayOfMonth: data['dayOfMonth'] as int?,
      dayOfWeek: data['dayOfWeek'] != null
          ? DayOfWeekExtension.fromId(data['dayOfWeek'])
          : null,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] as bool? ?? true,
      lastProcessedDate: data['lastProcessedDate'] != null
          ? (data['lastProcessedDate'] as Timestamp).toDate()
          : null,
      expenseRemark: data['expenseRemark'] as String? ?? '',
      expenseAmount: (data['expenseAmount'] as num).toDouble(),
      expenseCategoryId: data['expenseCategoryId'] as String? ?? 'others',
      expensePaymentMethod: data['expensePaymentMethod'] as String? ?? 'cash',
      expenseCurrency: data['expenseCurrency'] as String? ?? 'MYR',
      expenseDescription: data['expenseDescription'] as String?,
    );
  }

  /// Convert RecurringExpense entity to Firebase document
  Map<String, dynamic> _mapRecurringExpenseToFirebaseDoc(
      RecurringExpense recurringExpense) {
    return {
      'frequency': recurringExpense.frequency.id,
      'dayOfMonth': recurringExpense.dayOfMonth,
      'dayOfWeek': recurringExpense.dayOfWeek?.id,
      'startDate': Timestamp.fromDate(recurringExpense.startDate),
      'endDate': recurringExpense.endDate != null
          ? Timestamp.fromDate(recurringExpense.endDate!)
          : null,
      'isActive': recurringExpense.isActive,
      'lastProcessedDate': recurringExpense.lastProcessedDate != null
          ? Timestamp.fromDate(recurringExpense.lastProcessedDate!)
          : null,
      'expenseRemark': recurringExpense.expenseRemark,
      'expenseAmount': recurringExpense.expenseAmount,
      'expenseCategoryId': recurringExpense.expenseCategoryId,
      'expensePaymentMethod': recurringExpense.expensePaymentMethod,
      'expenseCurrency': recurringExpense.expenseCurrency,
      'expenseDescription': recurringExpense.expenseDescription,
    };
  }
}
