import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/session_service.dart';
import '../../services/financial_insights_service.dart';
import '../../services/gamification_service.dart';
import '../../models/wallet.dart';
import '../../models/transaction_model.dart';

class HomeViewModel extends ChangeNotifier {
  final bool isTutorialActive;
  
  List<Transaction> _transactions = [];
  List<Wallet> _wallets = [];
  double _totalBalance = 0;
  List<Insight> _insights = [];
  GamificationProfile? _gamificationProfile;
  
  bool _isNetWorthMode = false;
  bool _showGlow = false;
  double _prevBalance = 0;

  // Tutorial state
  final List<Transaction> _tutorialTransactions = [];
  late List<Wallet> _tutorialWallets;

  HomeViewModel({required this.isTutorialActive}) {
    if (isTutorialActive) _initTutorial();
    refresh();
  }

  List<Transaction> get transactions => isTutorialActive ? _tutorialTransactions : _transactions;
  List<Wallet> get wallets => isTutorialActive ? _tutorialWallets : _wallets;
  double get totalBalance => _totalBalance;
  List<Insight> get insights => _insights;
  GamificationProfile get gamificationProfile => _gamificationProfile ?? GamificationService.generateGlobalProfile();
  
  bool get isNetWorthMode => _isNetWorthMode;
  bool get showGlow => _showGlow;

  void toggleNetWorth() {
    _isNetWorthMode = !_isNetWorthMode;
    _calculateBalance();
    notifyListeners();
  }

  void refresh() {
    final account = SessionService.activeAccount;
    if (account == null && !isTutorialActive) return;

    if (!isTutorialActive) {
      _transactions = DatabaseService.getTransactions(account!.key as int);
      _wallets = DatabaseService.getWallets(account.key as int);
    }
    
    _calculateBalance();
    _generateInsights();
    _gamificationProfile = GamificationService.generateGlobalProfile();
    
    notifyListeners();
  }

  void handleTutorialSubmit(Transaction t) {
    if (!isTutorialActive) return;
    _tutorialTransactions.insert(0, t);
    if (_tutorialWallets.isNotEmpty) {
      _tutorialWallets[0].balance -= t.amount;
    }
    _calculateBalance();
    _generateInsights();
    notifyListeners();
  }

  void _calculateBalance() {
    final activeWallets = isTutorialActive ? _tutorialWallets : _wallets;
    _totalBalance = activeWallets
        .where((w) => _isNetWorthMode || !w.isExcluded)
        .fold(0.0, (sum, wallet) => sum + wallet.balance);

    if (_totalBalance != _prevBalance && _prevBalance != 0) {
      _triggerGlow();
    }
    _prevBalance = _totalBalance;
  }

  void _generateInsights() {
    _insights = FinancialInsightsService.generateInsights(
      transactions,
      _totalBalance,
    );
  }

  void _triggerGlow() {
    _showGlow = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 500), () {
      _showGlow = false;
      notifyListeners();
    });
  }

  void _initTutorial() {
    final account = SessionService.activeAccount;
    final realWallets = account != null
        ? DatabaseService.getWallets(account.key as int)
        : <Wallet>[];

    if (realWallets.isNotEmpty) {
      _tutorialWallets = realWallets.map((w) => Wallet(
        name: 'Demo ${w.name}',
        balance: w.balance < 250 ? 10000.0 : w.balance,
        type: w.type,
        accountKey: 999,
      )).toList();
    } else {
      _tutorialWallets = [
        Wallet(
          name: 'Demo Wallet',
          balance: 10000.0,
          type: 'E-Wallet',
          accountKey: 999,
        ),
      ];
    }
  }
}
