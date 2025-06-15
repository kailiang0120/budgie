import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthButton extends StatelessWidget {
  final String label;
  final Widget leadingIcon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;

  const AuthButton({
    Key? key,
    required this.label,
    required this.leadingIcon,
    required this.backgroundColor,
    this.textColor = const Color(0xFFF5F5F5),
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(45.r),
        ),
        disabledBackgroundColor: backgroundColor.withAlpha((255 * 0.6).toInt()),
        disabledForegroundColor: textColor.withAlpha((255 * 0.6).toInt()),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leadingIcon,
          SizedBox(width: 12.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
