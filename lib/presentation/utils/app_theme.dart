import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/category.dart';
import 'category_manager.dart';

/// Application theme management class
class AppTheme {
  /// Light theme colors
  static const Color primaryColor = Color(0xFFF57C00);
  static const Color secondaryColor = Color(0xFF2196F3);
  static const Color errorColor = Color(0xFFE91E63);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color backgroundLight = Color(0xFFF7FCFC);
  static const Color darkBackgroundLight = Color(0xFF333333);
  static const Color cardBackgroundLight = Color(0xfffafafa);
  static const Color lightTextLight = Color(0xFFFBFCF8);
  static const Color darkTextLight = Color(0xFF1A1A19);
  static const Color greyTextLight = Color(0xFF607D8B);
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color profileBackgroundLight = Color(0xff1A1A19);
  static const Color appBarBackgroundLight = Color(0xFFF5F5F5);
  static const Color appBarForegroundLight = Color(0xFF333333);

  /// Dark theme colors
  static const Color primaryColorDark = Color(0xFFF57C00);
  static const Color secondaryColorDark = Color(0xFF64B5F6);
  static const Color errorColorDark = Color(0xFFF06292);
  static const Color successColorDark = Color(0xFF81C784);
  static const Color warningColorDark = Color(0xFFFFD54F);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardBackgroundDark = Color(0xFF1E1E1E);
  static const Color lightTextDark = Color(0xFFFFFFFF);
  static const Color darkTextDark = Color(0xFFE0E0E0);
  static const Color greyTextDark = Color(0xFFB0BEC5);
  static const Color dividerDark = Color(0xFF424242);
  static const Color profileBackgroundDark = Color(0xff121212);
  static const Color appBarBackgroundDark = Color(0xFF1D1D1D);
  static const Color appBarForegroundDark = Color.fromARGB(255, 196, 196, 196);

  /// Font family
  static const String fontFamily = 'Lexend';

  /// Border radius values
  static const double borderRadius = 15.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 25.0;

  /// Get category color
  static Color getCategoryColor(Category category) {
    return CategoryManager.getColor(category);
  }

