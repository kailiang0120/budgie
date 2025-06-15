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
    Key? key,
    required this.initialFrequency,
    this.initialDayOfMonth,
    this.initialDayOfWeek,
    this.initialEndDate,
    required this.onFrequencyChanged,
    required this.onDayOfMonthChanged,
    required this.onDayOfWeekChanged,
    required this.onEndDateChanged,
  }) : super(key: key);

  @override
  State<RecurringExpenseConfig> createState() => _RecurringExpenseConfigState();
}

class _RecurringExpenseConfigState extends State<RecurringExpenseConfig> {
  late RecurringFrequency _selectedFrequency;
  int? _selectedDayOfMonth;
  DayOfWeek? _selectedDayOfWeek;
  DateTime? _selectedEndDate;

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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recurring Settings',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 16.h),

            // Frequency selection
            CustomDropdownField<String>(
              value: _selectedFrequency.displayName,
              items: AppConstants.recurringOptions,
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
            ),

            // Conditional fields based on frequency
            if (_selectedFrequency == RecurringFrequency.weekly) ...[
              SizedBox(height: 16.h),
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
              ),
            ],

            if (_selectedFrequency == RecurringFrequency.monthly) ...[
              SizedBox(height: 16.h),
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
              ),
            ],

            // End date selection (optional)
            if (_selectedFrequency != RecurringFrequency.oneTime) ...[
              SizedBox(height: 16.h),
              Text(
                'End Date (Optional)',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
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
                  showCurrentTimeButton: false,
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    final tomorrow =
                        DateTime.now().add(const Duration(days: 1));
                    setState(() {
                      _selectedEndDate = tomorrow;
                    });
                    widget.onEndDateChanged(tomorrow);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Set End Date'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 16.w,
                    ),
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                    foregroundColor: AppTheme.primaryColor,
                    elevation: 0,
                  ),
                ),
              if (_selectedEndDate != null) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recurring until ${_formatDate(_selectedEndDate!)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedEndDate = null;
                        });
                        widget.onEndDateChanged(null);
                      },
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              ],
            ],

            // Help text
            if (_selectedFrequency != RecurringFrequency.oneTime) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16.sp,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _getHelpText(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.primaryColor,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  RecurringFrequency? _getFrequencyFromDisplayName(String displayName) {
    switch (displayName) {
      case 'One-time':
        return RecurringFrequency.oneTime;
      case 'Weekly':
        return RecurringFrequency.weekly;
      case 'Monthly':
        return RecurringFrequency.monthly;
      default:
        return null;
    }
  }

  DayOfWeek? _getDayOfWeekFromDisplayName(String displayName) {
    switch (displayName) {
      case 'Monday':
        return DayOfWeek.monday;
      case 'Tuesday':
        return DayOfWeek.tuesday;
      case 'Wednesday':
        return DayOfWeek.wednesday;
      case 'Thursday':
        return DayOfWeek.thursday;
      case 'Friday':
        return DayOfWeek.friday;
      case 'Saturday':
        return DayOfWeek.saturday;
      case 'Sunday':
        return DayOfWeek.sunday;
      default:
        return null;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getHelpText() {
    switch (_selectedFrequency) {
      case RecurringFrequency.weekly:
        final day = _selectedDayOfWeek?.displayName ?? 'the selected day';
        return 'This expense will be automatically recorded every $day.';
      case RecurringFrequency.monthly:
        final dayText = _selectedDayOfMonth != null
            ? 'the $_selectedDayOfMonth${_getOrdinalSuffix(_selectedDayOfMonth!)}'
            : 'the selected day';
        return 'This expense will be automatically recorded on $dayText of each month.';
      case RecurringFrequency.oneTime:
        return '';
    }
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) {
      return 'th';
    }
    switch (number % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
