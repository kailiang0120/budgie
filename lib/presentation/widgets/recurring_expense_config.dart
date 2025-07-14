import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/recurring_expense.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import 'custom_dropdown_field.dart';
import 'date_time_picker_field.dart';

/// Widget for configuring recurring expense settings
class RecurringExpenseConfig extends StatefulWidget {
  final RecurringFrequency initialFrequency;
  final int? initialDayOfMonth;
  final DayOfWeek? initialDayOfWeek;
  final DateTime? initialEndDate;
  final ValueChanged<RecurringFrequency> onFrequencyChanged;
  final ValueChanged<int?> onDayOfMonthChanged;
  final ValueChanged<DayOfWeek?> onDayOfWeekChanged;
  final ValueChanged<DateTime?> onEndDateChanged;

  const RecurringExpenseConfig({
    super.key,
    required this.initialFrequency,
    this.initialDayOfMonth,
    this.initialDayOfWeek,
    this.initialEndDate,
    required this.onFrequencyChanged,
    required this.onDayOfMonthChanged,
    required this.onDayOfWeekChanged,
    required this.onEndDateChanged,
  });

  @override
  State<RecurringExpenseConfig> createState() => _RecurringExpenseConfigState();
}

class _RecurringExpenseConfigState extends State<RecurringExpenseConfig> {
  late RecurringFrequency _selectedFrequency;
  int? _selectedDayOfMonth;
  DayOfWeek? _selectedDayOfWeek;
  DateTime? _selectedEndDate;

