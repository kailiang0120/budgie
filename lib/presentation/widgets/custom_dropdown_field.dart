import 'package:flutter/material.dart';
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
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  itemLabelBuilder(item),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: isRequired ? '$labelText *' : labelText,
        labelStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator ??
          (isRequired
              ? (value) => value == null ? 'Please select $labelText' : null
              : null),
      iconEnabledColor: Theme.of(context).colorScheme.primary,
      dropdownColor: Theme.of(context).cardColor,
    );
  }
}
