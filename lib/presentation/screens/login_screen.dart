import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_button.dart';
import '../widgets/custom_text_field.dart';
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
  bool _isGuestLoading = false;
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
                                  image: AssetImage(
                                      'assets/images/budgie_logo.png'),
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

                // Bottom half—the login panel
                Expanded(
                  flex: 4, // Give the panel a bit more space
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
          label: _isLoading ? 'Signing in...' : 'Sign in with Google',
          leadingIcon: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                  ),
                )
              : Image.asset(
                  'assets/icons/google_logo.png',
                  width: 24,
                ),
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          onPressed: _isLoading || _isGuestLoading || _isEmailSignInLoading
              ? () {}
              : _handleGoogleSignIn,
        ),
        const SizedBox(height: 16),

        // Email Sign-in
        AuthButton(
          label: 'Sign in with Email',
          leadingIcon: const Icon(
            Icons.email_outlined,
            size: 24,
            color: Colors.white,
          ),
          backgroundColor: Colors.blue.shade700,
          textColor: Colors.white,
          onPressed: _isLoading || _isGuestLoading || _isEmailSignInLoading
              ? () {}
              : () {
                  setState(() {
                    _showEmailSignIn = true;
                  });
                },
        ),
        const SizedBox(height: 16),

        // Guest Sign-in
        AuthButton(
          label: _isGuestLoading ? 'Signing in...' : 'Continue as Guest',
          leadingIcon: _isGuestLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                )
              : const Icon(
                  Icons.person_outline,
                  size: 24,
                  color: Colors.white,
                ),
          backgroundColor: Colors.grey.shade700,
          textColor: Colors.white,
          onPressed: _isLoading || _isGuestLoading || _isEmailSignInLoading
              ? () {}
              : _handleGuestSignIn,
        ),
        const Spacer(),

        TextButton(
          onPressed: () {},
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
                const Expanded(
                  child: Text(
                    'Sign in with Email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance the back button
              ],
            ),
            const SizedBox(height: 24),

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
            const SizedBox(height: 16),

            // Password field
            CustomTextField(
              controller: _passwordController,
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icons.lock,
              isPassword: true,
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
            const SizedBox(height: 24),

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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isEmailSignInLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isEmailSignInLoading ? null : _handleCreateAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Create Account'),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.only(top: 16),
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

  Future<void> _handleGuestSignIn() async {
    setState(() {
      _isGuestLoading = true;
    });

    try {
      final result = await _authViewModel.signInAsGuest();

      // Only navigate to home if sign-in was successful
      if (mounted && result != null) {
        Navigator.pushReplacementNamed(context, Routes.home);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGuestLoading = false;
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
