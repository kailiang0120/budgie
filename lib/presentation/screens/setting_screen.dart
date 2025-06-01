import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter_background/flutter_background.dart';

import '../viewmodels/theme_viewmodel.dart';
import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/settings_service.dart';
import '../../di/injection_container.dart' as di;
import '../widgets/switch_tile.dart';
import '../widgets/dropdown_tile.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/animated_float_button.dart';
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
  final _notificationService = di.sl<NotificationService>();
  final _settingsService = di.sl<SettingsService>();

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
    if (user == null) return;

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
        await _notificationService.checkNotificationPermission();

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
            duration: const Duration(seconds: 2),
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
          ),
        );
      }
    }
  }

  Future<void> _handleNotificationPermission(bool value) async {
    try {
      if (value) {
        // First check if we already have notification listener permission on Android
        bool hasListenerPermission = true;
        if (Platform.isAndroid) {
          hasListenerPermission =
              await _notificationService.checkNotificationListenerPermission();
        }

        // Request basic notification permissions first
        final granted =
            await _notificationService.requestLocalNotificationPermissions();

        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Notification permission denied. Please enable in system settings.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        // Now handle notification listener permission for Android
        if (Platform.isAndroid && !hasListenerPermission) {
          // Initialize flutter_background configuration
          const androidConfig = FlutterBackgroundAndroidConfig(
            notificationTitle: "Budgie Expense Detector",
            notificationText: "Monitoring notifications for expenses",
            notificationImportance: AndroidNotificationImportance.normal,
            notificationIcon: AndroidResource(
              name: 'ic_launcher',
              defType: 'mipmap',
            ),
          );

          // Show explanation dialog first
          if (mounted) {
            final shouldProceed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Special Permission Required'),
                    content: const Text(
                        'To detect expenses from notifications, Budgie needs access to read your notifications. '
                        'You will be redirected to system settings where you need to enable "Notification Access" '
                        'for Budgie.\n\n'
                        'Look for "Budgie Notification Listener" in the list and toggle it ON.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('CONTINUE'),
                      ),
                    ],
                  ),
                ) ??
                false;

            if (!shouldProceed) {
              // User canceled, don't update the setting
              return;
            }

            // Initialize flutter_background
            final hasBackgroundPermission = await FlutterBackground.initialize(
              androidConfig: androidConfig,
            );

            if (!hasBackgroundPermission) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Background permission denied. Some features will be limited.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }

            // Open system settings for notification listener permission
            await _notificationService.requestNotificationAccessPermission();

            // Show follow-up guidance
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please enable "Budgie Notification Listener" in the list and come back to the app.',
                  ),
                  duration: Duration(seconds: 8),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }

        // Update the setting value
        await _settingsService.updateNotificationSetting(true);

        // Try to start the notification listener with multiple attempts
        if (Platform.isAndroid) {
          // Check if permission was granted
          final hasPermissionNow =
              await _notificationService.checkNotificationListenerPermission();

          if (hasPermissionNow) {
            // Make multiple attempts to start the listener
            bool listenerStarted = false;
            for (int i = 0; i < 3; i++) {
              await _notificationService.startNotificationListener();

              // Verify if listener is active
              await Future.delayed(const Duration(milliseconds: 500));
              if (_notificationService.isListening) {
                listenerStarted = true;
                break;
              }
            }

            if (listenerStarted) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Notification monitoring enabled successfully!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                  ),
                );
              }

              // Enable background execution as well if needed
              if (await FlutterBackground.hasPermissions &&
                  !await FlutterBackground.isBackgroundExecutionEnabled) {
                await FlutterBackground.enableBackgroundExecution();
              }

              // Test the listener with a simple notification
              await Future.delayed(const Duration(seconds: 1));
              await _notificationService
                  .testNotificationListenerWithBackground();
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Failed to start notification listener. Please try again.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Notification access not granted. Some features will be limited.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } else {
          // Non-Android platforms
          await _notificationService.startNotificationListener();
        }
      } else {
        // User wants to disable notifications
        await _settingsService.updateNotificationSetting(false);

        // Stop notification listener
        await _notificationService.stopNotificationListener();

        // For Android, prompt user to also revoke notification access permission
        if (Platform.isAndroid) {
          final hasListenerAccess =
              await _notificationService.checkNotificationListenerPermission();

          if (hasListenerAccess && mounted) {
            // Prompt the user to also revoke the notification access in system settings
            final shouldRevokeAccess = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Revoke Notification Access?'),
                    content: const Text(
                        'For complete privacy, you should also revoke notification access permission in system settings.\n\n'
                        'Would you like to open system settings to revoke notification access?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('SKIP'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('OPEN SETTINGS'),
                      ),
                    ],
                  ),
                ) ??
                false;

            if (shouldRevokeAccess) {
              await _notificationService.requestNotificationAccessPermission();
              // Show guidance
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please DISABLE "Budgie Notification Listener" in the list to completely revoke access.',
                    ),
                    duration: Duration(seconds: 8),
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling notification permission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating notification settings: $e')),
        );
      }
    }
  }

  Future<void> _updateAutoBudget(bool value) async {
    try {
      await _settingsService.updateAutoBudgetSetting(value);
      debugPrint('Auto budget updated to: $value');
    } catch (e) {
      debugPrint('Error updating auto budget: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update auto budget: $e')),
        );
      }
    }
  }

  Future<void> _updateImproveAccuracy(bool value) async {
    try {
      await _settingsService.updateImproveAccuracySetting(value);
      debugPrint('Improve accuracy updated to: $value');
    } catch (e) {
      debugPrint('Error updating improve accuracy: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update improve accuracy: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeViewModel = Provider.of<ThemeViewModel>(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Theme.of(context).dividerColor,
            height: 0.5,
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
            title: 'Auto budget rebalance',
            value: _settingsService.autoBudget,
            onChanged: _updateAutoBudget,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Divider(
              color: Theme.of(context).dividerColor,
              thickness: 0.5,
            ),
          ),

          // Notification API Test Button
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                Icons.bug_report,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            title: const Text('Notification API Test'),
            subtitle: const Text('Test notification detection API connection'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

          // // Debug: Force refresh settings button (only in debug mode)
          // if (kDebugMode)
          //   ListTile(
          //     leading: Container(
          //       padding: const EdgeInsets.all(8.0),
          //       decoration: BoxDecoration(
          //         color: Colors.orange.withOpacity(0.1),
          //         borderRadius: BorderRadius.circular(8.0),
          //       ),
          //       child: const Icon(
          //         Icons.refresh,
          //         color: Colors.orange,
          //         size: 20,
          //       ),
          //     ),
          //     title: const Text('Debug: Refresh Settings'),
          //     subtitle: const Text('Force reload settings from Firebase'),
          //     trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          //     onTap: () async {
          //       try {
          //         // Show loading indicator
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           const SnackBar(
          //             content: Text('Refreshing settings from Firebase...'),
          //             duration: Duration(seconds: 2),
          //           ),
          //         );

          //         // Force refresh settings
          //         await _settingsService.forceReloadFromFirebase();

          //         // Show success message
          //         if (mounted) {
          //           ScaffoldMessenger.of(context).hideCurrentSnackBar();
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             SnackBar(
          //               content: Text(
          //                   'Settings refreshed! Currency: ${_settingsService.currency}, Theme: ${_settingsService.theme}, Notifications: ${_settingsService.allowNotification}'),
          //               backgroundColor: Colors.green,
          //               duration: const Duration(seconds: 3),
          //             ),
          //           );
          //         }
          //       } catch (e) {
          //         if (mounted) {
          //           ScaffoldMessenger.of(context).hideCurrentSnackBar();
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             SnackBar(
          //               content: Text('Failed to refresh settings: $e'),
          //               backgroundColor: Colors.red,
          //               duration: const Duration(seconds: 3),
          //             ),
          //           );
          //         }
          //       }
          //     },
          //   ),
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
