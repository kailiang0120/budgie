import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/category.dart';
import '../utils/category_manager.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';

/// - Category selector widget - Responsive design
class CategorySelector extends StatelessWidget {
  /// - Required: Currently selected category
  final Category selectedCategory;

  /// - Required: Callback when category is selected
  final Function(Category) onCategorySelected;

  /// - Optional: Container size
  final double containerSize;

  /// - Optional: Icon size
  final double iconSize;

  /// - Optional: Text size
  final double fontSize;

  /// - Optional: Show category name
  final bool showCategoryName;

  /// - Optional: Filter categories
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
              color: categoryColor
                  .withAlpha((255 * AppConstants.opacityOverlay).toInt()),
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusXLarge.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withAlpha((255 * AppConstants.opacityOverlay).toInt()),
                  blurRadius: AppConstants.elevationSmall.r * 2,
                  offset: Offset(0, AppConstants.elevationSmall.h * 2),
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
            SizedBox(height: AppConstants.spacingSmall.h),
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
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.borderRadiusLarge.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: AppConstants.spacingXLarge.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Category',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: AppConstants.textSizeXLarge.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: AppConstants.spacingXLarge.h),
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
                        width: AppConstants.iconSizeXLarge.w * 1.25,
                        height: AppConstants.iconSizeXLarge.h * 1.25,
                        decoration: BoxDecoration(
                          color: categoryColor.withAlpha(
                              (255 * AppConstants.opacityOverlay).toInt()),
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusMedium.r),
                        ),
                        child: Icon(
                          categoryIcon,
                          color: categoryColor,
                          size: AppConstants.iconSizeLarge.sp,
                        ),
                      ),
                      title: Text(
                        categoryName,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: AppConstants.textSizeLarge.sp,
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
