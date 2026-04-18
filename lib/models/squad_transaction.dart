import 'package:hive/hive.dart';

part 'squad_transaction.g.dart';

@HiveType(typeId: 12)
enum SplitType {
  @HiveField(0)
  equal,
  @HiveField(1)
  amount,
  @HiveField(2)
  percentage
}

@HiveType(typeId: 11)
class SquadTransaction extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  int squadKey;

  @HiveField(4)
  int payerMemberKey;

  @HiveField(5)
  SplitType splitType;

  @HiveField(6)
  Map<int, double> memberSplits; // MemberKey -> share (amount or percentage)

  @HiveField(7)
  bool isSettlement;

  @HiveField(8)
  int? walletKey; // If "You" paid, link to personal wallet

  @HiveField(9)
  int? relatedBillKey; // Link settlement to a specific bill

  SquadTransaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.squadKey,
    required this.payerMemberKey,
    required this.splitType,
    required this.memberSplits,
    this.isSettlement = false,
    this.walletKey,
    this.relatedBillKey,
  });
}
