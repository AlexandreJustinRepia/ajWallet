import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';
import 'services/session_service.dart';
import 'services/update_service.dart';
import 'services/achievement_service.dart';
import 'services/user_profile_service.dart';
import 'services/quick_action_service.dart';
import 'splash_screen.dart';
import 'views/dashboard/dashboard_view.dart';
import 'add_transaction_screen.dart';
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

  // Initialize User Profile Service
  await UserProfileService.init();

  // Initialize Update Service
  await UpdateService.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Initialize Quick Actions
    QuickActionService.init((type) {
      ShortcutHandler.handle(type, _navigatorKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeState>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, themeState, _) {
        return MaterialApp(
          title: 'RootEXP',
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: themeState.lightTheme.toThemeData(),
          darkTheme: themeState.darkTheme.toThemeData(),
          themeMode: themeState.themeMode,
          builder: (context, child) => SecurityWrapper(child: child!),
          home: const SplashScreen(),
          routes: {
            '/dashboard': (context) {
              final index = ModalRoute.of(context)?.settings.arguments as int? ?? 0;
              return DashboardScreen(initialIndex: index);
            },
            '/add_transaction': (context) {
              final accountKey = SessionService.activeAccount?.key as int? ?? 0;
              return AddTransactionScreen(accountKey: accountKey);
            },
          },
        );
      },
    );
  }
}
