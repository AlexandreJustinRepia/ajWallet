// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 8;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      spentCoins: fields[0] as int,
      unlockedThemeIds: (fields[1] as List?)?.cast<String>(),
      unlockedCardSkinIds: (fields[2] as List?)?.cast<String>(),
      activeCardSkinId: fields[3] as String?,
      unlockedTreeSkinIds: (fields[4] as List?)?.cast<String>(),
      activeTreeSkinId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.spentCoins)
      ..writeByte(1)
      ..write(obj.unlockedThemeIds)
      ..writeByte(2)
      ..write(obj.unlockedCardSkinIds)
      ..writeByte(3)
      ..write(obj.activeCardSkinId)
      ..writeByte(4)
      ..write(obj.unlockedTreeSkinIds)
      ..writeByte(5)
      ..write(obj.activeTreeSkinId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
