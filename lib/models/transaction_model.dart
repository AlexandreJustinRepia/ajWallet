import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 2)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
  @HiveField(2)
  transfer
}

@HiveType(typeId: 3)
class Transaction extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String category;

  @HiveField(4)
  String description;

  @HiveField(5)
  TransactionType type;

  @HiveField(6)
  int accountKey;

  @HiveField(7)
  int? walletKey; // For Income and Expense

  @HiveField(8)
  int? toWalletKey; // Specifically for Transfer

  Transaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.description,
    required this.type,
    required this.accountKey,
    this.walletKey,
    this.toWalletKey,
  });

  Color get typeColor {
    switch (type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
    }
  }
}
