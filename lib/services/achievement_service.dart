import 'package:hive/hive.dart';
import '../models/transaction_model.dart';
import '../models/budget.dart';
import '../models/debt.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime? dateUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.dateUnlocked,
  });
}

class AchievementService {
  static const String _boxName = 'achievements';

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  static List<Achievement> getAchievements() {
    final box = Hive.box(_boxName);
    final all = [
      Achievement(id: 'streak_3', title: 'On a Roll', description: 'Stayed under budget for 3 days', icon: '🔥'),
      Achievement(id: 'debt_slayer', title: 'Debt Slayer', description: 'Paid off your first debt', icon: '⚔️'),
      Achievement(id: 'goal_getter', title: 'Goal Getter', description: 'Reached 25% of a savings goal', icon: '🏆'),
    ];

    return all.map((a) {
      final unlockedAt = box.get(a.id);
      return Achievement(
        id: a.id,
        title: a.title,
        description: a.description,
        icon: a.icon,
        dateUnlocked: unlockedAt != null ? DateTime.parse(unlockedAt) : null,
      );
    }).toList();
  }

  static void unlock(String id) {
    var box = Hive.box(_boxName);
    if (!box.containsKey(id)) {
      box.put(id, DateTime.now().toIso8601String());
    }
  }

  static List<Achievement> checkStreaks(List<Transaction> transactions, List<Budget> budgets) {
    final unlocked = <Achievement>[];
    final box = Hive.box(_boxName);

    // 1. Check for 3-day under-budget streak
    final now = DateTime.now();
    bool isClean = true;
    for (int i = 0; i < 3; i++) {
      final date = now.subtract(Duration(days: i));
      final dayExpenses = transactions
          .where((t) => t.type == TransactionType.expense && 
                        t.date.year == date.year && t.date.month == date.month && t.date.day == date.day)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      // Simple rule: if daily spend > 500 without budget, or over any budget
      if (dayExpenses > 1000) isClean = false; 
    }

    if (isClean && !box.containsKey('streak_3')) {
      unlock('streak_3');
      unlocked.add(getAchievements().firstWhere((a) => a.id == 'streak_3'));
    }

    return unlocked;
  }

  static List<Achievement> checkDebtCompletion(List<Debt> debts) {
    if (debts.isEmpty) return [];
    
    final box = Hive.box(_boxName);
    final newlyUnlocked = <Achievement>[];

    // Check if any debt is fully paid
    for (var debt in debts) {
      if (!debt.isOwedToMe && debt.paidAmount >= debt.totalAmount && debt.totalAmount > 0) {
        if (!box.containsKey('debt_slayer')) {
          unlock('debt_slayer');
          newlyUnlocked.add(getAchievements().firstWhere((a) => a.id == 'debt_slayer'));
        }
      }
    }

    return newlyUnlocked;
  }
}
