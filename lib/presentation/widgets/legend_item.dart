import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/category_manager.dart';
import '../../domain/entities/category.dart';

class LegendItem extends StatelessWidget {
  final String category;

  const LegendItem({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Category? catEnum = CategoryExtension.fromId(category);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.w,
          height: 12.h,
          decoration: BoxDecoration(
            color: catEnum != null
                ? CategoryManager.getColor(catEnum)
                : CategoryManager.getColorFromId(category),
            borderRadius: BorderRadius.circular(45.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          catEnum != null
              ? CategoryManager.getName(catEnum)
              : CategoryManager.getNameFromId(category),
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }
}
