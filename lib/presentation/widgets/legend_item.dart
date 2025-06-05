import 'package:flutter/material.dart';
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: catEnum != null
                ? CategoryManager.getColor(catEnum)
                : CategoryManager.getColorFromId(category),
            borderRadius: BorderRadius.circular(45),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          catEnum != null
              ? CategoryManager.getName(catEnum)
              : CategoryManager.getNameFromId(category),
          style: const TextStyle(
            fontFamily: 'Lexend',
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
