import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../../core/constants/routes.dart';

/// Utility class for showing dialogs throughout the app
class DialogUtils {
  /// Shows a dialog to confirm sign-out for anonymous users
  /// This handles the special case where guest users need a warning before sign-out
  static Future<void> showAnonymousSignOutDialog(BuildContext context) async {
    final theme = Theme.of(context);

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber[700],
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Warning: Data Loss Risk',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You are about to sign out as a guest user.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.delete_forever,
                            color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                        Text(
                          'Permanent Data Loss',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'All your expenses, budgets, and settings will be permanently deleted and cannot be recovered.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'To keep your data, link your account to an email or social login before signing out.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),

            // Link Account button
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                // Navigate to the account linking page
                Navigator.of(context).pushNamed(Routes.profile);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                elevation: 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Link Account & Save Data',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Delete & Sign Out button
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog

                // Store context-related variables before async operations
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final authViewModel =
                    Provider.of<AuthViewModel>(context, listen: false);

                try {
                  // Show loading indicator
                  showLoadingDialog(context, message: 'Deleting data...');

                  // Call the secure sign out method which handles data deletion
                  await authViewModel.secureSignOutAnonymousUser();

                  // Check if the widget is still mounted before using navigator
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
                  // Check if the widget is still mounted before using navigator
                  if (navigator.mounted) {
                    // Remove loading indicator if showing
                    if (navigator.canPop()) {
                      navigator.pop();
                    }

                    // Show error message
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Error signing out: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Delete & Sign Out',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Shows a loading dialog with a spinner
  static Future<void> showLoadingDialog(BuildContext context,
      {String message = 'Loading...'}) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.1).toInt()),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
