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

        // Get AuthViewModel to handle sign out
        final authViewModel =
            Provider.of<AuthViewModel>(context, listen: false);
        await authViewModel.signOut();

        // Remove loading indicator
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        // Navigate to login screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.login,
          (route) => false,
        );
      } catch (e) {
        // Remove loading indicator if showing
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
