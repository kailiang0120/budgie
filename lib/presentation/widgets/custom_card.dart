import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_theme.dart';

class CustomCard extends StatelessWidget {
  final Widget child;

  final Color? color;

  final double elevation;

  final double borderRadius;

  final EdgeInsetsGeometry? padding;

  final EdgeInsetsGeometry? margin;

  final Border? border;

  final VoidCallback? onTap;

  final bool showSplash;

  final double? width;

  final double? height;

  const CustomCard({
    Key? key,
    required this.child,
    this.color,
    this.elevation = 2.0,
    this.borderRadius = 15.0,
    this.padding,
    this.margin,
    this.border,
    this.onTap,
    this.showSplash = true,
    this.width,
    this.height,
  }) : super(key: key);

  // Default responsive padding and margin
  EdgeInsetsGeometry get _defaultPadding => EdgeInsets.all(16.w);
  EdgeInsetsGeometry get _defaultMargin => EdgeInsets.only(bottom: 16.h);

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).cardColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDarkMode
        ? Colors.black.withAlpha((255 * 0.3).toInt())
        : Colors.black.withAlpha((255 * 0.1).toInt());

    final card = Container(
      width: width?.w,
      height: height?.h,
      margin: margin ?? _defaultMargin,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(borderRadius.r),
        border: border,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: (elevation * 2).r,
                  offset: Offset(0, elevation.h),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding ?? _defaultPadding,
        child: child,
      ),
    );

    if (onTap == null) {
      return card;
    }

    return showSplash
        ? Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius.r),
              child: card,
            ),
          )
        : GestureDetector(
            onTap: onTap,
            child: card,
          );
  }

  /// Create a card with a title
  factory CustomCard.withTitle({
    Key? key,
    required String title,
    required Widget child,
    IconData? icon,
    Color? iconColor,
    Color? color,
    double elevation = 2.0,
    double borderRadius = 15.0,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Border? border,
    VoidCallback? onTap,
    bool showSplash = true,
    double? width,
    double? height,
  }) {
    return CustomCard(
      key: key,
      color: color,
      elevation: elevation,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      border: border,
      onTap: onTap,
      showSplash: showSplash,
      width: width,
      height: height,
      child: Builder(builder: (context) {
        final titleColor = Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: iconColor ?? AppTheme.primaryColor,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            child,
          ],
        );
      }),
    );
  }

  /// Create a card with an action button
  factory CustomCard.withAction({
    Key? key,
    required Widget child,
    required String actionText,
    required VoidCallback onActionPressed,
    IconData? actionIcon,
    Color? color,
    double elevation = 2.0,
    double borderRadius = 15.0,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Border? border,
    VoidCallback? onTap,
    bool showSplash = true,
    double? width,
    double? height,
  }) {
    return CustomCard(
      key: key,
      color: color,
      elevation: elevation,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      border: border,
      onTap: onTap,
      showSplash: showSplash,
      width: width,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          SizedBox(height: 16.h),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onActionPressed,
              icon: Icon(
                actionIcon ?? Icons.arrow_forward,
                size: 18.sp,
              ),
              label: Text(actionText),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
