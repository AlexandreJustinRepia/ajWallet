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

  @HiveField(6)
  String? description;

  Debt({
    required this.personName,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.accountKey,
    required this.isOwedToMe,
    this.dueDate,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'personName': personName,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'accountKey': accountKey,
      'isOwedToMe': isOwedToMe,
      'dueDate': dueDate?.toIso8601String(),
      'description': description,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      personName: map['personName'],
      totalAmount: map['totalAmount'],
      paidAmount: map['paidAmount'],
      accountKey: map['accountKey'],
      isOwedToMe: map['isOwedToMe'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      description: map['description'],
    );
  }
}
