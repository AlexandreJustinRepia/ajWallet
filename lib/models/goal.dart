import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 5)
class Goal extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double targetAmount;

  @HiveField(2)
  double savedAmount;

  @HiveField(3)
  int accountKey;

  @HiveField(4)
  DateTime? targetDate;

  @HiveField(5)
  int colorValue;

  Goal({
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0.0,
    required this.accountKey,
    this.targetDate,
    required this.colorValue,
  });
}
