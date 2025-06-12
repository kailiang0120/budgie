import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/routes.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../data/infrastructure/errors/app_error.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // 添加短暂延迟以显示启动屏幕
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      final viewModel = Provider.of<AuthViewModel>(context, listen: false);

      // 强制刷新认证状态
      await viewModel.refreshAuthState();

      if (!mounted) return;

      final route = viewModel.isAuthenticated ? Routes.home : Routes.login;
      debugPrint('认证状态: ${viewModel.isAuthenticated ? "已登录" : "未登录"}');

      if (viewModel.isAuthenticated) {
        debugPrint('当前用户ID: ${FirebaseAuth.instance.currentUser?.uid}');
      }

      // 导航到适当的屏幕
      if (route == Routes.login) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            settings: RouteSettings(name: route),
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionDuration: const Duration(milliseconds: 1200),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacementNamed(route);
      }
    } catch (e, stackTrace) {
      debugPrint('Splash screen error: $e');
      final error = AppError.from(e, stackTrace);
      error.log();

      // 出错时默认导航到登录页面
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero‐wrapped logo
            Hero(
              tag: 'logo',
              child: Container(
                width: size.width * 0.32,
                height: size.width * 0.4,
                decoration: const BoxDecoration(
                  shape: BoxShape.rectangle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/budgie_logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
