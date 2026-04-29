import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/app_theme.dart';

class ThemeState {
  final AppTheme lightTheme;
  final AppTheme darkTheme;
  final ThemeMode themeMode;

  ThemeState({
    required this.lightTheme,
    required this.darkTheme,
    required this.themeMode,
  });

  ThemeState copyWith({
    AppTheme? lightTheme,
    AppTheme? darkTheme,
    ThemeMode? themeMode,
  }) {
    return ThemeState(
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class ThemeService {
  static const String _boxName = 'settings';
  static const String _lightThemeKey = 'light_theme';
  static const String _darkThemeKey = 'dark_theme';
  static const String _themeModeKey = 'theme_mode_v2';
  static const String _savedThemesKey = 'saved_themes';

  static final ValueNotifier<ThemeState> themeNotifier =
      ValueNotifier<ThemeState>(
        ThemeState(
          lightTheme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
        ),
      );

  // Expose saved custom themes
  static final ValueNotifier<List<AppTheme>> savedThemesNotifier =
      ValueNotifier<List<AppTheme>>([]);

  // Premium Themes Registry
  static final List<AppTheme> premiumThemes = [
    AppTheme(
      id: 'premium_midnight_royal',
      name: 'Midnight Royal',
      isDark: true,
      primaryColor: 0xFFFFD700, // Gold
      backgroundColor: 0xFF001F3F, // Navy
      textColor: 0xFFFFFFFF,
      cardColor: 0xFF003366,
    ),
    AppTheme(
      id: 'premium_nebula',
      name: 'Vibrant Nebula',
      isDark: true,
      primaryColor: 0xFFE040FB, // Purple Neon
      backgroundColor: 0xFF12005E, // Deep Space
      textColor: 0xFFFFFFFF,
      cardColor: 0xFF1A1A2E,
    ),
    AppTheme(
      id: 'premium_golden_harvest',
      name: 'Golden Harvest',
      isDark: false,
      primaryColor: 0xFFD48806, // Deep Yellow
      backgroundColor: 0xFFFFFBE6, // Warm Paper
      textColor: 0xFF5C3D11,
      cardColor: 0xFFFFF1B8,
    ),
    AppTheme(
      id: 'premium_cyberpunk',
      name: 'Cyberpunk Neon',
      isDark: true,
      primaryColor: 0xFF00FF41, // Terminal Green
      backgroundColor: 0xFF0D0208, // Pure Black
      textColor: 0xFF00FF41,
      cardColor: 0xFF121212,
      expenseColor: 0xFFFF003C, // Neon Red
    ),
  ];

  static Map<String, int> premiumThemePrices = {
    'premium_midnight_royal': 300,
    'premium_nebula': 500,
    'premium_golden_harvest': 200,
    'premium_cyberpunk': 1000,
  };

  static Future<void> init() async {
    Box box;
    try {
      box = await Hive.openBox(_boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_boxName);
      box = await Hive.openBox(_boxName);
    }

    // Load active themes
    final lightTheme = box.get(_lightThemeKey) as AppTheme? ?? AppTheme.light();
    final darkTheme = box.get(_darkThemeKey) as AppTheme? ?? AppTheme.dark();

    final modeIndex = box.get(
      _themeModeKey,
      defaultValue: ThemeMode.system.index,
    );
    final themeMode = ThemeMode.values[modeIndex];

    themeNotifier.value = ThemeState(
      lightTheme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
    );

    // Load saved themes
    final savedList = box.get(_savedThemesKey);
    if (savedList != null) {
      savedThemesNotifier.value = List<AppTheme>.from(savedList);
    } else {
      // Provide defaults
      savedThemesNotifier.value = [AppTheme.light(), AppTheme.dark()];
      await box.put(_savedThemesKey, savedThemesNotifier.value);
    }
  }

  static Future<void> setLightTheme(AppTheme theme) async {
    final box = Hive.box(_boxName);
    await box.put(_lightThemeKey, theme);
    themeNotifier.value = themeNotifier.value.copyWith(lightTheme: theme);
  }

  static Future<void> setDarkTheme(AppTheme theme) async {
    final box = Hive.box(_boxName);
    await box.put(_darkThemeKey, theme);
    themeNotifier.value = themeNotifier.value.copyWith(darkTheme: theme);
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final box = Hive.box(_boxName);
    await box.put(_themeModeKey, mode.index);
    themeNotifier.value = themeNotifier.value.copyWith(themeMode: mode);
  }

  static Future<void> saveCustomTheme(AppTheme theme) async {
    final box = Hive.box(_boxName);
    final currentList = List<AppTheme>.from(savedThemesNotifier.value);

    // Replace if same ID, or add new
    int existingIdx = currentList.indexWhere((t) => t.id == theme.id);
    if (existingIdx >= 0) {
      currentList[existingIdx] = theme;
    } else {
      currentList.add(theme);
    }

    savedThemesNotifier.value = currentList;
    await box.put(_savedThemesKey, currentList);
  }

  static Future<void> deleteCustomTheme(AppTheme theme) async {
    // Don't delete defaults
    if (theme.id == 'default_light' || theme.id == 'default_dark') return;

    final box = Hive.box(_boxName);
    final currentList = List<AppTheme>.from(savedThemesNotifier.value);
    currentList.removeWhere((t) => t.id == theme.id);

    savedThemesNotifier.value = currentList;
    await box.put(_savedThemesKey, currentList);
  }
}
