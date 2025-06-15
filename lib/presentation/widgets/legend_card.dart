// lib/widgets/legend_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'legend_item.dart';

class LegendCard extends StatelessWidget {
  final List<String> categories;

  const LegendCard({
    Key? key,
    required this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categories',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 16.w,
              runSpacing: 16.h,
              children: categories.map((category) {
                return LegendItem(category: category);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
