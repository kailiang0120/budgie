import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Simplified FastAPI integration test that directly tests HTTP endpoints
/// without dependency injection complexities
void runTests() {
  group('Simple FastAPI Integration Tests', () {
    const baseUrl = 'http://10.0.2.2:8000/v1';

    test('should test expense extraction endpoint with dummy data', () async {
      print('\n🔍 Testing: Direct HTTP API Calls to FastAPI Backend');
      print('=' * 70);
      print('📡 Backend URL: $baseUrl');

      // Test data for expense extraction
      final testCases = [
        {
          'notification_id': 'test_1',
          'notification_text':
              'Payment of \$25.99 to McDonald\'s has been processed from your card ending in 1234',
          'timestamp': DateTime.now().toIso8601String(),
          'description': 'Fast food purchase notification'
        },
        {
          'notification_id': 'test_2',
          'notification_text':
              'Uber trip completed. Total fare: \$18.50 paid with your default payment method',
          'timestamp': DateTime.now().toIso8601String(),
          'description': 'Ride sharing payment notification'
        },
        {
          'notification_id': 'test_3',
          'notification_text':
              'Amazon: Your order total is \$67.89. Thank you for your purchase!',
          'timestamp': DateTime.now().toIso8601String(),
          'description': 'Online shopping notification'
        },
        {
          'notification_id': 'test_4',
          'notification_text':
              'Starbucks payment of \$6.45 processed successfully',
          'timestamp': DateTime.now().toIso8601String(),
          'description': 'Coffee purchase notification'
        }
      ];

      print('\n🧪 Testing Expense Extraction Endpoint:');
      print('   POST $baseUrl/expense-detection/extract-expense');

      for (int i = 0; i < testCases.length; i++) {
        final testCase = testCases[i];
        print(
            '\n📱 Test Case ${i + 1}/${testCases.length}: ${testCase['description']}');
        print('   Notification: "${testCase['notification_text']}"');

        try {
          final stopwatch = Stopwatch()..start();

          final response = await http.post(
            Uri.parse('$baseUrl/expense-detection/extract-expense'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(testCase),
          );

          stopwatch.stop();

          print('   📊 HTTP Response:');
          print('   ├─ Status Code: ${response.statusCode}');
          print('   ├─ Response Time: ${stopwatch.elapsedMilliseconds}ms');

          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            print('   ├─ Success: ✅');
            expect(responseData['success'], isTrue);
            final extractionResult =
                responseData['extraction_result'] as Map<String, dynamic>;
            expect(extractionResult['is_expense'], isTrue);
            print('   ├─ Amount: ${extractionResult['amount'] ?? 'N/A'}');
            print('   ├─ Currency: ${extractionResult['currency'] ?? 'N/A'}');
            print('   ├─ Merchant: ${extractionResult['merchant'] ?? 'N/A'}');
            print(
                '   ├─ Category: ${extractionResult['suggested_category'] ?? 'N/A'}');
            print(
                '   ├─ Confidence: ${extractionResult['confidence'] ?? 'N/A'}');
            print(
                '   ├─ Is Expense: ${extractionResult['is_expense'] ?? 'N/A'}');
            print('   └─ Raw Response: $responseData');
          } else {
            print('   ├─ Success: ❌');
            print('   ├─ Error: ${response.body}');
            print('   └─ Possible Causes:');
            print('     • Endpoint not implemented');
            print('     • Invalid request format');
            print('     • Backend service error');
          }
        } catch (e) {
          print('   ❌ Request Failed:');
          print('   ├─ Error: $e');
          print('   └─ Possible Causes:');
          print('     • FastAPI backend not running on $baseUrl');
          print('     • Network connectivity issues');
          print('     • CORS policy blocking request');
        }

        print('   ' + '-' * 50);
      }
    });

    test('should test budget reallocation endpoint with dummy data', () async {
      print('\n🔍 Testing: Budget Reallocation Analysis');
      print('=' * 70);

      final budgetData = {
        'current_budget': {
          'total_budget': 2500.0,
          'total_remaining': 1200.0,
          'categories': {
            'Food & Dining': {
              'allocated': 600.0,
              'remaining': 150.0,
            },
            'Transportation': {
              'allocated': 300.0,
              'remaining': 165.0,
            },
            'Shopping': {
              'allocated': 400.0,
              'remaining': -20.0, // Over budget
            },
            'Entertainment': {
              'allocated': 200.0,
              'remaining': 140.0,
            },
            'Bills & Utilities': {
              'allocated': 500.0,
              'remaining': 60.0,
            },
            'Other': {
              'allocated': 500.0,
              'remaining': 225.0,
            },
          },
          'savings': 500.0,
          'currency': 'USD',
        },
        'recent_expenses': [
          {
            'id': 'exp_1',
            'amount': 129.99,
            'category_id': 'shopping',
            'category_name': 'Shopping',
            'description': 'New running shoes',
            'date': '2024-01-15',
            'currency': 'USD',
            'merchant': 'Nike Store'
          },
          {
            'id': 'exp_2',
            'amount': 45.99,
            'category_id': 'food_dining',
            'category_name': 'Food & Dining',
            'description': 'Restaurant dinner',
            'date': '2024-01-16',
            'currency': 'USD',
            'merchant': 'Italian Bistro'
          }
        ],
        'category_utilization': {
          'Food & Dining': 0.75,
          'Transportation': 0.45,
          'Shopping': 1.05, // Over budget
          'Entertainment': 0.30,
          'Bills & Utilities': 0.88,
          'Other': 0.55,
        },
        'user_preferences': {
          'priority_categories': ['Bills & Utilities', 'Food & Dining'],
          'savings_goal_percentage': 15.0,
          'risk_tolerance': 'moderate',
          'optimization_focus': 'balance',
          'preserve_emergency_fund': true,
          'minimum_category_buffer': 0.05,
        },
        'spending_behavior_insights': {
          'spending_patterns': {
            'average_monthly_spending': 2300.0,
            'most_active_category': 'Shopping',
            'spending_trend': 'increasing',
            'seasonality': 'moderate'
          },
          'insights': [
            {
              'type': 'overspending',
              'category': 'Shopping',
              'description': 'Shopping category is 5% over budget',
              'confidence': 0.9
            }
          ],
          'recommendations': [
            {
              'title': 'Reduce Shopping Budget',
              'action': 'reallocate_budget',
              'expected_impact': 'save_50_monthly'
            }
          ],
          'reallocations': [
            {
              'from_category': 'Shopping',
              'to_category': 'Savings',
              'amount': 50.0,
              'reason': 'Over budget optimization'
            }
          ],
          'savings_opportunities': [
            {
              'category': 'Shopping',
              'potential_savings': 50.0,
              'confidence': 0.8
            }
          ],
          'potential_monthly_savings': 75.0
        }
      };

      print('💰 Testing Budget Reallocation Endpoint:');
      print('   POST $baseUrl/budget-reallocation/analyze');
      print(
          '   Budget Total: \$${(budgetData['current_budget'] as Map<String, dynamic>)['total_budget']}');
      print(
          '   Categories: ${((budgetData['current_budget'] as Map<String, dynamic>)['categories'] as Map).keys.length}');

      try {
        final stopwatch = Stopwatch()..start();

        final response = await http.post(
          Uri.parse('$baseUrl/budget-reallocation/analyze'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(budgetData),
        );

        stopwatch.stop();

        print('\n   📊 HTTP Response:');
        print('   ├─ Status Code: ${response.statusCode}');
        print('   ├─ Response Time: ${stopwatch.elapsedMilliseconds}ms');

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          print('   ├─ Success: ✅');
          expect(responseData['status'], isNotNull);
          print('   ├─ Status: ${responseData['status'] ?? 'N/A'}');
          final recommendations = responseData['recommendations'] as List;
          print('   ├─ Recommendations: ${recommendations.length}');
          expect(recommendations, isNotNull);
          print('   └─ Raw Response: $responseData');
        } else {
          print('   ├─ Success: ❌');
          print('   └─ Error: ${response.body}');
        }
      } catch (e) {
        print('   ❌ Request Failed: $e');
      }
    });

    test('should test spending behavior analysis endpoint', () async {
      print('\n🔍 Testing: Spending Behavior Analysis');
      print('=' * 70);

      final behaviorData = {
        'historical_expenses': List.generate(30, (index) {
          final categories = [
            {'id': 'food_dining', 'name': 'Food & Dining'},
            {'id': 'transportation', 'name': 'Transportation'},
            {'id': 'shopping', 'name': 'Shopping'},
            {'id': 'entertainment', 'name': 'Entertainment'}
          ];
          final category = categories[index % categories.length];
          return {
            'id': 'hist_exp_$index',
            'amount': 25.0 + (index % 10) * 15.0,
            'category_id': category['id'],
            'category_name': category['name'],
            'description': 'Historical expense $index',
            'date': DateTime.now()
                .subtract(Duration(days: index * 3))
                .toIso8601String(),
            'currency': 'USD',
            'is_recurring': false,
            'merchant': 'Merchant ${index % 5}',
          };
        }),
        'current_budget': {
          'total_budget': 3000.0,
          'remaining_budget': 1500.0,
          'category_budgets': {
            'food_dining': {
              'budget': 700.0,
              'allocated': 700.0,
              'remaining': 350.0
            },
            'transportation': {
              'budget': 400.0,
              'allocated': 400.0,
              'remaining': 200.0
            },
            'shopping': {
              'budget': 500.0,
              'allocated': 500.0,
              'remaining': 250.0
            },
            'entertainment': {
              'budget': 300.0,
              'allocated': 300.0,
              'remaining': 150.0
            },
            'other': {
              'budget': 1100.0,
              'allocated': 1100.0,
              'remaining': 550.0
            },
          },
          'savings': 500.0,
          'currency': 'USD',
        },
        'analysis_depth_months': 6,
        'user_profile': {
          'age_range': '25-34',
          'income_level': 'middle',
          'location': 'urban',
          'lifestyle': 'active',
          'spending_personality': 'balanced_spender',
        }
      };

      print('🧠 Testing Spending Behavior Endpoint:');
      print('   POST $baseUrl/spending-behavior/analyze');
      print(
          '   Historical Expenses: ${(behaviorData['historical_expenses'] as List).length}');
      print(
          '   Analysis Depth: ${behaviorData['analysis_depth_months']} months');

      try {
        final stopwatch = Stopwatch()..start();

        final response = await http.post(
          Uri.parse('$baseUrl/spending-behavior/analyze'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(behaviorData),
        );

        stopwatch.stop();

        print('\n   📊 HTTP Response:');
        print('   ├─ Status Code: ${response.statusCode}');
        print('   ├─ Response Time: ${stopwatch.elapsedMilliseconds}ms');

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          print('   ├─ Success: ✅');
          expect(responseData, isNotNull);
          print('   ├─ Analysis ID: ${responseData['analysis_id'] ?? 'N/A'}');
          print('   ├─ Status: ${responseData['status'] ?? 'N/A'}');
          print(
              '   ├─ Insights Generated: ${(responseData['insights'] as List?)?.length ?? 0}');
          print('   └─ Raw Response: $responseData');
        } else {
          print('   ├─ Success: ❌');
          print('   └─ Error: ${response.body}');
        }
      } catch (e) {
        print('   ❌ Request Failed: $e');
      }
    });

    test('should test service health endpoints', () async {
      print('\n🔍 Testing: Service Health Checks');
      print('=' * 70);

      final services = [
        'expense-detection/health',
        'budget-reallocation/health',
        'spending-behavior/health'
      ];

      final healthStatus = <String, bool>{};

      for (final service in services) {
        print('\n🏥 Health Check: $service');
        try {
          final stopwatch = Stopwatch()..start();
          final response = await http.get(Uri.parse('$baseUrl/$service'));
          stopwatch.stop();

          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            print('   Status: ✅ HEALTHY (200)');
            print('   Response Time: ${stopwatch.elapsedMilliseconds}ms');
            print('   Service Status: ${responseData['status'] ?? 'N/A'}');
            print('   Details: ${responseData['details'] ?? 'N/A'}');
            healthStatus[service] = responseData['status'] == 'healthy';
          } else {
            print('   Status: ❌ UNHEALTHY (${response.statusCode})');
            print('   Response: ${response.body}');
            healthStatus[service] = false;
          }
        } catch (e) {
          print('   Status: ❌ UNREACHABLE');
          print('   Error: $e');
          healthStatus[service] = false;
        }
      }

      print('\n🎯 Overall System Health Summary:');
      final allHealthy = healthStatus.values.every((isHealthy) => isHealthy);
      if (allHealthy) {
        print('   ✅ All services are healthy');
      } else {
        print('   💡 If services are down, ensure FastAPI backend is running:');
        print(
            '      python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000');
        print(
            '   💡 Test manually with: curl http://10.0.2.2:8000/v1/expense-detection/health');
      }
    }, timeout: Timeout(Duration(seconds: 90)));
  });
}
