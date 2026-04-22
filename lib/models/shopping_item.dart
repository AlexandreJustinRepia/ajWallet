import 'package:hive/hive.dart';

part 'shopping_item.g.dart';

@HiveType(typeId: 14)
class ShoppingItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  String category;

  @HiveField(5)
  bool isBought;

  @HiveField(6)
  int accountKey;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  String? listId; // New field for multi-list support

  @HiveField(9)
  int? linkedTransactionKey;

  @HiveField(10)
  String? imagePath;

  static const List<String> categories = [
    'Food & Drinks',
    'Groceries',
    'Health',
    'Personal Care',
    'Home',
    'Electronics',
    'Clothing',
    'Other',
  ];


  ShoppingItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    required this.category,
    this.isBought = false,
    required this.accountKey,
    required this.createdAt,
    this.listId,
    this.linkedTransactionKey,
    this.imagePath,
  });


  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'category': category,
      'isBought': isBought,
      'accountKey': accountKey,
      'createdAt': createdAt.toIso8601String(),
      'listId': listId,
      'linkedTransactionKey': linkedTransactionKey,
      'imagePath': imagePath,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      quantity: map['quantity'],
      category: map['category'],
      isBought: map['isBought'],
      accountKey: map['accountKey'],
      createdAt: DateTime.parse(map['createdAt']),
      listId: map['listId'],
      linkedTransactionKey: map['linkedTransactionKey'],
      imagePath: map['imagePath'],
    );
  }
}
