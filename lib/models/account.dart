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

  @HiveField(9)
  bool hasSeenTutorial;

  @HiveField(10)
  int xp;

  @HiveField(11)
  int level;

  @HiveField(12)
  int spentCoins;

  @HiveField(13)
  List<String> unlockedThemeIds;

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
    this.hasSeenTutorial = false,
    this.xp = 0,
    this.level = 1,
    this.spentCoins = 0,
    List<String>? unlockedThemeIds,
  }) : unlockedThemeIds = unlockedThemeIds ?? [];

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'budget': budget,
      'pin': pin,
      'isBiometricEnabled': isBiometricEnabled,
      'fakePin': fakePin,
      'isFake': isFake,
      'maxFailedAttempts': maxFailedAttempts,
      'isWipeEnabled': isWipeEnabled,
      'autoLockDurationSeconds': autoLockDurationSeconds,
      'hasSeenTutorial': hasSeenTutorial,
      'xp': xp,
      'level': level,
      'spentCoins': spentCoins,
      'unlockedThemeIds': unlockedThemeIds,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      name: map['name'],
      budget: map['budget'],
      pin: map['pin'],
      isBiometricEnabled: map['isBiometricEnabled'],
      fakePin: map['fakePin'],
      isFake: map['isFake'],
      maxFailedAttempts: map['maxFailedAttempts'],
      isWipeEnabled: map['isWipeEnabled'],
      autoLockDurationSeconds: map['autoLockDurationSeconds'],
      hasSeenTutorial: map['hasSeenTutorial'] ?? false,
      xp: map['xp'] ?? 0,
      level: map['level'] ?? 1,
      spentCoins: map['spentCoins'] ?? 0,
      unlockedThemeIds: List<String>.from(map['unlockedThemeIds'] ?? []),
    );
  }
}
