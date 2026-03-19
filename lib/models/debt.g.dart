// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DebtAdapter extends TypeAdapter<Debt> {
  @override
  final int typeId = 7;

  @override
  Debt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Debt(
      personName: fields[0] as String,
      totalAmount: fields[1] as double,
      paidAmount: fields[2] as double,
      accountKey: fields[3] as int,
      isOwedToMe: fields[4] as bool,
      dueDate: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Debt obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.personName)
      ..writeByte(1)
      ..write(obj.totalAmount)
      ..writeByte(2)
      ..write(obj.paidAmount)
      ..writeByte(3)
      ..write(obj.accountKey)
      ..writeByte(4)
      ..write(obj.isOwedToMe)
      ..writeByte(5)
      ..write(obj.dueDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
