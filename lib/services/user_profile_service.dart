import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

class UserProfileService {
  static const String _boxName = 'user_profile';
  static const String _profileKey = 'profile_key';

  static final ValueNotifier<UserProfile?> profileNotifier =
      ValueNotifier<UserProfile?>(null);

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    
    Box<UserProfile> box;
    try {
      box = await Hive.openBox<UserProfile>(_boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_boxName);
      box = await Hive.openBox<UserProfile>(_boxName);
    }

    if (box.isEmpty) {
      await box.put(_profileKey, UserProfile.createDefault());
    }

    profileNotifier.value = box.get(_profileKey);
  }

  static UserProfile get profile => profileNotifier.value!;

  static Future<void> saveProfile() async {
    await profile.save();
    // Notify listeners manually as saving an object doesn't trigger the ValueNotifier change if the reference is the same
    profileNotifier.value = profileNotifier.value;
  }
}
