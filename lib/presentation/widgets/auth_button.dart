import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

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
        padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMedium.h),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.borderRadiusCircular.r),
        ),
        disabledBackgroundColor: backgroundColor
            .withAlpha((255 * AppConstants.opacityDisabled).toInt()),
        disabledForegroundColor:
            textColor.withAlpha((255 * AppConstants.opacityDisabled).toInt()),
        elevation: AppConstants.elevationStandard,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leadingIcon,
          SizedBox(width: AppConstants.spacingMedium.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: AppConstants.textSizeLarge.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
