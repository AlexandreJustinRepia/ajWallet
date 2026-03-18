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
    
    // Handle Income/Expense wallet updates
    if (transaction.type == TransactionType.income && transaction.walletKey != null) {
      final wallet = _walletBox.get(transaction.walletKey);
      if (wallet != null) {
        wallet.balance += transaction.amount;
        await wallet.save();
      }
    } else if (transaction.type == TransactionType.expense && transaction.walletKey != null) {
      final wallet = _walletBox.get(transaction.walletKey);
      if (wallet != null) {
        wallet.balance -= transaction.amount;
        await wallet.save();
      }
    } 
    // Handle Transfers between wallets
    else if (transaction.type == TransactionType.transfer && transaction.walletKey != null && transaction.toWalletKey != null) {
      final fromWallet = _walletBox.get(transaction.walletKey);
      final toWallet = _walletBox.get(transaction.toWalletKey);
      if (fromWallet != null && toWallet != null) {
        double totalDeduction = transaction.amount + (transaction.charge ?? 0);
        fromWallet.balance -= totalDeduction;
        toWallet.balance += transaction.amount;
        await fromWallet.save();
        await toWallet.save();
      }
    }

    // Update global account balance
    final account = _box.values.firstWhere((a) => a.key == transaction.accountKey);
    if (transaction.type == TransactionType.income) {
      account.budget += transaction.amount;
    } else if (transaction.type == TransactionType.expense) {
      account.budget -= transaction.amount;
    } else if (transaction.type == TransactionType.transfer && transaction.charge != null) {
      // Transfers themselves don't change total budget, but charges do (money leaving the system)
      account.budget -= transaction.charge!;
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

  static Future<void> deleteTransaction(Transaction transaction) async {
    await transaction.delete();
  }

  static Wallet? getWalletByKey(int key) {
    final box = Hive.box<Wallet>(_walletBoxName);
    return box.get(key);
  }
}
