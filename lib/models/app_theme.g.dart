// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_theme.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppThemeAdapter extends TypeAdapter<AppTheme> {
  @override
  final int typeId = 1;

  @override
  AppTheme read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppTheme(
      primaryColor: fields[0] as int,
      backgroundColor: fields[1] as int,
      textColor: fields[2] as int,
      cardColor: fields[3] as int,
      name: fields[4] as String,
      incomeColor: fields[5] as int?,
      expenseColor: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, AppTheme obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.primaryColor)
      ..writeByte(1)
      ..write(obj.backgroundColor)
      ..writeByte(2)
      ..write(obj.textColor)
      ..writeByte(3)
      ..write(obj.cardColor)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.incomeColor)
      ..writeByte(6)
      ..write(obj.expenseColor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppThemeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
