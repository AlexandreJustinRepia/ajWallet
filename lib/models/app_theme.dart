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

  AppTheme({
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.cardColor,
    required this.name,
  });

  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: Color(primaryColor),
      scaffoldBackgroundColor: Color(backgroundColor),
      cardColor: Color(cardColor),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(primaryColor),
        primary: Color(primaryColor),
        background: Color(backgroundColor),
        onBackground: Color(textColor),
        surface: Color(cardColor),
        onSurface: Color(textColor),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Color(textColor)),
        bodyMedium: TextStyle(color: Color(textColor)),
        displayLarge: TextStyle(color: Color(textColor), fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Color(textColor), fontWeight: FontWeight.bold),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(backgroundColor),
        foregroundColor: Color(textColor),
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(primaryColor),
        foregroundColor: Colors.white,
      ),
    );
  }

  static AppTheme light() => AppTheme(
        primaryColor: Colors.black.value,
        backgroundColor: Colors.white.value,
        textColor: Colors.black.value,
        cardColor: const Color(0xFFF5F5F5).value,
        name: 'Light',
      );

  static AppTheme dark() => AppTheme(
        primaryColor: Colors.white.value,
        backgroundColor: const Color(0xFF121212).value,
        textColor: Colors.white.value,
        cardColor: const Color(0xFF1E1E1E).value,
        name: 'Dark',
      );
}
