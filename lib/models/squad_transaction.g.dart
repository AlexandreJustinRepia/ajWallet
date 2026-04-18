// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'squad_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SquadTransactionAdapter extends TypeAdapter<SquadTransaction> {
  @override
  final int typeId = 11;

  @override
  SquadTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SquadTransaction(
      title: fields[0] as String,
      amount: fields[1] as double,
      date: fields[2] as DateTime,
      squadKey: fields[3] as int,
      payerMemberKey: fields[4] as int,
      splitType: fields[5] as SplitType,
      memberSplits: (fields[6] as Map).cast<int, double>(),
      isSettlement: fields[7] as bool,
      walletKey: fields[8] as int?,
      relatedBillKey: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SquadTransaction obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.squadKey)
      ..writeByte(4)
      ..write(obj.payerMemberKey)
      ..writeByte(5)
      ..write(obj.splitType)
      ..writeByte(6)
      ..write(obj.memberSplits)
      ..writeByte(7)
      ..write(obj.isSettlement)
      ..writeByte(8)
      ..write(obj.walletKey)
      ..writeByte(9)
      ..write(obj.relatedBillKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SquadTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SplitTypeAdapter extends TypeAdapter<SplitType> {
  @override
  final int typeId = 12;

  @override
  SplitType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SplitType.equal;
      case 1:
        return SplitType.amount;
      case 2:
        return SplitType.percentage;
      default:
        return SplitType.equal;
    }
  }

  @override
  void write(BinaryWriter writer, SplitType obj) {
    switch (obj) {
      case SplitType.equal:
        writer.writeByte(0);
        break;
      case SplitType.amount:
        writer.writeByte(1);
        break;
      case SplitType.percentage:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
