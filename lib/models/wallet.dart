import 'package:hive/hive.dart';

part 'wallet.g.dart';

@HiveType(typeId: 4)
class Wallet extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double balance;

  @HiveField(2)
  String type; // Wallet, ATM, E-Wallet, Bank, etc.

  @HiveField(3)
  int accountKey; // Link to the user account

  @HiveField(4)
  bool isExcluded; // Whether to exclude from total balance

  Wallet({
    required this.name,
    this.balance = 0.0,
    required this.type,
    required this.accountKey,
    this.isExcluded = false,
  });
}
