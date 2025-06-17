import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the necessary services
import '../lib/data/infrastructure/config/firebase_options.dart';
import '../lib/data/infrastructure/services/firebase_data_fetcher_service.dart';
import '../lib/data/infrastructure/network/connectivity_service.dart';
import '../lib/data/datasources/local_data_source_impl.dart';
import '../lib/data/local/database/app_database.dart';

/// Firebase Data Fetching Script
///
/// This script demonstrates how to fetch expenses and budget data from Firebase
/// and test the AI prediction storage functionality.
///
/// Usage: dart run scripts/firebase_data_fetch_script.dart
void main() async {
  print('🚀 Starting Firebase Data Fetch Script...');

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // Initialize services
    final database = AppDatabase();
    final localDataSource = LocalDataSourceImpl(database);
    final connectivityService = ConnectivityServiceImpl();

    final firebaseDataFetcher = FirebaseDataFetcherService(
      localDataSource: localDataSource,
      connectivityService: connectivityService,
    );

    print('✅ Services initialized');

    // Check if user is authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('❌ No authenticated user found');
      print('Please ensure you have a signed-in user to test data fetching');
      return;
    }

    print('👤 Authenticated user: ${currentUser.uid}');

    // Test expense data fetching
    print('\n📊 Testing Expense Data Fetching...');
    try {
      final expensesResult = await firebaseDataFetcher.fetchExpensesData(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        limit: 50,
        forceRefresh: true,
      );

      print('✅ Expenses fetched successfully:');
      print('   - Source: ${expensesResult.source.name}');
      print('   - Count: ${expensesResult.totalCount}');
      print('   - Last sync: ${expensesResult.lastSyncTime}');

      if (expensesResult.hasError) {
        print('   - Warning: ${expensesResult.error?.message}');
      }

      // Display sample expenses
      if (expensesResult.expenses.isNotEmpty) {
        print('\n📋 Sample Expenses:');
        for (int i = 0; i < expensesResult.expenses.length && i < 5; i++) {
          final expense = expensesResult.expenses[i];
          print(
              '   ${i + 1}. ${expense.remark}: ${expense.amount} ${expense.currency} (${expense.category.name})');
        }
      }
    } catch (e) {
      print('❌ Expense fetching failed: $e');
    }

    // Test budget data fetching
    print('\n💰 Testing Budget Data Fetching...');
    try {
      final now = DateTime.now();
      final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final budgetResult = await firebaseDataFetcher.fetchBudgetData(
        monthId: monthId,
        forceRefresh: true,
      );

      print('✅ Budget fetched successfully:');
      print('   - Source: ${budgetResult.source.name}');
      print('   - Has budget: ${budgetResult.hasBudget}');
      print('   - Last sync: ${budgetResult.lastSyncTime}');

      if (budgetResult.hasError) {
        print('   - Warning: ${budgetResult.error?.message}');
      }

      if (budgetResult.hasBudget) {
        final budget = budgetResult.budget!;
        print('\n💸 Budget Details:');
        print('   - Total: ${budget.total} ${budget.currency}');
        print('   - Left: ${budget.left} ${budget.currency}');
        print('   - Saving: ${budget.saving} ${budget.currency}');
        print('   - Categories: ${budget.categories.length}');

        // Display category breakdown
        budget.categories.forEach((categoryId, categoryBudget) {
          print(
              '     * $categoryId: ${categoryBudget.left}/${categoryBudget.budget}');
        });
      }
    } catch (e) {
      print('❌ Budget fetching failed: $e');
    }

    // Test AI prediction storage
    print('\n🤖 Testing AI Prediction Storage...');
    try {
      final now = DateTime.now();
      final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Create sample prediction data
      final samplePredictionData = {
        'predictedExpenses': [
          {
            'categoryId': 'food',
            'categoryName': 'Food',
            'predictedAmount': 25.50,
            'estimatedDate':
                DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'confidence': 0.85,
            'reasoning': 'Based on daily eating patterns',
            'willExceedBudget': false,
            'budgetShortfall': 0.0,
          }
        ],
        'summary': {
          'totalPredictedSpending': 25.50,
          'budgetUtilizationRate': 0.3,
          'riskLevel': 'low',
          'categoriesAtRisk': <String>[],
          'totalBudgetShortfall': 0.0,
        },
        'confidenceScore': 0.85,
        'insights': [
          {
            'type': 'info',
            'category': '',
            'message': 'Your spending pattern looks healthy for tomorrow',
            'impact': 0.0,
            'recommendations': <String>[],
          }
        ],
        'budgetReallocationSuggestions': <Map<String, dynamic>>[],
        'metadata': {
          'aiModel': 'test-model',
          'timestamp': now.toIso8601String(),
          'predictionType': 'daily',
          'targetDate':
              now.add(const Duration(days: 1)).toIso8601String().split('T')[0],
          'version': '1.0',
          'createdAt': now.toIso8601String(),
        },
      };

      await firebaseDataFetcher.storePredictionResult(
        monthId: monthId,
        predictionDate: now,
        predictionData: samplePredictionData,
      );

      print('✅ AI prediction stored successfully');
    } catch (e) {
      print('❌ AI prediction storage failed: $e');
    }

    // Test historical predictions retrieval
    print('\n📈 Testing Historical Predictions Retrieval...');
    try {
      final historicalPredictions =
          await firebaseDataFetcher.getHistoricalPredictions(
        limit: 5,
      );

      print('✅ Historical predictions retrieved successfully:');
      print('   - Count: ${historicalPredictions.length}');

      for (int i = 0; i < historicalPredictions.length; i++) {
        final prediction = historicalPredictions[i];
        print(
            '   ${i + 1}. ${prediction['id']}: ${prediction['predictionType']} (${prediction['monthId']})');
      }
    } catch (e) {
      print('❌ Historical predictions retrieval failed: $e');
    }

    print('\n✅ Firebase Data Fetch Script completed successfully!');
    print('🎯 All Firebase data operations have been tested.');
  } catch (e, stackTrace) {
    print('❌ Script failed with error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  } finally {
    print('\n🧹 Cleaning up resources...');
    // Clean up resources if needed
    exit(0);
  }
}
