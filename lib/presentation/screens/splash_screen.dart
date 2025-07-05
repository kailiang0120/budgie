import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/routes.dart';
import '../widgets/responsive_logo.dart';
import '../utils/app_constants.dart';

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
    _navigateToHome();
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

  Future<void> _navigateToHome() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      // Check if this is the first time the user is opening the app
      final prefs = await SharedPreferences.getInstance();
      final bool welcomeCompleted = prefs.getBool('welcome_completed') ?? false;

      if (!welcomeCompleted) {
        // First time user - navigate to welcome screen
        Navigator.of(context).pushReplacementNamed(Routes.welcome);
      } else {
        // Returning user - navigate directly to home screen
        Navigator.of(context).pushReplacementNamed(Routes.home);
      }
    } catch (e) {
      debugPrint('Splash screen error: $e');
      if (mounted) {
        // Fallback to home screen in case of error
        Navigator.of(context).pushReplacementNamed(Routes.home);
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
                  SizedBox(height: AppConstants.spacingHuge.h),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: CircularProgressIndicator(
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white70),
                      strokeWidth: 1.w,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingLarge.h),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: AppConstants.textSizeSmall.sp,
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
