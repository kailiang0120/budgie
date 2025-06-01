import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// 提交按钮组件
class SubmitButton extends StatelessWidget {
  /// 按钮文本
  final String text;

  /// 加载状态文本
  final String loadingText;

  /// 是否处于加载状态
  final bool isLoading;

  /// 点击回调
  final VoidCallback onPressed;

  /// 按钮颜色
  final Color? color;

  /// 边框圆角
  final double borderRadius;

  /// 图标
  final IconData? icon;

  /// 按钮宽度
  final double? width;

  /// 按钮高度
  final double height;

  const SubmitButton({
    Key? key,
    required this.text,
    this.loadingText = 'Processing...',
    required this.isLoading,
    required this.onPressed,
    this.color,
    this.borderRadius = 15.0,
    this.icon,
    this.width,
    this.height = 50.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primaryColor;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveColor.withAlpha((255 * 0.7).toInt()),
          disabledBackgroundColor:
              effectiveColor.withAlpha((255 * 0.5).toInt()),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loadingText,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    );
  }
}
