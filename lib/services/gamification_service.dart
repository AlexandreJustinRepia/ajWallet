import 'dart:math' as math;
import '../models/transaction_model.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/debt.dart';
import '../models/account.dart';
import 'package:intl/intl.dart';

class DailyQuest {
  final String title;
  final String description;
  final int xpReward;
  final int coinReward;
  final bool isCompleted;

  DailyQuest({
    required this.title,
    required this.description,
    required this.xpReward,
    required this.coinReward,
    required this.isCompleted,
  });
}

class Achievement {
  final String title;
  final String icon;
  final String description;
  final double currentProgress;
  final double targetProgress;
  final String unit;
  final int coinReward;

  Achievement({
    required this.title,
    required this.icon,
    required this.description,
    required this.currentProgress,
    required this.targetProgress,
    this.unit = '',
    this.coinReward = 0,
  });

  bool get isUnlocked => currentProgress >= targetProgress;
  double get progressPercentage =>
      (currentProgress / targetProgress).clamp(0.0, 1.0);
}

class MidTermChallenge {
  final String title;
  final String description;
  final int xpReward;
  final int coinReward;
  final bool isCompleted;
  final String progress;

  MidTermChallenge({
    required this.title,
    required this.description,
    required this.xpReward,
    required this.coinReward,
    required this.isCompleted,
    required this.progress,
  });
}

class GamificationProfile {
  final int xp;
  final int level;
  final int coins; // Current spendable balance
  final int totalCoinsEarned;
  final int streakDays;
  final List<DailyQuest>? _dailyQuests;
  final List<MidTermChallenge>? _challenges;
  final List<Achievement>? _achievements;

  GamificationProfile({
    required this.xp,
    required this.level,
    required this.coins,
    required this.totalCoinsEarned,
    required this.streakDays,
    List<DailyQuest>? dailyQuests,
    List<MidTermChallenge>? challenges,
    List<Achievement>? achievements,
  }) : _dailyQuests = dailyQuests,
       _challenges = challenges,
       _achievements = achievements;

  List<DailyQuest> get dailyQuests => _dailyQuests ?? [];
  List<MidTermChallenge> get challenges => _challenges ?? [];
  List<Achievement> get achievements => _achievements ?? [];

  double get progressToNextLevel => (xp % 500) / 500;
}

