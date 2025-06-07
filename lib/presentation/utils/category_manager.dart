import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';

/// Unified category management utility class
class CategoryManager {
  /// Category color mapping
  static const Map<Category, Color> categoryColors = {
    Category.food: Color(0xFFF57C00), // Orange
    Category.transportation: Color(0xFF3F51B5), // Indigo
    Category.rental: Color(0xFF795548), // Brown
    Category.utilities: Color(0xFF2196F3), // Blue
    Category.shopping: Color(0xFFE91E63), // Pink
    Category.entertainment: Color(0xFF9C27B0), // Purple
    Category.education: Color(0xFF009688), // Teal
    Category.travel: Color(0xFF4CAF50), // Green
    Category.medical: Color(0xFFE91E63), // Pink
    Category.others: Color(0xFF607D8B), // Blue Grey
  };

  /// Category icon mapping
  static const Map<Category, IconData> categoryIcons = {
    Category.food: Icons.restaurant,
    Category.transportation: Icons.directions_car,
    Category.rental: Icons.home,
    Category.utilities: Icons.power,
    Category.shopping: Icons.shopping_bag,
    Category.entertainment: Icons.movie,
    Category.education: Icons.school,
    Category.travel: Icons.flight_takeoff,
    Category.medical: Icons.local_hospital,
    Category.others: Icons.more_horiz,
  };

  /// Category name mapping
  static const Map<Category, String> categoryNames = {
    Category.food: 'Food',
    Category.transportation: 'Transportation',
    Category.rental: 'Rental',
    Category.utilities: 'Utilities',
    Category.shopping: 'Shopping',
    Category.entertainment: 'Entertainment',
    Category.education: 'Education',
    Category.travel: 'Travel',
    Category.medical: 'Medical',
    Category.others: 'Others',
  };

  /// Get all available categories
  static List<Category> get allCategories => Category.values;

  /// Get the color for a specified category or string ID
  static Color getColor(dynamic category) {
    if (category is Category) {
      return categoryColors[category] ?? const Color(0xFF607D8B);
    } else if (category is String) {
      return getColorFromId(category);
    }
    return const Color(0xFF607D8B);
  }

  /// Get the icon for a specified category or string ID
  static IconData getIcon(dynamic category) {
    if (category is Category) {
      return categoryIcons[category] ?? Icons.more_horiz;
    } else if (category is String) {
      return getIconFromId(category);
    }
    return Icons.more_horiz;
  }

  /// Get the name for a specified category or string ID
  static String getName(dynamic category) {
    if (category is Category) {
      return categoryNames[category] ?? 'Unknown';
    } else if (category is String) {
      return getNameFromId(category);
    }
    return 'Unknown';
  }

  /// Get detailed information for all categories
  static List<Map<String, dynamic>> getAllCategoriesDetails() {
    return allCategories.map((category) {
      return {
        'id': category.id,
        'name': getName(category),
        'icon': getIcon(category),
        'color': getColor(category),
      };
    }).toList();
  }

  /// Get category from string ID
  static Category? getCategoryFromId(String id) {
    return CategoryExtension.fromId(id);
  }

  /// Get category color from string ID
  static Color getColorFromId(String id) {
    final category = getCategoryFromId(id);
    return category != null ? getColor(category) : const Color(0xFF607D8B);
  }

  /// Get category icon from string ID
  static IconData getIconFromId(String id) {
    final category = getCategoryFromId(id);
    return category != null ? getIcon(category) : Icons.more_horiz;
  }

  /// Get category name from string ID
  static String getNameFromId(String id) {
    final category = getCategoryFromId(id);
    return category != null
        ? getName(category)
        : id[0].toUpperCase() + id.substring(1);
  }

  /// Get category IDs used for budgets
  static List<String> getBudgetCategoryIds() {
    // Can filter or adjust category list as needed
    return allCategories.map((category) => category.id).toList();
  }
}
