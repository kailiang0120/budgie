import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';
import '../../presentation/viewmodels/theme_viewmodel.dart';
import '../../presentation/viewmodels/budget_viewmodel.dart';

import '../../data/infrastructure/services/permission_handler_service.dart';
import '../../data/infrastructure/services/settings_service.dart';
import '../../data/infrastructure/services/background_task_service.dart';
import '../../data/infrastructure/services/sync_service.dart';
import '../../di/injection_container.dart' as di;
import '../widgets/setting_tile.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/animated_float_button.dart';
import '../widgets/exchange_rate_status_widget.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';
import 'add_expense_screen.dart';
import 'notification_test_screen.dart';
import 'financial_profile_screen.dart';
import '../../domain/repositories/user_behavior_repository.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late SettingsService _settingsService;
  late SyncService _syncService;
  late PermissionHandlerService _permissionHandler;
  late BackgroundTaskService _backgroundTaskService;
  bool _isLoading = true;
  bool _isCurrencyUpdating = false; // Track currency update state
  String _currentCurrency = 'MYR'; // Local state for currency

  // Get services - using the new consolidated services
  // Note: NotificationListenerService is available through DI when needed

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize services with null checks and error handling
      try {
        _settingsService = di.sl<SettingsService>();
        debugPrint('✅ SettingsService initialized successfully');
      } catch (e) {
        debugPrint('❌ Error initializing SettingsService: $e');
        // Create a new instance if DI fails
        _settingsService = SettingsService();
      }

      try {
        _syncService = di.sl<SyncService>();
        debugPrint('✅ SyncService initialized successfully');
      } catch (e) {
        debugPrint('❌ Error initializing SyncService: $e');
        // We'll handle null _syncService in methods that use it
      }

      try {
        _permissionHandler = di.sl<PermissionHandlerService>();
        debugPrint('✅ PermissionHandlerService initialized successfully');
      } catch (e) {
        debugPrint('❌ Error initializing PermissionHandlerService: $e');
        // We'll handle null _permissionHandler in methods that use it
      }

      try {
        _backgroundTaskService = di.sl<BackgroundTaskService>();
        debugPrint('✅ BackgroundTaskService initialized successfully');
      } catch (e) {
        debugPrint('❌ Error initializing BackgroundTaskService: $e');
        // We'll handle null _backgroundTaskService in methods that use it
      }

      // NotificationListenerService is available through DI when needed
      debugPrint('✅ NotificationListenerService available through DI');

      // Add listener after services are initialized
      _settingsService.addListener(_onSettingsChanged);

      // Initialize local state with settings values
      _currentCurrency = _settingsService.currency;

      setState(() {
        _isLoading = false;
      });

      // Check if permissions match settings
      await _checkNotificationPermissionStatus();
    } catch (e) {
      debugPrint('❌ Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {
        // Update local state when settings change
        _currentCurrency = _settingsService.currency;
      });
    }
  }

  Future<void> _checkNotificationPermissionStatus() async {
    try {
      // Check if _permissionHandler is available
      try {
        _permissionHandler = di.sl<PermissionHandlerService>();
      } catch (e) {
        debugPrint('❌ Failed to initialize PermissionHandler: $e');
        return; // Exit early if we can't get the permission handler
      }

      final hasNotificationPermission = await _permissionHandler
          .hasPermissionsForFeature(PermissionFeature.notifications);

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
    } catch (e) {
      debugPrint('❌ Error checking notification permission status: $e');
    }
  }

  Future<void> _updateCurrency(String value) async {
    try {
      // Get BudgetViewModel to update budget with new currency
      final budgetViewModel =
          Provider.of<BudgetViewModel>(context, listen: false);

      debugPrint(
          'Currency change initiated: from ${_settingsService.currency} to $value');

      // Update local state immediately and set loading state
      setState(() {
        _currentCurrency = value;
        _isCurrencyUpdating = true;
      });

      // Update the currency in settings
      await _settingsService.updateCurrency(value);
      debugPrint('Settings updated with new currency: $value');

      // Trigger budget currency conversion - this will convert all budget amounts
      // and save them to Firebase with the new currency
      debugPrint('Triggering budget currency conversion to: $value');
      await budgetViewModel.onCurrencyChanged(value);

      // Show a success message to the user
      if (mounted) {
        setState(() {
          _isCurrencyUpdating = false;
        });

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

      // Revert local state on error and clear loading state
      setState(() {
        _currentCurrency = _settingsService.currency;
        _isCurrencyUpdating = false;
      });

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

  Future<void> _handleNotificationToggle(bool value) async {
    try {
      // Update UI immediately for better responsiveness
      setState(() {
        // This will make the toggle respond immediately
      });

      // Check if we need to request notification permissions
      if (value) {
        // Show a loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Requesting notification permissions...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        // Use the PermissionHandlerService to request permissions
        final permissionResult =
            await _permissionHandler.requestPermissionsForFeature(
          PermissionFeature.notifications,
          context,
        );

        if (!permissionResult.isGranted) {
          // Permission denied, update UI to reflect this
          if (mounted) {
            setState(() {
              // Force UI refresh to show correct state
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Notification permission was denied: ${permissionResult.message}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        // Update the settings if permission was granted
        await _settingsService.updateNotificationSetting(true);
      } else {
        // If turning off, just update the setting and optionally guide user to system settings
        await _settingsService.updateNotificationSetting(false);

        // Optionally show guidance for manually disabling system permissions
        if (await _permissionHandler
            .hasPermissionsForFeature(PermissionFeature.notifications)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'App notification monitoring disabled. You can also disable system permissions in device settings if desired.'),
                backgroundColor: Colors.grey,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }

      debugPrint('Notification setting updated to: $value');

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value
                ? 'Notification monitoring enabled'
                : 'Notification monitoring disabled'),
            backgroundColor: value ? Colors.green : Colors.grey,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling notification toggle: $e');
      // Ensure the setting is off if any catastrophic error occurs.
      if (_settingsService.allowNotification) {
        await _settingsService.updateNotificationSetting(false);
      }

      // Force refresh UI
      if (mounted) {
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enabling notifications: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Handle auto budget reallocation toggle
  Future<void> _handleAutoBudgetToggle(bool value) async {
    try {
      // Update UI immediately for better responsiveness
      setState(() {
        // This will make the toggle respond immediately
      });

      // Update the setting in SettingsService
      await _settingsService.updateAutoBudgetSetting(value);

      // Handle background task scheduling for auto reallocation
      try {
        _backgroundTaskService = di.sl<BackgroundTaskService>();
      } catch (e) {
        debugPrint('❌ Failed to initialize BackgroundTaskService: $e');
        throw Exception('Background service is not available');
      }

      if (value) {
        // Schedule auto reallocation task
        await _backgroundTaskService.scheduleAutoReallocationTask();
        debugPrint('✅ Auto budget reallocation task scheduled');
      } else {
        // Cancel auto reallocation task
        await _backgroundTaskService.cancelAutoReallocationTask();
        debugPrint('❌ Auto budget reallocation task canceled');
      }

      if (mounted) {
        if (value) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Auto budget reallocation enabled. Your budget will be optimized daily.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auto budget reallocation disabled.'),
              backgroundColor: Colors.grey,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating auto budget setting: $e');
      if (mounted) {
        // Reset UI state on error
        setState(() {
          // Force refresh UI to show correct state
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update auto budget setting: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Handle sync setting toggle
  Future<void> _handleSyncToggle(bool value) async {
    try {
      // Update UI immediately for better responsiveness
      setState(() {
        // This will make the toggle respond immediately
      });

      // Update the setting in SettingsService
      await _settingsService.updateSyncSetting(value);

      // Ensure we have the required services
      try {
        _syncService = di.sl<SyncService>();
        _backgroundTaskService = di.sl<BackgroundTaskService>();
      } catch (e) {
        debugPrint('❌ Failed to initialize required services: $e');
        throw Exception('Required services are not available');
      }

      // Update sync service and background task
      if (value) {
        // Enable sync in service
        await _syncService.setSyncEnabled(value);

        // Schedule background sync task
        await _backgroundTaskService.updateSyncTask(value);

        // Trigger an initial sync
        _syncService.syncData(fullSync: true);
      } else {
        // Disable sync in service
        await _syncService.setSyncEnabled(value);

        // Cancel background sync task
        await _backgroundTaskService.updateSyncTask(value);
      }

      if (mounted) {
        if (value) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Sync enabled. Your data will be synchronized with the cloud.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Sync disabled. Your data will remain local until sync is re-enabled.'),
              backgroundColor: Colors.grey,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating sync setting: $e');
      if (mounted) {
        // Reset UI state on error
        setState(() {
          // Force refresh UI to show correct state
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update sync setting: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeViewModel = Provider.of<ThemeViewModel>(context);

    if (_isLoading) {
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
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            color: Theme.of(context).dividerColor,
            height: 0.5.h,
          ),
        ),
      ),
      body: ListView(
        children: [
          SizedBox(height: AppConstants.spacingSmall.h),

          // Data Sync Section - moved to top
          SwitchSettingTile(
            icon: Icons.sync,
            title: 'Enable Data Sync',
            subtitle: 'Synchronize your data with the cloud',
            value: _settingsService.syncEnabled,
            onChanged: _handleSyncToggle,
          ),

          // Data Management Section - conditional on sync being enabled
          if (_settingsService.syncEnabled) ...[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingLarge.w,
                vertical: AppConstants.spacingSmall.h,
              ),
              child: Text(
                AppConstants.dataManagementTitle,
                style: TextStyle(
                  fontSize: AppConstants.textSizeSmall.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            _buildDataManagementTile(
              context,
              icon: Icons.cloud_sync,
              title: AppConstants.syncDataTitle,
              subtitle: 'Manually sync data with cloud',
              onTap: () {
                // TODO: Implement manual sync functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Manual sync feature coming soon'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            _buildDataManagementTile(
              context,
              icon: Icons.refresh,
              title: AppConstants.refreshDataTitle,
              subtitle: 'Reload all data from cloud',
              onTap: () {
                // TODO: Implement refresh from cloud functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refresh from cloud feature coming soon'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            _buildDataManagementTile(
              context,
              icon: Icons.backup,
              title: AppConstants.exportDataTitle,
              subtitle: 'Export your data as a backup file',
              onTap: () {
                // TODO: Implement export functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Export feature coming soon'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            SizedBox(height: AppConstants.spacingMedium.h),
          ],

          // Currency Section
          Stack(
            children: [
              DropdownSettingTile<String>(
                icon: Icons.currency_exchange,
                title: 'Currency',
                subtitle: 'Select your preferred currency',
                value: _currentCurrency,
                items: AppConstants.currencies,
                onChanged: (value) {
                  if (value != null && !_isCurrencyUpdating) {
                    _updateCurrency(value);
                  }
                },
                itemLabelBuilder: (item) =>
                    '$item - ${CurrencyFormatter.getCurrencyName(item)}',
                enabled: !_isCurrencyUpdating,
              ),
              if (_isCurrencyUpdating)
                Positioned.fill(
                  child: AbsorbPointer(
                    absorbing: true,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.1),
                      margin:
                          EdgeInsets.only(bottom: 8.h, left: 16.w, right: 16.w),
                      child: Center(
                        child: SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Exchange rate status
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingLarge.w,
                vertical: AppConstants.spacingSmall.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Row(
                  children: [
                    Expanded(child: ExchangeRateStatusWidget()),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  'Exchange rates are automatically updated from Bank Negara Malaysia\'s official API',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeSmall.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Dark theme toggle
          SwitchSettingTile(
            icon: Icons.dark_mode,
            title: 'Dark Theme',
            subtitle: 'Toggle between light and dark mode',
            value: themeViewModel.isDarkMode,
            onChanged: (v) {
              themeViewModel.toggleTheme();
            },
          ),

          // Notification toggle
          SwitchSettingTile(
            icon: Icons.notifications,
            title: 'Allow notification',
            subtitle:
                'Enable notification monitoring for automatic expense detection',
            value: _settingsService.allowNotification,
            onChanged: _handleNotificationToggle,
          ),

          // Auto budget reallocation toggle
          SwitchSettingTile(
            icon: Icons.auto_awesome,
            title: 'Auto budget reallocation',
            subtitle:
                'Automatically optimize budget allocation using AI analysis',
            value: _settingsService.autoBudget,
            onChanged: _handleAutoBudgetToggle,
          ),

          // Financial Profile Setting
          SettingTile(
            icon: Icons.psychology_rounded,
            title: 'Financial Profile',
            subtitle: 'Configure your financial behavior and AI preferences',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FinancialProfileScreen(
                    userBehaviorRepository: di.sl<UserBehaviorRepository>(),
                  ),
                ),
              );
            },
          ),

          // Divider for testing section
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingLarge.w,
                vertical: AppConstants.spacingSmall.h),
            child: Divider(
              color: Theme.of(context).dividerColor,
              thickness: 0.5.h,
            ),
          ),

          // Notification API Test Button
          SettingTile(
            icon: Icons.notifications_active,
            title: 'Notification Test Center',
            subtitle: 'Test and manage notification features',
            onTap: () {
              Navigator.push(
                context,
                PageTransition(
                  child: const NotificationTestScreen(),
                  type: TransitionType.smoothSlideRight,
                  settings: const RouteSettings(name: Routes.notificationTest),
                ),
              );
            },
          ),

          // Add some space at the bottom for better UI
          SizedBox(height: AppConstants.bottomPaddingWithNavBar.h),
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
        currentIndex: 3, // Settings tab at position 3
        onTap: (idx) {
          // Navigation is handled in BottomNavBar
        },
      ),
    );
  }

  Widget _buildDataManagementTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: AppConstants.elevationSmall,
      margin: EdgeInsets.only(
        bottom: AppConstants.spacingSmall.h,
        left: AppConstants.spacingLarge.w,
        right: AppConstants.spacingLarge.w,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium.r),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLarge.w,
            vertical: AppConstants.spacingXSmall.h),
        leading: Container(
          padding: EdgeInsets.all(AppConstants.spacingSmall.w),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withAlpha((255 * 0.1).toInt()),
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusSmall.r),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: AppConstants.iconSizeMedium.sp,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: AppConstants.textSizeLarge.sp,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: AppConstants.textSizeSmall.sp,
            color: Colors.grey[600],
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: AppConstants.iconSizeSmall.sp,
              color: Colors.grey,
            ),
        onTap: onTap,
      ),
    );
  }
}
