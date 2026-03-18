import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'get_started_screen.dart';
import 'account_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Simulate a brief loading time for professional feel
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    final accounts = DatabaseService.getAccounts();
    
    Widget nextScreen;
    if (accounts.isEmpty) {
      nextScreen = const GetStartedScreen();
    } else {
      nextScreen = const AccountListScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: theme.scaffoldBackgroundColor,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AJ Wallet',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
