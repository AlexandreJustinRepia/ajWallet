import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'transaction_model.dart';

part 'category.g.dart';

@HiveType(typeId: 13)
class Category extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int iconCode;

  @HiveField(2)
  TransactionType type;

  @HiveField(3)
  bool isDefault;

  // New field for keyword matching if we want to support dynamic quick add
  @HiveField(4)
  List<String>? keywords;

  @HiveField(5)
  int orderIndex;

  Category({
    required this.name,
    required this.iconCode,
    required this.type,
    this.isDefault = false,
    this.keywords,
    this.orderIndex = 0,
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconCode': iconCode,
      'type': type.index,
      'isDefault': isDefault,
      'keywords': keywords,
      'orderIndex': orderIndex,
    };
  }


  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      name: map['name'],
      iconCode: map['iconCode'],
      type: TransactionType.values[map['type']],
      isDefault: map['isDefault'] ?? false,
      keywords: (map['keywords'] as List?)?.cast<String>(),
      orderIndex: map['orderIndex'] ?? 0,
    );
  }
}

