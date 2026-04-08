import '../models/transaction_model.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/debt.dart';
import 'package:intl/intl.dart';

class GamificationBadge {
  final String title;
  final String icon;
  final bool isUnlocked;
  final String description;

  GamificationBadge({required this.title, required this.icon, required this.isUnlocked, required this.description});
}

class GamificationProfile {
  final int xp;
  final int level;
  final int streakDays;
  final List<GamificationBadge> badges;

  GamificationProfile({
    required this.xp,
    required this.level,
    required this.streakDays,
    required this.badges,
  });

  double get progressToNextLevel => (xp % 500) / 500;
}

class GamificationService {
  static GamificationProfile generateProfile({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<Goal> goals,
    required List<Debt> debts,
  }) {
    // 1. Calculate XP
    int txXp = transactions.length * 10;
    int budgetXp = budgets.length * 50;
    
    int completedGoals = goals.where((g) => g.targetAmount > 0 && g.savedAmount >= g.targetAmount).length;
    int goalXp = completedGoals * 100;

    int completedDebts = debts.where((d) => d.totalAmount > 0 && d.paidAmount >= d.totalAmount).length;
    int debtXp = completedDebts * 50;

    final datesActive = transactions.map((t) => DateFormat('yyyy-MM-dd').format(t.date)).toSet();
    int activeDaysXp = datesActive.length * 20;

    int totalXp = txXp + budgetXp + goalXp + debtXp + activeDaysXp;
    if (totalXp == 0 && transactions.isEmpty) totalXp = 0; // Baseline

    int level = (totalXp ~/ 500) + 1;

    // 2. Calculate Streak (Stayed within budget / logged)
    // Here we find consecutive active days where spending didn't massively exceed daily avg.
    // For simplicity, streak = consecutive days with at least 1 transaction
    int streak = 0;
    DateTime today = DateTime.now();
    for (int i = 0; i < 365; i++) {
        DateTime d = today.subtract(Duration(days: i));
        String dStr = DateFormat('yyyy-MM-dd').format(d);
        if (datesActive.contains(dStr)) {
            streak++;
        } else {
            if (i == 0) continue; // If they haven't logged today yet, streak doesn't break
            break;
        }
    }

    final owedDebts = debts.where((d) => !d.isOwedToMe).toList();
    final double totalRemainingOwed = owedDebts.fold(0.0, (sum, d) => sum + (d.totalAmount - d.paidAmount).clamp(0.0, double.infinity));

    List<GamificationBadge> badges = [
      GamificationBadge(
        title: 'First Step',
        icon: '🐣',
        isUnlocked: transactions.isNotEmpty,
        description: 'Log your first transaction.',
      ),
      GamificationBadge(
        title: 'Saver Level 1',
        icon: '💰',
        isUnlocked: goals.any((g) => g.savedAmount > 0),
        description: 'Put money towards a savings goal.',
      ),
      GamificationBadge(
        title: 'Debt Free',
        icon: '🏆',
        isUnlocked: totalRemainingOwed <= 0,
        description: 'You have no outstanding borrowed money!',
      ),
      GamificationBadge(
        title: 'Budget Master',
        icon: '🎯',
        isUnlocked: budgets.isNotEmpty && transactions.where((t) => t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount) < (budgets.fold(0.0, (sum, b) => sum + b.amountLimit) == 0 ? 1 : budgets.fold(0.0, (sum, b) => sum + b.amountLimit)),
        description: 'Stay under your total budget limit.',
      ),
      GamificationBadge(
        title: 'Streak Novice',
        icon: '🔥',
        isUnlocked: streak >= 3,
        description: 'Maintain a 3-day transaction streak.',
      )
    ];

    return GamificationProfile(
      xp: totalXp,
      level: level,
      streakDays: streak,
      badges: badges,
    );
  }
}
