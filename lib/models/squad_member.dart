import 'package:hive/hive.dart';

part 'squad_member.g.dart';

@HiveType(typeId: 10)
class SquadMember extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int squadKey;

  @HiveField(2)
  bool isYou;

  SquadMember({
    required this.name,
    required this.squadKey,
    this.isYou = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'squadKey': squadKey,
      'isYou': isYou,
    };
  }

  factory SquadMember.fromMap(Map<String, dynamic> map) {
    return SquadMember(
      name: map['name'],
      squadKey: map['squadKey'],
      isYou: map['isYou'],
    );
  }
}
