import 'package:flutter/material.dart';
import '../models/account.dart';
import 'database_service.dart';

class SessionService {
  static final ValueNotifier<Account?> activeAccountNotifier = ValueNotifier<Account?>(null);

  static Account? get activeAccount => activeAccountNotifier.value;

  static void setActiveAccount(Account? account) {
    activeAccountNotifier.value = account;
  }

  static Future<void> init() async {
    final account = DatabaseService.getLatestAccount();
    if (account != null) {
      setActiveAccount(account);
    }
  }

  static Future<void> setupFakeVault(Account primaryAccount) async {
    // Check if a fake account already exists
    final accounts = DatabaseService.getAccounts();
    Account? fakeAccount = accounts.firstWhere(
      (a) => a.name == '${primaryAccount.name} (Private)' && a.isFake,
      orElse: () => Account(name: '${primaryAccount.name} (Private)', isFake: true),
    );

    if (fakeAccount.key == null) {
      await DatabaseService.saveAccount(fakeAccount);
    }
    
    // Primary account stores the PIN that triggers this
  }
}
