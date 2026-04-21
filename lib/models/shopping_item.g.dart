// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShoppingItemAdapter extends TypeAdapter<ShoppingItem> {
  @override
  final int typeId = 14;

  @override
  ShoppingItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShoppingItem(
      id: fields[0] as String,
      name: fields[1] as String,
      price: fields[2] as double,
      quantity: fields[3] as int,
      category: fields[4] as String,
      isBought: fields[5] as bool,
      accountKey: fields[6] as int,
      createdAt: fields[7] as DateTime,
      listId: fields[8] as String?,
      linkedTransactionKey: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.isBought)
      ..writeByte(6)
      ..write(obj.accountKey)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.listId)
      ..writeByte(9)
      ..write(obj.linkedTransactionKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
