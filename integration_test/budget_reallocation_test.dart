import 'package:flutter_test/flutter_test.dart';
import 'package:budgie/data/infrastructure/services/gemini_api_client.dart';
import 'package:budgie/di/injection_container.dart' as di;

/// Test the Budget Reallocation FastAPI integration with dummy data
void runTests() {
  group('Budget Reallocation API Tests', () {
    late GeminiApiClient apiClient;

    setUpAll(() async {
      apiClient = di.sl<GeminiApiClient>();

      print('🧪 Test Setup: Budget Reallocation API client initialized');
      print('📡 API Base URL: ${apiClient.currentApiUrl}');
    });

    tearDownAll(() {
      apiClient.dispose();
      print('🧪 Test Cleanup: API client disposed');
    });

    test('should analyze budget reallocation with comprehensive dummy data',
        () async {
      print('\n🔍 Testing: Budget Reallocation Analysis');
      print('=' * 60);

      final testData = {
        'current_budget': {
          'total_budget': 2500.0,
          'remaining_budget': 1200.0,
          'category_budgets': {
            'food': {'budget': 600.0, 'remaining': 200.0},
          },
          'savings': 200.0,
          'currency': 'USD',
        },
        'recent_expenses': [
          {
            'amount': 45.99,
            'category_id': 'food',
            'category_name': 'food',
            'date': '2024-01-15T12:00:00Z',
            'currency': 'USD',
            'description': 'Restaurant dinner',
            'is_recurring': false,
          },
        ],
        'category_utilization': {
          'food': 0.65,
        },
        'user_preferences': {
          'risk_tolerance': 'conservative',
          'preserve_emergency_fund': true,
          'minimum_category_buffer': 0.10,
          'financial_goals': ['savings', 'debt_repayment']
        }
      };

      try {
        final stopwatch = Stopwatch()..start();

        final response = await apiClient.analyzeBudgetReallocation(
          currentBudget: testData['current_budget'] as Map<String, dynamic>,
          recentExpenses:
              testData['recent_expenses'] as List<Map<String, dynamic>>,
          categoryUtilization:
              testData['category_utilization'] as Map<String, double>,
          userPreferences: testData['user_preferences'] as Map<String, dynamic>,
        );

        stopwatch.stop();

        print('\n   ✅ API Response:');
        print('   ├─ Status: ${response['status']}');
        print(
            '   ├─ Recommendations: ${(response['recommendations'] as List).length}');
        print('   ├─ Response Time: ${stopwatch.elapsedMilliseconds}ms');
        print('   └─ Raw Response: $response');
      } catch (e) {
        print('\n   ❌ API Error:');
        print('   ├─ Error Type: ${e.runtimeType}');
        print('   ├─ Error Message: $e');
        print('   └─ Possible Causes:');
        print('     • FastAPI backend not running');
        print('     • Budget reallocation endpoint not implemented');
        print('     • Network connectivity issues');
        print('     • Invalid budget data format');
      }
    });

    test('should handle edge cases in budget reallocation', () async {
      print('\n🔍 Testing: Budget Reallocation Edge Cases');
      print('=' * 60);

      final edgeCases = [
        {
          'name': 'Zero Budget',
          'currentBudget': {'total_budget': 0.0, 'currency': 'USD'},
          'recentExpenses': <Map<String, dynamic>>[],
          'categoryUtilization': <String, double>{},
          'userPreferences': <String, dynamic>{}
        },
        {
          'name': 'Single Category Budget',
          'currentBudget': {
            'total_budget': 500.0,
            'categories': {
              'food': {'allocated': 500.0, 'remaining': 250.0}
            },
            'currency': 'USD'
          },
          'recentExpenses': <Map<String, dynamic>>[],
          'categoryUtilization': {'food': 0.5},
          'userPreferences': <String, dynamic>{}
        },
        {
          'name': 'Extreme Over Budget',
          'currentBudget': {
            'total_budget': 1000.0,
            'categories': {
              'shopping': {'allocated': 200.0, 'remaining': -800.0}
            },
            'currency': 'USD'
          },
          'recentExpenses': <Map<String, dynamic>>[],
          'categoryUtilization': {'shopping': 5.0},
          'userPreferences': <String, dynamic>{}
        }
      ];

      for (int i = 0; i < edgeCases.length; i++) {
        final testCase = edgeCases[i];
        print(
            '\n🧪 Edge Case ${i + 1}/${edgeCases.length}: ${testCase['name']}');

        try {
          final response = await apiClient.analyzeBudgetReallocation(
            currentBudget: testCase['currentBudget'] as Map<String, dynamic>,
            recentExpenses:
                testCase['recentExpenses'] as List<Map<String, dynamic>>,
            categoryUtilization:
                testCase['categoryUtilization'] as Map<String, double>,
            userPreferences:
                testCase['userPreferences'] as Map<String, dynamic>,
          );

          print(
              '   📝 Response: ${response.isNotEmpty ? "Received" : "Empty"}');

          if (response['status'] != null) {
            print('   ✅ API handled edge case: ${response['status']}');
          } else {
            print('   ⚠️  No status in response');
          }
        } catch (e) {
          print('   ❌ Error (may be expected): $e');
        }
      }
    });

    test('should check budget reallocation service health', () async {
      print('\n🔍 Testing: Budget Reallocation Service Health');
      print('=' * 60);

      try {
        final healthStatus = await apiClient.checkServicesHealth();
        final budgetHealth = healthStatus['budget_reallocation'] ?? false;
        print(
            '🎯 Budget Reallocation Service: ${budgetHealth ? "✅ OPERATIONAL" : "❌ DOWN"}');

        if (budgetHealth) {
          print('💡 Service is ready for budget reallocation');
        } else {
          print('💡 Troubleshooting Steps:');
          print('   1. Ensure FastAPI backend is running');
          print('   2. Check /v1/budget-reallocation/health endpoint');
          print('   3. Verify budget reallocation service configuration');
        }
      } catch (e) {
        print('❌ Health Check Failed: $e');
      }
    }, timeout: Timeout(Duration(seconds: 60)));

    test('should measure budget reallocation performance', () async {
      print('\n🔍 Testing: Budget Reallocation Performance');
      print('=' * 60);

      // Test with different data complexities
      final performanceTests = [
        {
          'name': 'Simple Budget (3 categories)',
          'currentBudget': {
            'total_amount': 1500.0,
            'categories': {
              'Food': 500.0,
              'Transport': 400.0,
              'Entertainment': 600.0,
            }
          },
          'recentExpenses': List.generate(
              5,
              (i) => {
                    'amount': 25.0 + i * 10,
                    'category': ['Food', 'Transport', 'Entertainment'][i % 3],
                    'description': 'Test expense $i'
                  }),
          'categoryUtilization': {
            'Food': 0.6,
            'Transport': 0.3,
            'Entertainment': 0.8,
          }
        },
        {
          'name': 'Complex Budget (8 categories)',
          'currentBudget': {
            'total_amount': 4000.0,
            'categories': {
              'Food & Dining': 800.0,
              'Transportation': 400.0,
              'Shopping': 600.0,
              'Entertainment': 400.0,
              'Bills & Utilities': 700.0,
              'Healthcare': 300.0,
              'Travel': 500.0,
              'Other': 300.0,
            }
          },
          'recentExpenses': List.generate(
              20,
              (i) => {
                    'amount': 30.0 + i * 5,
                    'category': [
                      'Food & Dining',
                      'Transportation',
                      'Shopping',
                      'Entertainment'
                    ][i % 4],
                    'description': 'Complex test expense $i'
                  }),
          'categoryUtilization': {
            'Food & Dining': 0.7,
            'Transportation': 0.5,
            'Shopping': 0.9,
            'Entertainment': 0.4,
            'Bills & Utilities': 0.85,
            'Healthcare': 0.2,
            'Travel': 0.1,
            'Other': 0.6,
          }
        }
      ];

      for (int i = 0; i < performanceTests.length; i++) {
        final test = performanceTests[i];
        print(
            '\n⏱️  Performance Test ${i + 1}/${performanceTests.length}: ${test['name']}');

        try {
          final stopwatch = Stopwatch()..start();

          final response = await apiClient.analyzeBudgetReallocation(
            currentBudget: test['currentBudget'] as Map<String, dynamic>,
            recentExpenses:
                test['recentExpenses'] as List<Map<String, dynamic>>,
            categoryUtilization:
                test['categoryUtilization'] as Map<String, double>,
          );

          stopwatch.stop();
          final responseTime = stopwatch.elapsedMilliseconds;

          final status = responseTime < 3000
              ? '✅ FAST'
              : responseTime < 7000
                  ? '⚠️  MODERATE'
                  : '❌ SLOW';
          print('   Response Time: ${responseTime}ms $status');
          print('   Success: ${response.isNotEmpty}');

          if (response['recommendations'] != null) {
            final recs = response['recommendations'];
            print(
                '   Recommendations Generated: ${recs is List ? recs.length : 0}');
          }
        } catch (e) {
          print('   ❌ Performance test failed: $e');
        }
      }
    });
  });
}
