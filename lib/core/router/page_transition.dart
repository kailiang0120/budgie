import 'package:flutter/material.dart';

enum TransitionType {
  slideRight,
  slideLeft,
  slideUp,
  slideDown,
  fade,
  scale,
  rotate,
  fadeAndScale,
  fadeAndSlideUp,
  fadeAndSlideRight,
  fadeAndSlideLeft,

  // New smooth transition types
  smoothSlideRight,
  smoothSlideLeft,
  smoothFadeSlide,
  elasticSlide,
  materialPageRoute,
  cupertinoPageRoute,
  smoothScale,
  zoomIn,
  zoomOut,
  slideAndFadeVertical,
  parallaxSlide,

  none,
}

/// Enhanced custom page route transition class with smooth animations
class PageTransition extends PageRouteBuilder {
  final Widget child;
  final TransitionType type;
  final Curve curve;
  final Alignment alignment;
  final Duration duration;
  final Duration reverseDuration;

  PageTransition({
    required this.child,
    this.type = TransitionType.smoothSlideRight,
    this.curve = Curves.easeInOutCubic,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 350),
    this.reverseDuration = const Duration(milliseconds: 300),
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          settings: settings,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(
                type, animation, secondaryAnimation, child, curve, alignment);
          },
        );

  static Widget _buildTransition(
    TransitionType type,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    Curve curve,
    Alignment alignment,
  ) {
    final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
    final reverseCurvedAnimation = CurvedAnimation(
      parent: secondaryAnimation,
      curve: curve,
    );

    switch (type) {
      case TransitionType.smoothSlideRight:
        return Stack(
          children: [
            // Outgoing page - slide out to left with fade
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(-0.3, 0),
              ).animate(reverseCurvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.3)
                    .animate(reverseCurvedAnimation),
                child: Container(), // This will be the previous page
              ),
            ),
            // Incoming page - slide in from right with smooth curve
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: child,
              ),
            ),
          ],
        );

      case TransitionType.smoothSlideLeft:
        return Stack(
          children: [
            // Outgoing page - slide out to right with fade
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(0.3, 0),
              ).animate(reverseCurvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.3)
                    .animate(reverseCurvedAnimation),
                child: Container(),
              ),
            ),
            // Incoming page - slide in from left
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: child,
              ),
            ),
          ],
        );

      case TransitionType.smoothFadeSlide:
        return Stack(
          children: [
            // Outgoing page fades and scales down slightly
            FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.0)
                  .animate(reverseCurvedAnimation),
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 0.95)
                    .animate(reverseCurvedAnimation),
                child: Container(),
              ),
            ),
            // Incoming page slides in with fade and slight scale
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0)
                      .animate(curvedAnimation),
                  child: child,
                ),
              ),
            ),
          ],
        );

      case TransitionType.elasticSlide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.elasticOut,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case TransitionType.materialPageRoute:
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.25),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.fastOutSlowIn,
              ),
            ),
            child: child,
          ),
        );

      case TransitionType.cupertinoPageRoute:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.linearToEaseOut,
            ),
          ),
          child: child,
        );

      case TransitionType.smoothScale:
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outgoing page scales down and fades
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 0.8)
                  .animate(reverseCurvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.0)
                    .animate(reverseCurvedAnimation),
                child: Container(),
              ),
            ),
            // Incoming page scales up from small
            ScaleTransition(
              scale:
                  Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            ),
          ],
        );

      case TransitionType.zoomIn:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.bounceOut,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case TransitionType.zoomOut:
        return ScaleTransition(
          scale: Tween<double>(begin: 1.5, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case TransitionType.slideAndFadeVertical:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
              ),
            ),
            child: child,
          ),
        );

      case TransitionType.parallaxSlide:
        return Stack(
          children: [
            // Background page moves slower (parallax effect)
            Transform.translate(
              offset: Offset(-50 * reverseCurvedAnimation.value, 0),
              child: Container(),
            ),
            // Foreground page slides in normally
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          ],
        );

      // Legacy transitions (keeping for backward compatibility)
      case TransitionType.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );

      case TransitionType.scale:
        return ScaleTransition(
          scale: animation,
          alignment: alignment,
          child: child,
        );

      case TransitionType.rotate:
        return RotationTransition(
          turns: animation,
          alignment: alignment,
          child: child,
        );

      case TransitionType.fadeAndScale:
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale:
                Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );

      case TransitionType.fadeAndSlideUp:
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );

      case TransitionType.fadeAndSlideRight:
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );

      case TransitionType.fadeAndSlideLeft:
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.3, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );

      case TransitionType.none:
        return child;
    }
  }
}

/// Screen navigation direction
enum NavDirection { forward, backward }

/// Enhanced route creation with smooth animations
Route createRoute(Widget page,
    {NavDirection direction = NavDirection.forward,
    RouteSettings? settings,
    TransitionType? forwardTransition,
    TransitionType? backwardTransition,
    Duration? duration,
    Curve? curve}) {
  // Use new smooth transitions as defaults
  const defaultForwardTransition = TransitionType.smoothSlideRight;
  const defaultBackwardTransition = TransitionType.smoothSlideLeft;

  TransitionType type = direction == NavDirection.forward
      ? (forwardTransition ?? defaultForwardTransition)
      : (backwardTransition ?? defaultBackwardTransition);

  return PageTransition(
    child: page,
    type: type,
    settings: settings,
    duration: duration ?? const Duration(milliseconds: 350),
    curve: curve ?? Curves.easeInOutCubic,
  );
}
