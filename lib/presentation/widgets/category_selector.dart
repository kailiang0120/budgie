import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/category.dart';
import '../utils/category_manager.dart';
import '../utils/app_theme.dart';

/// 类别选择器组件 - Responsive Design
class CategorySelector extends StatelessWidget {
  /// 当前选择的类别
  final Category selectedCategory;

  /// 类别选择回调
  final Function(Category) onCategorySelected;

  /// 容器大小
  final double containerSize;

  /// 图标大小
  final double iconSize;

  /// 文本大小
  final double fontSize;

  /// 是否显示类别名称
  final bool showCategoryName;

  /// 可选的过滤类别列表
  final List<Category>? categories;

  const CategorySelector({
    Key? key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.containerSize = 80,
    this.iconSize = 40,
    this.fontSize = 16,
    this.showCategoryName = true,
    this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryManager.getColor(selectedCategory);
    final categoryIcon = CategoryManager.getIcon(selectedCategory);
    final categoryName = CategoryManager.getName(selectedCategory);

    return GestureDetector(
      onTap: () => _showCategoryPicker(context),
      child: Column(
        children: [
          Container(
            width: containerSize.w,
            height: containerSize.h,
            decoration: BoxDecoration(
              color: categoryColor.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(AppTheme.largeBorderRadius.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                categoryIcon,
                size: iconSize.sp,
                color: categoryColor,
              ),
            ),
          ),
          if (showCategoryName) ...[
            SizedBox(height: 8.h),
            Text(
              categoryName,
              style: TextStyle(
                color: categoryColor,
                fontSize: fontSize.sp,
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    final availableCategories = categories ?? CategoryManager.allCategories;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Category',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 20.h),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableCategories.length,
                  itemBuilder: (context, index) {
                    final category = availableCategories[index];
                    final categoryColor = CategoryManager.getColor(category);
                    final categoryIcon = CategoryManager.getIcon(category);
                    final categoryName = CategoryManager.getName(category);

                    return ListTile(
                      leading: Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: categoryColor.withAlpha((255 * 0.1).toInt()),
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        child: Icon(
                          categoryIcon,
                          color: categoryColor,
                          size: 24.sp,
                        ),
                      ),
                      title: Text(
                        categoryName,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      onTap: () {
                        onCategorySelected(category);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
