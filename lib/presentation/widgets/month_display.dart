import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A widget to display the current budget month
class MonthDisplay extends StatelessWidget {
  final DateTime date;
  final Color? themeColor;
  final String? prefix;
  final bool showDay;

  const MonthDisplay({
    Key? key,
    required this.date,
    this.themeColor,
    this.prefix = 'Budget for',
    this.showDay = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = themeColor ?? Theme.of(context).primaryColor;
    final String dateFormat = showDay ? 'dd MMMM yyyy' : 'MMMM yyyy';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: effectiveColor.withAlpha((255 * 0.1).toInt()),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: effectiveColor.withAlpha((255 * 0.3).toInt())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            color: effectiveColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              '$prefix ${DateFormat(dateFormat).format(date)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.normal,
                color: effectiveColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
