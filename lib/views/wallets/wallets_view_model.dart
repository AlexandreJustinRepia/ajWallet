import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/session_service.dart';
import '../../models/wallet.dart';
import '../../models/transaction_model.dart';

class WalletsViewModel extends ChangeNotifier {
  List<Wallet> _wallets = [];
  List<Transaction> _transactions = [];
  double _totalBalance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;

  StreamSubscription? _txSubscription;
  StreamSubscription? _walletSubscription;

  WalletsViewModel() {
    _setupListeners();
    refresh();
  }

  // Getters
  List<Wallet> get wallets => _wallets;
  List<Transaction> get transactions => _transactions;
  double get totalBalance => _totalBalance;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;

  void refresh() {
    final account = SessionService.activeAccount;
    if (account == null) return;

    final key = account.key as int;
    _wallets = DatabaseService.getWallets(key);
    _transactions = DatabaseService.getTransactions(key);

    _totalBalance = _wallets
        .where((w) => !w.isExcluded)
        .fold(0.0, (sum, w) => sum + w.balance);
    _totalIncome = _transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    _totalExpense = _transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    notifyListeners();
  }

  void _setupListeners() {
    _txSubscription?.cancel();
    _walletSubscription?.cancel();

    _txSubscription = DatabaseService.transactionWatcher.listen((_) => refresh());
    _walletSubscription = DatabaseService.walletWatcher.listen((_) => refresh());
  }

  @override
  void dispose() {
    _txSubscription?.cancel();
    _walletSubscription?.cancel();
    super.dispose();
  }
}
