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

  @HiveField(9)
  double? charge;

  @HiveField(10)
  int? goalKey;

  @HiveField(11)
  int? budgetKey;

  @HiveField(12)
  int? debtKey;

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
    this.charge,
    this.goalKey,
    this.budgetKey,
    this.debtKey,
    this.squadTxKey,
  });

  @HiveField(13)
  int? squadTxKey;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'description': description,
      'type': type.index,
      'accountKey': accountKey,
      'walletKey': walletKey,
      'toWalletKey': toWalletKey,
      'charge': charge,
      'goalKey': goalKey,
      'budgetKey': budgetKey,
      'debtKey': debtKey,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: map['category'],
      description: map['description'],
      type: TransactionType.values[map['type']],
      accountKey: map['accountKey'],
      walletKey: map['walletKey'],
      toWalletKey: map['toWalletKey'],
      charge: map['charge'],
      goalKey: map['goalKey'],
      budgetKey: map['budgetKey'],
      debtKey: map['debtKey'],
    );
  }

  Color get typeColor {
    switch (type) {
      case TransactionType.income:
        return const Color(0xFF2E7D32); // Forest Green
      case TransactionType.expense:
        return const Color(0xFFC62828); // Deep Red
      case TransactionType.transfer:
        return const Color(0xFF00796B); // Botanical Teal
    }
  }
}
