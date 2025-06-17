import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';
import '../../presentation/viewmodels/theme_viewmodel.dart';
import '../../data/infrastructure/services/notification_manager_service.dart';
import '../../data/infrastructure/services/notification_permission_service.dart';
import '../../data/infrastructure/services/settings_service.dart';
import '../../data/infrastructure/services/background_task_service.dart';
import '../../di/injection_container.dart' as di;
import '../widgets/switch_tile.dart';
import '../widgets/dropdown_tile.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/animated_float_button.dart';
import '../widgets/exchange_rate_status_widget.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';
import 'add_expense_screen.dart';
import 'notification_test_screen.dart';
import '../viewmodels/budget_viewmodel.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _loading = true;

  // Get services
  final _notificationManager = di.sl<NotificationManagerService>();
  final _notificationPermissionService = di.sl<NotificationPermissionService>();
  final _settingsService = di.sl<SettingsService>();
  final _backgroundTaskService = di.sl<BackgroundTaskService>();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Listen to settings changes
    _settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Handle non-signed-in user
      setState(() {
        _loading = false;
        // We'll show a placeholder in the build method when no user is signed in
      });
      return;
    }

    try {
      // Settings are already loaded by AuthViewModel, just update the UI
      setState(() {
        _loading = false;
      });

      // Check if permissions match settings
      await _checkNotificationPermissionStatus();
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _checkNotificationPermissionStatus() async {
    final hasNotificationPermission =
        await _notificationManager.checkNotificationPermission();

    // Only show a warning if app setting is ON but OS permission is OFF
    if (_settingsService.allowNotification && !hasNotificationPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Notification permission is disabled in system settings. Please enable it for full functionality.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    // Do NOT update the app setting here!
  }

  Future<void> _updateCurrency(String value) async {
    try {
      // Get BudgetViewModel to update budget with new currency
      final budgetViewModel =
          Provider.of<BudgetViewModel>(context, listen: false);

      debugPrint(
          'Currency change initiated: from ${_settingsService.currency} to $value');

      // Update the currency in settings first
      await _settingsService.updateCurrency(value);
      debugPrint('Settings updated with new currency: $value');

      // Trigger budget currency conversion - this will convert all budget amounts
      // and save them to Firebase with the new currency
      debugPrint('Triggering budget currency conversion to: $value');
      await budgetViewModel.onCurrencyChanged(value);

      // Show a success message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Currency updated to $value. All budgets have been converted.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating currency: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update currency: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _handleNotificationPermission(bool value) async {
    // This method orchestrates the entire permission and service flow
    // based on the user's choice in the UI.
    try {
      // First, immediately update the master setting. This is the source of truth.
      await _settingsService.updateNotificationSetting(value);
      debugPrint('🔔 Settings toggled to: $value. Notifying services.');

      if (value) {
        // If the user turned the setting ON, trigger the enable workflow.
        // The service will read the setting we just saved.
        final result =
            await _notificationPermissionService.enableNotifications(context);

        // The enableNotifications service handles reverting the setting on failure,
        // so we just need to show the final result to the user.
        if (mounted && result.message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: result.isSuccess
                  ? (result.type == NotificationPermissionResultType.pending
                      ? Colors.orange
                      : Colors.green)
                  : Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        // If the user turned the setting OFF, trigger the disable workflow.
        final result =
            await _notificationPermissionService.disableNotifications(context);

        if (mounted && result.message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: result.isSuccess ? Colors.green : Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Top-level error handling notification permission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      // Ensure the setting is off if any catastrophic error occurs.
      if (_settingsService.allowNotification) {
        await _settingsService.updateNotificationSetting(false);
      }
    }
  }

  Future<void> _handleAutomaticRebalance(bool value) async {
    try {
      // Update both settings to maintain backward compatibility
      await _settingsService.updateAutoBudgetSetting(value);
      await _settingsService.updateAutomaticRebalanceSuggestions(value);
      debugPrint('Auto budget reallocation updated to: $value');

      if (value) {
        await _backgroundTaskService.scheduleBudgetSuggestionTask();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Auto budget reallocation enabled. AI will automatically optimize your budget daily.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        await _backgroundTaskService.cancelBudgetSuggestionTask();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto budget reallocation disabled.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating auto budget reallocation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update auto budget reallocation: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _updateImproveAccuracy(bool value) async {
    try {
      // If user is trying to enable the setting, show consent dialog
      if (value && !_settingsService.improveAccuracy) {
        final shouldEnable = await _showImproveAccuracyDialog();
        if (!shouldEnable) {
          return; // User declined, don't update the setting
        }
      }

      await _settingsService.updateImproveAccuracySetting(value);
      debugPrint('Improve accuracy updated to: $value');

      // Show confirmation message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Thank you for helping improve our expense detection model!'
                  : 'Model improvement has been disabled.',
            ),
            backgroundColor: value ? Colors.green : Colors.grey,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating improve accuracy: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update improve accuracy: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<bool> _showImproveAccuracyDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // User must choose an option
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Improve our model',
                      style: TextStyle(fontSize: 18.sp),
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7.h,
                  maxWidth: MediaQuery.of(context).size.width * 0.9.w,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'We would like to use your anonymized user data to improve our AI model for better performance.',
                        textAlign: TextAlign.start,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha((255 * 0.1).toInt()),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: Colors.blue.withAlpha((255 * 0.3).toInt()),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.security,
                                  color: Colors.blue.shade700,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    'Data Privacy & Usage',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '• Your data will be completely anonymized\n'
                              '• No personal information will be shared\n'
                              '• Data is used solely for AI model training\n'
                              '• You can disable this anytime in settings\n'
                              '• Data helps improve model output accuracy',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'By enabling this feature, you consent to share anonymized data to help us build better AI models for all users.',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          'No, Keep Disabled',
                          style: TextStyle(fontSize: 10.sp),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Agree & Enable',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              actionsPadding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
              contentPadding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
              titlePadding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
            );
          },
        ) ??
        false; // Return false if dialog is dismissed without selection
  }

  @override
  Widget build(BuildContext context) {
    final themeViewModel = Provider.of<ThemeViewModel>(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Check if user is signed in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            AppConstants.settingsTitle,
            style:
                TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.h),
            child: Container(
              color: Theme.of(context).dividerColor,
              height: 0.5.h,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 80.sp,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withAlpha((255 * 0.7).toInt()),
              ),
              SizedBox(height: 20.h),
              Text(
                'Sign in to access settings',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Please log in to view and customize your settings',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 30.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Routes.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                ),
                child: const Text('Sign In'),
              ),
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
            );
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: const CircleBorder(),
          enableFeedback: true,
          reactToRouteChange: true,
          child:
              Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomNavBar(
          currentIndex: 2, // Settings tab
          onTap: (idx) {
            // Navigation is handled in BottomNavBar
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Setting',
          style:
              TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            color: Theme.of(context).dividerColor,
            height: 0.5.h,
          ),
        ),
      ),
      body: ListView(
        children: [
          // Currency selection
          DropdownTile<String>(
            title: 'Currency',
            value: _settingsService.currency,
            items: AppConstants.currencies,
            onChanged: (value) {
              if (value != null) {
                _updateCurrency(value);
              }
            },
            itemLabelBuilder: (item) =>
                '$item - ${CurrencyFormatter.getCurrencyName(item)}',
          ),

          // Exchange rate status
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 6.h),
                const Row(
                  children: [
                    Expanded(child: ExchangeRateStatusWidget()),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  'Exchange rates are automatically updated from Bank Negara Malaysia\'s official API',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Dark theme toggle
          SwitchTile(
            title: 'Dark Theme',
            value: themeViewModel.isDarkMode,
            onChanged: (v) {
              themeViewModel.toggleTheme();
            },
          ),

          // Switch options
          SwitchTile(
            title: 'Auto Budget Reallocation',
            value: _settingsService.automaticRebalanceSuggestions,
            onChanged: _handleAutomaticRebalance,
            subtitle:
                'Automatically optimize your budget using AI-powered analysis',
          ),
          SwitchTile(
            title: 'Allow notification',
            value: _settingsService.allowNotification,
            onChanged: _handleNotificationPermission,
            subtitle:
                'Enable notification monitoring for automatic expense detection',
          ),
          SwitchTile(
            title: 'Improve model accuracy',
            value: _settingsService.improveAccuracy,
            onChanged: _updateImproveAccuracy,
          ),

          // Divider for testing section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Divider(
              color: Theme.of(context).dividerColor,
              thickness: 0.5.h,
            ),
          ),

          // Notification API Test Button
          ListTile(
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.bug_report,
                color: Theme.of(context).colorScheme.primary,
                size: 20.sp,
              ),
            ),
            title: const Text('Notification API Test'),
            subtitle: const Text('Test notification detection API connection'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
            onTap: () {
              Navigator.push(
                context,
                PageTransition(
                  child: const NotificationTestScreen(),
                  type: TransitionType.smoothSlideRight,
                  settings: const RouteSettings(name: '/notification_test'),
                ),
              );
            },
          ),

          // Add some space at the bottom for better UI
          SizedBox(height: 90.h),
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        enableFeedback: true,
        reactToRouteChange: true,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2, // Settings tab
        onTap: (idx) {
          // Navigation is handled in BottomNavBar
        },
      ),
    );
  }
}
