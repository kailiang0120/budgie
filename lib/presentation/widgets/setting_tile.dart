import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

/// A reusable setting tile widget with a modern card design
///
/// This widget displays a setting option with an icon, title, subtitle,
/// and optional trailing widget (like a switch or arrow).
class SettingTile extends StatelessWidget {
  /// The icon to display on the left side of the tile
  final IconData icon;

  /// The title text of the setting
  final String title;

  /// Optional subtitle text that appears below the title
  final String? subtitle;

  /// Optional widget to display on the right side (e.g., Switch, Icon)
  final Widget? trailing;

  /// Callback function when the tile is tapped
  final VoidCallback? onTap;

  /// Whether the tile is enabled and interactive
  final bool enabled;

  /// Color of the icon background - defaults to primary color with opacity
  final Color? iconBackgroundColor;

  /// Color of the icon - defaults to primary color
  final Color? iconColor;

  const SettingTile({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.iconBackgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveIconBackgroundColor = iconBackgroundColor ??
        Theme.of(context)
            .colorScheme
            .primary
            .withAlpha((255 * AppConstants.opacityOverlay).toInt());

    final effectiveIconColor =
        iconColor ?? Theme.of(context).colorScheme.primary;

    return Card(
      elevation: AppConstants.elevationSmall,
      margin: EdgeInsets.only(
          bottom: AppConstants.spacingSmall.h,
          left: AppConstants.spacingLarge.w,
          right: AppConstants.spacingLarge.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium.r),
        child: Opacity(
          opacity: enabled ? 1.0 : AppConstants.opacityDisabled,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingLarge.w,
                vertical: AppConstants.spacingXSmall.h),
            leading: Container(
              padding: AppConstants.containerPaddingSmall,
              decoration: BoxDecoration(
                color: effectiveIconBackgroundColor,
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusSmall.r),
              ),
              child: Icon(
                icon,
                color: effectiveIconColor,
                size: AppConstants.iconSizeMedium.sp,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w500,
                fontSize: AppConstants.textSizeLarge.sp,
              ),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: AppConstants.textSizeSmall.sp,
                      color: Colors.grey[600],
                    ),
                  )
                : null,
            trailing: trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  size: AppConstants.iconSizeSmall.sp,
                  color: Colors.grey,
                ),
            enabled: enabled,
          ),
        ),
      ),
    );
  }
}

/// A specialized version of SettingTile that includes a switch
class SwitchSettingTile extends StatelessWidget {
  /// The icon to display on the left side of the tile
  final IconData icon;

  /// The title text of the setting
  final String title;

  /// Optional subtitle text that appears below the title
  final String? subtitle;

  /// Current value of the switch
  final bool value;

  /// Callback function when the switch value changes
  final ValueChanged<bool> onChanged;

  /// Whether the tile is enabled and interactive
  final bool enabled;

  /// Color of the icon background - defaults to primary color with opacity
  final Color? iconBackgroundColor;

  /// Color of the icon - defaults to primary color
  final Color? iconColor;

  /// Optional callback when the tile itself is tapped (separate from the switch)
  final VoidCallback? onTap;

  const SwitchSettingTile({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.iconBackgroundColor,
    this.iconColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SettingTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      iconBackgroundColor: iconBackgroundColor,
      iconColor: iconColor,
      onTap: onTap ??
          () {
            // Toggle the switch when the tile is tapped
            onChanged(!value);
          },
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// A specialized version of SettingTile for dropdown selection
class DropdownSettingTile<T> extends StatelessWidget {
  /// The icon to display on the left side of the tile
  final IconData icon;

  /// The title text of the setting
  final String title;

  /// Optional subtitle text that appears below the title
  final String? subtitle;

  /// Current selected value
  final T value;

  /// List of available items
  final List<T> items;

  /// Callback function when selection changes
  final ValueChanged<T?> onChanged;

  /// Function to build the display label for each item
  final String Function(T) itemLabelBuilder;

  /// Whether the tile is enabled and interactive
  final bool enabled;

  const DropdownSettingTile({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabelBuilder,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SettingTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      onTap: enabled
          ? () {
              _showDropdownMenu(context);
            }
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            itemLabelBuilder(value),
            style: TextStyle(
              fontSize: AppConstants.textSizeSmall.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: AppConstants.spacingXSmall.w),
          Icon(
            Icons.arrow_drop_down,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Future<void> _showDropdownMenu(BuildContext context) async {
    final result = await showModalBottomSheet<T>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.borderRadiusLarge.r)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(AppConstants.spacingLarge.w),
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppConstants.textSizeXLarge.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(itemLabelBuilder(item)),
                  trailing: value == item
                      ? Icon(Icons.check,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    Navigator.of(context).pop(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      onChanged(result);
    }
  }
}
