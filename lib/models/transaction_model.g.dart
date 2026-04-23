// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 3;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      title: fields[0] as String,
      amount: fields[1] as double,
      date: fields[2] as DateTime,
      category: fields[3] as String,
      description: fields[4] as String,
      type: fields[5] as TransactionType,
      accountKey: fields[6] as int,
      walletKey: fields[7] as int?,
      toWalletKey: fields[8] as int?,
      charge: fields[9] as double?,
      goalKey: fields[10] as int?,
      budgetKey: fields[11] as int?,
      debtKey: fields[12] as int?,
      squadTxKey: fields[13] as int?,
      attachmentPaths: (fields[14] as List?)?.cast<String>(),
      shoppingListId: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.accountKey)
      ..writeByte(7)
      ..write(obj.walletKey)
      ..writeByte(8)
      ..write(obj.toWalletKey)
      ..writeByte(9)
      ..write(obj.charge)
      ..writeByte(10)
      ..write(obj.goalKey)
      ..writeByte(11)
      ..write(obj.budgetKey)
      ..writeByte(12)
      ..write(obj.debtKey)
      ..writeByte(14)
      ..write(obj.attachmentPaths)
      ..writeByte(13)
      ..write(obj.squadTxKey)
      ..writeByte(15)
      ..write(obj.shoppingListId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 2;

  @override
  TransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionType.income;
      case 1:
        return TransactionType.expense;
      case 2:
        return TransactionType.transfer;
      default:
        return TransactionType.income;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    switch (obj) {
      case TransactionType.income:
        writer.writeByte(0);
        break;
      case TransactionType.expense:
        writer.writeByte(1);
        break;
      case TransactionType.transfer:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
