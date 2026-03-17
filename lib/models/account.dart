import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 0)
class Account extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double budget;

  @HiveField(2)
  String? pin;

  @HiveField(3)
  bool isBiometricEnabled;

  Account({
    required this.name,
    this.budget = 0.0,
    this.pin,
    this.isBiometricEnabled = false,
  });
}