  // Only weekly and monthly frequencies are available
  final List<String> _frequencyOptions = ['Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    _selectedFrequency = widget.initialFrequency;
    _selectedDayOfMonth = widget.initialDayOfMonth;
    _selectedDayOfWeek = widget.initialDayOfWeek;
    _selectedEndDate = widget.initialEndDate;

    // Ensure default values are set
    if (_selectedFrequency == RecurringFrequency.weekly &&
        _selectedDayOfWeek == null) {
      _selectedDayOfWeek = DayOfWeek.monday;
      widget.onDayOfWeekChanged(_selectedDayOfWeek);
    }

    if (_selectedFrequency == RecurringFrequency.monthly &&
        _selectedDayOfMonth == null) {
      _selectedDayOfMonth = 1;
      widget.onDayOfMonthChanged(_selectedDayOfMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.elevationStandard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge.r),
      ),
      child: Padding(
        padding: AppConstants.containerPaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recurring Settings',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: AppConstants.textSizeXLarge.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: AppConstants.spacingLarge.h),

            // Frequency selection
            CustomDropdownField<String>(
              value: _selectedFrequency.displayName,
              items: _frequencyOptions,
              labelText: 'Frequency',
              onChanged: (value) {
                if (value != null) {
                  final frequency = _getFrequencyFromDisplayName(value);
                  if (frequency != null) {
                    setState(() {
                      _selectedFrequency = frequency;
                      // Reset day selections when frequency changes
                      if (frequency != RecurringFrequency.monthly) {
                        _selectedDayOfMonth = null;
                        widget.onDayOfMonthChanged(null);
                      }
                      if (frequency != RecurringFrequency.weekly) {
                        _selectedDayOfWeek = null;
                        widget.onDayOfWeekChanged(null);
                      } else {
                        // Set default day of week to Monday if not already set
                        if (_selectedDayOfWeek == null) {
                          _selectedDayOfWeek = DayOfWeek.monday;
                          widget.onDayOfWeekChanged(_selectedDayOfWeek);
                        }
                      }

                      // Set default day of month to 1 if monthly and not already set
                      if (frequency == RecurringFrequency.monthly &&
                          _selectedDayOfMonth == null) {
                        _selectedDayOfMonth = 1;
                        widget.onDayOfMonthChanged(_selectedDayOfMonth);
                      }
                    });
                    widget.onFrequencyChanged(frequency);
                  }
                }
              },
              itemLabelBuilder: (item) => item,
              prefixIcon: Icons.repeat,
              borderRadius: AppConstants.borderRadiusMedium,
            ),

            // Conditional fields based on frequency
            if (_selectedFrequency == RecurringFrequency.weekly) ...[
              SizedBox(height: AppConstants.spacingLarge.h),
              CustomDropdownField<String>(
                value: _selectedDayOfWeek?.displayName ??
                    AppConstants.daysOfWeek.first,
                items: AppConstants.daysOfWeek,
                labelText: 'Day of Week',
                onChanged: (value) {
                  if (value != null) {
                    final dayOfWeek = _getDayOfWeekFromDisplayName(value);
                    setState(() {
                      _selectedDayOfWeek = dayOfWeek;
                    });
                    widget.onDayOfWeekChanged(dayOfWeek);
                  }
                },
                itemLabelBuilder: (item) => item,
                prefixIcon: Icons.today,
                borderRadius: AppConstants.borderRadiusMedium,
              ),
            ],

            if (_selectedFrequency == RecurringFrequency.monthly) ...[
              SizedBox(height: AppConstants.spacingLarge.h),
              CustomDropdownField<String>(
                value: _selectedDayOfMonth?.toString() ?? '1',
                items: AppConstants.getDaysOfMonth(),
                labelText: 'Day of Month',
                onChanged: (value) {
                  if (value != null) {
                    final dayOfMonth = int.tryParse(value);
                    setState(() {
                      _selectedDayOfMonth = dayOfMonth;
                    });
                    widget.onDayOfMonthChanged(dayOfMonth);
                  }
                },
                itemLabelBuilder: (item) => item,
                prefixIcon: Icons.calendar_today,
                borderRadius: AppConstants.borderRadiusMedium,
              ),
            ],

            // End date selection (optional) - now always shown for recurring expenses
            SizedBox(height: AppConstants.spacingLarge.h),
            Text(
              'End Date (Optional)',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: AppConstants.textSizeMedium.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppConstants.spacingSmall.h),
            if (_selectedEndDate != null)
              DateTimePickerField(
                dateTime: _selectedEndDate!,
                onDateChanged: (date) {
                  setState(() {
                    _selectedEndDate = date;
                  });
                  widget.onEndDateChanged(date);
                },
                onTimeChanged: (time) {
                  // Just update the date without changing time
                  setState(() {
                    _selectedEndDate = time;
                  });
                  widget.onEndDateChanged(time);
                },
                onCurrentTimePressed: () {
                  final now = DateTime.now();
                  setState(() {
                    _selectedEndDate = now;
                  });
                  widget.onEndDateChanged(now);
                },
              ),
            if (_selectedEndDate == null)
              OutlinedButton.icon(
                onPressed: () {
                  final now = DateTime.now().add(const Duration(days: 30));
                  setState(() {
                    _selectedEndDate = now;
                  });
                  widget.onEndDateChanged(now);
                },
                icon: Icon(
                  Icons.date_range,
                  size: AppConstants.iconSizeMedium.sp,
                ),
                label: Text(
                  'Set End Date',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: AppConstants.textSizeMedium.sp,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: EdgeInsets.symmetric(
                    vertical: AppConstants.spacingMedium.h,
                    horizontal: AppConstants.spacingLarge.w,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium.r),
                  ),
                ),
              ),
            if (_selectedEndDate != null) ...[
              SizedBox(height: AppConstants.spacingSmall.h),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedEndDate = null;
                  });
                  widget.onEndDateChanged(null);
                },
                icon: Icon(
                  Icons.clear,
                  size: AppConstants.iconSizeSmall.sp,
                  color: Colors.red.shade700,
                ),
                label: Text(
                  'Remove End Date',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: AppConstants.textSizeSmall.sp,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  RecurringFrequency? _getFrequencyFromDisplayName(String name) {
    switch (name) {
      case 'Weekly':
        return RecurringFrequency.weekly;
      case 'Monthly':
        return RecurringFrequency.monthly;
      default:
        return null;
    }
  }

  DayOfWeek? _getDayOfWeekFromDisplayName(String name) {
    final index = AppConstants.daysOfWeek.indexOf(name);
    if (index >= 0) {
      return DayOfWeek.values[index];
    }
    return null;
  }
}
