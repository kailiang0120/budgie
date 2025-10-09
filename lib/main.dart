import 'app/app.dart';
import 'app/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const BudgieApp());
}
