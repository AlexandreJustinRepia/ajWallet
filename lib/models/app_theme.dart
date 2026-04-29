import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/color_utils.dart';

part 'app_theme.g.dart';

@HiveType(typeId: 1)
class AppTheme extends HiveObject {
  @HiveField(0)
  int primaryColor;

  @HiveField(1)
  int backgroundColor;

  @HiveField(2)
  int textColor;

  @HiveField(3)
  int cardColor;

  @HiveField(4)
  String name;

  @HiveField(5)
  int? incomeColor; // Success

  @HiveField(6)
  int? expenseColor; // Error

  @HiveField(7)
  bool isDark;

  @HiveField(8)
  String id;

  @HiveField(9)
  int? warningColor;

  @HiveField(10)
  int? infoColor;

  AppTheme({
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.cardColor,
    required this.name,
    required this.isDark,
    required this.id,
    this.incomeColor,
    this.expenseColor,
    this.warningColor,
    this.infoColor,
  });

  ThemeData toThemeData() {
    final bgColor = Color(backgroundColor);
    final pdColor = Color(primaryColor);
    final cardCol = Color(cardColor);

    // Validate and enforce contrast for core elements
    final baseTextColor = ColorUtils.ensureContrast(Color(textColor), bgColor);
    final onPrimaryColor = ColorUtils.getContrastColor(pdColor);

    // Semantic Colors
    final accentSuccess = Color(
      incomeColor ?? (isDark ? 0xFF3DA35D : 0xFF2D5A27),
    );
    final accentError = Color(
      expenseColor ?? (isDark ? 0xFFE63946 : 0xFF922B21),
    );
    final accentInfo = Color(infoColor ?? 0xFF4A90E2);

    final outlineColor = ColorUtils.getOutlineColor(bgColor, baseTextColor);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: pdColor,
      scaffoldBackgroundColor: bgColor,
      cardColor: cardCol,
      dividerColor: outlineColor,

      colorScheme: ColorScheme.fromSeed(
        seedColor: pdColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: pdColor,
        onPrimary: onPrimaryColor,
        secondary: accentInfo,
        onSecondary: ColorUtils.getContrastColor(accentInfo),
        surface: bgColor,
        onSurface: baseTextColor,
        surfaceContainerHighest: cardCol,
        surfaceTint: pdColor.withAlpha(25),
        error: accentError,
        onError: ColorUtils.getContrastColor(accentError),
        tertiary: accentSuccess, // Using tertiary for success logically
        onTertiary: ColorUtils.getContrastColor(accentSuccess),
        outline: outlineColor,
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: baseTextColor,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
        ),
        displayMedium: TextStyle(
          color: baseTextColor,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.8,
        ),
        displaySmall: TextStyle(
          color: baseTextColor,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: baseTextColor,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          color: baseTextColor,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: baseTextColor.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: baseTextColor, fontSize: 16),
        bodyMedium: TextStyle(
          color: baseTextColor.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        labelLarge: TextStyle(
          color: baseTextColor.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: baseTextColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: baseTextColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: pdColor,
        foregroundColor: onPrimaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgColor,
        indicatorColor: pdColor.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: pdColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            );
          }
          return TextStyle(
            color: baseTextColor.withValues(alpha: 0.5),
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: pdColor);
          }
          return IconThemeData(color: baseTextColor.withValues(alpha: 0.5));
        }),
      ),
    );
  }

  static AppTheme light() => AppTheme(
    id: 'default_light',
    isDark: false,
    primaryColor: 0xFF1B5E20, // Deep Forest Green
    backgroundColor: 0xFFFFFFFF,
    textColor: 0xFF000000,
    cardColor: 0xFFF8F9FA,
    incomeColor: 0xFF2D5A27,
    expenseColor: 0xFF922B21,
    warningColor: 0xFFF5A623,
    infoColor: 0xFF00796B, // Teal-Green Info
    name: 'Botanical Light',
  );

  static AppTheme dark() => AppTheme(
    id: 'default_dark',
    isDark: true,
    primaryColor: 0xFF81C784, // Soft Botanical Green
    backgroundColor: 0xFF0A0F0A, // Deep Moss Background
    textColor: 0xFFE0E0E0,
    cardColor: 0xFF121A12,
    incomeColor: 0xFF3DA35D,
    expenseColor: 0xFFE63946,
    warningColor: 0xFFFFC107,
    infoColor: 0xFF4DB6AC, // Soft Teal Info
    name: 'Botanical Dark',
  );
}