  /// Get the application's light theme with responsive text sizes
  static ThemeData getLightTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundLight,
      canvasColor: backgroundLight,
      cardColor: cardBackgroundLight,
      dividerColor: dividerLight,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: cardBackgroundLight,
        onPrimary: lightTextLight,
        onSecondary: lightTextLight,
        onSurface: darkTextLight,
        onError: lightTextLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackgroundLight,
        foregroundColor: appBarForegroundLight,
        elevation: 0,
        shadowColor: Colors.black.withAlpha((255 * 0.15).toInt()),
        iconTheme: const IconThemeData(color: appBarForegroundLight),
        actionsIconTheme: const IconThemeData(color: appBarForegroundLight),
        titleTextStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      fontFamily: fontFamily,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: lightTextLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: EdgeInsets.symmetric(vertical: 16.h),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: greyTextLight),
        hintStyle:
            TextStyle(color: greyTextLight.withAlpha((255 * 0.7).toInt())),
      ),
      cardTheme: CardTheme(
        color: cardBackgroundLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 2,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withAlpha((255 * 0.5).toInt());
          }
          return Colors.grey.shade300;
        }),
      ),
      iconTheme: const IconThemeData(color: greyTextLight),
      primaryIconTheme: const IconThemeData(color: primaryColor),
    );
  }

  /// Get the application's dark theme with responsive text sizes
  static ThemeData getDarkTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      brightness: Brightness.dark,
      primaryColor: primaryColorDark,
      scaffoldBackgroundColor: backgroundDark,
      canvasColor: backgroundDark,
      cardColor: cardBackgroundDark,
      dividerColor: dividerDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColorDark,
        secondary: secondaryColorDark,
        error: errorColorDark,
        surface: cardBackgroundDark,
        onPrimary: lightTextDark,
        onSecondary: lightTextDark,
        onSurface: darkTextDark,
        onError: lightTextDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackgroundDark,
        foregroundColor: appBarForegroundDark,
        elevation: 0,
        shadowColor: Colors.black.withAlpha((255 * 0.07).toInt()),
        iconTheme: const IconThemeData(color: appBarForegroundDark),
        actionsIconTheme: const IconThemeData(color: appBarForegroundDark),
        titleTextStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColorDark,
          foregroundColor: lightTextDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: EdgeInsets.symmetric(vertical: 16.h),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        filled: true,
        fillColor: cardBackgroundDark,
        labelStyle: const TextStyle(color: greyTextDark),
        hintStyle:
            TextStyle(color: greyTextDark.withAlpha((255 * 0.7).toInt())),
      ),
      cardTheme: CardTheme(
        color: cardBackgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 2,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return primaryColorDark;
          return Colors.grey.shade600;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColorDark.withAlpha((255 * 0.5).toInt());
          }
          return Colors.grey.shade700;
        }),
      ),
      iconTheme: const IconThemeData(color: greyTextDark),
      primaryIconTheme: const IconThemeData(color: primaryColorDark),
    );
  }

  // Backward compatibility methods for existing code that doesn't have context

  /// Get light theme without context (fallback for existing code)
  static ThemeData get lightTheme {
    // Use a dummy context for responsive calculations
    // This is a fallback - ideally all code should use the context-aware version
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundLight,
      canvasColor: backgroundLight,
      cardColor: cardBackgroundLight,
      dividerColor: dividerLight,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: cardBackgroundLight,
        onPrimary: lightTextLight,
        onSecondary: lightTextLight,
        onSurface: darkTextLight,
        onError: lightTextLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarBackgroundLight,
        foregroundColor: appBarForegroundLight,
        elevation: 0,
        iconTheme: IconThemeData(color: appBarForegroundLight),
        actionsIconTheme: IconThemeData(color: appBarForegroundLight),
        titleTextStyle: TextStyle(
          color: appBarForegroundLight,
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: darkTextLight, fontFamily: fontFamily),
        displayMedium: TextStyle(color: darkTextLight, fontFamily: fontFamily),
        displaySmall: TextStyle(color: darkTextLight, fontFamily: fontFamily),
        headlineLarge: TextStyle(color: darkTextLight, fontFamily: fontFamily),
        headlineMedium: TextStyle(color: darkTextLight, fontFamily: fontFamily),
        headlineSmall: TextStyle(color: darkTextLight, fontFamily: fontFamily),
        titleLarge: TextStyle(color: darkTextLight, fontFamily: fontFamily),
        titleMedium: TextStyle(color: darkTextLight, fontFamily: fontFamily),
        titleSmall: TextStyle(color: darkTextLight, fontFamily: fontFamily),
        bodyLarge: TextStyle(color: darkTextLight, fontFamily: fontFamily),
        bodyMedium: TextStyle(color: darkTextLight, fontFamily: fontFamily),
        bodySmall: TextStyle(color: greyTextLight, fontFamily: fontFamily),
        labelLarge: TextStyle(color: lightTextLight, fontFamily: fontFamily),
        labelMedium: TextStyle(color: greyTextLight, fontFamily: fontFamily),
        labelSmall: TextStyle(color: greyTextLight, fontFamily: fontFamily),
      ),
      fontFamily: fontFamily,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: lightTextLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: greyTextLight),
        hintStyle:
            TextStyle(color: greyTextLight.withAlpha((255 * 0.7).toInt())),
      ),
      cardTheme: CardTheme(
        color: cardBackgroundLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 2,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withAlpha((255 * 0.5).toInt());
          }
          return Colors.grey.shade300;
        }),
      ),
      iconTheme: const IconThemeData(color: greyTextLight),
      primaryIconTheme: const IconThemeData(color: primaryColor),
    );
  }

  /// Get dark theme without context (fallback for existing code)
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      brightness: Brightness.dark,
      primaryColor: primaryColorDark,
      scaffoldBackgroundColor: backgroundDark,
      canvasColor: backgroundDark,
      cardColor: cardBackgroundDark,
      dividerColor: dividerDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColorDark,
        secondary: secondaryColorDark,
        error: errorColorDark,
        surface: cardBackgroundDark,
        onPrimary: lightTextDark,
        onSecondary: lightTextDark,
        onSurface: darkTextDark,
        onError: lightTextDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarBackgroundDark,
        foregroundColor: appBarForegroundDark,
        elevation: 0,
        iconTheme: IconThemeData(color: appBarForegroundDark),
        actionsIconTheme: IconThemeData(color: appBarForegroundDark),
        titleTextStyle: TextStyle(
          color: appBarForegroundDark,
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: lightTextDark, fontFamily: fontFamily),
        displayMedium: TextStyle(color: lightTextDark, fontFamily: fontFamily),
        displaySmall: TextStyle(color: lightTextDark, fontFamily: fontFamily),
        headlineLarge: TextStyle(color: lightTextDark, fontFamily: fontFamily),
        headlineMedium: TextStyle(color: lightTextDark, fontFamily: fontFamily),
        headlineSmall: TextStyle(color: lightTextDark, fontFamily: fontFamily),
        titleLarge: TextStyle(color: lightTextDark, fontFamily: fontFamily),
        titleMedium: TextStyle(color: lightTextDark, fontFamily: fontFamily),
        titleSmall: TextStyle(color: lightTextDark, fontFamily: fontFamily),
        bodyLarge: TextStyle(color: lightTextDark, fontFamily: fontFamily),
        bodyMedium: TextStyle(color: lightTextDark, fontFamily: fontFamily),
        bodySmall: TextStyle(color: greyTextDark, fontFamily: fontFamily),
        labelLarge: TextStyle(color: lightTextDark, fontFamily: fontFamily),
        labelMedium: TextStyle(color: greyTextDark, fontFamily: fontFamily),
        labelSmall: TextStyle(color: greyTextDark, fontFamily: fontFamily),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColorDark,
          foregroundColor: lightTextDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        filled: true,
        fillColor: cardBackgroundDark,
        labelStyle: const TextStyle(color: greyTextDark),
        hintStyle:
            TextStyle(color: greyTextDark.withAlpha((255 * 0.7).toInt())),
      ),
      cardTheme: CardTheme(
        color: cardBackgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 2,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return primaryColorDark;
          return Colors.grey.shade600;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColorDark.withAlpha((255 * 0.5).toInt());
          }
          return Colors.grey.shade700;
        }),
      ),
      iconTheme: const IconThemeData(color: greyTextDark),
      primaryIconTheme: const IconThemeData(color: primaryColorDark),
    );
  }
}
