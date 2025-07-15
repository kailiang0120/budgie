import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/routes.dart';
import '../../data/infrastructure/services/permission_handler_service.dart';
import '../../data/infrastructure/services/settings_service.dart';
import '../../di/injection_container.dart' as di;
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/dialog_utils.dart';
import '../widgets/submit_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentPage = 0;
  final int _totalPages = 4;
  bool _isPermissionRequesting = false;

  // Individual permission request tracking
  final Map<String, bool> _permissionRequestStates = {
    'Notifications': false,
    'Storage': false,
    'Camera': false,
    'Location': false,
  };

  // Permission status tracking with descriptions
  final Map<String, Map<String, dynamic>> _permissionStatus = {
    'Notifications': {
      'granted': false,
      'description': 'Detect expenses from SMS and notifications automatically',
      'icon': Icons.notifications_outlined,
      'required': true,
      'color': AppTheme.primaryColorDark,
      'available': true,
    },
    'Storage': {
      'granted': false,
      'description': 'Save receipts and export your financial data',
      'icon': Icons.folder_outlined,
      'required': true,
      'color': AppTheme.secondaryColorDark,
      'available': true,
    },
    'Camera': {
      'granted': false,
      'description': 'Scan receipts and documents for expense tracking',
      'icon': Icons.camera_alt_outlined,
      'required': false,
      'color': AppTheme.successColorDark,
      'available': false, // Coming soon
    },
    'Location': {
      'granted': false,
      'description': 'Location-based expense tracking and merchant detection',
      'icon': Icons.location_on_outlined,
      'required': false,
      'color': AppTheme.warningColorDark,
      'available': false, // Coming soon
    },
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkInitialPermissions();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: AppConstants.animationDurationMedium,
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: AppConstants.animationDurationLong,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _animationController.forward();
  }

  Future<void> _checkInitialPermissions() async {
    final permissionService = di.sl<PermissionHandlerService>();

    // Only check permissions for available features
    final storage = await permissionService.hasStoragePermission();
    final notifications = await permissionService
        .hasPermissionsForFeature(PermissionFeature.notifications);

    if (mounted) {
      setState(() {
        _permissionStatus['Storage']!['granted'] = storage;
        _permissionStatus['Notifications']!['granted'] = notifications;
        // Camera and Location remain false as they're not available yet
        _permissionStatus['Camera']!['granted'] = false;
        _permissionStatus['Location']!['granted'] = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: AppConstants.animationDurationMedium,
        curve: Curves.easeInOut,
      );
    } else {
      _completeWelcome();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppConstants.animationDurationMedium,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeWelcome() async {
    // Mark welcome as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_completed', true);

    // Update settings based on granted permissions
    await _updateSettingsBasedOnPermissions();

    // Navigate to home
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(Routes.home);
    }
  }

  /// Request individual permission and update UI in real-time
  Future<void> _requestIndividualPermission(String permissionName) async {
    // Check if permission is available for request
    if (!_permissionStatus[permissionName]!['available']) {
      // Show coming soon message for unavailable permissions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$permissionName feature coming soon! 🚀'),
          backgroundColor: AppTheme.warningColorDark,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_permissionRequestStates[permissionName] == true) return;

    setState(() {
      _permissionRequestStates[permissionName] = true;
    });

    final permissionService = di.sl<PermissionHandlerService>();
    bool granted = false;

    try {
      switch (permissionName) {
        case 'Notifications':
          final result = await permissionService.requestPermissionsForFeature(
            PermissionFeature.notifications,
            context,
          );
          granted = result.isGranted;
          break;
        case 'Storage':
          granted = await permissionService.requestStoragePermission();
          break;
        case 'Camera':
        case 'Location':
          // These are not available yet, shouldn't reach here
          return;
      }

      if (mounted) {
        setState(() {
          _permissionStatus[permissionName]!['granted'] = granted;
          _permissionRequestStates[permissionName] = false;
        });

        // Show feedback
        if (granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$permissionName permission granted ✓'),
              backgroundColor: AppTheme.successColorDark,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error requesting $permissionName permission: $e');
      if (mounted) {
        setState(() {
          _permissionRequestStates[permissionName] = false;
        });
      }
    }
  }

  /// Request all remaining permissions (only available ones)
  Future<void> _requestAllRemainingPermissions() async {
    setState(() {
      _isPermissionRequesting = true;
    });

    final ungranted = _permissionStatus.entries
        .where((entry) =>
            !entry.value['granted'] && entry.value['available'] == true)
        .map((entry) => entry.key)
        .toList();

    for (final permissionName in ungranted) {
      if (!mounted) break;
      await _requestIndividualPermission(permissionName);
      // Small delay between requests for better UX
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (mounted) {
      setState(() {
        _isPermissionRequesting = false;
      });
    }
  }

  /// Update settings based on granted permissions
  Future<void> _updateSettingsBasedOnPermissions() async {
    try {
      final settingsService = di.sl<SettingsService>();

      final hasNotifications =
          _permissionStatus['Notifications']!['granted'] as bool;
      final hasStorage = _permissionStatus['Storage']!['granted'] as bool;
      final hasCamera = _permissionStatus['Camera']!['granted'] as bool;
      final hasLocation = _permissionStatus['Location']!['granted'] as bool;

      // Update settings to match actual permissions
      if (hasNotifications != settingsService.allowNotification) {
        await settingsService.updateNotificationSetting(hasNotifications);
      }

      if (hasStorage != settingsService.storageEnabled) {
        await settingsService.updateStorageSetting(hasStorage);
      }

      if (hasCamera != settingsService.cameraEnabled) {
        await settingsService.updateCameraSetting(hasCamera);
      }

      if (hasLocation != settingsService.locationEnabled) {
        await settingsService.updateLocationSetting(hasLocation);
      }
    } catch (e) {
      debugPrint('⚠️ Error updating settings based on permissions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildWelcomePage(),
                      _buildFeaturePage(),
                      _buildAutoBalancingPage(),
                      _buildPermissionsPage(),
                    ],
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLarge.w),
      child: Row(
        children: List.generate(_totalPages, (index) {
          return Expanded(
            child: Container(
              height: 4.h,
              margin: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingXSmall.w),
              decoration: BoxDecoration(
                color: index <= _currentPage
                    ? AppTheme.primaryColorDark
                        .withAlpha((255 * AppConstants.opacityHigh).toInt())
                    : AppTheme.cardBackgroundDark,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: AppConstants.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo placeholder
          Container(
            width: 120.w,
            height: 120.h,
            decoration: BoxDecoration(
              color: AppTheme.cardBackgroundDark,
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusXLarge.r),
              border: Border.all(
                color: AppTheme.primaryColorDark
                    .withAlpha((255 * AppConstants.opacityMedium).toInt()),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 60.sp,
              color: AppTheme.primaryColorDark,
            ),
          ),
          SizedBox(height: AppConstants.spacingXXLarge.h),

          Text(
            'Welcome to Budgie',
            style: TextStyle(
              fontSize: AppConstants.textSizeHuge.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTextDark,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacingLarge.h),

          Text(
            'Your intelligent budget companion that helps you track, analyze, and optimize your spending habits effortlessly.',
            style: TextStyle(
              fontSize: AppConstants.textSizeLarge.sp,
              color: AppTheme.greyTextDark,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacingXXLarge.h),

          Container(
            padding: EdgeInsets.all(AppConstants.spacingLarge.w),
            decoration: BoxDecoration(
              color: AppTheme.cardBackgroundDark,
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusLarge.r),
              border: Border.all(
                color: AppTheme.primaryColorDark
                    .withAlpha((255 * AppConstants.opacityMedium).toInt()),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: AppConstants.iconSizeLarge.sp,
                  color: AppTheme.primaryColorDark,
                ),
                SizedBox(height: AppConstants.spacingMedium.h),
                Text(
                  'Smart Financial Management',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeLarge.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTextDark,
                  ),
                ),
                SizedBox(height: AppConstants.spacingSmall.h),
                Text(
                  'Get insights, track expenses automatically, and stay within budget with our intelligent features.',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeMedium.sp,
                    color: AppTheme.greyTextDark,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePage() {
    final features = [
      {
        'icon': Icons.receipt_long_outlined,
        'title': 'Expense Tracking',
        'description':
            'Automatically detect and categorize your expenses from notifications'
      },
      {
        'icon': Icons.analytics_outlined,
        'title': 'Smart Analytics',
        'description':
            'Get detailed insights about your spending patterns and trends'
      },
      {
        'icon': Icons.account_balance_outlined,
        'title': 'Budget Management',
        'description':
            'Set budgets and get real-time alerts when you\'re overspending'
      },
    ];

    return Padding(
      padding: AppConstants.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Key Features',
            style: TextStyle(
              fontSize: AppConstants.textSizeHuge.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTextDark,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacingXLarge.h),
          Text(
            'Discover what makes Budgie your perfect financial companion',
            style: TextStyle(
              fontSize: AppConstants.textSizeLarge.sp,
              color: AppTheme.greyTextDark,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacingXXLarge.h),
          ...features.map((feature) => Container(
                margin: EdgeInsets.only(bottom: AppConstants.spacingLarge.h),
                padding: EdgeInsets.all(AppConstants.spacingLarge.w),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackgroundDark,
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadiusLarge.r),
                  border: Border.all(
                    color: AppTheme.primaryColorDark
                        .withAlpha((255 * AppConstants.opacityMedium).toInt()),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppConstants.spacingMedium.w),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColorDark.withAlpha(
                            (255 * AppConstants.opacityOverlay).toInt()),
                        borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium.r),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        size: AppConstants.iconSizeLarge.sp,
                        color: AppTheme.primaryColorDark,
                      ),
                    ),
                    SizedBox(width: AppConstants.spacingLarge.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature['title'] as String,
                            style: TextStyle(
                              fontSize: AppConstants.textSizeLarge.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.lightTextDark,
                            ),
                          ),
                          SizedBox(height: AppConstants.spacingSmall.h),
                          Text(
                            feature['description'] as String,
                            style: TextStyle(
                              fontSize: AppConstants.textSizeMedium.sp,
                              color: AppTheme.greyTextDark,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAutoBalancingPage() {
    return Padding(
      padding: AppConstants.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image placeholder
          Container(
            width: 200.w,
            height: 150.h,
            decoration: BoxDecoration(
              color: AppTheme.cardBackgroundDark,
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusLarge.r),
              border: Border.all(
                color: AppTheme.primaryColorDark
                    .withAlpha((255 * AppConstants.opacityMedium).toInt()),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 60.sp,
                  color: AppTheme.primaryColorDark,
                ),
                SizedBox(height: AppConstants.spacingSmall.h),
                Text(
                  'Image Placeholder',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeSmall.sp,
                    color: AppTheme.greyTextDark,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppConstants.spacingXXLarge.h),

          Text(
            'Auto-Rebalancing Budget',
            style: TextStyle(
              fontSize: AppConstants.textSizeHuge.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTextDark,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacingLarge.h),

          Text(
            'Let Budgie intelligently adjust your budget based on your spending patterns and financial goals.',
            style: TextStyle(
              fontSize: AppConstants.textSizeLarge.sp,
              color: AppTheme.greyTextDark,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacingXXLarge.h),

          Container(
            padding: EdgeInsets.all(AppConstants.spacingLarge.w),
            decoration: BoxDecoration(
              color: AppTheme.cardBackgroundDark,
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusLarge.r),
              border: Border.all(
                color: AppTheme.successColorDark
                    .withAlpha((255 * AppConstants.opacityMedium).toInt()),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.trending_up,
                  size: AppConstants.iconSizeLarge.sp,
                  color: AppTheme.successColorDark,
                ),
                SizedBox(height: AppConstants.spacingMedium.h),
                Text(
                  'Smart Optimization',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeLarge.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTextDark,
                  ),
                ),
                SizedBox(height: AppConstants.spacingSmall.h),
                Text(
                  '• Analyze spending patterns\n• Suggest budget adjustments\n• Optimize category allocations\n• Achieve financial goals faster',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeMedium.sp,
                    color: AppTheme.greyTextDark,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage() {
    final availablePermissions = _permissionStatus.entries
        .where((entry) => entry.value['available'] as bool)
        .toList();
    final grantedCount = availablePermissions
        .where((entry) => entry.value['granted'] as bool)
        .length;
    final totalCount = availablePermissions.length;
    final requiredCount = availablePermissions
        .where((entry) => entry.value['required'] as bool)
        .length;
    final grantedRequiredCount = availablePermissions
        .where((entry) =>
            entry.value['required'] as bool && entry.value['granted'] as bool)
        .length;

    return Padding(
      padding: AppConstants.screenPadding,
      child: Column(
        children: [
          // Header
          Text(
            'Permissions Setup',
            style: TextStyle(
              fontSize: AppConstants.textSizeHuge.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTextDark,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacingMedium.h),

          // Progress indicator
          Container(
            padding: EdgeInsets.all(AppConstants.spacingLarge.w),
            decoration: BoxDecoration(
              color: AppTheme.cardBackgroundDark,
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusLarge.r),
              border: Border.all(
                color: AppTheme.primaryColorDark
                    .withAlpha((255 * AppConstants.opacityMedium).toInt()),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: grantedRequiredCount == requiredCount
                        ? AppTheme.successColorDark
                        : AppTheme.primaryColorDark,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    grantedRequiredCount == requiredCount
                        ? Icons.check_circle
                        : Icons.shield_outlined,
                    color: Colors.white,
                    size: AppConstants.iconSizeMedium.sp,
                  ),
                ),
                SizedBox(width: AppConstants.spacingLarge.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$grantedCount of $totalCount permissions granted',
                        style: TextStyle(
                          fontSize: AppConstants.textSizeLarge.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTextDark,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '$grantedRequiredCount of $requiredCount required permissions',
                        style: TextStyle(
                          fontSize: AppConstants.textSizeMedium.sp,
                          color: AppTheme.greyTextDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: AppConstants.spacingLarge.h),

          Text(
            'Tap each permission to grant access. Don\'t worry - you can change these later in settings!',
            style: TextStyle(
              fontSize: AppConstants.textSizeMedium.sp,
              color: AppTheme.greyTextDark,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppConstants.spacingXLarge.h),

          // Permissions checklist
          Expanded(
            child: ListView(
              children: _permissionStatus.entries.map((entry) {
                final String permissionName = entry.key;
                final Map<String, dynamic> permissionData = entry.value;
                final bool isGranted = permissionData['granted'] as bool;
                final String description =
                    permissionData['description'] as String;
                final IconData icon = permissionData['icon'] as IconData;
                final bool isRequired = permissionData['required'] as bool;
                final Color permissionColor = permissionData['color'] as Color;
                final bool isAvailable = permissionData['available'] as bool;
                final bool isRequesting =
                    _permissionRequestStates[permissionName] == true;

                return Container(
                  margin: EdgeInsets.only(bottom: AppConstants.spacingMedium.h),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isGranted || isRequesting || !isAvailable
                          ? null
                          : () => _requestIndividualPermission(permissionName),
                      borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusLarge.r),
                      child: Container(
                        padding: EdgeInsets.all(AppConstants.spacingLarge.w),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackgroundDark,
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusLarge.r),
                          border: Border.all(
                            color: isGranted
                                ? AppTheme.successColorDark
                                : (!isAvailable
                                    ? AppTheme.greyTextDark.withAlpha(
                                        (255 * AppConstants.opacityLow).toInt())
                                    : (isRequired
                                        ? permissionColor.withAlpha(
                                            (255 * AppConstants.opacityMedium)
                                                .toInt())
                                        : AppTheme.greyTextDark.withAlpha(
                                            (255 * AppConstants.opacityMedium)
                                                .toInt()))),
                            width: isGranted ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Status indicator
                            Container(
                              width: 50.w,
                              height: 50.h,
                              decoration: BoxDecoration(
                                color: isGranted
                                    ? AppTheme.successColorDark
                                    : (!isAvailable
                                        ? AppTheme.greyTextDark.withAlpha(
                                            (255 * AppConstants.opacityLow)
                                                .toInt())
                                        : (isRequesting
                                            ? permissionColor.withAlpha((255 *
                                                    AppConstants.opacityMedium)
                                                .toInt())
                                            : permissionColor.withAlpha((255 *
                                                    AppConstants.opacityOverlay)
                                                .toInt()))),
                                borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadiusMedium.r),
                              ),
                              child: isRequesting
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                permissionColor),
                                      ),
                                    )
                                  : Icon(
                                      isGranted
                                          ? Icons.check_circle
                                          : (!isAvailable
                                              ? Icons.schedule
                                              : icon),
                                      color: isGranted
                                          ? Colors.white
                                          : (!isAvailable
                                              ? AppTheme.greyTextDark
                                              : permissionColor),
                                      size: AppConstants.iconSizeMedium.sp,
                                    ),
                            ),
                            SizedBox(width: AppConstants.spacingLarge.w),

                            // Permission details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        permissionName,
                                        style: TextStyle(
                                          fontSize:
                                              AppConstants.textSizeLarge.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.lightTextDark,
                                        ),
                                      ),
                                      SizedBox(
                                          width: AppConstants.spacingSmall.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                              AppConstants.spacingSmall.w,
                                          vertical: 2.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: !isAvailable
                                              ? AppTheme.greyTextDark.withAlpha(
                                                  (255 *
                                                          AppConstants
                                                              .opacityOverlay)
                                                      .toInt())
                                              : (isRequired
                                                  ? AppTheme.warningColorDark
                                                      .withAlpha((255 *
                                                              AppConstants
                                                                  .opacityOverlay)
                                                          .toInt())
                                                  : AppTheme.greyTextDark
                                                      .withAlpha((255 *
                                                              AppConstants
                                                                  .opacityOverlay)
                                                          .toInt())),
                                          borderRadius:
                                              BorderRadius.circular(8.r),
                                        ),
                                        child: Text(
                                          !isAvailable
                                              ? 'Coming Soon'
                                              : (isRequired
                                                  ? 'Required'
                                                  : 'Optional'),
                                          style: TextStyle(
                                            fontSize:
                                                AppConstants.textSizeXSmall.sp,
                                            color: !isAvailable
                                                ? AppTheme.greyTextDark
                                                : (isRequired
                                                    ? AppTheme.warningColorDark
                                                    : AppTheme.greyTextDark),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppConstants.spacingSmall.h),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: AppConstants.textSizeMedium.sp,
                                      color: AppTheme.greyTextDark,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (isGranted) ...[
                                    SizedBox(
                                        height: AppConstants.spacingSmall.h),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: AppConstants.iconSizeSmall.sp,
                                          color: AppTheme.successColorDark,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Permission granted',
                                          style: TextStyle(
                                            fontSize:
                                                AppConstants.textSizeSmall.sp,
                                            color: AppTheme.successColorDark,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else if (!isRequesting) ...[
                                    SizedBox(
                                        height: AppConstants.spacingSmall.h),
                                    Row(
                                      children: [
                                        Icon(
                                          !isAvailable
                                              ? Icons.schedule_outlined
                                              : Icons.touch_app_outlined,
                                          size: AppConstants.iconSizeSmall.sp,
                                          color: !isAvailable
                                              ? AppTheme.greyTextDark
                                              : permissionColor,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          !isAvailable
                                              ? 'Feature coming soon'
                                              : 'Tap to grant permission',
                                          style: TextStyle(
                                            fontSize:
                                                AppConstants.textSizeSmall.sp,
                                            color: !isAvailable
                                                ? AppTheme.greyTextDark
                                                : permissionColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Action indicator
                            if (!isGranted && !isRequesting)
                              Icon(
                                Icons.arrow_forward_ios,
                                size: AppConstants.iconSizeSmall.sp,
                                color: AppTheme.greyTextDark,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          SizedBox(height: AppConstants.spacingLarge.h),

          // Action buttons
          if (grantedCount < totalCount) ...[
            SubmitButton(
              text: 'Grant All Remaining',
              isLoading: _isPermissionRequesting,
              onPressed: _requestAllRemainingPermissions,
              color: AppTheme.primaryColorDark,
            ),
            SizedBox(height: AppConstants.spacingMedium.h),
          ],

          TextButton(
            onPressed: _completeWelcome,
            child: Text(
              grantedRequiredCount == requiredCount
                  ? 'Continue to App'
                  : 'Skip for now',
              style: TextStyle(
                fontSize: AppConstants.textSizeMedium.sp,
                color: grantedRequiredCount == requiredCount
                    ? AppTheme.primaryColorDark
                    : AppTheme.greyTextDark,
                fontWeight: grantedRequiredCount == requiredCount
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLarge.w),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: ElevatedButton(
                onPressed: _previousPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cardBackgroundDark,
                  foregroundColor: AppTheme.greyTextDark,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                      vertical: AppConstants.spacingLarge.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusXLarge.r),
                    side: BorderSide(
                      color: AppTheme.greyTextDark.withAlpha(
                          (255 * AppConstants.opacityMedium).toInt()),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeLarge.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.greyTextDark,
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) SizedBox(width: AppConstants.spacingLarge.w),
          Expanded(
            flex: _currentPage == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColorDark,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    EdgeInsets.symmetric(vertical: AppConstants.spacingLarge.h),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadiusXLarge.r),
                ),
              ),
              child: Text(
                _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
                style: TextStyle(
                  fontSize: AppConstants.textSizeLarge.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
