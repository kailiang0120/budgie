import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const SwitchTile({
    Key? key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              color: enabled
                  ? Theme.of(context).textTheme.titleLarge?.color
                  : Theme.of(context).disabledColor,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: enabled
                        ? Theme.of(context).textTheme.bodyMedium?.color
                        : Theme.of(context).disabledColor,
                  ),
                )
              : null,
          trailing: Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
          ),
          enabled: enabled,
        ),
        Divider(
          height: 1.h,
          thickness: 1.h,
          indent: 18.w,
          endIndent: 25.w,
          color: Theme.of(context).dividerColor,
        ),
      ],
    );
  }
}
