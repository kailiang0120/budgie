import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import 'date_picker_button.dart';

/// A widget to display the current budget month
class MonthDisplay extends StatelessWidget {
  final DateTime date;
  final Color? themeColor;
  final String? prefix;
  final bool showDay;
  final bool showYear;
  final DateFilterMode? filterMode;

  const MonthDisplay({
    super.key,
    required this.date,
    this.themeColor,
    this.prefix = 'Budget for',
    this.showDay = false,
    this.showYear = false,
    this.filterMode,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = themeColor ?? Theme.of(context).primaryColor;

    // Determine date format based on filter mode or legacy parameters
    String dateFormat;
    if (filterMode != null) {
      switch (filterMode!) {
        case DateFilterMode.day:
          dateFormat = 'dd MMMM yyyy';
          break;
        case DateFilterMode.month:
          dateFormat = 'MMMM yyyy';
          break;
        case DateFilterMode.year:
          dateFormat = 'yyyy';
          break;
      }
    } else {
      // Legacy support
      if (showYear) {
        dateFormat = 'yyyy';
      } else {
        dateFormat = showDay ? 'dd MMMM yyyy' : 'MMMM yyyy';
      }
    }

    return Container(
      height: 42.h, // Match the height of the toggle button for consistency
      padding: EdgeInsets.symmetric(
          vertical: AppConstants.spacingSmall.h,
          horizontal: AppConstants.spacingLarge.w),
      decoration: BoxDecoration(
        color: effectiveColor
            .withAlpha((255 * AppConstants.opacityOverlay).toInt()),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium.r),
        border: Border.all(
            color: effectiveColor
                .withAlpha((255 * AppConstants.opacityLow).toInt())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max, // Expand to fill available space
        mainAxisAlignment: MainAxisAlignment.start, // Align text to start
        children: [
          Icon(
            _getIconForFilterMode(),
            color: effectiveColor,
            size: AppConstants.iconSizeMedium.sp,
          ),
          SizedBox(width: AppConstants.spacingMedium.w),
          Expanded(
            // Use Expanded instead of Flexible to fill space
            child: Text(
              '$prefix ${DateFormat(dateFormat).format(date)}',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: AppConstants.textSizeMedium.sp,
                fontWeight: FontWeight.normal,
                color: effectiveColor,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start, // Ensure text is left-aligned
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForFilterMode() {
    if (filterMode != null) {
      switch (filterMode!) {
        case DateFilterMode.day:
          return Icons.today;
        case DateFilterMode.month:
          return Icons.calendar_month;
        case DateFilterMode.year:
          return Icons.date_range;
      }
    }

    // Legacy icon selection
    if (showYear) {
      return Icons.date_range;
    } else if (showDay) {
      return Icons.today;
    } else {
      return Icons.calendar_today;
    }
  }
}
