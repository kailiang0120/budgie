import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Quick health check for BudgieAI FastAPI services
/// This script verifies that all required API endpoints are accessible
/// before running the comprehensive integration tests.
void main() async {
  print('🏥 BudgieAI FastAPI Health Check');
  print('=' * 60);
  print('📅 Check Time: ${DateTime.now()}');
  print('🌐 Target: http://localhost:8000/v1');
  print('');

  const baseUrl = 'http://localhost:8000/v1';
  const timeout = Duration(seconds: 10);

  final endpoints = [
    {'name': 'Expense Detection', 'url': '$baseUrl/expense-detection/health'},
    {
      'name': 'Budget Reallocation',
      'url': '$baseUrl/budget-reallocation/health'
    },
    {'name': 'Spending Behavior', 'url': '$baseUrl/spending-behavior/health'},
  ];

  int healthyServices = 0;
  int totalServices = endpoints.length;

  print('🔍 Checking Service Health...');
  print('-' * 60);

  for (final endpoint in endpoints) {
    final serviceName = endpoint['name']!;
    final url = endpoint['url']!;

    try {
      print('\n📡 Testing: $serviceName');
      print('   URL: $url');

      final stopwatch = Stopwatch()..start();

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);

      stopwatch.stop();

      final responseTime = stopwatch.elapsedMilliseconds;

      if (response.statusCode == 200) {
        healthyServices++;
        print('   Status: ✅ HEALTHY');
        print('   Response Time: ${responseTime}ms');

        try {
          final data = json.decode(response.body);
          print('   Service Status: ${data['status'] ?? 'active'}');
        } catch (e) {
          print(
              '   Response: ${response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body}');
        }
      } else {
        print('   Status: ❌ UNHEALTHY (${response.statusCode})');
        print('   Response Time: ${responseTime}ms');
        print(
            '   Error: ${response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body}');
      }
    } catch (e) {
      print('   Status: ❌ UNREACHABLE');
      print('   Error: $e');

      if (e.toString().contains('TimeoutException')) {
        print('   Cause: Service timeout (>${timeout.inSeconds}s)');
      } else if (e.toString().contains('Connection refused')) {
        print('   Cause: Backend not running on localhost:8000');
      }
    }
  }

  print('\n📊 HEALTH CHECK SUMMARY');
  print('=' * 60);

  final healthPercentage = (healthyServices / totalServices * 100).round();
  print(
      '🎯 Overall Health: $healthyServices/$totalServices services healthy ($healthPercentage%)');

  if (healthyServices == totalServices) {
    print('✅ All services are operational - Ready for integration tests!');
    print('');
    print('🚀 Next Steps:');
    print('   • Run: flutter test test/integration/simple_api_test.dart');
    print('   • Run: dart test/run_api_tests.dart');
    exit(0);
  } else {
    print('⚠️  Some services are not responding properly');
    print('');
    print('🔧 Troubleshooting:');
    print('   1. Ensure FastAPI backend is running:');
    print(
        '      python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000');
    print('');
    print('   2. Check if backend started successfully:');
    print('      curl http://localhost:8000/health');
    print('');
    print('   3. Check backend logs for errors');
    print('');
    print('   4. Verify all AI models and dependencies are loaded');
    exit(1);
  }
}
