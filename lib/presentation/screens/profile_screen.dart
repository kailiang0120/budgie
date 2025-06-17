import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';
import '../widgets/auth_button.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/animated_float_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/submit_button.dart';
import '../utils/auth_utils.dart';
import '../viewmodels/expenses_viewmodel.dart';
import 'add_expense_screen.dart';
import '../utils/app_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isUpgrading = false;
  bool _isEditingProfile = false;
  bool _isUpdatingProfile = false;
  String? _selectedPhotoUrl;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = viewModel.currentUser;
    _displayNameController.text = user?.displayName ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Choose Profile Photo',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 512,
                      maxHeight: 512,
                      imageQuality: 75,
                    );
                    if (image != null) {
                      setState(() {
                        _selectedPhotoUrl = image.path;
                      });
                    }
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 512,
                      maxHeight: 512,
                      imageQuality: 75,
                    );
                    if (image != null) {
                      setState(() {
                        _selectedPhotoUrl = image.path;
                      });
                    }
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.delete_outline,
                  label: 'Remove',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedPhotoUrl = '';
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Icon(
              icon,
              size: 28.sp,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final viewModel = Provider.of<AuthViewModel>(context);
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final user = viewModel.currentUser;
    final isGuest = viewModel.isGuestUser;

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.1).round()),
                      blurRadius: 20.r,
                      offset: Offset(0, 10.h),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60.r,
                  backgroundColor: themeViewModel.isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  backgroundImage: _selectedPhotoUrl != null &&
                          _selectedPhotoUrl!.isNotEmpty
                      ? (_selectedPhotoUrl!.startsWith('http')
                          ? NetworkImage(_selectedPhotoUrl!)
                          : FileImage(File(_selectedPhotoUrl!))
                              as ImageProvider)
                      : (user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                          ? NetworkImage(user.photoUrl!)
                          : null),
                  child: ((_selectedPhotoUrl == null ||
                              _selectedPhotoUrl!.isEmpty) &&
                          (user?.photoUrl == null || user!.photoUrl!.isEmpty))
                      ? Icon(
                          Icons.person,
                          size: 60.sp,
                          color: themeViewModel.isDarkMode
                              ? Colors.grey[500]
                              : Colors.grey[400],
                        )
                      : null,
                ),
              ),
              if (!isGuest && _isEditingProfile)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 36.w,
                      height: 36.h,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2.w,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20.h),
          if (_isEditingProfile && !isGuest)
            Container(
              width: 250.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.r),
                color: themeViewModel.isDarkMode
                    ? Theme.of(context).cardColor
                    : Colors.white.withAlpha((255 * 0.8).round()),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.05).round()),
                    blurRadius: 10.r,
                    offset: Offset(0, 5.h),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _displayNameController,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter display name',
                  hintStyle: TextStyle(
                    color: Theme.of(context).hintColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.r),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            )
          else
            Text(
              isGuest ? 'Guest User' : (user?.displayName ?? 'User'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          SizedBox(height: 8.h),
          Text(
            isGuest ? 'Signed in as guest' : (user?.email ?? ''),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: isGuest
                  ? Colors.amber.shade800
                  : Theme.of(context).textTheme.bodyMedium?.color,
              fontStyle: isGuest ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          if (!isGuest) ...[
            SizedBox(height: 20.h),
            Column(
              children: [
                if (_isEditingProfile) ...[
                  SubmitButton(
                      text: 'Save',
                      loadingText: 'Saving...',
                      isLoading: _isUpdatingProfile,
                      onPressed: _saveProfileChanges,
                      icon: Icons.save,
                      color: Colors.green),
                  SizedBox(height: 16.h),
                  SubmitButton(
                    text: 'Cancel',
                    isLoading: false,
                    onPressed: _isUpdatingProfile ? () {} : _cancelEdit,
                    icon: Icons.close,
                    color: Colors.grey,
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: SubmitButton(
                          text: 'Edit Profile',
                          isLoading: false,
                          onPressed: () {
                            setState(() {
                              _isEditingProfile = true;
                              _displayNameController.text =
                                  user?.displayName ?? '';
                              _selectedPhotoUrl = user?.photoUrl;
                            });
                          },
                          icon: Icons.edit,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveProfileChanges() async {
    setState(() {
      _isUpdatingProfile = true;
    });

    try {
      final viewModel = Provider.of<AuthViewModel>(context, listen: false);
      final displayName = _displayNameController.text.trim();

      // Update both Firebase Auth profile and Firestore document
      await viewModel.updateProfile(
        displayName: displayName.isEmpty ? null : displayName,
        photoUrl: _selectedPhotoUrl,
      );

      // Also update the user settings in Firestore
      if (displayName.isNotEmpty) {
        await viewModel.updateUserSettings(
          theme: null, // Keep current theme
          displayName: displayName,
        );
      }

      setState(() {
        _isEditingProfile = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfile = false;
        });
      }
    }
  }

  void _cancelEdit() {
    final viewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = viewModel.currentUser;

    setState(() {
      _isEditingProfile = false;
      _displayNameController.text = user?.displayName ?? '';
      _selectedPhotoUrl = user?.photoUrl;
    });
  }

  void _handleLogout(BuildContext context) async {
    await AuthUtils.handleSignOut(context);
  }

  void _handleSwitchAccount(BuildContext context) async {
    await AuthUtils.handleSwitchAccount(context);
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() {
      _isUpgrading = true;
    });

    try {
      final viewModel = Provider.of<AuthViewModel>(context, listen: false);
      await viewModel.signInWithGoogle();

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Account upgraded successfully with Google!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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

  Future<void> _handleGuestUpgrade(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() {
      _isUpgrading = true;
    });

    try {
      final viewModel = Provider.of<AuthViewModel>(context, listen: false);
      await viewModel.upgradeGuestAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Account upgraded successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final isGuest = viewModel.isGuestUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          AppConstants.profileTitle,
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),

            // Guest account upgrade section
            if (isGuest) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.05).round()),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withAlpha((255 * 0.1).round()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.amber.shade800,
                            size: 24.sp,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Guest Account',
                            style: TextStyle(
                              fontSize: 19.sp,
                              fontWeight: FontWeight.w700,
                              color:
                                  Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You are currently using a guest account. Your data is stored locally and will be lost if you uninstall the app or clear app data.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  Colors.green.withAlpha((255 * 0.05).round()),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    Colors.green.withAlpha((255 * 0.2).round()),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upgrade to a permanent account to:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...[
                                  '• Save your data securely in the cloud',
                                  '• Access your budget across multiple devices',
                                  '• Protect your data from being lost',
                                ].map((text) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        text,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

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
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icons.lock,
                            isPassword: true,
                            isRequired: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SubmitButton(
                            text: 'Upgrade Account',
                            isLoading: _isUpgrading,
                            onPressed: _isUpgrading
                                ? () {}
                                : () => _handleGuestUpgrade(context),
                            icon: Icons.upgrade,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(
                                      color: Theme.of(context).dividerColor)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Or connect with',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: Divider(
                                      color: Theme.of(context).dividerColor)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AuthButton(
                            label: 'Continue with Google',
                            leadingIcon: Image.asset(
                              'assets/icons/google_logo.png',
                              height: 24,
                              width: 24,
                            ),
                            backgroundColor: themeViewModel.isDarkMode
                                ? Colors.grey[800]!
                                : Colors.white,
                            textColor: themeViewModel.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                            onPressed: () => _handleGoogleSignIn(context),
                          ),
                          const SizedBox(height: 12),
                          AuthButton(
                            label: 'Continue with Apple',
                            leadingIcon: Image.asset(
                              'assets/icons/apple_logo.png',
                              height: 24,
                              width: 24,
                              color: Colors.white,
                            ),
                            backgroundColor:
                                Colors.black.withAlpha((255 * 0.7).round()),
                            onPressed: null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action buttons
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((255 * 0.05).round()),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        AuthButton(
                          label: 'Log out',
                          leadingIcon:
                              const Icon(Icons.logout, color: Colors.white),
                          backgroundColor: const Color(0xff1A1A19),
                          onPressed: () => _handleLogout(context),
                        ),
                        const SizedBox(height: 16),
                        AuthButton(
                          label: 'Switch Account',
                          leadingIcon: const Icon(Icons.switch_account,
                              color: Colors.white),
                          backgroundColor: Colors.grey.shade700,
                          onPressed: () => _handleSwitchAccount(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Space for bottom navigation
          ],
        ),
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
          ).then((result) {
            // Only refresh data if an expense was actually added (result == true)
            if (!mounted || result != true) return;

            // Refresh the expenses data
            final expensesVM =
                Provider.of<ExpensesViewModel>(context, listen: false);
            expensesVM.refreshData();
          });
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
