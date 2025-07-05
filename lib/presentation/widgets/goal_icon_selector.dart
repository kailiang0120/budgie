import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/financial_goal.dart';
import '../utils/app_constants.dart';

/// A widget for selecting icons and colors for financial goals
class GoalIconSelector extends StatefulWidget {
  /// Initial selected icon
  final GoalIcon initialIcon;

  /// Callback when icon is selected
  final Function(GoalIcon) onIconSelected;

  /// Constructor
  const GoalIconSelector({
    Key? key,
    required this.initialIcon,
    required this.onIconSelected,
  }) : super(key: key);

  @override
  State<GoalIconSelector> createState() => _GoalIconSelectorState();
}

class _GoalIconSelectorState extends State<GoalIconSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GoalIcon _selectedIcon;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedIcon = widget.initialIcon;
    _selectedColor = widget.initialIcon.color;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateSelectedIcon(GoalIcon icon) {
    setState(() {
      _selectedIcon = GoalIcon(
        icon: icon.icon,
        name: icon.name,
        color: _selectedColor,
      );
    });
    widget.onIconSelected(_selectedIcon);
  }

  void _updateSelectedColor(Color color) {
    setState(() {
      _selectedColor = color;
      _selectedIcon = GoalIcon(
        icon: _selectedIcon.icon,
        name: _selectedIcon.name,
        color: color,
      );
    });
    widget.onIconSelected(_selectedIcon);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Preview of selected icon
        Container(
          padding: EdgeInsets.all(AppConstants.spacingMedium.w),
          decoration: BoxDecoration(
            color: _selectedColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _selectedIcon.icon,
            size: 48.sp,
            color: _selectedColor,
          ),
        ),
        SizedBox(height: AppConstants.spacingMedium.h),

        // Tab bar for icons and colors
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Icons'),
            Tab(text: 'Colors'),
          ],
        ),

        // Tab views
        SizedBox(
          height: 200.h,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Icons grid
              _buildIconsGrid(),

              // Colors grid
              _buildColorsGrid(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconsGrid() {
    final icons = GoalIcon.getAllIcons(defaultColor: _selectedColor);

    return GridView.builder(
      padding: EdgeInsets.all(AppConstants.spacingSmall.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: AppConstants.spacingSmall.w,
        mainAxisSpacing: AppConstants.spacingSmall.h,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final icon = icons[index];
        final isSelected = icon.name == _selectedIcon.name;

        return GestureDetector(
          onTap: () => _updateSelectedIcon(icon),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? _selectedColor.withOpacity(0.2)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected ? _selectedColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusMedium.r),
            ),
            child: Icon(
              icon.icon,
              color: _selectedColor,
              size: 24.sp,
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorsGrid() {
    final colors = GoalIcon.getAllColors();

    return GridView.builder(
      padding: EdgeInsets.all(AppConstants.spacingSmall.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: AppConstants.spacingSmall.w,
        mainAxisSpacing: AppConstants.spacingSmall.h,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final isSelected = color.value == _selectedColor.value;

        return GestureDetector(
          onTap: () => _updateSelectedColor(color),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }
}
