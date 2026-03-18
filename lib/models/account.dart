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

  @HiveField(4)
  String? fakePin;

  @HiveField(5)
  bool isFake;

  @HiveField(6)
  int maxFailedAttempts;

  @HiveField(7)
  bool isWipeEnabled;

  @HiveField(8)
  int autoLockDurationSeconds;

  Account({
    required this.name,
    this.budget = 0.0,
    this.pin,
    this.isBiometricEnabled = false,
    this.fakePin,
    this.isFake = false,
    this.maxFailedAttempts = 5,
    this.isWipeEnabled = false,
    this.autoLockDurationSeconds = 30,
  });
}
