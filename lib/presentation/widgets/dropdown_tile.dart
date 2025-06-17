import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DropdownTile<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabelBuilder;

  const DropdownTile({
    Key? key,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabelBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: TextStyle(fontSize: 16.sp),
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 4.h,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<T>(
              value: value,
              onChanged: onChanged,
              underline: Container(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.primary,
                size: 24.sp,
              ),
              isDense: true,
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabelBuilder(item),
                    style: TextStyle(fontSize: 14.sp),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Divider(
          height: 1.h,
          thickness: 1.h,
          indent: 18.w,
          endIndent: 18.w,
          color: Theme.of(context).dividerColor,
        ),
      ],
    );
  }
}
