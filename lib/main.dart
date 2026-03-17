import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'create_account_screen.dart';
import 'account_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Database Service
  await DatabaseService.init();

  // Determine starting screen:
  // If no accounts exist, go to Create Account.
  // If accounts exist, go to the Account Listing.
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
    return MaterialApp(
      title: 'AJ Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: home,
    );
  }
}
