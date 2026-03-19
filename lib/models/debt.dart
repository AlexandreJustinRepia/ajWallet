import 'package:hive/hive.dart';

part 'debt.g.dart';

@HiveType(typeId: 7)
class Debt extends HiveObject {
  @HiveField(0)
  String personName;

  @HiveField(1)
  double totalAmount;

  @HiveField(2)
  double paidAmount;

  @HiveField(3)
  int accountKey;

  @HiveField(4)
  bool isOwedToMe; // true = lent money out (they owe you), false = borrowed money (you owe them)

  @HiveField(5)
  DateTime? dueDate;

  Debt({
    required this.personName,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.accountKey,
    required this.isOwedToMe,
    this.dueDate,
  });
}
