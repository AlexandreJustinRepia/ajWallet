import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 6)
class Budget extends HiveObject {
  @HiveField(0)
  String category;

  @HiveField(1)
  double amountLimit;

  @HiveField(2)
  int accountKey;

  @HiveField(3)
  int month;

  @HiveField(4)
  int year;

  Budget({
    required this.category,
    required this.amountLimit,
    required this.accountKey,
    required this.month,
    required this.year,
  });
}
