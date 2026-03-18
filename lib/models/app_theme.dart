import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

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
  int? incomeColor;

  @HiveField(6)
  int? expenseColor;

  AppTheme({
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.cardColor,
    required this.name,
    this.incomeColor,
    this.expenseColor,
  });

  ThemeData toThemeData() {
    final baseTextColor = Color(textColor);
    final accentIncome = Color(incomeColor ?? 0xFF2D5A27); // Muted Emerald
    final accentExpense = Color(expenseColor ?? 0xFF922B21); // Muted Crimson

    return ThemeData(
      useMaterial3: true,
      brightness: ThemeData.estimateBrightnessForColor(Color(backgroundColor)),
      primaryColor: Color(primaryColor),
      scaffoldBackgroundColor: Color(backgroundColor),
      cardColor: Color(cardColor),
      dividerColor: baseTextColor.withOpacity(0.1),
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(primaryColor),
        primary: Color(primaryColor),
        background: Color(backgroundColor),
        onBackground: baseTextColor,
        surface: Color(cardColor),
        onSurface: baseTextColor,
        surfaceVariant: Color(cardColor).withOpacity(0.8),
        tertiary: accentIncome,
        error: accentExpense,
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
        backgroundColor: Color(backgroundColor),
        foregroundColor: baseTextColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: baseTextColor, fontSize: 20, fontWeight: FontWeight.bold),
      ),



      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(primaryColor),
        foregroundColor: Color(backgroundColor),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Color(backgroundColor),
        indicatorColor: Color(primaryColor).withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(color: Color(primaryColor), fontSize: 12, fontWeight: FontWeight.bold);
          }
          return TextStyle(color: baseTextColor.withOpacity(0.5), fontSize: 12);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: Color(primaryColor));
          }
          return IconThemeData(color: baseTextColor.withOpacity(0.5));
        }),
      ),
    );
  }

  static AppTheme light() => AppTheme(
        primaryColor: 0xFF000000,
        backgroundColor: 0xFFFFFFFF,
        textColor: 0xFF000000,
        cardColor: 0xFFF8F9FA,
        incomeColor: 0xFF2D5A27,
        expenseColor: 0xFF922B21,
        name: 'Light',
      );

  static AppTheme dark() => AppTheme(
        primaryColor: 0xFFFFFFFF,
        backgroundColor: 0xFF0A0A0A,
        textColor: 0xFFFFFFFF,
        cardColor: 0xFF161616,
        incomeColor: 0xFF3DA35D,
        expenseColor: 0xFFE63946,
        name: 'Dark',
      );
}
