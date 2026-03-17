import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/app_theme.dart';

class ThemeService {
  static const String _boxName = 'settings';
  static const String _themeKey = 'current_theme';

  static final ValueNotifier<AppTheme> themeNotifier = 
      ValueNotifier<AppTheme>(AppTheme.light());

  static Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    final savedTheme = box.get(_themeKey);
    if (savedTheme != null) {
      themeNotifier.value = savedTheme as AppTheme;
    }
  }

  static Future<void> setTheme(AppTheme theme) async {
    final box = Hive.box(_boxName);
    await box.put(_themeKey, theme);
    themeNotifier.value = theme;
  }
}
