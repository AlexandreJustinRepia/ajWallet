import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 8)
class UserProfile extends HiveObject {
  @HiveField(0)
  int spentCoins;

  @HiveField(1)
  List<String> unlockedThemeIds;

  @HiveField(2)
  List<String> unlockedCardSkinIds;

  @HiveField(3)
  String? activeCardSkinId;

  @HiveField(4)
  List<String> unlockedTreeSkinIds;

  @HiveField(5)
  String? activeTreeSkinId;

  UserProfile({
    this.spentCoins = 0,
    List<String>? unlockedThemeIds,
    List<String>? unlockedCardSkinIds,
    this.activeCardSkinId,
    List<String>? unlockedTreeSkinIds,
    this.activeTreeSkinId,
  })  : unlockedThemeIds = unlockedThemeIds ?? [],
        unlockedCardSkinIds = unlockedCardSkinIds ?? [],
        unlockedTreeSkinIds = unlockedTreeSkinIds ?? [];

  // Factory for default creation
  factory UserProfile.createDefault() {
    return UserProfile(
      spentCoins: 0,
      unlockedThemeIds: [],
      unlockedCardSkinIds: [],
      unlockedTreeSkinIds: ['spring'],
      activeTreeSkinId: 'spring',
    );
  }
}
