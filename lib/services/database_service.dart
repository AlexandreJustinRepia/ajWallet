import 'package:hive_flutter/hive_flutter.dart';
import '../models/account.dart';
import '../models/app_theme.dart';
import '../models/transaction_model.dart';

class DatabaseService {
  static const String _boxName = 'accounts';
  static const String _transactionBoxName = 'transactions';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AccountAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppThemeAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TransactionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    
    await Hive.openBox<Account>(_boxName);
    await Hive.openBox<Transaction>(_transactionBoxName);
  }

  static Box<Account> get _box => Hive.box<Account>(_boxName);
  static Box<Transaction> get _transactionBox => Hive.box<Transaction>(_transactionBoxName);

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
    return _box.values.last;
  }

  // Transaction Operations
  static Future<void> saveTransaction(Transaction transaction) async {
    await _transactionBox.add(transaction);
    
    // Update account balance
    final account = _box.values.firstWhere((a) => a.key == transaction.accountKey);
    
    if (transaction.type == TransactionType.income) {
      account.budget += transaction.amount;
    } else if (transaction.type == TransactionType.expense) {
      account.budget -= transaction.amount;
    }
    await account.save();
  }

  static List<Transaction> getTransactions(int accountKey) {
    return _transactionBox.values.where((t) => t.accountKey == accountKey).toList();
  }
}
