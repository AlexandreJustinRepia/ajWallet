import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';
import 'services/session_service.dart';
import 'services/achievement_service.dart';
import 'splash_screen.dart';
import 'models/app_theme.dart';
import 'widgets/security_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Database Service
  await DatabaseService.init();
  
  // Initialize Theme Service
  await ThemeService.init();

  // Initialize Session Service
  await SessionService.init();

  // Initialize Achievement Service
  await AchievementService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeState>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, themeState, _) {
        return MaterialApp(
          title: 'AJ Wallet',
          debugShowCheckedModeBanner: false,
          theme: themeState.lightTheme.toThemeData(),
          darkTheme: themeState.darkTheme.toThemeData(),
          themeMode: themeState.themeMode,
          builder: (context, child) => SecurityWrapper(child: child!),
          home: const SplashScreen(),
        );
      },
    );
  }
}
