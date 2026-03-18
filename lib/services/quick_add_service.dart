import '../models/transaction_model.dart';
import 'package:flutter/material.dart';

class QuickAddResult {
  final double amount;
  final String category;
  final TransactionType type;
  final String title;
  final String? fromWallet;
  final String? toWallet;

  QuickAddResult({
    required this.amount,
    required this.category,
    required this.type,
    required this.title,
    this.fromWallet,
    this.toWallet,
  });
}

class QuickAddService {
  static final Map<String, List<String>> _categoryKeywords = {
    'Food & Drinks': ['food', 'eat', 'coffee', 'starbucks', 'dinner', 'lunch', 'breakfast', 'snack', 'restaurant', 'pizza', 'burger', 'drink', 'water', 'grocery', 'market'],
    'Transportation': ['taxi', 'uber', 'grab', 'bus', 'train', 'gas', 'fuel', 'oil', 'parking', 'toll', 'ticket', 'flight', 'travel', 'car', 'jeep', 'tricycle', 'e-tric'],
    'Shopping': ['shop', 'clothe', 'shirt', 'shoe', 'mall', 'amazon', 'lazada', 'shopee', 'gift', 'buy', 'purchase', 'gadget', 'phone'],
    'Entertainment': ['movie', 'netflix', 'game', 'party', 'concert', 'club', 'spotify', 'subscription', 'fun'],
    'Health': ['doctor', 'med', 'pharmacy', 'hospital', 'dentist', 'clinic', 'gym', 'workout', 'fitness', 'health'],
    'Utilities': ['rent', 'bill', 'electric', 'water', 'internet', 'wifi', 'cleaning', 'maintenance', 'repair'],
    'Salary': ['salary', 'bonus', 'paycheck', 'dividend', 'income', 'profit', 'work', 'freelance'],
  };

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
    final words = lowerInput.split(RegExp(r'\s+'));
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
      bool categoryFound = false;
      for (var word in words) {
        final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
        if (cleanWord.isEmpty) continue;

        for (var entry in _categoryKeywords.entries) {
          if (entry.value.contains(cleanWord)) {
            category = entry.key;
            categoryFound = true;
            if (category == 'Salary' || entry.value.contains('income')) {
              type = TransactionType.income;
            }
            break;
          }
        }
        if (categoryFound) break;
      }
      title = categoryFound ? category : (input.replaceAll(amountRegex, '').trim().isEmpty ? 'Quick Transaction' : input.replaceAll(amountRegex, '').trim());
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
    );
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Drinks': return Icons.fastfood;
      case 'Transportation': return Icons.directions_car;
      case 'Shopping': return Icons.shopping_bag;
      case 'Entertainment': return Icons.movie;
      case 'Health': return Icons.medical_services;
      case 'Utilities': return Icons.home;
      case 'Salary': return Icons.payments;
      default: return Icons.more_horiz;
    }
  }

  static Color getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income: return Colors.green;
      case TransactionType.expense: return Colors.red;
      case TransactionType.transfer: return Colors.blue;
    }
  }
}
