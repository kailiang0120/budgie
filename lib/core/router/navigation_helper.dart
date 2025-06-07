import 'package:flutter/material.dart';

import 'page_transition.dart';
import 'app_router.dart' show AppRouter, navigatorKey;
import '../constants/routes.dart';

/// Enhanced navigation helper with smooth transitions
class NavigationHelper {
  /// Navigate with specified transition type
  static Future<T?> _navigateWithTransition<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
    TransitionType transitionType = TransitionType.smoothSlideRight,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOutCubic,
  }) async {
    // Create route settings to pass to app router
    final RouteSettings settings = RouteSettings(
      name: routeName,
      arguments: arguments,
    );

    // Get the route from app router to ensure correct screen is used
    final route = AppRouter.generateRoute(settings);

    // Apply custom transition
    final pageRoute = PageTransition(
      // Access the route's widget directly
      child: _extractChildFromRoute(route),
      type: transitionType,
      duration: duration,
      curve: curve,
      settings: settings,
    );

    if (replace) {
      return Navigator.pushReplacement<T, void>(context, pageRoute as Route<T>);
    } else {
      return Navigator.push<T>(context, pageRoute as Route<T>);
    }
  }

  /// Extract child widget from a route
  static Widget _extractChildFromRoute(Route<dynamic> route) {
    // For MaterialPageRoute, PageRouteBuilder, and our custom PageTransition
    if (route is MaterialPageRoute) {
      return route.builder(navigatorKey.currentContext!);
    } else if (route is PageRouteBuilder) {
      return route.pageBuilder(
        navigatorKey.currentContext!,
        Animation<double>.fromValueListenable(
          const AlwaysStoppedAnimation<double>(1.0),
        ),
        Animation<double>.fromValueListenable(
          const AlwaysStoppedAnimation<double>(1.0),
        ),
      );
    } else if (route is PageTransition) {
      return route.child;
    }

    // Fallback for unknown route types
    return const Scaffold(
      body: Center(
        child: Text('Screen not found'),
      ),
    );
  }

  /// Navigate with smooth slide transition
  static Future<T?> navigateWithSlide<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
    TransitionType? customTransition,
  }) async {
    return _navigateWithTransition<T>(
      context,
      routeName,
      arguments: arguments,
      replace: replace,
      transitionType: customTransition ?? TransitionType.smoothSlideRight,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  /// Navigate with fade transition for subtle changes
  static Future<T?> navigateWithFade<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) async {
    return _navigateWithTransition<T>(
      context,
      routeName,
      arguments: arguments,
      replace: replace,
      transitionType: TransitionType.smoothFadeSlide,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
    );
  }

  /// Navigate with scale transition for important screens
  static Future<T?> navigateWithScale<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) async {
    return _navigateWithTransition<T>(
      context,
      routeName,
      arguments: arguments,
      replace: replace,
      transitionType: TransitionType.smoothScale,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutBack,
    );
  }

  /// Navigate with modal-style transition (from bottom)
  static Future<T?> navigateModal<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    return _navigateWithTransition<T>(
      context,
      routeName,
      arguments: arguments,
      replace: false,
      transitionType: TransitionType.slideAndFadeVertical,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  /// Navigate to home with special transition
  static Future<void> navigateToHome(BuildContext context,
      {bool replace = false}) async {
    await navigateWithSlide(
      context,
      Routes.home,
      replace: replace,
      customTransition: TransitionType.smoothSlideRight,
    );
  }

  /// Navigate to settings with Material Design transition
  static Future<void> navigateToSettings(BuildContext context) async {
    await navigateWithFade(context, Routes.settings);
  }

  /// Navigate to profile with scale transition
  static Future<void> navigateToProfile(BuildContext context) async {
    await navigateWithScale(context, Routes.profile);
  }

  /// Navigate to analytics with fade transition
  static Future<void> navigateToAnalytics(BuildContext context) async {
    await navigateWithFade(context, Routes.analytic);
  }

  /// Navigate to add expense as modal
  static Future<void> navigateToAddExpense(BuildContext context) async {
    await navigateModal(context, Routes.expenses);
  }

  /// Go back with smooth transition
  static void goBack(BuildContext context, [Object? result]) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }

  /// Replace current route with smooth transition
  static Future<T?> replace<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    TO? result,
    TransitionType? transition,
  }) async {
    // Create route settings
    final RouteSettings settings = RouteSettings(
      name: routeName,
      arguments: arguments,
    );

    // Get the route from app router
    final route = AppRouter.generateRoute(settings);

    // Apply custom transition
    final pageRoute = PageTransition(
      child: _extractChildFromRoute(route),
      type: transition ?? TransitionType.smoothSlideRight,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      settings: settings,
    );

    return Navigator.pushReplacement<T, TO>(context, pageRoute as Route<T>,
        result: result);
  }

  /// Clear stack and navigate to route
  static Future<T?> navigateAndClearStack<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    TransitionType? transition,
  }) async {
    // Create route settings
    final RouteSettings settings = RouteSettings(
      name: routeName,
      arguments: arguments,
    );

    // Get the route from app router
    final route = AppRouter.generateRoute(settings);

    // Apply custom transition
    final pageRoute = PageTransition(
      child: _extractChildFromRoute(route),
      type: transition ?? TransitionType.smoothFadeSlide,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      settings: settings,
    );

    return Navigator.pushAndRemoveUntil<T>(
      context,
      pageRoute as Route<T>,
      (Route<dynamic> route) => false,
    );
  }
}

/// Extension methods for Navigator for easier smooth transitions
extension NavigatorExtensions on BuildContext {
  /// Navigate with smooth slide transition
  Future<T?> navigateSlide<T extends Object?>(
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) =>
      NavigationHelper.navigateWithSlide<T>(
        this,
        routeName,
        arguments: arguments,
        replace: replace,
      );

  /// Navigate with fade transition
  Future<T?> navigateFade<T extends Object?>(
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) =>
      NavigationHelper.navigateWithFade<T>(
        this,
        routeName,
        arguments: arguments,
        replace: replace,
      );

  /// Navigate with scale transition
  Future<T?> navigateScale<T extends Object?>(
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) =>
      NavigationHelper.navigateWithScale<T>(
        this,
        routeName,
        arguments: arguments,
        replace: replace,
      );

  /// Navigate as modal
  Future<T?> navigateModal<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) =>
      NavigationHelper.navigateModal<T>(
        this,
        routeName,
        arguments: arguments,
      );
}
