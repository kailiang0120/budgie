import 'package:flutter/material.dart';

import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/welcome_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/add_expense_screen.dart';
import '../../presentation/screens/edit_expense_screen.dart';
import '../../presentation/screens/analytic_screen.dart';
import '../../presentation/screens/setting_screen.dart';
import '../../presentation/screens/goals_screen.dart';
import '../../presentation/screens/notification_test_screen.dart';
import '../../domain/entities/expense.dart';
import '../constants/routes.dart';
import 'page_transition.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Special handling for expense screen (modal behavior)
    if (settings.name == Routes.expenses || settings.name == '/add_expense') {
      // Handle prefilled data if provided
      final prefilledData = settings.arguments as Map<String, dynamic>?;
      return PageTransition(
        child: AddExpenseScreen(prefilledData: prefilledData),
        type: TransitionType.slideAndFadeVertical,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        settings: settings,
      );
    }

    // Special handling for edit expense screen (modal behavior)
    if (settings.name == Routes.editExpense) {
      final expense = settings.arguments as Expense;
      return PageTransition(
        child: EditExpenseScreen(expense: expense),
        type: TransitionType.slideAndFadeVertical,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        settings: settings,
      );
    }

    switch (settings.name) {
      case Routes.splash:
        return PageTransition(
          child: const SplashScreen(),
          type: TransitionType.smoothFadeSlide,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          settings: settings,
        );

      case Routes.welcome:
        return PageTransition(
          child: const WelcomeScreen(),
          type: TransitionType.smoothFadeSlide,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          settings: settings,
        );

      case Routes.home:
        return PageTransition(
          child: const HomeScreen(),
          type: TransitionType.smoothFadeSlide,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          settings: settings,
        );

      case Routes.analytic:
        return PageTransition(
          child: const AnalyticScreen(),
          type: TransitionType.smoothFadeSlide,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
          settings: settings,
        );

      case Routes.goals:
        return PageTransition(
          child: const GoalsScreen(),
          type: TransitionType.smoothScale,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutBack,
          settings: settings,
        );

      case Routes.settings:
        return PageTransition(
          child: const SettingScreen(),
          type: TransitionType.materialPageRoute,
          duration: const Duration(milliseconds: 350),
          curve: Curves.fastOutSlowIn,
          settings: settings,
        );

      case Routes.notificationTest:
        return PageTransition(
          child: const NotificationTestScreen(),
          type: TransitionType.smoothFadeSlide,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
          settings: settings,
        );

      default:
        return PageTransition(
          child: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Page Not Found',
                    style: navigatorKey.currentContext != null
                        ? Theme.of(navigatorKey.currentContext!)
                            .textTheme
                            .headlineSmall
                        : const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No route defined for ${settings.name}',
                    style: navigatorKey.currentContext != null
                        ? Theme.of(navigatorKey.currentContext!)
                            .textTheme
                            .bodyMedium
                        : const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          type: TransitionType.smoothFadeSlide,
          settings: settings,
        );
    }
  }
}

/// Global navigation key for accessing Navigator without context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
