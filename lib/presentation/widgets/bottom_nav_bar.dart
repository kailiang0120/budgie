import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/routes.dart';
import '../utils/app_constants.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.home,
      Icons.analytics,
      Icons.flag,
      Icons.settings,
    ];
    final labels = [
      'Home',
      'Analytics',
      'Goals',
      'Settings',
    ];

    // Page routes mapping
    final routes = [
      Routes.home,
      Routes.analytic,
      Routes.goals,
      Routes.settings,
    ];

    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurface;

    // Create a more distinct background for the nav bar
    final backgroundColor = Theme.of(context).brightness == Brightness.dark
        ? Color.lerp(Theme.of(context).colorScheme.surface, Colors.black,
            AppConstants.opacityLow)!
        : Color.lerp(
            Theme.of(context).colorScheme.surface, Colors.blueGrey, 0.0)!;

    return SizedBox(
      height: 80.h,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Custom painted background with notch
          Positioned.fill(
            child: CustomPaint(
              painter: _NavBarPainter(backgroundColor),
            ),
          ),
          // Enhanced nav bar icons with smooth animations
          Positioned.fill(
            bottom: AppConstants
                .spacingLarge.h, // Adjust bottom position for better centering
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(4, (idx) {
                final isSelected = currentIndex == idx;
                return _buildNavItem(
                  context,
                  idx,
                  isSelected,
                  icons[idx],
                  labels[idx],
                  routes[idx],
                  primaryColor,
                  textColor,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    bool isSelected,
    IconData icon,
    String label,
    String route,
    Color primaryColor,
    Color textColor,
  ) {
    return GestureDetector(
      onTap: () => _handleNavigation(context, index, route),
      child: AnimatedContainer(
        duration: AppConstants.animationDurationShort,
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(AppConstants.spacingSmall.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? primaryColor
                  .withAlpha((255 * AppConstants.opacityOverlay).toInt())
              : Colors.transparent,
        ),
        child: AnimatedScale(
          scale: isSelected ? 1.1 : 1.0,
          duration: AppConstants.animationDurationShort,
          curve: Curves.easeInOut,
          child: Icon(
            icon,
            color: isSelected
                ? primaryColor
                : textColor
                    .withAlpha((255 * AppConstants.opacityMedium).toInt()),
            size: AppConstants.iconSizeLarge.sp,
          ),
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int targetIndex, String route) {
    // Don't navigate if already on the target tab
    if (currentIndex == targetIndex) {
      return;
    }

    // Update the tab index first for immediate visual feedback
    onTap(targetIndex);

    // Choose appropriate transition based on navigation direction and target
    _navigateWithSmoothTransition(context, targetIndex, route);
  }

  void _navigateWithSmoothTransition(
      BuildContext context, int targetIndex, String route) {
    // Enhanced smooth navigation with potential for custom transitions
    Navigator.pushReplacementNamed(
      context,
      route,
    );
  }
}

class _NavBarPainter extends CustomPainter {
  final Color backgroundColor;

  const _NavBarPainter(this.backgroundColor);

  @override
  void paint(Canvas canvas, Size size) {
    // Make background color slightly darker for better contrast
    final Color navBarColor = HSLColor.fromColor(backgroundColor)
        .withLightness((HSLColor.fromColor(backgroundColor).lightness - 0.05)
            .clamp(0.0, 1.0))
        .toColor();

    final paint = Paint()
      ..color = navBarColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double notchRadius = AppConstants.borderRadiusLarge.r;
    final double notchCenterX = size.width / 2;
    const double notchTop = 0;
    final double barHeight = size.height;

    final path = Path();
    path.moveTo(0, notchTop);
    // Left to notch
    path.lineTo(
        notchCenterX - notchRadius - AppConstants.spacingMedium.w, notchTop);
    // Notch curve
    path.quadraticBezierTo(
      notchCenterX - notchRadius,
      notchTop,
      notchCenterX - notchRadius * 0.8,
      notchTop + notchRadius * 0.3,
    );
    path.arcToPoint(
      Offset(notchCenterX + notchRadius * 0.8, notchTop + notchRadius * 0.3),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.quadraticBezierTo(
      notchCenterX + notchRadius,
      notchTop,
      notchCenterX + notchRadius + AppConstants.spacingMedium.w,
      notchTop,
    );
    // Right to end
    path.lineTo(size.width, notchTop);
    path.lineTo(size.width, barHeight);
    path.lineTo(0, barHeight);
    path.close();

    canvas.drawShadow(
        path, Colors.black.withAlpha((255 * 0.15).toInt()), 8.r, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
