import 'package:hive/hive.dart';

part 'squad.g.dart';

@HiveType(typeId: 9)
class Squad extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? color;

  @HiveField(2)
  int accountKey;

  @HiveField(3)
  DateTime createdAt;

  Squad({
    required this.name,
    this.color,
    required this.accountKey,
    required this.createdAt,
  });
}
