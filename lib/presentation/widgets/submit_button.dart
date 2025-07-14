import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';

class SubmitButton extends StatelessWidget {
  final String text;

  final String loadingText;

  final bool isLoading;

  final VoidCallback onPressed;

  final Color? color;

  final double borderRadius;

  final IconData? icon;

  final double? width;

  final double height;

  const SubmitButton({
    super.key,
    required this.text,
    this.loadingText = AppConstants.processingText,
    required this.isLoading,
    required this.onPressed,
    this.color,
    this.borderRadius = 45.0,
    this.icon,
    this.width,
    this.height = 45.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primaryColor;

    return SizedBox(
      width: width?.w,
      height: height.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveColor,
          disabledBackgroundColor: effectiveColor
              .withAlpha((255 * AppConstants.opacityMedium).toInt()),
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMedium.w,
            vertical: AppConstants.spacingMedium.h,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusCircular.r),
          ),
          elevation: AppConstants.elevationStandard,
        ),
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: AppConstants.iconSizeSmall.w,
                    height: AppConstants.iconSizeSmall.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: AppConstants.spacingMedium.w),
                  Text(
                    loadingText,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: AppConstants.textSizeLarge.sp,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppConstants.iconSizeMedium.sp),
          SizedBox(width: AppConstants.spacingSmall.w),
          Text(
            text,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: AppConstants.textSizeLarge.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: AppConstants.textSizeLarge.sp,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    );
  }
}
