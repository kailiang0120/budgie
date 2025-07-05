// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

/// Filter modes for date picker
enum DateFilterMode {
  day,
  month,
  year,
}

/// A comprehensive date picker and filter component with modern UI design
class DatePickerButton extends StatelessWidget {
  /// Current selected date
  final DateTime date;

  /// Theme color for the component
  final Color? themeColor;

  /// Prefix text to show before the date
  final String? prefix;

  /// Callback when date is changed
  final Function(DateTime) onDateChanged;

  /// First date available in picker
  final DateTime? firstDate;

  /// Last date available in picker
  final DateTime? lastDate;

  /// Whether to show day selection (false = month only)
  final bool showDaySelection;

  /// Filter mode for the date picker
  final DateFilterMode? filterMode;

  /// Callback when filter mode is changed
  final Function(DateFilterMode)? onFilterModeChanged;

  /// Whether to show the filter mode selector
  final bool showFilterModeSelector;

  /// Custom width for the component (null = full width)
  final double? width;

  const DatePickerButton({
    Key? key,
    required this.date,
    required this.onDateChanged,
    this.themeColor,
    this.prefix,
    this.firstDate,
    this.lastDate,
    this.showDaySelection = false,
    this.filterMode,
    this.onFilterModeChanged,
    this.showFilterModeSelector = true,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveThemeColor = themeColor ?? Theme.of(context).primaryColor;
    final effectiveFirstDate = firstDate ?? DateTime(2020);
    final effectiveLastDate = lastDate ?? DateTime(2100);
    final effectiveFilterMode = filterMode ?? DateFilterMode.month;

    return Container(
      width: width,
      padding: EdgeInsets.all(AppConstants.spacingMedium.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
        border: Border.all(
          color: effectiveThemeColor.withAlpha((255 * 0.1).toInt()),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.04).toInt()),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Mode Selector with modern chip design
          if (showFilterModeSelector &&
              filterMode != null &&
              onFilterModeChanged != null) ...[
            Row(
              children: [
                Icon(
                  Icons.tune,
                  size: AppConstants.iconSizeSmall.sp,
                  color: Colors.grey[600],
                ),
                SizedBox(width: AppConstants.spacingSmall.w),
                Text(
                  prefix ?? 'Filter by',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: AppConstants.textSizeSmall.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: AppConstants.spacingMedium.w),
                Expanded(
                  child: Row(
                    children: DateFilterMode.values.map((mode) {
                      final isSelected = mode == effectiveFilterMode;
                      final isLast = mode == DateFilterMode.values.last;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: isLast ? 0 : AppConstants.spacingSmall.w,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onFilterModeChanged!(mode),
                              borderRadius: BorderRadius.circular(
                                AppConstants.borderRadiusMedium.r,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppConstants.spacingSmall.w,
                                  vertical: AppConstants.spacingSmall.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? effectiveThemeColor
                                      : effectiveThemeColor
                                          .withAlpha((255 * 0.08).toInt()),
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadiusMedium.r,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? effectiveThemeColor
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getIconForMode(mode),
                                      size: AppConstants.iconSizeSmall.sp,
                                      color: isSelected
                                          ? Colors.white
                                          : effectiveThemeColor,
                                    ),
                                    SizedBox(width: 4.w),
                                    Flexible(
                                      child: Text(
                                        _getModeDisplayName(mode),
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize:
                                              AppConstants.textSizeSmall.sp,
                                          color: isSelected
                                              ? Colors.white
                                              : effectiveThemeColor,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingMedium.h),
          ],

          // Date Display and Picker
          InkWell(
            onTap: () => _showDatePicker(context, effectiveThemeColor,
                effectiveFirstDate, effectiveLastDate, effectiveFilterMode),
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusMedium.r),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMedium.w,
                vertical: AppConstants.spacingMedium.h,
              ),
              decoration: BoxDecoration(
                color: effectiveThemeColor.withAlpha((255 * 0.05).toInt()),
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusMedium.r),
                border: Border.all(
                  color: effectiveThemeColor.withAlpha((255 * 0.2).toInt()),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppConstants.spacingSmall.w),
                    decoration: BoxDecoration(
                      color: effectiveThemeColor.withAlpha((255 * 0.1).toInt()),
                      borderRadius:
                          BorderRadius.circular(AppConstants.spacingSmall.r),
                    ),
                    child: Icon(
                      _getIconForMode(effectiveFilterMode),
                      size: AppConstants.iconSizeSmall.sp,
                      color: effectiveThemeColor,
                    ),
                  ),
                  SizedBox(width: AppConstants.spacingMedium.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Showing ${_getModeDisplayName(effectiveFilterMode).toLowerCase()} data',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: AppConstants.textSizeSmall.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _getFormattedDate(effectiveFilterMode),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: AppConstants.textSizeMedium.sp,
                            color: effectiveThemeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    size: AppConstants.iconSizeSmall.sp,
                    color: effectiveThemeColor.withAlpha((255 * 0.7).toInt()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForMode(DateFilterMode mode) {
    switch (mode) {
      case DateFilterMode.day:
        return Icons.today;
      case DateFilterMode.month:
        return Icons.calendar_view_month;
      case DateFilterMode.year:
        return Icons.date_range;
    }
  }

  String _getModeDisplayName(DateFilterMode mode) {
    switch (mode) {
      case DateFilterMode.day:
        return 'Day';
      case DateFilterMode.month:
        return 'Month';
      case DateFilterMode.year:
        return 'Year';
    }
  }

  String _getFormattedDate(DateFilterMode filterMode) {
    switch (filterMode) {
      case DateFilterMode.day:
        return '${date.day.toString().padLeft(2, '0')} ${_getMonthName(date.month)} ${date.year}';
      case DateFilterMode.month:
        return '${_getMonthName(date.month)} ${date.year}';
      case DateFilterMode.year:
        return '${date.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Future<void> _showDatePicker(BuildContext context, Color themeColor,
      DateTime firstDate, DateTime lastDate, DateFilterMode filterMode) async {
    try {
      DateTime? selectedDate;

      switch (filterMode) {
        case DateFilterMode.day:
          selectedDate = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: firstDate,
            lastDate: lastDate,
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: themeColor,
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
          break;

        case DateFilterMode.month:
          selectedDate = await _showMonthYearPicker(
              context, themeColor, firstDate, lastDate);
          break;

        case DateFilterMode.year:
          selectedDate =
              await _showYearPicker(context, themeColor, firstDate, lastDate);
          break;
      }

      if (selectedDate != null && selectedDate != date) {
        onDateChanged(selectedDate);
      }
    } catch (e) {
      debugPrint('Error showing date picker: $e');
    }
  }

  Future<DateTime?> _showMonthYearPicker(BuildContext context, Color themeColor,
      DateTime firstDate, DateTime lastDate) async {
    return await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return _MonthYearPickerDialog(
          initialDate: date,
          firstDate: firstDate,
          lastDate: lastDate,
          themeColor: themeColor,
        );
      },
    );
  }

  Future<DateTime?> _showYearPicker(BuildContext context, Color themeColor,
      DateTime firstDate, DateTime lastDate) async {
    return await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return _YearPickerDialog(
          initialDate: date,
          firstDate: firstDate,
          lastDate: lastDate,
          themeColor: themeColor,
        );
      },
    );
  }

  /// Show a custom month-only picker
  Future<void> _showMonthPicker(BuildContext context, Color themeColor,
      DateTime firstDate, DateTime lastDate) async {
    try {
      final DateTime? result = await showDialog<DateTime>(
        context: context,
        builder: (BuildContext context) {
          return _MonthYearPickerDialog(
            initialDate: date,
            firstDate: firstDate,
            lastDate: lastDate,
            themeColor: themeColor,
          );
        },
      );

      if (result != null &&
          (result.year != date.year || result.month != date.month)) {
        // Preserve the day from the original date
        final newDate = DateTime(result.year, result.month, date.day);
        onDateChanged(newDate);
      }
    } catch (e) {
      debugPrint('Error in month picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open month picker: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Custom month year picker dialog
class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color themeColor;

  const _MonthYearPickerDialog({
    Key? key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.themeColor,
  }) : super(key: key);

  @override
  _MonthYearPickerDialogState createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  late PageController _yearController;

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;

    // Position the year page view to show the initial year
    final initialYearIndex = _selectedYear - widget.firstDate.year;
    _yearController = PageController(initialPage: initialYearIndex);
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableYears = List<int>.generate(
      widget.lastDate.year - widget.firstDate.year + 1,
      (index) => widget.firstDate.year + index,
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingLarge.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Month and Year',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: AppConstants.textSizeXLarge.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppConstants.spacingLarge.h),
            // Month selector
            Container(
              height: AppConstants.componentHeightStandard,
              decoration: BoxDecoration(
                color: widget.themeColor
                    .withAlpha((255 * AppConstants.opacityOverlay).toInt()),
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusMedium.r),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _months.length,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final isSelected = month == _selectedMonth;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMonth = month;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingMedium.w),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? widget.themeColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium.r),
                      ),
                      child: Text(
                        _months[index].substring(0, 3),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontFamily: AppTheme.fontFamily,
                          fontSize: AppConstants.textSizeMedium.sp,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: AppConstants.spacingLarge.h),
            // Year selector
            SizedBox(
              height: AppConstants.componentHeightStandard,
              child: PageView.builder(
                controller: _yearController,
                itemCount: availableYears.length,
                onPageChanged: (index) {
                  setState(() {
                    _selectedYear = widget.firstDate.year + index;
                  });
                },
                itemBuilder: (context, index) {
                  final year = widget.firstDate.year + index;
                  return Center(
                    child: Text(
                      year.toString(),
                      style: TextStyle(
                        fontSize: AppConstants.textSizeXLarge.sp,
                        fontWeight: FontWeight.w600,
                        color: widget.themeColor,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: AppConstants.spacingLarge.h),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    AppConstants.cancelButtonText,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: AppConstants.textSizeMedium.sp,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ),
                SizedBox(width: AppConstants.spacingMedium.w),
                TextButton(
                  onPressed: () {
                    final selectedDate =
                        DateTime(_selectedYear, _selectedMonth);
                    Navigator.pop(context, selectedDate);
                  },
                  child: Text(
                    AppConstants.confirmButtonText,
                    style: TextStyle(
                      color: widget.themeColor,
                      fontSize: AppConstants.textSizeMedium.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom year picker dialog
class _YearPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color themeColor;

  const _YearPickerDialog({
    Key? key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.themeColor,
  }) : super(key: key);

  @override
  _YearPickerDialogState createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  late int _selectedYear;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;

    // Calculate initial scroll position to center on selected year
    final yearIndex = _selectedYear - widget.firstDate.year;
    final itemHeight = 56.0;
    final initialOffset = yearIndex * itemHeight;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableYears = List<int>.generate(
      widget.lastDate.year - widget.firstDate.year + 1,
      (index) => widget.firstDate.year + index,
    );

    return AlertDialog(
      title: Text(
        'Select Year',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: widget.themeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 200.w,
        height: 300.h,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: availableYears.length,
          itemBuilder: (context, index) {
            final year = availableYears[index];
            final isSelected = year == _selectedYear;

            return ListTile(
              title: Text(
                year.toString(),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: AppConstants.textSizeLarge.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? widget.themeColor : null,
                ),
                textAlign: TextAlign.center,
              ),
              selected: isSelected,
              selectedTileColor: widget.themeColor.withOpacity(0.1),
              onTap: () {
                setState(() {
                  _selectedYear = year;
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(DateTime(_selectedYear, 1, 1));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.themeColor,
          ),
          child: const Text(
            'OK',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
