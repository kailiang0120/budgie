import 'package:flutter_test/flutter_test.dart';
import 'package:budgie/data/infrastructure/services/gemini_api_client.dart';
import 'package:budgie/di/injection_container.dart' as di;

/// Test the Spending Behavior Analysis FastAPI integration with dummy data
void runTests() {
  group('Spending Behavior Analysis API Tests', () {
    late GeminiApiClient apiClient;

    setUpAll(() async {
      apiClient = di.sl<GeminiApiClient>();
      print('🧪 Test Setup: Spending Behavior Analysis API client initialized');
      print('📡 API Base URL: ${apiClient.currentApiUrl}');
    });

    tearDownAll(() {
      apiClient.dispose();
      print('🧪 Test Cleanup: API client disposed');
    });

    test('should analyze spending behavior with dummy data', () async {
      print('\n🔍 Testing: Spending Behavior Analysis');
      print('=' * 60);

      final testData = {
        'historical_expenses': [
          {
            'amount': 25.50,
            'category_id': 'food',
            'category_name': 'food',
            'date': '2024-01-15T10:30:00Z',
            'currency': 'USD',
            'description': 'Starbucks Coffee',
            'is_recurring': false,
          },
        ],
        'current_budget': {
          'total_budget': 3000.0,
          'remaining_budget': 2100.0,
          'category_budgets': {
            'food': {'budget': 500.0, 'remaining': 350.0},
          },
          'savings': 500.0,
          'currency': 'USD',
        },
        'analysis_depth_months': 6,
        'user_profile': {
          'age_group': '25-34',
          'income_level': 'mid',
          'financial_goals': ['savings', 'investment']
        }
      };

      try {
        final stopwatch = Stopwatch()..start();

        final response = await apiClient.analyzeSpendingBehavior(
          historicalExpenses:
              testData['historical_expenses'] as List<Map<String, dynamic>>,
          currentBudget: testData['current_budget'] as Map<String, dynamic>,
          analysisDepthMonths: testData['analysis_depth_months'] as int,
          userProfile: testData['user_profile'] as Map<String, dynamic>,
        );

        stopwatch.stop();

        print('\n   ✅ API Response:');
        print('   ├─ Success: ${response.isNotEmpty}');
        print('   ├─ Confidence Score: ${response['confidenceScore']}');
        print('   ├─ Response Time: ${stopwatch.elapsedMilliseconds}ms');
        print('   └─ Raw Response: $response');
      } catch (e) {
        print('\n   ❌ API Error:');
        print('   ├─ Error Type: ${e.runtimeType}');
        print('   ├─ Error Message: $e');
        print('   └─ Possible Causes:');
        print('     • FastAPI backend not running');
        print('     • Spending behavior endpoint not implemented');
        print('     • Network connectivity issues');
        print('     • Invalid historical data format');
      }
    });

    test('should handle edge cases in spending analysis', () async {
      print('\n🔍 Testing: Spending Analysis Edge Cases');
      print('=' * 60);

      final edgeCases = [
        {
          'name': 'No Spending History',
          'historical_expenses': <Map<String, dynamic>>[],
          'current_budget': <String, dynamic>{},
          'analysis_depth_months': 1,
          'user_profile': <String, dynamic>{},
        },
        {
          'name': 'Single Large Expense',
          'historical_expenses': [
            {
              'amount': 5000.0,
              'category_id': 'one-time',
              'category_name': 'one-time',
              'date': '2024-01-15T12:00:00Z',
              'currency': 'USD',
              'description': 'Down payment for car',
              'is_recurring': false,
            }
          ],
          'current_budget': <String, dynamic>{},
          'analysis_depth_months': 1,
          'user_profile': <String, dynamic>{},
        }
      ];

      for (int i = 0; i < edgeCases.length; i++) {
        final testCase = edgeCases[i];
        print(
            '\n🧪 Edge Case ${i + 1}/${edgeCases.length}: ${testCase['name']}');

        try {
          final response = await apiClient.analyzeSpendingBehavior(
            historicalExpenses:
                testCase['historical_expenses'] as List<Map<String, dynamic>>,
            currentBudget: testCase['current_budget'] as Map<String, dynamic>,
            analysisDepthMonths: testCase['analysis_depth_months'] as int,
            userProfile: testCase['user_profile'] as Map<String, dynamic>,
          );

          print('\n   ✅ API Response:');
          print('   ├─ Success: ${response.isNotEmpty}');
          print('   ├─ Confidence Score: ${response['confidenceScore']}');
          print('   └─ Raw Response: $response');
        } catch (e) {
          print('   ❌ Error (may be expected): $e');
        }
      }
    });
  });
}
