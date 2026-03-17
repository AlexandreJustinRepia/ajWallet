import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';
import 'create_account_screen.dart';
import 'account_list_screen.dart';
import 'models/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Database Service
  await DatabaseService.init();
  
  // Initialize Theme Service
  await ThemeService.init();

  // Determine starting screen:
  final accounts = DatabaseService.getAccounts();
  final Widget initialScreen = accounts.isEmpty 
      ? const CreateAccountScreen() 
      : const AccountListScreen();

  runApp(MyApp(home: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget home;
  const MyApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, appTheme, _) {
        return MaterialApp(
          title: 'AJ Wallet',
          debugShowCheckedModeBanner: false,
          theme: appTheme.toThemeData(),
          home: home,
        );
      },
    );
  }
}
