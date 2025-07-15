import 'package:flutter/material.dart';

import 'page_transition.dart';
import 'app_router.dart' show navigatorKey;
import '../constants/routes.dart';

import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/setting_screen.dart';
import '../../presentation/screens/goals_screen.dart';
import '../../presentation/screens/analytic_screen.dart';
import '../../presentation/screens/add_expense_screen.dart';
import '../../domain/entities/expense.dart';
import '../../presentation/screens/edit_expense_screen.dart';

/// Enhanced navigation helper with smooth transitions
class NavigationHelper {
  static Future<T?> _navigate<T extends Object?>(
    BuildContext context,
    Widget child,
    String routeName, {
    Object? arguments,
    bool replace = false,
    bool clearStack = false,
    TransitionType transitionType = TransitionType.smoothSlideRight,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOutCubic,
  }) {
    final pageRoute = PageTransition(
      child: child,
      type: transitionType,
      duration: duration,
      curve: curve,
      settings: RouteSettings(name: routeName, arguments: arguments),
    );

    if (clearStack) {
      return Navigator.pushAndRemoveUntil<T>(
        context,
        pageRoute as Route<T>,
        (route) => false,
      );
    } else if (replace) {
      return Navigator.pushReplacement<T, Object?>(
          context, pageRoute as Route<T>);
    } else {
      return Navigator.push<T>(context, pageRoute as Route<T>);
    }
  }

  /// Navigate to home with special transition
  static Future<void> navigateToHome(BuildContext context,
      {bool replace = false}) {
    return _navigate(
      context,
      const HomeScreen(),
      Routes.home,
      replace: replace,
      transitionType: TransitionType.smoothSlideRight,
    );
  }

  /// Navigate to settings with Material Design transition
  static Future<void> navigateToSettings(BuildContext context) {
    return _navigate(
      context,
      const SettingScreen(),
      Routes.settings,
      transitionType: TransitionType.smoothFadeSlide,
      duration: const Duration(milliseconds: 400),
    );
  }

  /// Navigate to profile with scale transition
  static Future<void> navigateToProfile(BuildContext context) {
    return _navigate(
      context,
      const GoalsScreen(),
      Routes.goals,
      transitionType: TransitionType.smoothScale,
      duration: const Duration(milliseconds: 450),
    );
  }

  /// Navigate to analytics with fade transition
  static Future<void> navigateToAnalytics(BuildContext context) {
    return _navigate(
      context,
      const AnalyticScreen(),
      Routes.analytic,
      transitionType: TransitionType.smoothFadeSlide,
      duration: const Duration(milliseconds: 400),
    );
  }

  /// Navigate to add expense as modal
  static Future<T?> navigateToAddExpense<T extends Object?>(
    BuildContext context, {
    Map<String, dynamic>? prefilledData,
  }) {
    return _navigate<T>(
      context,
      AddExpenseScreen(prefilledData: prefilledData),
      Routes.expenses,
      transitionType: TransitionType.slideAndFadeVertical,
      duration: const Duration(milliseconds: 400),
    );
  }

  /// Navigate to edit expense as modal
  static Future<T?> navigateToEditExpense<T extends Object?>(
    BuildContext context,
    Expense expense,
  ) {
    return _navigate<T>(
      context,
      EditExpenseScreen(expense: expense),
      Routes.editExpense,
      transitionType: TransitionType.slideAndFadeVertical,
      duration: const Duration(milliseconds: 400),
    );
  }

  /// Go back with smooth transition
  static void goBack(BuildContext context, [Object? result]) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }
}

/// Extension methods for Navigator for easier smooth transitions
extension NavigatorExtensions on BuildContext {
  /// Navigate to a named route with a specific transition
  Future<T?> navigate<T extends Object?>(
    String routeName, {
    Object? arguments,
    bool replace = false,
    bool clearStack = false,
    TransitionType transition = TransitionType.smoothSlideRight,
  }) {
    final Widget child = _getChildForRoute(routeName, arguments);
    return NavigationHelper._navigate<T>(
      this,
      child,
      routeName,
      arguments: arguments,
      replace: replace,
      clearStack: clearStack,
      transitionType: transition,
    );
  }

  /// Get the widget for a given route name
  Widget _getChildForRoute(String routeName, Object? arguments) {
    switch (routeName) {
      case Routes.home:
        return const HomeScreen();
      case Routes.settings:
        return const SettingScreen();
      case Routes.goals:
        return const GoalsScreen();
      case Routes.analytic:
        return const AnalyticScreen();
      case Routes.expenses:
        return AddExpenseScreen(
            prefilledData: arguments as Map<String, dynamic>?);
      case Routes.editExpense:
        return EditExpenseScreen(expense: arguments as Expense);
      default:
        return Scaffold(
          body: Center(child: Text('No route defined for $routeName')),
        );
    }
  }

  void pop([Object? result]) => NavigationHelper.goBack(this, result);
}
