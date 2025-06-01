import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_button.dart';
import '../../core/constants/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _panelAnimation;
  late AuthViewModel _authViewModel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _panelAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // start off‐screen below
      end: Offset.zero, // slide into place
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _authViewModel = Provider.of<AuthViewModel>(context, listen: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: Column(
        children: [
          // Top half with the hero logo
          Expanded(
            flex: 3,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'logo',
                    child: ClipRRect(
                      child: Container(
                        width: size.width * 0.3,
                        height: size.width * 0.37,
                        decoration: const BoxDecoration(
                          shape: BoxShape.rectangle,
                          image: DecorationImage(
                            image: AssetImage('assets/images/budgie_logo.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom half—the login panel—slides up on entry
          SizedBox(
            height: size.height * 0.5,
            child: SlideTransition(
              position: _panelAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFBFCF8),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Sign in to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Apple Sign-in
                    AuthButton(
                      label: 'Sign in with Apple',
                      leadingIcon: Image.asset(
                        'assets/icons/apple_logo.png',
                        width: 24,
                        height: 24,
                      ),
                      backgroundColor: Colors.black,
                      onPressed: () {
                        // TODO: implement Apple auth
                      },
                    ),
                    const SizedBox(height: 16),

                    // Google Sign-in
                    AuthButton(
                      label:
                          _isLoading ? 'Signing in...' : 'Sign in with Google',
                      leadingIcon: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black87),
                              ),
                            )
                          : Image.asset(
                              'assets/icons/google.png',
                              width: 24,
                            ),
                      backgroundColor: Colors.white,
                      textColor: Colors.black87,
                      onPressed: _isLoading ? () {} : _handleGoogleSignIn,
                    ),
                    const Spacer(),

                    TextButton(
                      onPressed: () {
                        // TODO: contact us action
                      },
                      child: const Text(
                        '2025 Budgie',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authViewModel.signInWithGoogle();

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, Routes.home);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _handleGoogleSignIn,
        ),
      ),
    );
  }
}
