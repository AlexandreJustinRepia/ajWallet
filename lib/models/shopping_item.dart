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
}
