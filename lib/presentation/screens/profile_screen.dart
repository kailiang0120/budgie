import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';
import '../widgets/auth_button.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/animated_float_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/auth_utils.dart';
import 'add_expense_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isUpgrading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Custom password field with visibility toggle
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _showPassword = !_showPassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      obscureText: !_showPassword,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  void _handleLogout(BuildContext context) async {
    // Use the new secure sign-out handler from AuthUtils
    await AuthUtils.handleSignOut(context);
  }

  void _handleSwitchAccount(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(Routes.login);
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() {
      _isUpgrading = true;
    });

    try {
      final viewModel = Provider.of<AuthViewModel>(context, listen: false);
      await viewModel.signInWithGoogle();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account upgraded successfully with Google!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpgrading = false;
        });
      }
    }
  }

  // Apple sign-in functionality is currently handled in other locations

  Future<void> _handleGuestUpgrade(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUpgrading = true;
    });

    try {
      final viewModel = Provider.of<AuthViewModel>(context, listen: false);
      await viewModel.upgradeGuestAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account upgraded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpgrading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AuthViewModel>(context);
    final user = viewModel.currentUser;
    final isGuest = viewModel.isGuestUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage:
                user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
            child: user?.photoUrl == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            isGuest ? 'Guest User' : (user?.displayName ?? 'User'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isGuest ? 'Signed in as guest' : (user?.email ?? ''),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isGuest ? Colors.amber.shade800 : Colors.grey,
              fontStyle: isGuest ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 32),

          // Guest account upgrade section
          if (isGuest) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      const Text(
                        'Guest Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You are currently using a guest account. Your data is stored locally and will be lost if you uninstall the app or clear app data.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Upgrade to a permanent account to:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Save your data securely in the cloud'),
                  const Text('• Access your budget across multiple devices'),
                  const Text('• Protect your data from being lost'),
                  const SizedBox(height: 16),

                  // Upgrade form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          controller: _emailController,
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildPasswordField(),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isUpgrading
                              ? null
                              : () => _handleGuestUpgrade(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isUpgrading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text('Upgrade Account'),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Or connect with:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Google Sign In Button
                        AuthButton(
                          label: 'Continue with Google',
                          leadingIcon: Image.asset(
                            'assets/icons/google_logo.png',
                            height: 24,
                            width: 24,
                          ),
                          backgroundColor: Colors.white,
                          textColor: Colors.black87,
                          onPressed: () => _handleGoogleSignIn(context),
                        ),
                        const SizedBox(height: 12),
                        // Apple Sign In Button
                        AuthButton(
                          label: 'Continue with Apple',
                          leadingIcon: Image.asset(
                            'assets/icons/apple_logo.png',
                            height: 24,
                            width: 24,
                            color: Colors.white,
                          ),
                          backgroundColor: Colors.black.withAlpha((255 * 0.5)
                              .toInt()), // Dimmed to indicate it's disabled
                          onPressed:
                              null, // Disabled because Apple developer account is required
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                AuthButton(
                  label: 'Log out',
                  leadingIcon: const Icon(Icons.logout),
                  backgroundColor: const Color(0xff1A1A19),
                  onPressed: () => _handleLogout(context),
                ),
                const SizedBox(height: 12),
                AuthButton(
                  label: 'Switch Account',
                  leadingIcon: const Icon(Icons.switch_account),
                  backgroundColor: const Color(0xff1A1A19),
                  onPressed: () => _handleSwitchAccount(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
      extendBody: true,
      floatingActionButton: AnimatedFloatButton(
        onPressed: () {
          Navigator.push(
            context,
            PageTransition(
              child: const AddExpenseScreen(),
              type: TransitionType.fadeAndSlideUp,
              settings: const RouteSettings(name: Routes.expenses),
            ),
          );
        },
        backgroundColor: const Color(0xFFF57C00),
        shape: const CircleBorder(),
        enableFeedback: true,
        reactToRouteChange: true,
        child: const Icon(Icons.add, color: Color(0xFFFBFCF8)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (idx) {
          // Navigation is handled in BottomNavBar
        },
      ),
    );
  }
}
