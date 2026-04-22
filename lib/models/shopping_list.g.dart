// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShoppingListAdapter extends TypeAdapter<ShoppingList> {
  @override
  final int typeId = 16;

  @override
  ShoppingList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShoppingList(
      id: fields[0] as String,
      name: fields[1] as String,
      accountKey: fields[2] as int,
      createdAt: fields[3] as DateTime,
      isSettled: fields[4] as bool,
      totalAmount: fields[5] as double,
      linkedTransactionKey: fields[6] as int?,
      storeName: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingList obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.accountKey)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.isSettled)
      ..writeByte(5)
      ..write(obj.totalAmount)
      ..writeByte(6)
      ..write(obj.linkedTransactionKey)
      ..writeByte(7)
      ..write(obj.storeName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
