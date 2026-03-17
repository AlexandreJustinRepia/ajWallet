import 'package:hive_flutter/hive_flutter.dart';
import '../models/account.dart';

class DatabaseService {
  static const String _boxName = 'accounts';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AccountAdapter());
    }
    await Hive.openBox<Account>(_boxName);
  }

  static Box<Account> get _box => Hive.box<Account>(_boxName);

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
}
