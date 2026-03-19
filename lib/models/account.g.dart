// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountAdapter extends TypeAdapter<Account> {
  @override
  final int typeId = 0;

  @override
  Account read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Account(
      name: fields[0] as String,
      budget: fields[1] as double,
      pin: fields[2] as String?,
      isBiometricEnabled: fields[3] as bool,
      fakePin: fields[4] as String?,
      isFake: fields[5] as bool,
      maxFailedAttempts: fields[6] as int,
      isWipeEnabled: fields[7] as bool,
      autoLockDurationSeconds: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.budget)
      ..writeByte(2)
      ..write(obj.pin)
      ..writeByte(3)
      ..write(obj.isBiometricEnabled)
      ..writeByte(4)
      ..write(obj.fakePin)
      ..writeByte(5)
      ..write(obj.isFake)
      ..writeByte(6)
      ..write(obj.maxFailedAttempts)
      ..writeByte(7)
      ..write(obj.isWipeEnabled)
      ..writeByte(8)
      ..write(obj.autoLockDurationSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
