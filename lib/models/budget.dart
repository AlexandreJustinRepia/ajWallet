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

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'amountLimit': amountLimit,
      'accountKey': accountKey,
      'month': month,
      'year': year,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      category: map['category'],
      amountLimit: map['amountLimit'],
      accountKey: map['accountKey'],
      month: map['month'],
      year: map['year'],
    );
  }
}
