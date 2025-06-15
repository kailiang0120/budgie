import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/routes.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../data/infrastructure/errors/app_error.dart';
import '../widgets/responsive_logo.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthState();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      final viewModel = Provider.of<AuthViewModel>(context, listen: false);

      await viewModel.refreshAuthState();

      if (!mounted) return;

      final route = viewModel.isAuthenticated ? Routes.home : Routes.login;
      debugPrint(
          'Auth State: ${viewModel.isAuthenticated ? "Authenticated" : "Not Authenticated"}');

      if (viewModel.isAuthenticated) {
        debugPrint(
            'Current User ID: ${FirebaseAuth.instance.currentUser?.uid}');
      }

      if (route == Routes.login) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            settings: RouteSettings(name: route),
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionDuration: const Duration(
                milliseconds:
                    800), // Slightly longer for smooth hero transition
            reverseTransitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (_, animation, __, child) {
              // Combination of slide and fade for smooth hero transition
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.15), // Start slightly below center
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(
                  opacity: Tween<double>(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
                  )),
                  child: child,
                ),
              );
            },
          ),
        );
      } else {
        Navigator.of(context).pushReplacementNamed(route);
      }
    } catch (e, stackTrace) {
      debugPrint('Splash screen error: $e');
      final error = AppError.from(e, stackTrace);
      error.log();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Enhanced Hero-wrapped logo with responsive sizing
                  Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: const ResponsiveLogo(
                        heroTag: 'logo',
                        logoSize: LogoSize.extraLarge,
                        showShadow: true,
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: CircularProgressIndicator(
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white70),
                      strokeWidth: 1.w,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
