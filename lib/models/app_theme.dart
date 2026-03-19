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
    final onCardColor = ColorUtils.ensureContrast(baseTextColor, cardCol);

    // Semantic Colors
    final accentSuccess = Color(incomeColor ?? (isDark ? 0xFF3DA35D : 0xFF2D5A27)); 
    final accentError = Color(expenseColor ?? (isDark ? 0xFFE63946 : 0xFF922B21));
    final accentWarning = Color(warningColor ?? 0xFFF5A623);
    final accentInfo = Color(infoColor ?? 0xFF4A90E2);

    final surfaceVariant = ColorUtils.getSurfaceVariant(bgColor, pdColor);
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
        surface: cardCol,
        onSurface: onCardColor,
        surfaceVariant: surfaceVariant,
        onSurfaceVariant: ColorUtils.ensureContrast(baseTextColor, surfaceVariant),
        background: bgColor,
        onBackground: baseTextColor,
        error: accentError,
        onError: ColorUtils.getContrastColor(accentError),
        tertiary: accentSuccess, // Using tertiary for success logically
        onTertiary: ColorUtils.getContrastColor(accentSuccess),
        outline: outlineColor,
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(color: baseTextColor, fontWeight: FontWeight.bold, letterSpacing: -1.0),
        displayMedium: TextStyle(color: baseTextColor, fontWeight: FontWeight.bold, letterSpacing: -0.8),
        displaySmall: TextStyle(color: baseTextColor, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: baseTextColor, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        titleLarge: TextStyle(color: baseTextColor, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: baseTextColor.withOpacity(0.8), fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: baseTextColor, fontSize: 16),
        bodyMedium: TextStyle(color: baseTextColor.withOpacity(0.7), fontSize: 14),
        labelLarge: TextStyle(color: baseTextColor.withOpacity(0.5), fontWeight: FontWeight.w500, fontSize: 12),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: baseTextColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: baseTextColor, fontSize: 20, fontWeight: FontWeight.bold),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: pdColor,
        foregroundColor: onPrimaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgColor,
        indicatorColor: pdColor.withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(color: pdColor, fontSize: 12, fontWeight: FontWeight.bold);
          }
          return TextStyle(color: baseTextColor.withOpacity(0.5), fontSize: 12);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: pdColor);
          }
          return IconThemeData(color: baseTextColor.withOpacity(0.5));
        }),
      ),
    );
  }

  static AppTheme light() => AppTheme(
        id: 'default_light',
        isDark: false,
        primaryColor: 0xFF000000,
        backgroundColor: 0xFFFFFFFF,
        textColor: 0xFF000000,
        cardColor: 0xFFF5F5F5,
        incomeColor: 0xFF2D5A27,
        expenseColor: 0xFF922B21,
        warningColor: 0xFFF5A623,
        infoColor: 0xFF4A90E2,
        name: 'Classic Light',
      );

  static AppTheme dark() => AppTheme(
        id: 'default_dark',
        isDark: true,
        primaryColor: 0xFFFFFFFF,
        backgroundColor: 0xFF0A0A0A,
        textColor: 0xFFFFFFFF,
        cardColor: 0xFF161616,
        incomeColor: 0xFF3DA35D,
        expenseColor: 0xFFE63946,
        warningColor: 0xFFFFC107,
        infoColor: 0xFF64B5F6,
        name: 'Classic Dark',
      );
}
