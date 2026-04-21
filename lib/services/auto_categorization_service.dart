import '../models/transaction_model.dart';
import 'database_service.dart';

class AutoCategorizationService {
  static final Map<String, List<String>> _staticKeywords = {
    // Expense Categories
    'Food & Drinks': ['food', 'eat', 'coffee', 'starbucks', 'dinner', 'lunch', 'breakfast', 'snack', 'restaurant', 'pizza', 'burger', 'drink', 'grocery', 'market', 'mcdo', 'jollibee', 'kfc', 'boba', 'milk', 'juice', 'energen', 'milo', 'water', 'rice', 'ulam', 'viand', 'noodle', 'merienda', 'siomai', 'siopao', 'pandesal', 'bread', 'cake', 'dessert', 'tea', 'ice cream'],
    'Transportation': ['taxi', 'uber', 'grab', 'bus', 'train', 'gas', 'fuel', 'oil', 'parking', 'toll', 'ticket', 'flight', 'travel', 'car', 'jeep', 'jeepney', 'tricycle', 'tric', 'e-tric', 'etric', 'joyride', 'angkas', 'motorcycle', 'bike', 'commute', 'fare'],
    'Shopping': ['shop', 'clothe', 'shirt', 'shoe', 'mall', 'amazon', 'lazada', 'shopee', 'gift', 'buy', 'purchase', 'gadget', 'phone'],
    'Entertainment': ['movie', 'netflix', 'game', 'party', 'concert', 'club', 'spotify', 'subscription', 'fun'],
    'Health': ['doctor', 'med', 'pharmacy', 'hospital', 'dentist', 'clinic', 'gym', 'workout', 'fitness', 'health', 'medicine'],
    'Utilities': ['rent', 'bill', 'electric', 'internet', 'wifi', 'cleaning', 'maintenance', 'repair', 'meralco', 'globe', 'smart', 'pldt'],
    'Education': ['school', 'course', 'book', 'tuition', 'class', 'study'],
    'Pet Food': ['pet', 'dog', 'cat', 'dogfood', 'catfood', 'pedigree', 'whiskas', 'purina', 'alpo', 'pet food', 'petfood', 'kibble', 'treats', 'pet treat'],
    
    // Income Categories
    'Salary': ['salary', 'paycheck', 'work', 'freelance', 'job', 'wage'],
    'Bonus': ['bonus', 'extra'],
    'Dividend': ['dividend', 'stock', 'share'],
    'Gift': ['gift', 'present'],
    'Investment': ['investment', 'crypto', 'bitcoin', 'profit', 'trade'],
  };

  static String? predictCategory(String text, TransactionType type) {
    if (text.trim().isEmpty) return null;
    
    final lowerText = text.toLowerCase();
    
    // 1. History Match (Highest Priority)
    final historyMatch = DatabaseService.getFrequentCategoryForDescription(text, type);
    if (historyMatch != null) return historyMatch;

    // 2. Custom Category Keyword Match
    final categories = DatabaseService.getCategories(type);
    for (var cat in categories) {
      if (cat.keywords != null) {
        for (var kw in cat.keywords!) {
          if (lowerText.contains(kw.toLowerCase())) {
            return cat.name;
          }
        }
      }
    }

    // 3. Static Keyword Match
    for (var entry in _staticKeywords.entries) {
      // Check if this category exists for the given type in the database
      final dbCat = DatabaseService.getCategoryByName(entry.key);
      if (dbCat != null && dbCat.type == type) {
        for (var kw in entry.value) {
          if (lowerText.contains(kw)) {
            return entry.key;
          }
        }
      }
    }

    return null;
  }
}
