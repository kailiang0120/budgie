import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/responsive_logo.dart';
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
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoFadeAnimation;
  late AuthViewModel _authViewModel;
  bool _isLoading = false;
  bool _isEmailSignInLoading = false;
  bool _showEmailSignIn = false;

  // Controllers for email sign in
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 1000), // Longer duration to sync with hero transition
    );

    _panelAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // start off‐screen below
      end: Offset.zero, // slide into place
    ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0,
            curve: Curves.easeOutCubic))); // Start after hero transition

    // Minimal logo animation - let Hero handle most of the transition
    _logoScaleAnimation = Tween<double>(
      begin: 1.0, // No initial scaling to let Hero handle it
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut), // Sync with hero
    ));

    // Delay the animation start to let Hero transition complete first
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _controller.forward();
      }
    });

    _authViewModel = Provider.of<AuthViewModel>(context, listen: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: size.height, // Ensure the content can fill the screen
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                // Top half with the hero logo
                Expanded(
                  flex: 3,
                  child: SafeArea(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.scale(
                                scale: _logoScaleAnimation.value,
                                child: FadeTransition(
                                  opacity: _logoFadeAnimation,
                                  child: const ResponsiveLogo(
                                    heroTag: 'logo',
                                    logoSize: LogoSize.large,
                                    showShadow: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Bottom half—the login panel
                Expanded(
                  flex: 4, // Give the panel a bit more space
                  child: SlideTransition(
                    position: _panelAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 32.h,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFFBFCF8),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(35.r),
                          topRight: Radius.circular(35.r),
                        ),
                      ),
                      child: _showEmailSignIn
                          ? _buildEmailSignInForm()
                          : _buildSocialLoginButtons(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sign in to continue',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 28.sp,
            fontWeight: FontWeight.w300,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 24.h),

        // Apple Sign-in
        AuthButton(
          label: 'Sign in with Apple',
          leadingIcon: Image.asset(
            'assets/icons/apple_logo.png',
            width: 24.w,
            height: 24.h,
          ),
          backgroundColor: Colors.black,
          onPressed: () {
            // TODO: implement Apple auth
          },
        ),
        SizedBox(height: 16.h),

        // Google Sign-in
        AuthButton(
          label: _isLoading ? 'Signing in...' : 'Sign in with Google',
          leadingIcon: _isLoading
              ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                  ),
                )
              : Image.asset(
                  'assets/icons/google_logo.png',
                  width: 24.w,
                ),
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          onPressed:
              _isLoading || _isEmailSignInLoading ? () {} : _handleGoogleSignIn,
        ),
        SizedBox(height: 16.h),

        // Email Sign-in
        AuthButton(
          label: 'Sign in with Email',
          leadingIcon: Icon(
            Icons.email_outlined,
            size: 24.sp,
            color: Colors.white,
          ),
          backgroundColor: Colors.blue.shade700,
          textColor: Colors.white,
          onPressed: _isLoading || _isEmailSignInLoading
              ? () {}
              : () {
                  setState(() {
                    _showEmailSignIn = true;
                  });
                },
        ),
        SizedBox(height: 16.h),

        // Guest Sign-in
        AuthButton(
          label: 'Continue as Guest',
          leadingIcon: Icon(
            Icons.person_outline,
            size: 24.sp,
            color: Colors.white,
          ),
          backgroundColor: Colors.grey.shade700,
          textColor: Colors.white,
          onPressed: null, // Disabled as anonymous sign-in has been removed
        ),
        const Spacer(),

        TextButton(
          onPressed: () {},
          child: Text(
            '2025 Budgie',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSignInForm() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _showEmailSignIn = false;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    'Sign in with Email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w300,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(width: 48.w), // Balance the back button
              ],
            ),
            SizedBox(height: 24.h),

            // Email field
            CustomTextField(
              controller: _emailController,
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),

            // Password field
            CustomTextField(
              controller: _passwordController,
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icons.lock,
              isPassword: true,
              isRequired: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 24.h),

            // Sign in and Create Account buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isEmailSignInLoading ? null : _handleEmailSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: _isEmailSignInLoading
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.w,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Sign In'),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isEmailSignInLoading ? null : _handleCreateAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: const Text('Create Account'),
                  ),
                ),
              ],
            ),

            Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: TextButton(
                onPressed: () {
                  // TODO: Implement forgot password
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEmailSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isEmailSignInLoading = true;
    });

    try {
      final user = await _authViewModel.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted && user != null) {
        Navigator.pushReplacementNamed(context, Routes.home);
      } else if (mounted) {
        // Show error from AuthViewModel if available
        final error = _authViewModel.error ?? 'Sign-in failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEmailSignInLoading = false;
        });
      }
    }
  }

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isEmailSignInLoading = true;
    });

    try {
      final user = await _authViewModel.signUp(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted && user != null) {
        Navigator.pushReplacementNamed(context, Routes.home);
      } else if (mounted) {
        // Show error from AuthViewModel if available
        final error = _authViewModel.error ?? 'Account creation failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEmailSignInLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Capture the result of the Google sign-in
      final bool signInResult = await _authViewModel.signInWithGoogle();

      // Only navigate to home if sign-in was successful
      if (signInResult && mounted) {
        Navigator.pushReplacementNamed(context, Routes.home);
      } else if (mounted) {
        // User canceled the Google sign-in flow
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign-in was canceled'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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
          onPressed:
              _showEmailSignIn ? _handleEmailSignIn : _handleGoogleSignIn,
        ),
      ),
    );
  }
}
