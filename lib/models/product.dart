import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 15)
class Product extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double lastPrice;

  @HiveField(2)
  String defaultCategory;

  @HiveField(3)
  int accountKey;

  Product({
    required this.name,
    required this.lastPrice,
    required this.defaultCategory,
    required this.accountKey,
  });
}
