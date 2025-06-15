import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A responsive logo widget that adapts to different screen sizes and provides hero animation support
class ResponsiveLogo extends StatelessWidget {
  final String heroTag;
  final LogoSize logoSize;
  final bool showShadow;
  final double? customWidth;
  final double? customHeight;
  final VoidCallback? onTap;

  const ResponsiveLogo({
    Key? key,
    this.heroTag = 'logo',
    this.logoSize = LogoSize.medium,
    this.showShadow = true,
    this.customWidth,
    this.customHeight,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final calculatedSize = _calculateLogoSize(context);

    Widget logoWidget = Container(
      width: calculatedSize.width,
      height: calculatedSize.height,
      constraints: _getConstraints(),
      decoration: showShadow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_getShadowOpacity()),
                  blurRadius: _getShadowBlur(),
                  offset: Offset(0, _getShadowOffset()),
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Image.asset(
          'assets/images/budgie_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback icon if image fails to load
            return Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: calculatedSize.width * 0.6,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );

    if (onTap != null) {
      logoWidget = GestureDetector(
        onTap: onTap,
        child: logoWidget,
      );
    }

    return Hero(
      tag: heroTag,
      transitionOnUserGestures: true,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        // Custom flight animation for smooth logo transition
        final Hero toHero = toHeroContext.widget as Hero;
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            // Scale animation during flight
            final scale = Tween<double>(
              begin: 1.0,
              end: 0.85, // Slightly smaller in destination
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ));

            // Rotation for smooth movement effect
            final rotation = Tween<double>(
              begin: 0.0,
              end: 0.02, // Very subtle rotation
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
            ));

            return Transform.scale(
              scale: scale.value,
              child: Transform.rotate(
                angle: rotation.value,
                child: toHero.child,
              ),
            );
          },
        );
      },
      child: logoWidget,
    );
  }

  /// Calculate logo size based on screen size and logo size enum
  Size _calculateLogoSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;

    // Use custom dimensions if provided
    if (customWidth != null && customHeight != null) {
      return Size(customWidth!, customHeight!);
    }

    // Base logo dimensions (maintaining aspect ratio)
    const aspectRatio = 120 / 160; // width / height from original

    // Calculate available space
    final availableWidth = screenSize.width - safePadding.horizontal - 32.w;

    // Determine base width based on logo size
    double baseWidth;
    double maxWidth;
    double minWidth;

    switch (logoSize) {
      case LogoSize.small:
        baseWidth = screenSize.width * 0.2;
        maxWidth = 100.w;
        minWidth = 60.w;
        break;
      case LogoSize.medium:
        baseWidth = screenSize.width * 0.28;
        maxWidth = 120.w;
        minWidth = 80.w;
        break;
      case LogoSize.large:
        baseWidth = screenSize.width * 0.35;
        maxWidth = 150.w;
        minWidth = 100.w;
        break;
      case LogoSize.extraLarge:
        baseWidth = screenSize.width * 0.4;
        maxWidth = 180.w;
        minWidth = 120.w;
        break;
    }

    double logoWidth = baseWidth.clamp(minWidth, maxWidth);
    double logoHeight = logoWidth / aspectRatio;

    // Ensure logo fits within available space
    if (logoWidth > availableWidth) {
      logoWidth = availableWidth;
      logoHeight = logoWidth / aspectRatio;
    }

    return Size(logoWidth, logoHeight);
  }

  /// Get constraints based on logo size
  BoxConstraints _getConstraints() {
    switch (logoSize) {
      case LogoSize.small:
        return BoxConstraints(
          minWidth: 60.w,
          minHeight: 80.h,
          maxWidth: 100.w,
          maxHeight: 130.h,
        );
      case LogoSize.medium:
        return BoxConstraints(
          minWidth: 80.w,
          minHeight: 100.h,
          maxWidth: 120.w,
          maxHeight: 160.h,
        );
      case LogoSize.large:
        return BoxConstraints(
          minWidth: 100.w,
          minHeight: 130.h,
          maxWidth: 150.w,
          maxHeight: 200.h,
        );
      case LogoSize.extraLarge:
        return BoxConstraints(
          minWidth: 120.w,
          minHeight: 160.h,
          maxWidth: 180.w,
          maxHeight: 240.h,
        );
    }
  }

  /// Get shadow opacity based on logo size
  double _getShadowOpacity() {
    switch (logoSize) {
      case LogoSize.small:
        return 0.15;
      case LogoSize.medium:
        return 0.2;
      case LogoSize.large:
        return 0.25;
      case LogoSize.extraLarge:
        return 0.3;
    }
  }

  /// Get shadow blur radius
  double _getShadowBlur() {
    switch (logoSize) {
      case LogoSize.small:
        return 10.r;
      case LogoSize.medium:
        return 15.r;
      case LogoSize.large:
        return 20.r;
      case LogoSize.extraLarge:
        return 25.r;
    }
  }

  /// Get shadow offset
  double _getShadowOffset() {
    switch (logoSize) {
      case LogoSize.small:
        return 5.h;
      case LogoSize.medium:
        return 8.h;
      case LogoSize.large:
        return 10.h;
      case LogoSize.extraLarge:
        return 12.h;
    }
  }
}

/// Logo size options for different use cases
enum LogoSize {
  small, // For compact spaces (cards, headers)
  medium, // For login screens, standard usage
  large, // For splash screens, prominent display
  extraLarge, // For very large screens or special emphasis
}

/// Extension to get size descriptions
extension LogoSizeExtension on LogoSize {
  String get description {
    switch (this) {
      case LogoSize.small:
        return 'Small (60-100w)';
      case LogoSize.medium:
        return 'Medium (80-120w)';
      case LogoSize.large:
        return 'Large (100-150w)';
      case LogoSize.extraLarge:
        return 'Extra Large (120-180w)';
    }
  }
}