class GamificationService {
  static GamificationProfile generateProfile({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<Goal> goals,
    required List<Debt> debts,
    int spentCoins = 0,
  }) {
    // 1. Calculate Base XP and Base Coins
    int txXp = transactions.length * 10;
    int txCoins = transactions.length * 2; // 2 coins per transaction
    int budgetXp = budgets.length * 50;
    // Coins for budgets will be handled in dynamic quests

    int completedGoals = goals
        .where((g) => g.targetAmount > 0 && g.savedAmount >= g.targetAmount)
        .length;
    int goalXp = completedGoals * 100;
    int goalCoinsMilestone = completedGoals * 50; // 50 coins per completed goal

    int completedDebts = debts
        .where((d) => d.totalAmount > 0 && d.paidAmount >= d.totalAmount)
        .length;
    int debtXp = completedDebts * 50;
    int debtCoinsMilestone = completedDebts * 25;

    final datesActive = transactions
        .map((t) => DateFormat('yyyy-MM-dd').format(t.date))
        .toSet();
    int activeDaysXp = datesActive.length * 20;
    int activeDaysCoins = datesActive.length * 5; // 5 coins per unique day active

    int totalXp = txXp + budgetXp + goalXp + debtXp + activeDaysXp;
    int totalCoinsEarned = txCoins + goalCoinsMilestone + debtCoinsMilestone + activeDaysCoins;

    if (totalXp == 0 && transactions.isEmpty) {
      totalXp = 0;
      totalCoinsEarned = 0;
    }

    // TESTING BONUS: 100,000 Coins
    totalCoinsEarned += 100000;

    int level = (totalXp ~/ 500) + 1;

    // 2. Calculate Streak
    int streak = 0;
    DateTime today = DateTime.now();
    for (int i = 0; i < 365; i++) {
      DateTime d = today.subtract(Duration(days: i));
      String dStr = DateFormat('yyyy-MM-dd').format(d);
      if (datesActive.contains(dStr)) {
        streak++;
      } else {
        if (i == 0) continue;
        break;
      }
    }
    
    // Add coins for streak milestones (every 7 days)
    totalCoinsEarned += (streak ~/ 7) * 50;

    // 3. Evaluate Daily Quests and add dynamic behavior
    String todayStr = DateFormat('yyyy-MM-dd').format(today);
    bool loggedToday = datesActive.contains(todayStr);
    bool hasActiveBudget = budgets.any(
      (b) => b.month == today.month && b.year == today.year,
    );
    bool fundedGoalToday = transactions.any(
      (t) =>
          DateFormat('yyyy-MM-dd').format(t.date) == todayStr &&
          t.goalKey != null &&
          t.type == TransactionType.expense,
    ); // Expense to wallet = funding a goal

    final pendingGoals = goals
        .where((g) => g.targetAmount > g.savedAmount)
        .toList();

    Goal? selectedGoal;
    if (pendingGoals.isNotEmpty) {
      selectedGoal = pendingGoals.reduce((a, b) {
        if (a.targetDate == null && b.targetDate == null) {
          final aRemaining = a.targetAmount - a.savedAmount;
          final bRemaining = b.targetAmount - b.savedAmount;
          return aRemaining >= bRemaining ? a : b;
        }
        if (a.targetDate == null) return b;
        if (b.targetDate == null) return a;
        return a.targetDate!.isBefore(b.targetDate!) ? a : b;
      });
    }

    int goalMissionTarget = 0;
    String goalMissionName = '';
    bool goalMissionCompleted = false;
    if (selectedGoal != null) {
      final goalRemaining =
          selectedGoal.targetAmount - selectedGoal.savedAmount;
      final daysLeft = selectedGoal.targetDate != null
          ? math.max(1, selectedGoal.targetDate!.difference(today).inDays)
          : 30;
      final suggested = selectedGoal.targetDate != null
          ? (goalRemaining / daysLeft)
          : math.min(500.0, goalRemaining);
      goalMissionTarget = math.max(1, suggested.round());
      if (goalMissionTarget > goalRemaining) {
        goalMissionTarget = goalRemaining.ceil();
      }
      goalMissionName = selectedGoal.name;
      final goalKeyValue = selectedGoal.key as int?;
      final todayGoalSavings = goalKeyValue != null
          ? transactions
                .where(
                  (t) =>
                      t.goalKey == goalKeyValue &&
                      t.type == TransactionType.expense &&
                      DateFormat('yyyy-MM-dd').format(t.date) == todayStr,
                )
                .fold(0.0, (sum, t) => sum + t.amount)
          : 0.0;
      goalMissionCompleted = todayGoalSavings >= goalMissionTarget;
    }

    DateTime? lastActiveDate = transactions.isEmpty
        ? null
        : transactions.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date;
    int daysSinceLastActive = lastActiveDate == null
        ? 999
        : today
              .difference(
                DateTime(
                  lastActiveDate.year,
                  lastActiveDate.month,
                  lastActiveDate.day,
                ),
              )
              .inDays;

    bool isNoSpendDay(List<Transaction> txs) {
      return txs
          .where((t) => t.type == TransactionType.expense && t.amount > 0)
          .isEmpty;
    }

    List<Transaction> transactionsForDay(DateTime day) {
      return transactions
          .where(
            (t) =>
                t.date.year == day.year &&
                t.date.month == day.month &&
                t.date.day == day.day,
          )
          .toList();
    }

    final currentMonthBudgets = budgets
        .where((b) => b.month == today.month && b.year == today.year)
        .toList();

    Budget? overspentBudget;
    double highestUsage = 0;
    for (final budget in currentMonthBudgets) {
      final budgetKey = budget.key as int?;
      final double monthSpent = transactions
          .where((t) => t.type == TransactionType.expense)
          .where(
            (t) => t.date.month == today.month && t.date.year == today.year,
          )
          .where(
            (t) => budgetKey != null
                ? t.budgetKey == budgetKey
                : t.category == budget.category,
          )
          .fold(0.0, (sum, t) => sum + t.amount);
      final double usageRatio = budget.amountLimit > 0
          ? (monthSpent / budget.amountLimit)
          : 1.0;
      if (usageRatio >= 0.9 && usageRatio > highestUsage) {
        highestUsage = usageRatio;
        overspentBudget = budget;
      }
    }

    final savingsContributionDays = transactions
        .where((t) => t.goalKey != null && t.type == TransactionType.expense)
        .where((t) => !t.date.isBefore(today.subtract(const Duration(days: 7))))
        .map((t) => DateFormat('yyyy-MM-dd').format(t.date))
        .toSet()
        .length;
    final bool savesOften = savingsContributionDays >= 3 && goals.isNotEmpty;
    final bool isInactive = !loggedToday && daysSinceLastActive >= 3;

    List<DailyQuest> quests = [
      DailyQuest(
        title: 'Daily Tracker',
        description: 'Record any transaction today.',
        xpReward: 20,
        coinReward: 5,
        isCompleted: loggedToday,
      ),
      DailyQuest(
        title: 'Future Planner',
        description: 'Have an active budget set for this month.',
        xpReward: 10,
        coinReward: 2,
        isCompleted: hasActiveBudget,
      ),
      selectedGoal != null
          ? DailyQuest(
              title: 'Save ₱$goalMissionTarget toward $goalMissionName',
              description: 'Move closer to your $goalMissionName goal today.',
              xpReward: 35,
              coinReward: 10,
              isCompleted: goalMissionCompleted,
            )
          : DailyQuest(
              title: 'Wealth Builder',
              description: 'Add money to any savings goal today.',
              xpReward: 30,
              coinReward: 8,
              isCompleted: fundedGoalToday,
            ),
    ];

    DailyQuest dynamicQuest;
    if (overspentBudget != null) {
      dynamicQuest = DailyQuest(
        title: 'Stay under your ${overspentBudget.category} budget',
        description:
            'Keep spending within your ${overspentBudget.category} budget today.',
        xpReward: 25,
        coinReward: 10,
        isCompleted: highestUsage <= 1.0,
      );
    } else if (isInactive) {
      dynamicQuest = DailyQuest(
        title: 'Restore your Growth Chain',
        description: 'Log 1 transaction to restart your activity growth chain.',
        xpReward: 20,
        coinReward: 5,
        isCompleted: loggedToday,
      );
    } else if (savesOften) {
      dynamicQuest = DailyQuest(
        title: 'Boost your savings',
        description: 'Increase your savings progress by 10% today.',
        xpReward: 30,
        coinReward: 15,
        isCompleted: fundedGoalToday,
      );
    } else {
      dynamicQuest = DailyQuest(
        title: 'Keep momentum going',
        description: 'Stay on track with your spending or savings today.',
        xpReward: 15,
        coinReward: 5,
        isCompleted: loggedToday || hasActiveBudget,
      );
    }

    quests.add(dynamicQuest);

    // Sum up coins from completed daily quests today
    int dailyQuestCoins = quests
        .where((q) => q.isCompleted)
        .fold(0, (sum, q) => sum + q.coinReward);
    totalCoinsEarned += dailyQuestCoins;

    // Add extra XP theoretically generated by quests today (just for the UI to feel responsive if they aren't derived elsewhere)
    if (hasActiveBudget) totalXp += 10;
    if (fundedGoalToday) totalXp += 30;
    // loggedToday is already covered natively by strictly adding activeDaysXp (which gives 20)

    level = (totalXp ~/ 500) + 1; // Recalculate level just in case

    // 4. Calculate Mid-Term Challenges
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final double goalContributionThisWeek = transactions
        .where((t) => t.goalKey != null && t.type == TransactionType.expense)
        .where((t) => !t.date.isBefore(weekStart) && t.date.isBefore(weekEnd))
        .fold(0.0, (sum, t) => sum + t.amount);

    final bool weeklySaverComplete = goalContributionThisWeek >= 1000.0;
    final String weeklySaverProgress = weeklySaverComplete
        ? 'Goal reached for the week!'
        : '₱${goalContributionThisWeek.toStringAsFixed(0)} / ₱1000 saved this week.';

    final saturdayDate = weekStart.add(const Duration(days: 5));
    final sundayDate = weekStart.add(const Duration(days: 6));
    final saturdayPassed = !saturdayDate.isAfter(today);
    final sundayPassed = !sundayDate.isAfter(today);

    final saturdayNoSpend =
        saturdayPassed && isNoSpendDay(transactionsForDay(saturdayDate));
    final sundayNoSpend =
        sundayPassed && isNoSpendDay(transactionsForDay(sundayDate));
    final int weekendDaysValidated =
        (saturdayPassed ? 1 : 0) + (sundayPassed ? 1 : 0);
    final int noSpendDaysCount = [
      saturdayNoSpend,
      sundayNoSpend,
    ].where((passed) => passed).length;

    final bool noSpendWeekendComplete =
        weekendDaysValidated == 2 && noSpendDaysCount == 2;
    final String noSpendWeekendProgress = weekendDaysValidated == 0
        ? 'Weekend not started yet.'
        : '$noSpendDaysCount / 2 spend-free days this weekend.';

    int budgetsOnTrack = 0;

    for (final budget in currentMonthBudgets) {
      final budgetKey = budget.key as int?;
      final totalSpent = transactions
          .where((t) => t.type == TransactionType.expense)
          .where(
            (t) => t.date.month == today.month && t.date.year == today.year,
          )
          .where(
            (t) => budgetKey != null
                ? t.budgetKey == budgetKey
                : t.category == budget.category,
          )
          .fold(0.0, (sum, t) => sum + t.amount);
      if (totalSpent <= budget.amountLimit) budgetsOnTrack += 1;
    }

    final bool budgetMasterComplete =
        currentMonthBudgets.isNotEmpty &&
        budgetsOnTrack == currentMonthBudgets.length;
    final String budgetMasterProgress = currentMonthBudgets.isEmpty
        ? 'No active budgets this month.'
        : '$budgetsOnTrack / ${currentMonthBudgets.length} budgets on track.';

    final List<MidTermChallenge> challenges = [
      MidTermChallenge(
        title: 'Weekly Saver',
        description: 'Save ₱1,000 this week.',
        xpReward: 60,
        coinReward: 30,
        isCompleted: weeklySaverComplete,
        progress: weeklySaverProgress,
      ),
      MidTermChallenge(
        title: 'No-Spend Weekend',
        description:
            'Avoid any expense transactions for 2 days. Logging is still encouraged.',
        xpReward: 40,
        coinReward: 20,
        isCompleted: noSpendWeekendComplete,
        progress: noSpendWeekendProgress,
      ),
      MidTermChallenge(
        title: 'Budget Master',
        description: 'Stay within all budgets this month.',
        xpReward: 70,
        coinReward: 50,
        isCompleted: budgetMasterComplete,
        progress: budgetMasterProgress,
      ),
    ];

    if (weeklySaverComplete) {
      totalXp += 60;
      totalCoinsEarned += 30;
    }
    if (noSpendWeekendComplete) {
      totalXp += 40;
      totalCoinsEarned += 20;
    }
    if (budgetMasterComplete) {
      totalXp += 70;
      totalCoinsEarned += 50;
    }
    level = (totalXp ~/ 500) + 1;

    // 5. Calculate Achievements
    final owedDebts = debts.where((d) => !d.isOwedToMe).toList();
    final double totalPaidDebt = owedDebts.fold(
      0.0,
      (sum, d) => sum + d.paidAmount,
    );
    final double totalRemainingOwed = owedDebts.fold(
      0.0,
      (sum, d) =>
          sum + (d.totalAmount - d.paidAmount).clamp(0.0, double.infinity),
    );
    final double totalSaved = goals.fold(0.0, (sum, g) => sum + g.savedAmount);

    List<Achievement> achievementsList = [
      Achievement(
        title: 'Loyal Tracker I',
        icon: '📝',
        description: 'Log 50 transactions to build a habit.',
        currentProgress: transactions.length.toDouble(),
        targetProgress: 50.0,
        unit: 'logs',
        coinReward: 50,
      ),
      Achievement(
        title: 'Loyal Tracker II',
        icon: '📝',
        description: 'Log 200 transactions to deepen your tracking habit.',
        currentProgress: transactions.length.toDouble(),
        targetProgress: 200.0,
        unit: 'logs',
        coinReward: 150,
      ),
      Achievement(
        title: 'Loyal Tracker III',
        icon: '📝',
        description: 'Log 500 transactions and become a tracking pro.',
        currentProgress: transactions.length.toDouble(),
        targetProgress: 500.0,
        unit: 'logs',
        coinReward: 400,
      ),
      Achievement(
        title: 'Wealth Accumulator I',
        icon: '💰',
        description: 'Save ₱5,000 across your goals.',
        currentProgress: totalSaved,
        targetProgress: 5000.0,
        unit: '₱',
        coinReward: 100,
      ),
      Achievement(
        title: 'Wealth Accumulator II',
        icon: '💰',
        description: 'Save ₱15,000 across your goals.',
        currentProgress: totalSaved,
        targetProgress: 15000.0,
        unit: '₱',
        coinReward: 300,
      ),
      Achievement(
        title: 'Wealth Accumulator III',
        icon: '💰',
        description: 'Save ₱30,000 across your goals.',
        currentProgress: totalSaved,
        targetProgress: 30000.0,
        unit: '₱',
        coinReward: 600,
      ),
      Achievement(
        title: 'Steady Growth',
        icon: '🌳',
        description: 'Reach a 7-day transaction growth chain.',
        currentProgress: streak.toDouble(),
        targetProgress: 7.0,
        unit: 'days',
        coinReward: 70,
      ),
      Achievement(
        title: 'Debt Destroyer I',
        icon: '🏆',
        description: 'Pay off ₱5,000 of borrowed money.',
        currentProgress: totalPaidDebt,
        targetProgress: 5000.0,
        unit: '₱',
        coinReward: 100,
      ),
      Achievement(
        title: 'Debt Destroyer II',
        icon: '🏆',
        description: 'Pay off ₱15,000 of borrowed money.',
        currentProgress: totalPaidDebt,
        targetProgress: 15000.0,
        unit: '₱',
        coinReward: 300,
      ),
      Achievement(
        title: 'Debt Destroyer III',
        icon: '🏆',
        description: 'Pay off ₱30,000 of borrowed money.',
        currentProgress: totalPaidDebt,
        targetProgress: 30000.0,
        unit: '₱',
        coinReward: 600,
      ),
      Achievement(
        title: 'Debt Free (Bonus)',
        icon: '👼',
        description: 'Have zero outstanding borrowed money.',
        currentProgress: totalRemainingOwed <= 0 && owedDebts.isNotEmpty
            ? 1.0
            : 0.0,
        targetProgress: 1.0,
        unit: 'done',
        coinReward: 500,
      ),
    ];

    // Add coins from completed achievements
    int achievementCoins = achievementsList
        .where((a) => a.isUnlocked)
        .fold(0, (sum, a) => sum + a.coinReward);
    totalCoinsEarned += achievementCoins;

    return GamificationProfile(
      xp: totalXp,
      level: level,
      coins: (totalCoinsEarned - spentCoins).clamp(0, 999999),
      totalCoinsEarned: totalCoinsEarned,
      streakDays: streak,
      dailyQuests: quests,
      challenges: challenges,
      achievements: achievementsList,
    );
  }

  static Future<void> syncProfileToAccount(Account account, GamificationProfile profile) async {
    bool changed = false;
    if (account.xp != profile.xp) {
      account.xp = profile.xp;
      changed = true;
    }
    if (account.level != profile.level) {
      account.level = profile.level;
      changed = true;
    }
    
    if (changed) {
      await account.save();
    }
  }
}
