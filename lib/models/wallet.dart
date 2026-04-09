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

  @HiveField(5)
  String? iconPath; // Path to the institution's logo

  Wallet({
    required this.name,
    this.balance = 0.0,
    required this.type,
    required this.accountKey,
    this.isExcluded = false,
    this.iconPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'balance': balance,
      'type': type,
      'accountKey': accountKey,
      'isExcluded': isExcluded,
      'iconPath': iconPath,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      name: map['name'],
      balance: map['balance'],
      type: map['type'],
      accountKey: map['accountKey'],
      isExcluded: map['isExcluded'],
      iconPath: map['iconPath'],
    );
  }
}
