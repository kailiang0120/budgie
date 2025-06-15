import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_theme.dart';

class CustomDropdownField<T> extends StatelessWidget {
  final T value;

  final List<T> items;

  final String labelText;

  final Function(T?) onChanged;

  final String Function(T) itemLabelBuilder;

  final IconData? prefixIcon;

  final bool isRequired;

  final String? Function(T?)? validator;

  final double borderRadius;

  const CustomDropdownField({
    Key? key,
    required this.value,
    required this.items,
    required this.labelText,
    required this.onChanged,
    required this.itemLabelBuilder,
    this.prefixIcon,
    this.isRequired = false,
    this.validator,
    this.borderRadius = 15.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: isRequired ? '$labelText *' : labelText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20.sp) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius.r),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          fontSize: 14.sp,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 16.h,
        ),
      ),
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemLabelBuilder(item),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16.sp,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 16.sp,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
      icon: Icon(
        Icons.arrow_drop_down,
        size: 24.sp,
        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
      ),
    );
  }
}
