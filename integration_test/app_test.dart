import 'package:integration_test/integration_test.dart';
import 'package:budgie/di/injection_container.dart' as di;

import 'api_services_test.dart' as api_services;
import 'budget_reallocation_test.dart' as budget_reallocation;
import 'expense_extraction_test.dart' as expense_extraction;
import 'simple_api_test.dart' as simple_api;
import 'spending_behavior_test.dart' as spending_behavior;

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies once for all tests
  await di.init();

  api_services.runTests();
  budget_reallocation.runTests();
  expense_extraction.runTests();
  simple_api.runTests();
  spending_behavior.runTests();
}
