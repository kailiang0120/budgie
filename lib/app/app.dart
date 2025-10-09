import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../core/constants/routes.dart';
import '../core/router/app_router.dart';
import '../core/router/navigation_keys.dart';
import '../core/router/route_observers.dart';
import '../data/infrastructure/services/settings_service.dart';
import '../di/injection_container.dart' as di;
import '../presentation/screens/analytic_screen.dart';
import '../presentation/screens/goals_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/setting_screen.dart';
import '../presentation/utils/app_constants.dart';
import '../presentation/utils/app_theme.dart';
import '../presentation/viewmodels/analysis_viewmodel.dart';
import '../presentation/viewmodels/budget_viewmodel.dart';
import '../presentation/viewmodels/expenses_viewmodel.dart';
import '../presentation/viewmodels/goals_viewmodel.dart';
import '../presentation/viewmodels/theme_viewmodel.dart';
import 'lifecycle/app_lifecycle_handler.dart';

/// Root widget for the Budgie application.
class BudgieApp extends StatefulWidget {
  const BudgieApp({super.key});

  @override
  State<BudgieApp> createState() => _BudgieAppState();
}

class _BudgieAppState extends State<BudgieApp> with WidgetsBindingObserver {
  final AppLifecycleHandler _lifecycleHandler = AppLifecycleHandler();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _lifecycleHandler.handleResume();
        break;
      case AppLifecycleState.detached:
        _lifecycleHandler.handleDetached();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _providers,
      child: ScreenUtilInit(
        designSize: const Size(430, 952),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, _) {
          if (kDebugMode) {
            Future.delayed(const Duration(milliseconds: 500), () {
              AppConstants.debugTextSizes();
            });
          }
          return _buildMaterialApp();
        },
      ),
    );
  }

  List<SingleChildWidget> get _providers => [
        ChangeNotifierProvider.value(value: di.sl<ThemeViewModel>()),
        ChangeNotifierProvider.value(value: di.sl<ExpensesViewModel>()),
        ChangeNotifierProvider.value(value: di.sl<BudgetViewModel>()),
        ChangeNotifierProvider.value(value: di.sl<AnalysisViewModel>()),
        ChangeNotifierProvider.value(value: di.sl<GoalsViewModel>()),
      ];

  Widget _buildMaterialApp() {
    return Consumer<ThemeViewModel>(
      builder: (context, themeViewModel, _) {
        final theme = themeViewModel.isDarkMode
            ? AppTheme.getDarkTheme(context)
            : AppTheme.getLightTheme(context);

        return MaterialApp(
          title: 'Budgie',
          theme: theme,
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: scaffoldMessengerKey,
          navigatorKey: navigatorKey,
          navigatorObservers: [fabRouteObserver],
          routes: _appRoutes,
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: Routes.splash,
        );
      },
    );
  }

  Map<String, WidgetBuilder> get _appRoutes => {
        Routes.home: (context) => MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: di.sl<SettingsService>()),
              ],
              child: const HomeScreen(),
            ),
        Routes.analytic: (context) => const AnalyticScreen(),
        Routes.settings: (context) => const SettingScreen(),
        Routes.goals: (context) => const GoalsScreen(),
      };
}
