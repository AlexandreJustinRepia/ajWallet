// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'squad_member.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SquadMemberAdapter extends TypeAdapter<SquadMember> {
  @override
  final int typeId = 10;

  @override
  SquadMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SquadMember(
      name: fields[0] as String,
      squadKey: fields[1] as int,
      isYou: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SquadMember obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.squadKey)
      ..writeByte(2)
      ..write(obj.isYou);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SquadMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
