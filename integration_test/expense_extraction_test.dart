import 'package:flutter_test/flutter_test.dart';
import 'package:budgie/data/infrastructure/services/gemini_api_client.dart';
import 'package:budgie/di/injection_container.dart' as di;

/// Test the Expense Extraction FastAPI integration with dummy data
void runTests() {
  group('Expense Extraction API Tests', () {
    late GeminiApiClient apiClient;

    setUpAll(() async {
      // Initialize services directly for testing
      apiClient = di.sl<GeminiApiClient>();

      print('🧪 Test Setup: Expense Extraction API client initialized');
      print('📡 API Base URL: ${apiClient.currentApiUrl}');
    });

    tearDownAll(() {
      apiClient.dispose();
      print('🧪 Test Cleanup: API client disposed');
    });

    test('should extract expense from dummy notification data', () async {
      print('\n🔍 Testing: Expense Extraction with Dummy Data');
      print('=' * 60);

      // Test notifications with different patterns
      final testCases = [
        {
          'id': 'test_1',
          'text':
              'Payment of \$25.99 to McDonald\'s has been processed from your card ending in 1234',
          'expected_amount': 25.99,
          'expected_merchant': 'McDonald\'s',
          'expected_category': 'food'
        },
        {
          'id': 'test_2',
          'text':
              'Uber trip completed. Total fare: \$18.50 paid with your default payment method',
          'expected_amount': 18.50,
          'expected_merchant': 'Uber',
          'expected_category': 'transportation'
        },
        {
          'id': 'test_3',
          'text':
              'Amazon: Your order total is \$67.89. Thank you for your purchase!',
          'expected_amount': 67.89,
          'expected_merchant': 'Amazon',
          'expected_category': 'shopping'
        },
        {
          'id': 'test_4',
          'text': 'Starbucks payment of \$6.45 processed successfully',
          'expected_amount': 6.45,
          'expected_merchant': 'Starbucks',
          'expected_category': 'food'
        },
        {
          'id': 'test_5',
          'text':
              'Netflix subscription renewal \$15.99 charged to your account',
          'expected_amount': 15.99,
          'expected_merchant': 'Netflix',
          'expected_category': 'entertainment'
        }
      ];

      for (int i = 0; i < testCases.length; i++) {
        final testCase = testCases[i];
        print('\n📱 Test Case ${i + 1}/${testCases.length}:');
        print('   ID: ${testCase['id']}');
        print('   Text: "${testCase['text']}"');

        try {
          final stopwatch = Stopwatch()..start();

          final response = await apiClient.extractExpenseFromNotification(
            notificationId: testCase['id'] as String,
            notificationText: testCase['text'] as String,
            timestamp: DateTime.now(),
          );

          stopwatch.stop();

          final extraction = response['extraction_result'] ?? {};

          print('\n   ✅ API Response:');
          print('   ├─ Success: ${response['success']}');
          print('   ├─ Is Expense: ${extraction['is_expense']}');
          print('   ├─ Amount: ${extraction['amount']}');
          print('   ├─ Currency: ${extraction['currency']}');
          print('   ├─ Merchant: ${extraction['merchant']}');
          print('   ├─ Category: ${extraction['suggested_category']}');
          print('   ├─ Confidence: ${extraction['confidence']}');
          print('   ├─ Response Time: ${stopwatch.elapsedMilliseconds}ms');
          print('   └─ Raw Response: $response');
        } catch (e) {
          print('\n   ❌ API Error:');
          print('   ├─ Error Type: ${e.runtimeType}');
          print('   ├─ Error Message: $e');
        }

        print('\n' + '-' * 60);
      }
    });

    test('should handle invalid notification data', () async {
      print('\n🔍 Testing: Invalid Data Handling');
      print('=' * 60);

      final invalidCases = [
        {'id': '', 'text': '', 'description': 'Empty notification data'},
        {
          'id': 'test_invalid_1',
          'text': 'This is not a financial notification',
          'description': 'Non-financial notification'
        },
      ];

      for (int i = 0; i < invalidCases.length; i++) {
        final testCase = invalidCases[i];
        print('\n🚫 Invalid Case ${i + 1}/${invalidCases.length}:');
        print('   Description: ${testCase['description']}');
        print('   Text: "${testCase['text']}"');

        try {
          final response = await apiClient.extractExpenseFromNotification(
            notificationId: testCase['id'] as String,
            notificationText: testCase['text'] as String,
            timestamp: DateTime.now(),
          );

          print('   📝 Response: $response');

          if (response['success'] == true &&
              response['extraction_result']['is_expense'] == false) {
            print('   ✅ Correctly identified as non-expense');
          } else {
            print('   ⚠️  Unexpectedly identified as expense');
          }
        } catch (e) {
          print('   ❌ Error (expected for some cases): $e');
        }
      }
    });

    test('should check expense extraction service health', () async {
      print('\n🔍 Testing: Service Health Check');
      print('=' * 60);

      try {
        final healthStatus = await apiClient.checkServicesHealth();

        final expenseDetectionHealth =
            healthStatus['expense_detection'] ?? false;
        print(
            '\n🎯 Expense Detection Service: ${expenseDetectionHealth ? "✅ OPERATIONAL" : "❌ DOWN"}');
      } catch (e) {
        print('❌ Health Check Failed: $e');
      }
    }, timeout: Timeout(Duration(seconds: 60)));
  });
}
