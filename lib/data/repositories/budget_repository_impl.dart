import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../infrastructure/errors/app_error.dart';
import '../datasources/local_data_source.dart';
import '../infrastructure/network/connectivity_service.dart';

/// Implementation of BudgetRepository with offline support
class BudgetRepositoryImpl implements BudgetRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;

  BudgetRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required LocalDataSource localDataSource,
    required ConnectivityService connectivityService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _localDataSource = localDataSource,
        _connectivityService = connectivityService;

  /// Gets the current user ID with null safety
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

  /// Checks if user is authenticated
  void _checkAuthentication() {
    if (_userId == null) {
      throw AuthError.unauthenticated();
    }
  }

  /// Gets the Firestore document reference for a budget with proper null safety
  DocumentReference<Map<String, dynamic>> _budgetDoc(String monthId) {
    final userId = _requireUserId();
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(monthId);
  }

  @override
  Future<Budget?> getBudget(String monthId) async {
    try {
      _checkAuthentication();
      final userId = _requireUserId();

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        // Offline mode: get budget from local database
        return _localDataSource.getBudget(monthId, userId);
      }

      // Online mode: get data from Firebase
      final doc = await _budgetDoc(monthId).get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw NetworkError(
              'Firebase budget get timeout - request took too long');
        },
      );
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) {
        return null;
      }

      final budget = Budget.fromMap(data);

      // Only update local cache if it doesn't exist or is out of sync
      final localBudget = await _localDataSource.getBudget(monthId, userId);
      if (localBudget == null) {
        // Local budget doesn't exist, save it
        await _localDataSource.saveBudget(monthId, budget, userId,
            isSynced: true);
        await _localDataSource.markBudgetAsSynced(monthId, userId);
      }

      return budget;
    } catch (e, stackTrace) {
      if (e is AuthError) {
        rethrow;
      }

      if (e is NetworkError) {
        // If network error, try to get data from local storage
        final userId = _userId;
        if (userId != null) {
          return _localDataSource.getBudget(monthId, userId);
        }
        return null;
      }

      throw DataError('Failed to get budget: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> setBudget(String monthId, Budget budget) async {
    try {
      _checkAuthentication();
      final userId = _requireUserId();
      debugPrint('Setting budget for month: $monthId, user: $userId');

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;
      debugPrint('Network connectivity: $isConnected');

      // First check if the budget already exists and is identical
      final existingBudget = await _localDataSource.getBudget(monthId, userId);
      if (existingBudget != null && existingBudget == budget) {
        debugPrint(
            'Budget for month $monthId is identical to existing budget - skipping update');
        return;
      }

      // Save to local database first
      await _localDataSource.saveBudget(monthId, budget, userId,
          isSynced: isConnected); // Mark as synced if we're online
      debugPrint('Budget saved to local database');

      if (!isConnected) {
        // Offline mode: save locally only, sync later
        debugPrint('Offline mode: Budget saved locally only');
        return;
      }

      // Online mode: save to Firebase
      debugPrint('Online mode: Saving budget to Firebase');
      try {
        await _budgetDoc(monthId).set(budget.toMap()).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw NetworkError(
                'Firebase budget save timeout - request took too long');
          },
        );
        debugPrint('Budget saved to Firebase successfully');

        // Mark as synced only if Firebase save succeeded
        await _localDataSource.markBudgetAsSynced(monthId, userId);
        debugPrint('Budget marked as synced in local database');
      } catch (e) {
        debugPrint('Firebase budget save error: $e');
        if (e is FirebaseException) {
          debugPrint('Firebase error code: ${e.code}, message: ${e.message}');
          throw NetworkError('Firebase budget error: ${e.message}',
              code: e.code);
        }
        rethrow;
      }
    } catch (e, stackTrace) {
      if (e is AuthError) {
        rethrow;
      }

      if (e is NetworkError) {
        // Network error but already saved locally, no additional handling needed
        return;
      }

      throw DataError('Failed to set budget: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }
}
