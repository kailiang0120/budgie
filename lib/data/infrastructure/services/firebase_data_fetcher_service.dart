import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/entities/expense.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/entities/category.dart' as app_category;
import '../../../domain/entities/recurring_expense.dart';
import '../errors/app_error.dart';
import '../network/connectivity_service.dart';
import '../../datasources/local_data_source.dart';

/// Service for fetching expenses and budget data from Firebase with offline support
/// Provides centralized data fetching with proper error handling and synchronization
class FirebaseDataFetcherService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;

  FirebaseDataFetcherService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required LocalDataSource localDataSource,
    required ConnectivityService connectivityService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _localDataSource = localDataSource,
        _connectivityService = connectivityService;

  /// Get current authenticated user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Require authenticated user
  String _requireUserId() {
    final userId = _userId;
    if (userId == null) {
      throw AuthError.unauthenticated();
    }
    return userId;
  }

  /// Fetch expenses data from Firebase with offline fallback
  /// Returns comprehensive expense data for AI prediction analysis
  Future<ExpensesFetchResult> fetchExpensesData({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    bool forceRefresh = false,
  }) async {
    try {
      final userId = _requireUserId();
      debugPrint('🔥 FirebaseDataFetcher: Fetching expenses for user: $userId');

      // Check connectivity
      final isConnected = await _connectivityService.isConnected;
      debugPrint('🔥 Network connectivity: $isConnected');

      if (!isConnected || !forceRefresh) {
        // Try local data first
        debugPrint('🔥 Attempting to fetch from local database...');
        final localExpenses = await _localDataSource.getExpenses();

        if (localExpenses.isNotEmpty && !forceRefresh) {
          debugPrint(
              '🔥 Using local expenses data (${localExpenses.length} items)');
          return ExpensesFetchResult(
            expenses: localExpenses,
            source: DataSource.local,
            lastSyncTime: DateTime.now(),
            totalCount: localExpenses.length,
          );
        }
      }

      if (!isConnected) {
        throw NetworkError('No internet connection available');
      }

      // Fetch from Firebase
      debugPrint('🔥 Fetching expenses from Firebase...');
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .orderBy('date', descending: true);

      // Apply date filters if provided
      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Apply limit if provided
      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      final snapshot = await query.get().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw NetworkError('Firebase fetch timeout'),
          );

      debugPrint('🔥 Retrieved ${snapshot.docs.length} expenses from Firebase');

      // Convert Firebase documents to Expense objects
      final expenses = <Expense>[];
      for (final doc in snapshot.docs) {
        try {
          final expense = _documentToExpense(doc);
          expenses.add(expense);

          // Save to local database for offline access
          await _localDataSource.saveSyncedExpense(expense);
        } catch (e) {
          debugPrint('🔥 Error processing expense document ${doc.id}: $e');
          // Continue processing other documents
        }
      }

      debugPrint('🔥 Successfully processed ${expenses.length} expenses');

      return ExpensesFetchResult(
        expenses: expenses,
        source: DataSource.firebase,
        lastSyncTime: DateTime.now(),
        totalCount: expenses.length,
      );
    } catch (e, stackTrace) {
      debugPrint('🔥 Error fetching expenses: $e');

      if (e is AuthError || e is NetworkError) {
        rethrow;
      }

      // Fallback to local data on error
      try {
        final localExpenses = await _localDataSource.getExpenses();
        debugPrint(
            '🔥 Fallback to local data: ${localExpenses.length} expenses');

        return ExpensesFetchResult(
          expenses: localExpenses,
          source: DataSource.local,
          lastSyncTime: DateTime.now(),
          totalCount: localExpenses.length,
          error: AppError.from(e, stackTrace),
        );
      } catch (localError) {
        throw DataError(
          'Failed to fetch expenses from both Firebase and local storage',
          originalError: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Fetch budget data from Firebase with offline fallback
  /// Returns budget data for AI prediction analysis
  Future<BudgetFetchResult> fetchBudgetData({
    required String monthId,
    bool forceRefresh = false,
  }) async {
    try {
      final userId = _requireUserId();
      debugPrint(
          '🔥 FirebaseDataFetcher: Fetching budget for month: $monthId, user: $userId');

      // Check connectivity
      final isConnected = await _connectivityService.isConnected;
      debugPrint('🔥 Network connectivity: $isConnected');

      if (!isConnected || !forceRefresh) {
        // Try local data first
        debugPrint('🔥 Attempting to fetch budget from local database...');
        final localBudget = await _localDataSource.getBudget(monthId, userId);

        if (localBudget != null && !forceRefresh) {
          debugPrint('🔥 Using local budget data');
          return BudgetFetchResult(
            budget: localBudget,
            source: DataSource.local,
            lastSyncTime: DateTime.now(),
          );
        }
      }

      if (!isConnected) {
        throw NetworkError('No internet connection available');
      }

      // Fetch from Firebase
      debugPrint('🔥 Fetching budget from Firebase...');
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .doc(monthId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw NetworkError('Firebase budget fetch timeout'),
          );

      if (!doc.exists) {
        debugPrint('🔥 Budget not found in Firebase for month: $monthId');
        return BudgetFetchResult(
          budget: null,
          source: DataSource.firebase,
          lastSyncTime: DateTime.now(),
        );
      }

      final data = doc.data();
      if (data == null) {
        debugPrint('🔥 Budget document exists but has no data');
        return BudgetFetchResult(
          budget: null,
          source: DataSource.firebase,
          lastSyncTime: DateTime.now(),
        );
      }

      final budget = Budget.fromMap(data);
      debugPrint('🔥 Successfully fetched budget from Firebase');

      // Save to local database
      await _localDataSource.saveBudget(monthId, budget, userId,
          isSynced: true);
      await _localDataSource.markBudgetAsSynced(monthId, userId);

      return BudgetFetchResult(
        budget: budget,
        source: DataSource.firebase,
        lastSyncTime: DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint('🔥 Error fetching budget: $e');

      if (e is AuthError || e is NetworkError) {
        rethrow;
      }

      // Fallback to local data on error
      try {
        final userId = _requireUserId();
        final localBudget = await _localDataSource.getBudget(monthId, userId);
        debugPrint('🔥 Fallback to local budget data');

        return BudgetFetchResult(
          budget: localBudget,
          source: DataSource.local,
          lastSyncTime: DateTime.now(),
          error: AppError.from(e, stackTrace),
        );
      } catch (localError) {
        throw DataError(
          'Failed to fetch budget from both Firebase and local storage',
          originalError: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Store AI prediction results in Firebase for historical analysis
  Future<void> storePredictionResult({
    required String monthId,
    required DateTime predictionDate,
    required Map<String, dynamic> predictionData,
  }) async {
    try {
      final userId = _requireUserId();
      debugPrint(
          '🔥 Storing AI prediction result for user: $userId, month: $monthId');

      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        debugPrint(
            '🔥 No connectivity - prediction will be stored when online');
        // TODO: Add to sync queue for later storage
        return;
      }

      final predictionId =
          '${monthId}_${predictionDate.millisecondsSinceEpoch}';

      final predictionDoc = {
        'userId': userId,
        'monthId': monthId,
        'predictionDate': Timestamp.fromDate(predictionDate),
        'targetDate': predictionData['metadata']?['targetDate'],
        'predictionData': predictionData,
        'createdAt': FieldValue.serverTimestamp(),
        'aiModel': predictionData['metadata']?['aiModel'] ?? 'unknown',
        'predictionType':
            predictionData['metadata']?['predictionType'] ?? 'daily',
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ai_predictions')
          .doc(predictionId)
          .set(predictionDoc)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw NetworkError('Firebase prediction storage timeout'),
          );

      debugPrint('🔥 AI prediction stored successfully with ID: $predictionId');
    } catch (e, stackTrace) {
      debugPrint('🔥 Error storing prediction result: $e');

      if (e is NetworkError) {
        // Log but don't throw - prediction storage is non-critical
        debugPrint('🔥 Network error storing prediction - will retry later');
        return;
      }

      throw DataError(
        'Failed to store AI prediction result',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get historical AI predictions for analysis
  Future<List<Map<String, dynamic>>> getHistoricalPredictions({
    String? monthId,
    int limit = 10,
  }) async {
    try {
      final userId = _requireUserId();
      debugPrint('🔥 Fetching historical predictions for user: $userId');

      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        throw NetworkError(
            'Internet connection required for historical predictions');
      }

      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .doc(userId)
          .collection('ai_predictions')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (monthId != null) {
        query = query.where('monthId', isEqualTo: monthId);
      }

      final snapshot = await query.get().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw NetworkError(
                'Firebase historical predictions fetch timeout'),
          );

      final predictions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      debugPrint('🔥 Retrieved ${predictions.length} historical predictions');
      return predictions;
    } catch (e, stackTrace) {
      debugPrint('🔥 Error fetching historical predictions: $e');

      if (e is AuthError || e is NetworkError) {
        rethrow;
      }

      throw DataError(
        'Failed to fetch historical predictions',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Convert Firebase document to Expense object
  Expense _documentToExpense(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    // Parse category
    final categoryString = data['category'] as String?;
    final category = categoryString != null
        ? app_category.CategoryExtension.fromId(categoryString) ??
            app_category.Category.others
        : app_category.Category.others;

    // Parse payment method
    final methodString = data['method'] as String?;
    final method = PaymentMethod.values.firstWhere(
      (e) => e.toString().split('.').last == methodString,
      orElse: () => PaymentMethod.cash,
    );

    // Parse recurring details
    RecurringDetails? recurringDetails;
    final recurringData = data['recurringDetails'] as Map<String, dynamic>?;
    if (recurringData != null) {
      try {
        recurringDetails = RecurringDetails.fromJson(recurringData);
      } catch (e) {
        debugPrint('🔥 Error parsing recurring details for ${doc.id}: $e');
      }
    }

    return Expense(
      id: doc.id,
      remark: data['remark'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: category,
      method: method,
      description: data['description'] as String?,
      currency: data['currency'] as String? ?? 'MYR',
      recurringDetails: recurringDetails,
    );
  }
}

/// Result object for expenses fetch operation
class ExpensesFetchResult {
  final List<Expense> expenses;
  final DataSource source;
  final DateTime lastSyncTime;
  final int totalCount;
  final AppError? error;

  ExpensesFetchResult({
    required this.expenses,
    required this.source,
    required this.lastSyncTime,
    required this.totalCount,
    this.error,
  });

  bool get hasError => error != null;
  bool get isFromCache => source == DataSource.local;
}

/// Result object for budget fetch operation
class BudgetFetchResult {
  final Budget? budget;
  final DataSource source;
  final DateTime lastSyncTime;
  final AppError? error;

  BudgetFetchResult({
    required this.budget,
    required this.source,
    required this.lastSyncTime,
    this.error,
  });

  bool get hasError => error != null;
  bool get isFromCache => source == DataSource.local;
  bool get hasBudget => budget != null;
}

/// Data source enumeration
enum DataSource {
  firebase,
  local,
}
