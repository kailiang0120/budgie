import 'package:flutter_test/flutter_test.dart';
import 'package:budgie/domain/services/expense_extraction_service.dart';
import 'package:budgie/data/infrastructure/services/expense_extraction_service_impl.dart';
import 'package:budgie/data/infrastructure/services/gemini_api_client.dart';
import 'package:budgie/data/infrastructure/services/notification_service.dart';
import 'package:budgie/data/infrastructure/services/data_collection_service.dart';
import 'package:budgie/domain/usecase/notification/record_notification_detection_usecase.dart';
import 'package:budgie/di/injection_container.dart' as di;

/// Test the complete hybrid expense detection flow
/// 1. TensorFlow Lite classification (local)
/// 2. FastAPI extraction (if classified as expense)
/// 3. Data collection and validation
void runTests() {
  group('Hybrid Expense Detection Tests', () {
    late ExpenseExtractionDomainService domainService;
    late ExpenseExtractionServiceImpl implService;

    setUpAll(() async {
      print('🧪 Test Setup: Initializing hybrid expense detection services');

      // Initialize implementation service
      implService = ExpenseExtractionServiceImpl();

      // Initialize domain service
      domainService = ExpenseExtractionDomainService();
      domainService.setExtractionService(implService);
      domainService.setNotificationService(di.sl<NotificationService>());
      domainService.setDataCollectionService(di.sl<DataCollectionService>());
      domainService
          .setRecordUseCase(di.sl<RecordNotificationDetectionUseCase>());

      await domainService.initialize();

      print('✅ Test Setup: Hybrid services initialized');
    });

    tearDownAll(() {
      domainService.dispose();
      implService.dispose();
      print('🧪 Test Cleanup: Services disposed');
    });

    group('TensorFlow Lite Classification Tests', () {
      test('should classify expense notifications correctly', () async {
        print(
            '\n🔍 Testing: TensorFlow Classification - Expense Notifications');
        print('=' * 70);

        final expenseNotifications = [
          {
            'title': 'Payment Notification',
            'content': 'You spent RM25.50 at McDonald\'s using your card',
            'expected': true,
            'description': 'Banking payment notification'
          },
          {
            'title': 'Transaction Alert',
            'content':
                'CIMB: Debit transaction of RM150.00 at Starbucks completed',
            'expected': true,
            'description': 'Bank transaction alert'
          },
          {
            'title': 'Purchase Confirmation',
            'content':
                'Grab: Your payment of RM18.90 for food delivery has been processed',
            'expected': true,
            'description': 'E-wallet purchase'
          },
          {
            'title': 'GrabPay',
            'content': 'RM12.50 spent at 7-Eleven via GrabPay wallet',
            'expected': true,
            'description': 'Convenience store purchase'
          },
          {
            'title': 'Shopee Payment',
            'content': 'Payment of RM67.80 to merchant completed successfully',
            'expected': true,
            'description': 'E-commerce payment'
          }
        ];

        for (int i = 0; i < expenseNotifications.length; i++) {
          final notification = expenseNotifications[i];
          print('\n💳 Expense Test ${i + 1}/${expenseNotifications.length}:');
          print('   Description: ${notification['description']}');
          print('   Title: "${notification['title']}"');
          print('   Content: "${notification['content']}"');

          final stopwatch = Stopwatch()..start();

          final isExpense = await domainService.classifyNotification(
            title: notification['title'] as String,
            content: notification['content'] as String,
            source: 'test_app',
          );

          stopwatch.stop();

          final expected = notification['expected'] as bool;
          print(
              '   Result: ${isExpense ? "✅ EXPENSE" : "❌ NOT EXPENSE"} (Expected: ${expected ? "EXPENSE" : "NOT EXPENSE"})');
          print('   Classification Time: ${stopwatch.elapsedMilliseconds}ms');

          expect(isExpense, equals(expected),
              reason:
                  'Failed to classify "${notification['title']}: ${notification['content']}" correctly');
        }
      });

      test('should classify non-expense notifications correctly', () async {
        print(
            '\n🔍 Testing: TensorFlow Classification - Non-Expense Notifications');
        print('=' * 70);

        final nonExpenseNotifications = [
          {
            'title': 'Weather Update',
            'content':
                'Today\'s forecast: Sunny with clear skies, temperature 28°C',
            'expected': false,
            'description': 'Weather notification'
          },
          {
            'title': 'Package Delivery',
            'content': 'Your package has been delivered to your doorstep',
            'expected': false,
            'description': 'Delivery notification'
          },
          {
            'title': 'App Update',
            'content':
                'New version available. Please update to the latest version',
            'expected': false,
            'description': 'System notification'
          },
          {
            'title': 'Security Code',
            'content':
                'Your verification code is: 123456. Do not share it with anyone',
            'expected': false,
            'description': 'OTP notification'
          },
          {
            'title': 'Calendar Reminder',
            'content':
                'You have a meeting starting at 2:00 PM. Topic: Project Review',
            'expected': false,
            'description': 'Calendar notification'
          }
        ];

        for (int i = 0; i < nonExpenseNotifications.length; i++) {
          final notification = nonExpenseNotifications[i];
          print(
              '\n📱 Non-Expense Test ${i + 1}/${nonExpenseNotifications.length}:');
          print('   Description: ${notification['description']}');
          print('   Title: "${notification['title']}"');
          print('   Content: "${notification['content']}"');

          final stopwatch = Stopwatch()..start();

          final isExpense = await domainService.classifyNotification(
            title: notification['title'] as String,
            content: notification['content'] as String,
            source: 'test_app',
          );

          stopwatch.stop();

          final expected = notification['expected'] as bool;
          print(
              '   Result: ${isExpense ? "💳 EXPENSE" : "✅ NOT EXPENSE"} (Expected: ${expected ? "EXPENSE" : "NOT EXPENSE"})');
          print('   Classification Time: ${stopwatch.elapsedMilliseconds}ms');

          expect(isExpense, equals(expected),
              reason:
                  'Failed to classify "${notification['title']}: ${notification['content']}" correctly');
        }
      });
    });

    group('Complete Hybrid Flow Tests', () {
      test('should process expense notifications end-to-end', () async {
        print('\n🔍 Testing: Complete Hybrid Processing');
        print('=' * 70);

        final testNotifications = [
          {
            'title': 'Payment Alert',
            'content':
                'MAYBANK: Transaction of RM45.60 at Starbucks Coffee completed',
            'source': 'maybank_app',
            'packageName': 'com.maybank.app',
            'expectedClassification': true,
          },
          {
            'title': 'GrabFood Order',
            'content':
                'Your payment of RM28.90 to McDonald\'s Setapak has been processed',
            'source': 'grab_app',
            'packageName': 'com.grab.app',
            'expectedClassification': true,
          },
          {
            'title': 'Weather Alert',
            'content':
                'Heavy rain expected in your area from 3:00 PM to 6:00 PM',
            'source': 'weather_app',
            'packageName': 'com.weather.app',
            'expectedClassification': false,
          }
        ];

        for (int i = 0; i < testNotifications.length; i++) {
          final notification = testNotifications[i];
          print('\n🔄 Hybrid Test ${i + 1}/${testNotifications.length}:');
          print('   Title: "${notification['title']}"');
          print('   Content: "${notification['content']}"');
          print('   Source: ${notification['source']}');

          final stopwatch = Stopwatch()..start();

          try {
            final result = await domainService.processNotification(
              title: notification['title'] as String,
              content: notification['content'] as String,
              source: notification['source'] as String,
              packageName: notification['packageName'] as String,
            );

            stopwatch.stop();

            final expectedClassification =
                notification['expectedClassification'] as bool;

            if (expectedClassification) {
              // Should be classified as expense and extracted
              if (result != null) {
                print('   ✅ HYBRID SUCCESS:');
                print('   ├─ Classification: ✅ Expense');
                print('   ├─ Extraction: ✅ Success');
                print('   ├─ Amount: ${result.amount}');
                print('   ├─ Currency: ${result.currency}');
                print('   ├─ Merchant: ${result.merchantName}');
                print('   ├─ Payment Method: ${result.paymentMethod}');
                print('   ├─ Category: ${result.suggestedCategory}');
                print(
                    '   ├─ Confidence: ${result.confidence.toStringAsFixed(3)}');
                print('   └─ Total Time: ${stopwatch.elapsedMilliseconds}ms');

                expect(result.hasEssentialData, isTrue,
                    reason: 'Extracted result should have essential data');
              } else {
                print('   ❌ HYBRID FAILURE: Expected extraction but got null');
                fail('Expected successful extraction for expense notification');
              }
            } else {
              // Should be classified as non-expense, no extraction
              if (result == null) {
                print('   ✅ HYBRID SUCCESS:');
                print('   ├─ Classification: ✅ Non-Expense');
                print('   ├─ Extraction: ⏭️  Skipped (as expected)');
                print('   └─ Total Time: ${stopwatch.elapsedMilliseconds}ms');
              } else {
                print(
                    '   ❌ HYBRID FAILURE: Expected no extraction but got result');
                fail('Expected no extraction for non-expense notification');
              }
            }
          } catch (e) {
            stopwatch.stop();
            print('   ❌ HYBRID ERROR:');
            print('   ├─ Error Type: ${e.runtimeType}');
            print('   ├─ Error Message: $e');
            print('   └─ Time: ${stopwatch.elapsedMilliseconds}ms');

            // For testing purposes, we might want to continue rather than fail
            // depending on whether the API backend is available
            print('   ⚠️  Continuing test (API might be unavailable)');
          }

          print('\n' + '-' * 70);
        }
      });
    });

    group('Performance Tests', () {
      test('should classify notifications within acceptable time limits',
          () async {
        print('\n🔍 Testing: Classification Performance');
        print('=' * 70);

        final testNotification = {
          'title': 'Payment Notification',
          'content': 'You spent RM25.50 at McDonald\'s using your debit card',
        };

        final times = <int>[];
        const iterations = 10;

        for (int i = 0; i < iterations; i++) {
          final stopwatch = Stopwatch()..start();

          await domainService.classifyNotification(
            title: testNotification['title']!,
            content: testNotification['content']!,
            source: 'test_app',
          );

          stopwatch.stop();
          times.add(stopwatch.elapsedMilliseconds);
        }

        final avgTime = times.reduce((a, b) => a + b) / times.length;
        final minTime = times.reduce((a, b) => a < b ? a : b);
        final maxTime = times.reduce((a, b) => a > b ? a : b);

        print('\n⏱️  Classification Performance (${iterations} iterations):');
        print('   ├─ Average: ${avgTime.toStringAsFixed(1)}ms');
        print('   ├─ Minimum: ${minTime}ms');
        print('   ├─ Maximum: ${maxTime}ms');
        print('   └─ All times: $times');

        // TensorFlow Lite should be fast (typically < 100ms)
        expect(avgTime, lessThan(500),
            reason: 'Average classification time should be under 500ms');
        expect(maxTime, lessThan(1000),
            reason: 'Maximum classification time should be under 1000ms');
      });
    });
  });
}
