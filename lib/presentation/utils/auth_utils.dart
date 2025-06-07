import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'dialog_utils.dart';
import '../../core/constants/routes.dart';

/// Utility class for common authentication operations
class AuthUtils {
  /// Handle sign-out with special handling for anonymous users
  /// This is the main entry point for sign-out actions in the UI
  static Future<void> handleSignOut(BuildContext context) async {
    // Store context-related variables before async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // Get the current user from Firebase
    final user = FirebaseAuth.instance.currentUser;

    // Check if the user is anonymous
    if (user != null && user.isAnonymous) {
      // Show warning dialog for guest users
      await DialogUtils.showAnonymousSignOutDialog(context);
    } else {
      // For non-anonymous users, sign out normally
      try {
        // Show loading indicator
        DialogUtils.showLoadingDialog(context, message: 'Signing out...');

        // Sign out using the stored authViewModel reference
        await authViewModel.signOut();

        // We need to check if the widget is still in the tree before using navigator
        if (navigator.mounted) {
          // Remove loading indicator
          if (navigator.canPop()) {
            navigator.pop();
          }

          // Navigate to login screen
          navigator.pushNamedAndRemoveUntil(
            Routes.login,
            (route) => false,
          );
        }
      } catch (e) {
        // We need to check if the widget is still in the tree before using navigator
        if (navigator.mounted) {
          // Remove loading indicator if showing
          if (navigator.canPop()) {
            navigator.pop();
          }

          // Show error message using the stored scaffoldMessenger reference
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
