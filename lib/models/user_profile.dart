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

  UserProfile({
    this.spentCoins = 0,
    List<String>? unlockedThemeIds,
    List<String>? unlockedCardSkinIds,
    this.activeCardSkinId,
  })  : unlockedThemeIds = unlockedThemeIds ?? [],
        unlockedCardSkinIds = unlockedCardSkinIds ?? [];

  // Factory for default creation
  factory UserProfile.createDefault() {
    return UserProfile(
      spentCoins: 0,
      unlockedThemeIds: [],
      unlockedCardSkinIds: [],
    );
  }
}
