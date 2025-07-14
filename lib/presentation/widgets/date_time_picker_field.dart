import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';

/// 日期和时间选择器组件 - Responsive Design
class DateTimePickerField extends StatelessWidget {
  /// 当前选择的日期时间
  final DateTime dateTime;

  /// 日期变更回调
  final Function(DateTime) onDateChanged;

  /// 时间变更回调
  final Function(DateTime) onTimeChanged;

  /// 设置为当前时间的回调
  final Function() onCurrentTimePressed;

  /// 主题色
  final Color? themeColor;

  /// 日期格式
  final DateFormat? dateFormat;

  /// 时间格式
  final DateFormat? timeFormat;

  /// 是否显示"当前时间"按钮
  final bool showCurrentTimeButton;

  const DateTimePickerField({
    super.key,
    required this.dateTime,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.onCurrentTimePressed,
    this.themeColor,
    this.dateFormat,
    this.timeFormat,
    this.showCurrentTimeButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveThemeColor = themeColor ?? AppTheme.primaryColor;
    final effectiveDateFormat =
        dateFormat ?? DateFormat(AppConstants.dateFormat);
    final effectiveTimeFormat =
        timeFormat ?? DateFormat(AppConstants.timeFormat);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(context, effectiveThemeColor),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMedium.w,
                    vertical: AppConstants.spacingMedium.h,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(
                        color: isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade400),
                    borderRadius: BorderRadius.only(
                      topLeft:
                          Radius.circular(AppConstants.borderRadiusMedium.r),
                      bottomLeft:
                          Radius.circular(AppConstants.borderRadiusMedium.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: effectiveThemeColor,
                          size: AppConstants.iconSizeMedium.sp),
                      SizedBox(width: AppConstants.spacingSmall.w),
                      Text(
                        effectiveDateFormat.format(dateTime),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: AppConstants.textSizeMedium.sp,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 1.w,
              height: AppConstants.componentHeightStandard * 0.8,
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
            Expanded(
              child: InkWell(
                onTap: () => _pickTime(context, effectiveThemeColor),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMedium.w,
                    vertical: AppConstants.spacingMedium.h,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(
                        color: isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade400),
                    borderRadius: BorderRadius.only(
                      topRight:
                          Radius.circular(AppConstants.borderRadiusMedium.r),
                      bottomRight:
                          Radius.circular(AppConstants.borderRadiusMedium.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          color: effectiveThemeColor,
                          size: AppConstants.iconSizeMedium.sp),
                      SizedBox(width: AppConstants.spacingSmall.w),
                      Text(
                        effectiveTimeFormat.format(dateTime),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: AppConstants.textSizeMedium.sp,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showCurrentTimeButton) ...[
          SizedBox(height: AppConstants.spacingSmall.h),
          ElevatedButton.icon(
            onPressed: onCurrentTimePressed,
            icon: Icon(Icons.access_time, size: AppConstants.iconSizeSmall.sp),
            label: Text(
              AppConstants.currentTimeButtonText,
              style: TextStyle(
                fontSize: AppConstants.textSizeMedium.sp,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: effectiveThemeColor,
              foregroundColor: Colors.white,
              elevation: AppConstants.elevationSmall,
              padding:
                  EdgeInsets.symmetric(vertical: AppConstants.spacingMedium.h),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusMedium.r),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, Color themeColor) async {
    final date = await showDatePicker(
      context: context,
      initialDate: dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: themeColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      onDateChanged(DateTime(
        date.year,
        date.month,
        date.day,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
      ));
    }
  }

  Future<void> _pickTime(BuildContext context, Color themeColor) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(dateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: themeColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      onTimeChanged(DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        time.hour,
        time.minute,
      ));
    }
  }
}
