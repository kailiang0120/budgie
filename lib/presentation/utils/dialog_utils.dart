import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber[700],
                size: 32.sp,
              ),
              Text(
                'Warning! Data Loss Risk',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to sign out as a guest user.',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.delete_forever,
                            color: theme.colorScheme.error),
                        SizedBox(width: 8.w),
                        Text(
                          'Permanent Data Loss',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'All your expenses, budgets, and settings will be permanently deleted and cannot be recovered.',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'To keep your data, link your account to an email or social login before signing out.',
                style: TextStyle(fontSize: 14.sp),
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
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link, size: 18.sp),
                  SizedBox(width: 8.w),
                  const Text(
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
                  await authViewModel.signOut();

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
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline, size: 18.sp),
                  SizedBox(width: 8.w),
                  const Text(
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

  /// Shows a loading dialog with optional message
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(height: 16.h),
                Text(
                  message ?? 'Loading...',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows a generic confirmation dialog
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: confirmColor ?? Theme.of(context).colorScheme.primary,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
              ],
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    confirmColor ?? Theme.of(context).colorScheme.primary,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }
}
