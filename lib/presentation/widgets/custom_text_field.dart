import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';

/// 自定义文本输入字段组件 - Responsive Design
class CustomTextField extends StatefulWidget {
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

  /// 自定义后缀图标widget (用于更复杂的后缀)
  final Widget? suffixIconWidget;

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

  /// 是否启用 (用于禁用字段)
  final bool enabled;

  /// 自动焦点
  final bool autofocus;

  /// 文本输入操作
  final TextInputAction? textInputAction;

  /// 提交回调
  final VoidCallback? onEditingComplete;

  /// 字段提交回调
  final Function(String)? onFieldSubmitted;

  /// 是否自动纠正
  final bool autocorrect;

  /// 是否启用建议
  final bool enableSuggestions;

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
    this.suffixIconWidget,
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
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.autocorrect = true,
    this.enableSuggestions = true,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();

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
    bool enabled = true,
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
      enabled: enabled,
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
    bool enabled = true,
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
      enabled: enabled,
    );
  }
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    // Initialize password visibility
    _obscureText = widget.isPassword;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Widget? _buildSuffixIcon() {
    // If custom suffix widget is provided, use it
    if (widget.suffixIconWidget != null) {
      return widget.suffixIconWidget;
    }

    // If it's a password field, show password visibility toggle
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          size: 20.sp,
        ),
        onPressed: _togglePasswordVisibility,
        splashRadius: 20.r,
      );
    }

    // Default suffix icon
    if (widget.suffixIcon != null) {
      return Icon(widget.suffixIcon, size: 20.sp);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      decoration: InputDecoration(
        labelText:
            widget.isRequired ? '${widget.labelText} *' : widget.labelText,
        hintText: widget.hintText,
        helperText: widget.helperText,
        errorText: widget.errorText,
        prefixText: widget.prefixText,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20.sp)
            : null,
        suffixText: widget.suffixText,
        suffixIcon: _buildSuffixIcon(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius.r),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius.r),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
            width: 1.w,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius.r),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2.w,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius.r),
          borderSide: BorderSide(
            color: Colors.red,
            width: 1.w,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius.r),
          borderSide: BorderSide(
            color: Colors.red,
            width: 2.w,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius.r),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            width: 1.w,
          ),
        ),
        filled: true,
        fillColor: widget.enabled
            ? Theme.of(context).cardColor
            : (isDarkMode ? Colors.grey[800] : Colors.grey[100]),
        labelStyle: TextStyle(
          color: widget.enabled
              ? (isDarkMode ? Colors.grey[300] : Colors.grey[700])
              : (isDarkMode ? Colors.grey[500] : Colors.grey[400]),
          fontSize: 14.sp,
        ),
        hintStyle: TextStyle(
          color: widget.enabled
              ? (isDarkMode ? Colors.grey[400] : Colors.grey[500])
              : (isDarkMode ? Colors.grey[600] : Colors.grey[300]),
          fontSize: 14.sp,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 16.h,
        ),
      ),
      keyboardType:
          widget.isMultiline ? TextInputType.multiline : widget.keyboardType,
      obscureText: widget.isPassword ? _obscureText : false,
      maxLines: widget.isPassword
          ? 1
          : (widget.isMultiline ? widget.maxLines ?? 5 : widget.maxLines ?? 1),
      minLines: widget.isMultiline ? widget.minLines ?? 3 : null,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      validator: widget.validator ??
          (widget.isRequired
              ? (value) => (value == null || value.isEmpty)
                  ? AppConstants.requiredFieldMessage
                  : null
              : null),
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 16.sp,
        color: widget.enabled
            ? Theme.of(context).textTheme.bodyMedium?.color
            : (isDarkMode ? Colors.grey[500] : Colors.grey[400]),
      ),
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onFieldSubmitted,
      autocorrect: widget.isPassword ? false : widget.autocorrect,
      enableSuggestions: widget.isPassword ? false : widget.enableSuggestions,
    );
  }
}
