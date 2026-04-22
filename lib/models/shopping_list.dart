import 'package:hive/hive.dart';

part 'shopping_list.g.dart';

@HiveType(typeId: 16)
class ShoppingList extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int accountKey;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  bool isSettled;

  @HiveField(5)
  double totalAmount;

  @HiveField(6)
  int? linkedTransactionKey;

  @HiveField(7)
  String? storeName;

  ShoppingList({
    required this.id,
    required this.name,
    required this.accountKey,
    required this.createdAt,
    this.isSettled = false,
    this.totalAmount = 0.0,
    this.linkedTransactionKey,
    this.storeName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'accountKey': accountKey,
      'createdAt': createdAt.toIso8601String(),
      'isSettled': isSettled,
      'totalAmount': totalAmount,
      'linkedTransactionKey': linkedTransactionKey,
      'storeName': storeName,
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'],
      name: map['name'],
      accountKey: map['accountKey'],
      createdAt: DateTime.parse(map['createdAt']),
      isSettled: map['isSettled'] ?? false,
      totalAmount: map['totalAmount'] ?? 0.0,
      linkedTransactionKey: map['linkedTransactionKey'],
      storeName: map['storeName'],
    );
  }
}

