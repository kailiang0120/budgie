import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class CustomCard extends StatelessWidget {
  final Widget child;

  final Color? color;

  final double elevation;

  final double borderRadius;

  final EdgeInsetsGeometry padding;

  final EdgeInsetsGeometry margin;

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
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.only(bottom: 16.0),
    this.border,
    this.onTap,
    this.showSplash = true,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).cardColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDarkMode
        ? Colors.black.withAlpha((255 * 0.3).toInt())
        : Colors.black.withAlpha((255 * 0.1).toInt());

    final card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding,
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
              borderRadius: BorderRadius.circular(borderRadius),
              child: card,
            ),
          )
        : GestureDetector(
            onTap: onTap,
            child: card,
          );
  }

  factory CustomCard.withTitle({
    Key? key,
    required String title,
    required Widget child,
    IconData? icon,
    Color? iconColor,
    Color? color,
    double elevation = 2.0,
    double borderRadius = 15.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 16.0),
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
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        );
      }),
    );
  }

  /// 创建一个带操作按钮的卡片
  factory CustomCard.withAction({
    Key? key,
    required Widget child,
    required String actionText,
    required VoidCallback onActionPressed,
    IconData? actionIcon,
    Color? color,
    double elevation = 2.0,
    double borderRadius = 15.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 16.0),
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
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onActionPressed,
              icon: Icon(
                actionIcon ?? Icons.arrow_forward,
                size: 18,
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
