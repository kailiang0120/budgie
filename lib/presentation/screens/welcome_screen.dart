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

  // Permission status tracking with descriptions
  Map<String, Map<String, dynamic>> _permissionStatus = {
    'Notifications': {
      'granted': false,
      'description': 'Detect expenses from SMS and notifications',
      'icon': Icons.notifications_outlined,
      'required': true,
    },
    'Storage': {
      'granted': false,
      'description': 'Save receipts and export your data',
      'icon': Icons.folder_outlined,
      'required': true,
    },
    'Camera': {
      'granted': false,
      'description': 'Scan receipts and documents',
      'icon': Icons.camera_alt_outlined,
      'required': false,
    },
    'Location': {
      'granted': false,
      'description': 'Location-based expense tracking (optional)',
      'icon': Icons.location_on_outlined,
      'required': false,
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

    final storage = await permissionService.hasStoragePermission();
    final notifications = await permissionService
        .hasPermissionsForFeature(PermissionFeature.notifications);
    final camera = await permissionService.hasCameraPermission();
    final location = await permissionService.hasLocationPermission();

    setState(() {
      _permissionStatus['Storage']!['granted'] = storage;
      _permissionStatus['Notifications']!['granted'] = notifications;
      _permissionStatus['Camera']!['granted'] = camera;
      _permissionStatus['Location']!['granted'] = location;
    });
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

    // Navigate to home
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(Routes.home);
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      _isPermissionRequesting = true;
    });

    final permissionService = di.sl<PermissionHandlerService>();
    final settingsService = di.sl<SettingsService>();

    try {
      // Request notification permissions (includes SMS and notification listener)
      if (!_permissionStatus['Notifications']!['granted']) {
        await permissionService.requestPermissionsForFeature(
          PermissionFeature.notifications,
          context,
        );
        final notifications = await permissionService
            .hasPermissionsForFeature(PermissionFeature.notifications);
        _permissionStatus['Notifications']!['granted'] = notifications;
      }

      // Request storage permission
      if (!_permissionStatus['Storage']!['granted']) {
        if (context.mounted) {
          final requestStorage = await DialogUtils.showConfirmationDialog(
            context,
            title: 'Storage Permission',
            content:
                'Budgie needs storage access to save receipts and export your data.',
            confirmText: 'Allow',
            cancelText: 'Skip',
          );

          if (requestStorage == true) {
            final storage = await permissionService.requestStoragePermission();
            _permissionStatus['Storage']!['granted'] = storage;
          }
        }
      }

      // Request camera permission
      if (!_permissionStatus['Camera']!['granted']) {
        if (context.mounted) {
          final requestCamera = await DialogUtils.showConfirmationDialog(
            context,
            title: 'Camera Permission',
            content:
                'Budgie needs camera access to scan receipts and documents.',
            confirmText: 'Allow',
            cancelText: 'Skip',
          );

          if (requestCamera == true) {
            final camera = await permissionService.requestCameraPermission();
            _permissionStatus['Camera']!['granted'] = camera;
          }
        }
      }

      // Request location permission (optional)
      if (!_permissionStatus['Location']!['granted']) {
        if (context.mounted) {
          final requestLocation = await DialogUtils.showConfirmationDialog(
            context,
            title: 'Location Permission (Optional)',
            content:
                'Allow Budgie to access your location for location-based expense tracking?',
            confirmText: 'Allow',
            cancelText: 'Skip',
          );

          if (requestLocation == true) {
            final location =
                await permissionService.requestLocationPermission();
            _permissionStatus['Location']!['granted'] = location;
          }
        }
      }

      // Update settings based on granted permissions
      await _updateSettingsBasedOnPermissions(
          permissionService, settingsService);

      setState(() {});
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    } finally {
      setState(() {
        _isPermissionRequesting = false;
      });
    }
  }

  /// Update settings based on granted permissions
  Future<void> _updateSettingsBasedOnPermissions(
      PermissionHandlerService permissionHandler,
      SettingsService settingsService) async {
    try {
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
    return Padding(
      padding: AppConstants.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Permissions Setup',
            style: TextStyle(
              fontSize: AppConstants.textSizeHuge.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTextDark,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacingLarge.h),
          Text(
            'Grant permissions to unlock Budgie\'s full potential. Don\'t worry - you can still use the app without them!',
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
              children: _permissionStatus.entries.map((entry) {
                final String permissionName = entry.key;
                final Map<String, dynamic> permissionData = entry.value;
                final bool isGranted = permissionData['granted'] as bool;
                final String description =
                    permissionData['description'] as String;
                final IconData icon = permissionData['icon'] as IconData;
                final bool isRequired = permissionData['required'] as bool;

                return Container(
                  margin: EdgeInsets.only(bottom: AppConstants.spacingMedium.h),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: isGranted
                              ? AppTheme.successColorDark.withAlpha(
                                  (255 * AppConstants.opacityHigh).toInt())
                              : (isRequired
                                  ? AppTheme.warningColorDark.withAlpha(
                                      (255 * AppConstants.opacityHigh).toInt())
                                  : AppTheme.greyTextDark.withAlpha(
                                      (255 * AppConstants.opacityHigh)
                                          .toInt())),
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusMedium.r),
                        ),
                        child: Icon(
                          isGranted ? Icons.check_circle : icon,
                          color: isGranted
                              ? AppTheme.successColorDark
                              : (isRequired
                                  ? AppTheme.warningColorDark
                                  : AppTheme.greyTextDark),
                          size: AppConstants.iconSizeMedium.sp,
                        ),
                      ),
                      SizedBox(width: AppConstants.spacingLarge.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  permissionName,
                                  style: TextStyle(
                                    fontSize: AppConstants.textSizeLarge.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.lightTextDark,
                                  ),
                                ),
                                if (!isRequired) ...[
                                  SizedBox(width: AppConstants.spacingSmall.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppConstants.spacingSmall.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.greyTextDark.withAlpha(
                                          (255 * AppConstants.opacityMedium)
                                              .toInt()),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      'Optional',
                                      style: TextStyle(
                                        fontSize:
                                            AppConstants.textSizeXSmall.sp,
                                        color: AppTheme.greyTextDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: AppConstants.textSizeSmall.sp,
                                color: AppTheme.greyTextDark,
                                height: 1.3,
                              ),
                            ),
                            if (isGranted) ...[
                              SizedBox(height: 2.h),
                              Text(
                                'Granted ✓',
                                style: TextStyle(
                                  fontSize: AppConstants.textSizeXSmall.sp,
                                  color: AppTheme.successColorDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: AppConstants.spacingXLarge.h),
          if (!_permissionStatus.values.every((permission) =>
              (permission['granted'] as bool) ||
              !(permission['required'] as bool)))
            SubmitButton(
              text: 'Grant Permissions',
              isLoading: _isPermissionRequesting,
              onPressed: _requestAllPermissions,
              color: AppTheme.primaryColorDark,
            ),
          SizedBox(height: AppConstants.spacingMedium.h),
          TextButton(
            onPressed: _completeWelcome,
            child: Text(
              'Skip for now',
              style: TextStyle(
                fontSize: AppConstants.textSizeMedium.sp,
                color: AppTheme.greyTextDark,
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
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.primaryColorDark),
                  padding: EdgeInsets.symmetric(
                      vertical: AppConstants.spacingLarge.h),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadiusLarge.r),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeLarge.sp,
                    color: AppTheme.primaryColorDark,
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) SizedBox(width: AppConstants.spacingLarge.w),
          Expanded(
            flex: _currentPage == 0 ? 1 : 1,
            child: SubmitButton(
              text: _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
              isLoading: false,
              onPressed: _nextPage,
              color: AppTheme.primaryColorDark,
            ),
          ),
        ],
      ),
    );
  }
}
