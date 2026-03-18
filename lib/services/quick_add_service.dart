import '../models/transaction_model.dart';
import 'package:flutter/material.dart';

class QuickAddResult {
  final double amount;
  final String category;
  final TransactionType type;
  final String title;

  QuickAddResult({
    required this.amount,
    required this.category,
    required this.type,
    required this.title,
  });
}

class QuickAddService {
  static final Map<String, List<String>> _categoryKeywords = {
    'Food & Drinks': ['food', 'eat', 'coffee', 'starbucks', 'dinner', 'lunch', 'breakfast', 'snack', 'restaurant', 'pizza', 'burger', 'drink', 'water', 'grocery', 'market'],
    'Transportation': ['taxi', 'uber', 'grab', 'bus', 'train', 'gas', 'fuel', 'oil', 'parking', 'toll', 'ticket', 'flight', 'travel', 'car'],
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

    final words = input.toLowerCase().split(RegExp(r'\s+'));
    double amount = 0;
    String category = 'Others';
    TransactionType type = TransactionType.expense;
    String title = '';

    // 1. Extract amount (first number found)
    final amountRegex = RegExp(r'(\d+([.,]\d+)?)');
    final amountMatch = amountRegex.firstMatch(input);
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', '')) ?? 0;
    }

    // 2. Detect category and type using keywords
    bool categoryFound = false;
    for (var word in words) {
      // Clear numbers from word for matching
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      if (cleanWord.isEmpty) continue;

      for (var entry in _categoryKeywords.entries) {
        if (entry.value.contains(cleanWord)) {
          category = entry.key;
          categoryFound = true;
          
          // Salary/Income detection
          if (category == 'Salary' || entry.value.contains('income')) {
            type = TransactionType.income;
          }
          break;
        }
      }
      if (categoryFound) break;
    }

    // 3. Generate title (Category as Title)
    title = categoryFound ? category : (input.replaceAll(amountRegex, '').trim().isEmpty ? 'Quick Transaction' : input.replaceAll(amountRegex, '').trim());
    
    // For transfers, if identified as such (not in current keywords but planned)
    if (type == TransactionType.transfer) title = 'Transfer';

    return QuickAddResult(
      amount: amount,
      category: category,
      type: type,
      title: title,
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
