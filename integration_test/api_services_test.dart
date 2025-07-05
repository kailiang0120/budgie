import 'package:flutter_test/flutter_test.dart';
import 'package:budgie/data/infrastructure/services/gemini_api_client.dart';
import 'package:budgie/data/infrastructure/services/expense_extraction_service_impl.dart';
import 'package:budgie/data/models/expense_detection_models.dart';
import 'package:budgie/domain/services/budget_reallocation_service.dart';
import 'package:budgie/domain/services/spending_behavior_analysis_service.dart';
import 'package:budgie/data/infrastructure/network/connectivity_service.dart';
import 'package:budgie/di/injection_container.dart' as di;

/// Integration tests for BudgieAI FastAPI backend services
///
/// These tests verify the API communication with dummy data and log responses
/// to ensure the integration is working correctly.
void runTests() {
  group('FastAPI Services Integration Tests', () {
    late GeminiApiClient apiClient;
    late ExpenseExtractionServiceImpl expenseService;
    late BudgetReallocationService budgetService;
    late SpendingBehaviorAnalysisService behaviorService;

    setUpAll(() async {
      // Services are initialized in the main test driver
      apiClient = di.sl<GeminiApiClient>();
      final connectivityService = di.sl<ConnectivityService>();
      apiClient.setConnectivityService(connectivityService);

      expenseService = ExpenseExtractionServiceImpl();
      budgetService = di.sl<BudgetReallocationService>();
      behaviorService = di.sl<SpendingBehaviorAnalysisService>();

      print('🧪 Integration Test Setup: All services initialized');
    });

    tearDownAll(() {
      apiClient.dispose();
      print('🧪 Integration Test Cleanup: Services disposed');
    });

    group('Health Check Tests', () {
      test('should check all services health and log status', () async {
        print('\n🔍 Testing: Health Check for All Services');
        print('=' * 50);

        try {
          // Health check now uses the service, not direct API client
          final apiHealth = await apiClient.checkServicesHealth();
          final expenseHealth = apiHealth['expense_detection'] == true;
          final budgetHealth = apiHealth['budget_reallocation'] == true;
          final behaviorHealth = apiHealth['spending_behavior'] == true;

          print('📊 Health Check Results:');
          print(
              '  • expense_detection: ${expenseHealth ? '✅ HEALTHY' : '❌ UNHEALTHY'}');
          print(
              '  • budget_reallocation: ${budgetHealth ? '✅ HEALTHY' : '❌ UNHEALTHY'}');
          print(
              '  • spending_behavior: ${behaviorHealth ? '✅ HEALTHY' : '❌ UNHEALTHY'}');

          // Log overall system health
          final allHealthy = expenseHealth && budgetHealth && behaviorHealth;
          print(
              '\n🎯 Overall System Health: ${allHealthy ? "✅ ALL SERVICES HEALTHY" : "⚠️  SOME SERVICES DOWN"}');
        } catch (e) {
          print('❌ Health Check Error: $e');
          print(
              '💡 Make sure FastAPI backend is running on http://10.0.2.2:8000');
        }
      }, timeout: Timeout(Duration(seconds: 60)));
    });

    group('Expense Detection Service Tests', () {
      test('should extract expense from notification and log response',
          () async {
        print('\n🔍 Testing: Expense Extraction Service');
        print('=' * 50);

        // Dummy notification data
        final testNotifications = [
          {
            'id': 'test_notification_1',
            'text':
                'Payment of \$25.99 to McDonald\'s has been processed from your card ending in 1234',
            'description': 'Fast food purchase notification'
          },
          {
            'id': 'test_notification_2',
            'text':
                'Uber trip completed. Total fare: \$18.50 paid with your default payment method',
            'description': 'Ride sharing payment notification'
          },
          {
            'id': 'test_notification_3',
            'text':
                'Amazon: Your order total is \$67.89. Thank you for your purchase!',
            'description': 'Online shopping notification'
          },
          {
            'id': 'test_notification_4',
            'text': 'Coffee Bean & Tea Leaf - Transaction approved for \$4.75',
            'description': 'Coffee purchase notification'
          }
        ];

        for (final testData in testNotifications) {
          print('\n📱 Testing Notification: ${testData['description']}');
          print('📝 Notification Text: "${testData['text']}"');

          try {
            final response = await apiClient.extractExpenseFromNotification(
              notificationId: testData['id'] as String,
              notificationText: testData['text'] as String,
              timestamp: DateTime.now(),
            );
            final extraction = response['extraction_result'] ?? {};
            print('✅ Extraction Response:');
            print('   Is Expense: ${extraction['is_expense']}');
            print('   Amount: ${extraction['amount']}');
            print('   Currency: ${extraction['currency']}');
            print('   Merchant: ${extraction['merchant']}');
            print('   Payment Method: ${extraction['payment_method']}');
            print('   Category: ${extraction['suggested_category']}');
            print('   Confidence: ${extraction['confidence']}');
            print('   Transaction Date: ${extraction['transaction_date']}');
            print('   Description: ${extraction['description']}');
            print('   Processing Time: ${response['processing_time_ms']}ms');
            print('   Metadata: ${response['metadata']}');
            print('   Raw Response: $response');
          } catch (e) {
            print('❌ Extraction Error: $e');
            print('💡 Backend might be down or endpoint not implemented');
          }

          print('-' * 30);
        }
      });

      test('should test expense extraction service wrapper', () async {
        print('\n🔍 Testing: Expense Extraction Service Wrapper');
        print('=' * 50);

        const notificationText =
            'Starbucks payment of \$6.45 processed successfully';
        final availableCategories = ['Food & Dining', 'Shopping', 'Other'];

        try {
          final result = await expenseService.extractExpenseDetails(
            notificationText: notificationText,
            source: 'com.bank.app',
            availableCategories: availableCategories,
          );

          print('✅ Service Wrapper Response:');
          print('   Success: ${result != null}');
          print('   Has Valid Expense: ${result?.hasValidData ?? false}');
          if (result != null && result.hasValidData) {
            print('   Expense Amount: ${result.parsedAmount}');
            print('   Expense Category: ${result.suggestedCategory}');
            print('   Expense Merchant: ${result.merchantName}');
          }
          print('   Confidence Score: ${result?.confidence ?? 'N/A'}');
          print('   Raw Response: ${result?.toJson()}');
        } catch (e) {
          print('❌ Service Wrapper Error: $e');
        }
      });
    });

    group('Budget Reallocation Service Tests', () {
      test('should analyze budget reallocation and log recommendations',
          () async {
        print('\n🔍 Testing: Budget Reallocation Service');
        print('=' * 50);

        // Dummy budget data
        final currentBudget = {
          'total_budget': 2500.0,
          'total_remaining': 1200.0,
          'categories': {
            'food': {'allocated': 600.0, 'remaining': 200.0},
            'transportation': {'allocated': 300.0, 'remaining': 150.0},
            'shopping': {'allocated': 400.0, 'remaining': 100.0},
            'entertainment': {'allocated': 200.0, 'remaining': 50.0},
            'utilities': {'allocated': 500.0, 'remaining': 400.0},
            'medical': {'allocated': 150.0, 'remaining': 120.0},
            'travel': {'allocated': 250.0, 'remaining': 200.0},
            'others': {'allocated': 100.0, 'remaining': 80.0},
          },
          'savings': 200.0,
          'currency': 'USD'
        };

        // Dummy recent expenses
        final recentExpenses = [
          {
            'amount': 45.99,
            'category_id': 'food',
            'category_name': 'food',
            'date': '2024-01-15T12:00:00Z',
            'currency': 'USD',
            'description': 'Restaurant dinner',
          },
          {
            'amount': 25.50,
            'category_id': 'transportation',
            'category_name': 'transportation',
            'date': '2024-01-16T08:00:00Z',
            'currency': 'USD',
            'description': 'Uber ride',
          },
          {
            'amount': 129.99,
            'category_id': 'shopping',
            'category_name': 'shopping',
            'date': '2024-01-17T10:00:00Z',
            'currency': 'USD',
            'description': 'New running shoes',
          },
          {
            'amount': 89.99,
            'category_id': 'entertainment',
            'category_name': 'entertainment',
            'date': '2024-01-18T20:00:00Z',
            'currency': 'USD',
            'description': 'Concert tickets',
          }
        ];

        // Category utilization rates
        final categoryUtilization = {
          'food': 0.75,
          'transportation': 0.45,
          'shopping': 0.92,
          'entertainment': 0.65,
          'utilities': 0.88,
          'medical': 0.20,
          'travel': 0.10,
          'others': 0.55,
        };

        // User preferences
        final userPreferences = {
          'risk_tolerance': 'moderate',
          'preserve_emergency_fund': true,
          'minimum_category_buffer': 0.05,
          'financial_goals': ['emergency_fund', 'vacation']
        };

        print('📊 Test Budget Summary:');
        print('   Total Budget: \$${currentBudget['total_budget']}');
        print('   Total Remaining: \$${currentBudget['total_remaining']}');
        print(
            '   Categories: ${(currentBudget['categories'] as Map?)?.keys.length ?? 0}');
        print('   Recent Expenses: ${recentExpenses.length}');
        print('   User Preferences: ${userPreferences['financial_goals']}');

        try {
          final response = await apiClient.analyzeBudgetReallocation(
            currentBudget: currentBudget,
            recentExpenses: recentExpenses,
            categoryUtilization: categoryUtilization,
            userPreferences: userPreferences,
          );

          print('\n✅ Budget Reallocation Analysis:');
          print('   Reallocation Needed: ${response['reallocation_needed']}');
          print('   Confidence Score: ${response['confidence_score']}');
          print('   Recommendations: ${response['recommendations']}');
          print('   Summary: ${response['summary']}');
          print('   Insights: ${response['insights']}');
          print('   Projected Impact: ${response['projected_impact']}');
          print('   Metadata: ${response['metadata']}');
          print('   Raw Response: $response');
        } catch (e) {
          print('❌ Budget Reallocation Error: $e');
          print('💡 Backend might be down or endpoint not implemented');
        }
      });
    });

    group('Spending Behavior Analysis Service Tests', () {
      test('should analyze spending behavior and log insights', () async {
        print('\n🔍 Testing: Spending Behavior Analysis Service');
        print('=' * 50);

        // Dummy historical expenses (6 months)
        final historicalExpenses = List.generate(30, (index) {
          final date = DateTime.now().subtract(Duration(days: index * 6));
          final categories = [
            'food',
            'transportation',
            'shopping',
            'entertainment',
            'utilities'
          ];
          final category = categories[index % categories.length];

          return {
            'amount': 20.0 + (index % 10) * 15.5,
            'category_id': category,
            'category_name': category,
            'date': date.toIso8601String(),
            'currency': 'USD',
            'description': 'Historical ${category} expense',
            'is_recurring': false,
          };
        });

        final currentBudget = {
          'total_budget': 3000.0,
          'remaining_budget': 2100.0,
          'category_budgets': {
            'food': {'budget': 700.0, 'remaining': 350.0},
            'transportation': {'budget': 400.0, 'remaining': 200.0},
            'shopping': {'budget': 500.0, 'remaining': 250.0},
            'entertainment': {'budget': 300.0, 'remaining': 150.0},
            'utilities': {'budget': 600.0, 'remaining': 400.0},
            'others': {'budget': 500.0, 'remaining': 300.0},
          },
          'savings': 500.0,
          'currency': 'USD'
        };

        final userProfile = {
          'age_group': '25-34',
          'income_level': 'middle',
          'financial_goals': ['emergency_fund', 'vacation']
        };

        print('📊 Behavior Analysis Test Data:');
        print('   Historical Expenses: ${historicalExpenses.length} entries');
        print('   Analysis Period: 6 months');
        print(
            '   Budget Categories: ${(currentBudget['category_budgets'] as Map?)?.keys.length ?? 0}');
        print('   User Profile: ${userProfile['financial_goals']}');

        try {
          final response = await apiClient.analyzeSpendingBehavior(
            historicalExpenses: historicalExpenses,
            currentBudget: currentBudget,
            analysisDepthMonths: 6,
            userProfile: userProfile,
          );

          print('\n✅ Spending Behavior Analysis:');
          print('   Patterns: ${response['patterns']}');
          print('   Insights: ${response['insights']}');
          print('   Trends: ${response['trends']}');
          print('   Category Analysis: ${response['categoryAnalysis']}');
          print(
              '   Optimization Suggestions: ${response['optimizationSuggestions']}');
          print('   Confidence Score: ${response['confidenceScore']}');
          print('   Metadata: ${response['metadata']}');
          print('   Raw Response: $response');
        } catch (e) {
          print('❌ Spending Behavior Analysis Error: $e');
          print('💡 Backend might be down or endpoint not implemented');
        }
      });
    });

    group('Error Handling Tests', () {
      test('should handle invalid data gracefully', () async {
        print('\n🔍 Testing: Error Handling with Invalid Data');
        print('=' * 50);

        // Test with invalid notification data
        try {
          await apiClient.extractExpenseFromNotification(
            notificationId: '',
            notificationText: '',
          );
          print('⚠️  Expected error but received success response');
        } catch (e) {
          print('✅ Correctly handled invalid notification data: $e');
        }

        // Test with malformed budget data
        try {
          await apiClient.analyzeBudgetReallocation(
            currentBudget: {'invalid': 'data'},
            recentExpenses: [],
            categoryUtilization: {},
          );
          print('⚠️  Expected error but received success response');
        } catch (e) {
          print('✅ Correctly handled invalid budget data: $e');
        }

        // Test with empty spending data
        try {
          await apiClient.analyzeSpendingBehavior(
            historicalExpenses: [],
            currentBudget: {},
          );
          print('⚠️  Expected error but received success response');
        } catch (e) {
          print('✅ Correctly handled empty spending data: $e');
        }
      });
    });

    group('Performance Tests', () {
      test('should measure API response times', () async {
        print('\n🔍 Testing: API Performance Metrics');
        print('=' * 50);

        final performanceResults = <String, int>{};

        // Test expense extraction performance
        try {
          final stopwatch = Stopwatch()..start();
          await apiClient.extractExpenseFromNotification(
            notificationId: 'perf_test_1',
            notificationText: 'Amazon purchase \$29.99 processed',
          );
          stopwatch.stop();
          performanceResults['expense_extraction'] =
              stopwatch.elapsedMilliseconds;
        } catch (e) {
          print('⚠️  Expense extraction performance test failed: $e');
        }

        // Test budget reallocation performance
        try {
          final stopwatch = Stopwatch()..start();
          await apiClient.analyzeBudgetReallocation(
            currentBudget: {
              'total_amount': 1000.0,
              'categories': {'Food': 500.0}
            },
            recentExpenses: [
              {'amount': 25.0, 'category': 'Food'}
            ],
            categoryUtilization: {'Food': 0.5},
          );
          stopwatch.stop();
          performanceResults['budget_reallocation'] =
              stopwatch.elapsedMilliseconds;
        } catch (e) {
          print('⚠️  Budget reallocation performance test failed: $e');
        }

        // Test spending behavior performance
        try {
          final stopwatch = Stopwatch()..start();
          await apiClient.analyzeSpendingBehavior(
            historicalExpenses: List.generate(
                10,
                (i) => {
                      'amount': 50.0 + i,
                      'category': 'Food',
                      'date': DateTime.now()
                          .subtract(Duration(days: i))
                          .toIso8601String(),
                    }),
            currentBudget: {'total_amount': 2000.0},
          );
          stopwatch.stop();
          performanceResults['spending_behavior'] =
              stopwatch.elapsedMilliseconds;
        } catch (e) {
          print('⚠️  Spending behavior performance test failed: $e');
        }

        print('⏱️  Performance Results:');
        performanceResults.forEach((service, timeMs) {
          final status = timeMs < 5000
              ? '✅ FAST'
              : timeMs < 10000
                  ? '⚠️  MODERATE'
                  : '❌ SLOW';
          print('   $service: ${timeMs}ms $status');
        });

        final avgTime = performanceResults.values.isNotEmpty
            ? performanceResults.values.reduce((a, b) => a + b) /
                performanceResults.values.length
            : 0;
        print('   Average Response Time: ${avgTime.toStringAsFixed(0)}ms');
      });
    });
  });
}
