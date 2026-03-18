import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';
import 'splash_screen.dart';
import 'models/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Database Service
  await DatabaseService.init();
  
  // Initialize Theme Service
  await ThemeService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, appTheme, _) {
        return MaterialApp(
          title: 'AJ Wallet',
          debugShowCheckedModeBanner: false,
          theme: appTheme.toThemeData(),
          home: const SplashScreen(),
        );
      },
    );
  }
}
