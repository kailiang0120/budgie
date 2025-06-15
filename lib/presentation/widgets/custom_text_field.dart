import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';

/// 自定义文本输入字段组件 - Responsive Design
class CustomTextField extends StatelessWidget {
  /// 控制器
  final TextEditingController? controller;

  /// 初始值
  final String? initialValue;

  /// 标签文本
  final String labelText;

  /// 提示文本
  final String? hintText;

  /// 帮助文本
  final String? helperText;

  /// 错误文本
  final String? errorText;

  /// 前缀文本
  final String? prefixText;

  /// 前缀图标
  final IconData? prefixIcon;

  /// 后缀文本
  final String? suffixText;

  /// 后缀图标
  final IconData? suffixIcon;

  /// 值变更回调
  final Function(String)? onChanged;

  /// 验证器
  final String? Function(String?)? validator;

  /// 键盘类型
  final TextInputType keyboardType;

  /// 输入格式化器
  final List<TextInputFormatter>? inputFormatters;

  /// 是否必填
  final bool isRequired;

  /// 是否密码输入
  final bool isPassword;

  /// 是否多行输入
  final bool isMultiline;

  /// 最大行数
  final int? maxLines;

  /// 最小行数
  final int? minLines;

  /// 边框圆角
  final double borderRadius;

  const CustomTextField({
    Key? key,
    this.controller,
    this.initialValue,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixText,
    this.prefixIcon,
    this.suffixText,
    this.suffixIcon,
    this.onChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.isRequired = false,
    this.isPassword = false,
    this.isMultiline = false,
    this.maxLines,
    this.minLines,
    this.borderRadius = 15.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      decoration: InputDecoration(
        labelText: isRequired ? '$labelText *' : labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixText: prefixText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20.sp) : null,
        suffixText: suffixText,
        suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 20.sp) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius.r),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          fontSize: 14.sp,
        ),
        hintStyle: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
          fontSize: 14.sp,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 16.h,
        ),
      ),
      keyboardType: isMultiline ? TextInputType.multiline : keyboardType,
      obscureText: isPassword,
      maxLines: isPassword ? 1 : (isMultiline ? maxLines ?? 5 : maxLines ?? 1),
      minLines: isMultiline ? minLines ?? 3 : null,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      validator: validator ??
          (isRequired
              ? (value) => (value == null || value.isEmpty)
                  ? AppConstants.requiredFieldMessage
                  : null
              : null),
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 16.sp,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
    );
  }

  /// 创建一个数字输入字段
  factory CustomTextField.number({
    TextEditingController? controller,
    String? initialValue,
    required String labelText,
    String? hintText,
    String? helperText,
    String? errorText,
    String? prefixText,
    IconData? prefixIcon,
    String? suffixText,
    Function(String)? onChanged,
    String? Function(String?)? validator,
    bool isRequired = false,
    bool allowDecimal = true,
    bool allowZero = false,
    int? maxLength,
    double borderRadius = 15.0,
  }) {
    return CustomTextField(
      controller: controller,
      initialValue: initialValue,
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      prefixText: prefixText,
      prefixIcon: prefixIcon ?? Icons.attach_money,
      suffixText: suffixText,
      onChanged: onChanged,
      validator: validator ??
          (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return AppConstants.requiredFieldMessage;
            }
            if (value != null && value.isNotEmpty) {
              if (double.tryParse(value) == null) {
                return AppConstants.invalidNumberMessage;
              }
              // Only validate positive if zero is not allowed
              if (!allowZero && double.parse(value) <= 0) {
                return AppConstants.positiveNumberMessage;
              }
              // When allowZero is true, we only check for negative values
              if (allowZero && double.parse(value) < 0) {
                return 'Value cannot be negative';
              }
            }
            return null;
          },
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        if (allowDecimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        if (!allowDecimal) FilteringTextInputFormatter.digitsOnly,
      ],
      isRequired: isRequired,
      borderRadius: borderRadius,
    );
  }

  /// 创建一个货币输入字段
  factory CustomTextField.currency({
    TextEditingController? controller,
    String? initialValue,
    required String labelText,
    String? hintText,
    String? helperText,
    String? errorText,
    String currencySymbol = 'MYR',
    Function(String)? onChanged,
    String? Function(String?)? validator,
    bool isRequired = false,
    bool allowZero = false,
    double borderRadius = 15.0,
  }) {
    return CustomTextField.number(
      controller: controller,
      initialValue: initialValue,
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: Icons.attach_money,
      suffixText: currencySymbol,
      onChanged: onChanged,
      validator: validator ??
          (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return AppConstants.requiredFieldMessage;
            }
            if (value != null && value.isNotEmpty) {
              if (double.tryParse(value) == null) {
                return AppConstants.invalidNumberMessage;
              }
              // Only validate positive if zero is not allowed
              if (!allowZero && double.parse(value) <= 0) {
                return AppConstants.positiveNumberMessage;
              }
              // When allowZero is true, we only check for negative values
              if (allowZero && double.parse(value) < 0) {
                return 'Value cannot be negative';
              }
            }
            return null;
          },
      isRequired: isRequired,
      allowDecimal: true,
      borderRadius: borderRadius,
    );
  }
}
