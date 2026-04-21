import '../models/transaction_model.dart';
import 'database_service.dart';
import 'package:flutter/material.dart';
import 'auto_categorization_service.dart';

class QuickAddResult {
  final double amount;
  final String category;
  final TransactionType type;
  final String title;
  final String? fromWallet;
  final String? toWallet;
  final Color color;

  QuickAddResult({
    required this.amount,
    required this.category,
    required this.type,
    required this.title,
    this.color = const Color(0xFF00695C),
    this.fromWallet,
    this.toWallet,
  });
}

class QuickAddService {
  static QuickAddResult parse(String input) {
    if (input.isEmpty) {
      return QuickAddResult(
        amount: 0,
        category: 'Others',
        type: TransactionType.expense,
        title: '',
      );
    }

    final lowerInput = input.toLowerCase();
    double amount = 0;
    String category = 'Others';
    TransactionType type = TransactionType.expense;
    String title = '';
    String? fromWallet;
    String? toWallet;

    // 1. Extract amount
    final amountRegex = RegExp(r'(\d+([.,]\d+)?)');
    final amountMatch = amountRegex.firstMatch(input);
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', '')) ?? 0;
    }

    // 2. Detect Transfer Intent
    if (lowerInput.contains('transfer') || lowerInput.contains(' to ') || lowerInput.contains('->')) {
      type = TransactionType.transfer;
      
      // Try to extract from/to wallets
      final fromPattern = RegExp(r'from\s+(\w+)');
      final toPattern = RegExp(r'to\s+(\w+)|->\s*(\w+)');
      
      final fromMatch = fromPattern.firstMatch(lowerInput);
      final toMatch = toPattern.firstMatch(lowerInput);

      if (fromMatch != null) fromWallet = fromMatch.group(1);
      if (toMatch != null) toWallet = toMatch.group(1) ?? toMatch.group(2);

      // If "Cash to Bank" style (no "from")
      if (fromWallet == null && toMatch != null) {
        final toIndex = lowerInput.indexOf(' to ');
        if (toIndex != -1) {
          final beforeTo = lowerInput.substring(0, toIndex).trim().split(' ').last;
          if (beforeTo != amountMatch?.group(1)) {
             fromWallet = beforeTo;
          }
        }
      }
    }

    // 3. Detect category and type using keywords (if not transfer)
    if (type != TransactionType.transfer) {
      final predictedCategory = AutoCategorizationService.predictCategory(input.replaceAll(amountRegex, '').trim(), type);
      if (predictedCategory != null) {
        category = predictedCategory;
        // Verify if it's an income category to adjust type
        final dbCat = DatabaseService.getCategoryByName(category);
        if (dbCat != null) {
          type = dbCat.type;
        }
      }
      
      title = input.replaceAll(amountRegex, '').trim().isEmpty ? 'Quick Transaction' : input.replaceAll(amountRegex, '').trim();
    } else {
      title = 'Transfer';
      category = 'Others';
    }

    return QuickAddResult(
      amount: amount,
      category: category,
      type: type,
      title: title,
      fromWallet: fromWallet,
      toWallet: toWallet,
      color: type == TransactionType.income ? const Color(0xFF2E7D32) : (type == TransactionType.expense ? const Color(0xFFB71C1C) : const Color(0xFF00695C)),
    );
  }

  static IconData getCategoryIcon(String category) {
    // 1. Check database for custom icon
    final dbCategory = DatabaseService.getCategoryByName(category);
    if (dbCategory != null) {
      return dbCategory.icon;
    }

    // 2. Fallback to hardcoded defaults for safety
    switch (category) {
      // Expense
      case 'Food & Drinks': return Icons.fastfood;
      case 'Transportation': return Icons.directions_car;
      case 'Shopping': return Icons.shopping_bag;
      case 'Entertainment': return Icons.movie;
      case 'Health': return Icons.medical_services;
      case 'Utilities': return Icons.home;
      case 'Education': return Icons.school;
      case 'Pet Food': return Icons.pets;
      
      // Income
      case 'Salary': return Icons.work;
      case 'Bonus': return Icons.card_giftcard;
      case 'Dividend': return Icons.pie_chart;
      case 'Gift': return Icons.redeem;
      case 'Investment': return Icons.trending_up;
      
      default: return Icons.category;
    }
  }

  static Color getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return const Color(0xFF2E7D32);
      case TransactionType.expense:
        return const Color(0xFFB71C1C);
      case TransactionType.transfer:
        return const Color(0xFF00695C);
    }
  }
}
