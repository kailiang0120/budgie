// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'month_display.dart';

/// A reusable date picker button that provides a consistent UI across the app
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

  const DatePickerButton({
    Key? key,
    required this.date,
    required this.onDateChanged,
    this.themeColor,
    this.prefix,
    this.firstDate,
    this.lastDate,
    this.showDaySelection = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveThemeColor = themeColor ?? Theme.of(context).primaryColor;
    final effectiveFirstDate = firstDate ?? DateTime(2020);
    final effectiveLastDate = lastDate ?? DateTime(2100);

    return InkWell(
      onTap: () {
        if (showDaySelection) {
          _showDatePicker(context, effectiveThemeColor, effectiveFirstDate,
              effectiveLastDate);
        } else {
          _showMonthPicker(context, effectiveThemeColor, effectiveFirstDate,
              effectiveLastDate);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: MonthDisplay(
        date: date,
        themeColor: effectiveThemeColor,
        prefix: prefix,
        showDay: showDaySelection,
      ),
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

  Future<void> _showDatePicker(BuildContext context, Color themeColor,
      DateTime firstDate, DateTime lastDate) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: firstDate,
        lastDate: lastDate,
        helpText: 'Select Date',
        initialDatePickerMode: DatePickerMode.day,
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

      if (picked != null && picked != date) {
        onDateChanged(picked);
      }
    } catch (e) {
      debugPrint('Error in date picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open date picker: ${e.toString()}'),
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

    // Get theme text colors for better dark mode support
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final disabledColor = Theme.of(context).disabledColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Center(
              child: Text(
                'Select Month',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.themeColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Year selector
            SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: widget.themeColor),
                    onPressed: _selectedYear > widget.firstDate.year
                        ? () {
                            setState(() {
                              _selectedYear--;
                              _yearController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            });
                          }
                        : null,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _yearController,
                      onPageChanged: (index) {
                        setState(() {
                          _selectedYear = widget.firstDate.year + index;
                        });
                      },
                      itemCount: availableYears.length,
                      itemBuilder: (context, index) {
                        final year = availableYears[index];
                        return Center(
                          child: Text(
                            year.toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: year == _selectedYear
                                  ? widget.themeColor
                                  : textColor.withAlpha((255 * 0.6).toInt()),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.arrow_forward_ios, color: widget.themeColor),
                    onPressed: _selectedYear < widget.lastDate.year
                        ? () {
                            setState(() {
                              _selectedYear++;
                              _yearController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Month grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected = month == _selectedMonth &&
                    _selectedYear == widget.initialDate.year;

                // Check if this month is within the valid date range
                bool isEnabled = true;
                if (_selectedYear == widget.firstDate.year &&
                    month < widget.firstDate.month) {
                  isEnabled = false;
                }
                if (_selectedYear == widget.lastDate.year &&
                    month > widget.lastDate.month) {
                  isEnabled = false;
                }

                return InkWell(
                  onTap: isEnabled
                      ? () {
                          setState(() {
                            _selectedMonth = month;
                          });
                          // Return the selected date
                          Navigator.of(context)
                              .pop(DateTime(_selectedYear, _selectedMonth, 1));
                        }
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? widget.themeColor : null,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? widget.themeColor
                            : isEnabled
                                ? Theme.of(context).dividerColor
                                : Theme.of(context)
                                    .dividerColor
                                    .withAlpha((255 * 0.3).toInt()),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _months[index].substring(0, 3),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isEnabled
                                  ? textColor
                                  : disabledColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
