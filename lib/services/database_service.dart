import 'package:hive_flutter/hive_flutter.dart';
import '../models/account.dart';
import '../models/app_theme.dart';
import '../models/transaction_model.dart';
import '../models/wallet.dart';

class DatabaseService {
  static const String _boxName = 'accounts';
  static const String _transactionBoxName = 'transactions';
  static const String _walletBoxName = 'wallets';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(AccountAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AppThemeAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TransactionTypeAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(WalletAdapter());
    
    await Hive.openBox<Account>(_boxName);
    await Hive.openBox<Transaction>(_transactionBoxName);
    await Hive.openBox<Wallet>(_walletBoxName);
  }

  static Box<Account> get _box => Hive.box<Account>(_boxName);
  static Box<Transaction> get _transactionBox => Hive.box<Transaction>(_transactionBoxName);
  static Box<Wallet> get _walletBox => Hive.box<Wallet>(_walletBoxName);

  static Future<void> saveAccount(Account account) async {
    await _box.add(account);
  }

  static Future<void> updateAccount(Account account) async {
    await account.save();
  }

  static Future<void> deleteAccount(Account account) async {
    await account.delete();
  }

  static List<Account> getAccounts() {
    return _box.values.toList();
  }

  static Account? getLatestAccount() {
    if (_box.isEmpty) return null;
    // Return the first non-fake account as the primary one for initial loading
    return _box.values.firstWhere((a) => !a.isFake, orElse: () => _box.values.last);
  }

  static Account? getFakeAccount(String primaryName) {
    try {
      return _box.values.firstWhere((a) => a.isFake && a.name.contains(primaryName));
    } catch (_) {
      return null;
    }
  }

  // Wallet Operations
  static Future<void> saveWallet(Wallet wallet) async {
    await _walletBox.add(wallet);
  }

  static Future<void> updateWallet(Wallet wallet) async {
    await wallet.save();
  }

  static List<Wallet> getWallets(int accountKey) {
    return _walletBox.values.where((w) => w.accountKey == accountKey).toList();
  }

  static List<Wallet> getAllWallets() {
    return _walletBox.values.toList();
  }

  static Wallet? getWallet(int key) {
    return _walletBox.get(key);
  }

  // Transaction Operations
  static Future<void> saveTransaction(Transaction transaction) async {
    await _transactionBox.add(transaction);
    await _applyTransactionEffect(transaction, isReversing: false);
  }

  static Future<void> deleteTransaction(Transaction transaction) async {
    await _applyTransactionEffect(transaction, isReversing: true);
    await transaction.delete();
  }

  static Future<void> updateTransaction(Transaction oldTx, Transaction newTx) async {
    // 1. Reverse old transaction's effect
    await _applyTransactionEffect(oldTx, isReversing: true);
    // 2. Apply new transaction's effect
    await _applyTransactionEffect(newTx, isReversing: false);
    // 3. Save new data (assuming it's the same HiveObject or we update its fields)
    await newTx.save();
  }

  static Future<void> _applyTransactionEffect(Transaction tx, {required bool isReversing}) async {
    double amount = isReversing ? -tx.amount : tx.amount;
    double charge = isReversing ? -(tx.charge ?? 0) : (tx.charge ?? 0);

    // Handle Income/Expense wallet updates
    if (tx.type == TransactionType.income && tx.walletKey != null) {
      final wallet = _walletBox.get(tx.walletKey);
      if (wallet != null) {
        wallet.balance += amount;
        await wallet.save();
      }
    } else if (tx.type == TransactionType.expense && tx.walletKey != null) {
      final wallet = _walletBox.get(tx.walletKey);
      if (wallet != null) {
        wallet.balance -= amount;
        await wallet.save();
      }
    } 
    // Handle Transfers between wallets
    else if (tx.type == TransactionType.transfer && tx.walletKey != null && tx.toWalletKey != null) {
      final fromWallet = _walletBox.get(tx.walletKey);
      final toWallet = _walletBox.get(tx.toWalletKey);
      if (fromWallet != null && toWallet != null) {
        double fromDeduction = tx.amount + (tx.charge ?? 0);
        if (isReversing) fromDeduction = -fromDeduction;
        
        fromWallet.balance -= fromDeduction;
        toWallet.balance += amount;
        
        await fromWallet.save();
        await toWallet.save();
      }
    }

    // Update global account budget
    final account = _box.values.firstWhere((a) => a.key == tx.accountKey);
    if (tx.type == TransactionType.income) {
      account.budget += amount;
    } else if (tx.type == TransactionType.expense) {
      account.budget -= amount;
    } else if (tx.type == TransactionType.transfer) {
      // Transfers themselves don't change total budget, only charges do
      account.budget -= charge;
    }

    await account.save();
  }

  static List<Transaction> getTransactions(int accountKey) {
    return _transactionBox.values.where((t) => t.accountKey == accountKey).toList();
  }

  static List<Transaction> getAllTransactions() {
    return _transactionBox.values.toList();
  }

  static List<Transaction> getWalletTransactions(int walletKey) {
    return _transactionBox.values
        .where((t) => t.walletKey == walletKey || t.toWalletKey == walletKey)
        .toList();
  }

  static Future<void> wipeAllData() async {
    await _box.clear();
    await _transactionBox.clear();
    await _walletBox.clear();
  }

  static Wallet? getWalletByKey(int key) {
    final box = Hive.box<Wallet>(_walletBoxName);
    return box.get(key);
  }
}
