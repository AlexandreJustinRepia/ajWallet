import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import '../models/transaction_model.dart';
import '../models/wallet.dart';
import '../widgets/animated_count_text.dart';
import '../widgets/slide_in_list_item.dart';
import '../widgets/quick_add_input.dart';
import '../widgets/transaction_card.dart';
import '../services/financial_insights_service.dart';
import '../services/gamification_service.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/debt.dart';
import 'insight_card.dart';
import 'dashboard_helpers.dart';
import '../widgets/financial_health_strip.dart';

class HomeView extends StatefulWidget {
  final VoidCallback onRefresh;
  final GlobalKey? balanceKey;
  final GlobalKey? quickAddKey;
  final GlobalKey? activityHeaderKey;
  final GlobalKey? sampleTransactionKey;
  final bool isTutorialActive;

  const HomeView({
    super.key, 
    required this.onRefresh,
    this.balanceKey,
    this.quickAddKey,
    this.activityHeaderKey,
    this.sampleTransactionKey,
    this.isTutorialActive = false,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  double _prevBalance = 0;
  bool _showGlow = false;
  bool _isNetWorthMode = false;

  final List<Transaction> _tutorialTransactions = [];
  late List<Wallet> _tutorialWallets;

  @override
  void initState() {
    super.initState();
    _initTutorialWallets();
  }

  void _initTutorialWallets() {
    final account = SessionService.activeAccount;
    final realWallets = account != null ? DatabaseService.getWallets(account.key as int) : <Wallet>[];
    
    if (realWallets.isNotEmpty) {
      _tutorialWallets = realWallets.map((w) => Wallet(
        name: 'Demo ${w.name}',
        balance: w.balance,
        // If initial balance is too small for a 250 deduction, use 10,000
        type: w.type,
        accountKey: 999,
      )).toList();
      
      if (_tutorialWallets[0].balance < 250) {
        _tutorialWallets[0].balance = 10000.0;
      }
    } else {
      _tutorialWallets = [
        Wallet(
          name: 'Demo Wallet', 
          balance: 10000.0, 
          type: 'E-Wallet',
          accountKey: 999,
        )
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = SessionService.activeAccount;
    
    List<Transaction> transactions;
    List<Wallet> wallets;
    List<Budget> budgets = [];
    List<Goal> goals = [];
    List<Debt> debts = [];

    if (widget.isTutorialActive) {
      transactions = _tutorialTransactions;
      wallets = _tutorialWallets;
    } else {
      transactions = account != null
          ? DatabaseService.getTransactions(account.key as int)
          : <Transaction>[];
      wallets = account != null
          ? DatabaseService.getWallets(account.key as int)
          : <Wallet>[];
      if (account != null) {
        budgets = DatabaseService.getBudgets(account.key as int);
        goals = DatabaseService.getGoals(account.key as int);
        debts = DatabaseService.getDebts(account.key as int);
      }
    }

    final double totalBalance = wallets
        .where((w) => _isNetWorthMode || !w.isExcluded)
        .fold(0, (sum, wallet) => sum + wallet.balance);

    final insights = FinancialInsightsService.generateInsights(transactions, totalBalance);

    final now = DateTime.now();
    // 1. Budget Used %
    final thisMonthBudgets = budgets.where((b) => b.month == now.month && b.year == now.year).toList();
    double totalBudgetLimit = 0;
    double totalBudgetSpent = 0;
    for (var b in thisMonthBudgets) {
      totalBudgetLimit += b.amountLimit;
      final spent = transactions
          .where((e) =>
              (e.budgetKey == b.key ||
               (e.category == b.category && e.date.month == now.month && e.date.year == now.year)) &&
              e.type == TransactionType.expense)
          .fold(0.0, (s, e) => s + e.amount);
      totalBudgetSpent += spent;
    }
    final budgetUsedPct = totalBudgetLimit > 0 ? (totalBudgetSpent / totalBudgetLimit * 100).clamp(0.0, 100.0) : 0.0;
    // 2. Savings Progress %
    final totalGoalTarget = goals.fold(0.0, (s, g) => s + g.targetAmount);
    final totalGoalSaved = goals.fold(0.0, (s, g) => s + g.savedAmount);
    final savingsPct = totalGoalTarget > 0 ? (totalGoalSaved / totalGoalTarget * 100).clamp(0.0, 100.0) : 0.0;
    // 3. Active Debts
    final activeDebtAmount = debts.where((d) => !d.isOwedToMe).fold(0.0, (s, d) => s + (d.totalAmount - d.paidAmount).clamp(0.0, double.infinity));

    if (totalBalance != _prevBalance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _showGlow = true;
          _prevBalance = totalBalance;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _showGlow = false);
        });
      });
    }

    final gamification = GamificationService.generateProfile(
      transactions: transactions, 
      budgets: budgets, 
      goals: goals, 
      debts: debts
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, account?.name ?? 'User', gamification),
          const SizedBox(height: 16),
          FinancialHealthStrip(
            budgetUsedPct: budgetUsedPct,
            savingsPct: savingsPct,
            activeDebtAmount: activeDebtAmount,
          ),
          const SizedBox(height: 24),
          _buildBalanceCard(context, totalBalance, _isNetWorthMode, (val) {
            setState(() => _isNetWorthMode = val);
          }, key: widget.balanceKey),
          if (account != null) ...[
            const SizedBox(height: 16),
            QuickAddInput(
              key: widget.quickAddKey,
              accountKey: account.key as int,
              onSaved: widget.onRefresh,
              onTutorialSubmit: widget.isTutorialActive ? (t) async {
                setState(() {
                  _tutorialTransactions.insert(0, t);
                  if (_tutorialWallets.isNotEmpty) {
                    _tutorialWallets[0].balance -= t.amount;
                  }
                });
              } : null,
            ),
          ],
          const SizedBox(height: 32),
          if (insights.isNotEmpty) ...[
            _buildInsightsHeader(context),
            const SizedBox(height: 16),
            _buildInsightsList(context, insights),
            const SizedBox(height: 32),
          ],
          _buildRecentActivityHeader(context, key: widget.activityHeaderKey),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            _buildEmptyState(context)
          else
            _buildRecentTransactions(context, transactions),
        ],
      ),
    );
  }

  Widget _buildInsightsHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'INTELLIGENT INSIGHTS',
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
          ),
        ),
        Icon(
          Icons.auto_awesome_rounded,
          size: 14,
          color: theme.colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildInsightsList(BuildContext context, List<Insight> insights) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: insights.length > 3 ? 3 : insights.length, // Show top 3
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 280,
            child: InsightCard(insight: insights[index]),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, GamificationProfile profile) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Day,',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              name,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () => _showGamificationSheet(context, profile, theme),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    Text('${profile.streakDays} Days', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('Lvl ${profile.level}', style: TextStyle(fontWeight: FontWeight.w900, color: theme.primaryColor, fontSize: 16)),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showGamificationSheet(BuildContext context, GamificationProfile profile, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24).copyWith(top: 0),
              child: Column(
                children: [
                  CircleAvatar(
                     radius: 40,
                     backgroundColor: Colors.amber.withOpacity(0.2),
                     child: const Icon(Icons.emoji_events_rounded, size: 40, color: Colors.amber),
                  ),
                  const SizedBox(height: 16),
                  Text('Level ${profile.level} Saver', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  Text('${profile.xp} Total XP', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                       value: profile.progressToNextLevel,
                       minHeight: 12,
                       backgroundColor: theme.primaryColor.withOpacity(0.1),
                       valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                    )
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text('Level ${profile.level}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                       Text('${500 - (profile.xp % 500)} XP to Level ${profile.level + 1}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24).copyWith(top: 16),
                children: [
                  const Text('Active Streak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                     ),
                     child: Row(
                        children: [
                           const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 32),
                           const SizedBox(width: 16),
                           Expanded(
                             child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   Text('${profile.streakDays} Days Fire Streak!', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange, fontSize: 16)),
                                   Text('You have logged an activity or stayed within budget for ${profile.streakDays} consecutive days.', style: TextStyle(fontSize: 12, color: Colors.orange.withOpacity(0.8))),
                                ]
                             )
                           )
                        ]
                     )
                  ),
                  const SizedBox(height: 32),
                  const Text('Today\'s Quests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...profile.dailyQuests.map((quest) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: quest.isCompleted ? Colors.green.withOpacity(0.5) : theme.dividerColor, width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: quest.isCompleted ? Colors.green.withOpacity(0.2) : theme.primaryColor.withOpacity(0.1),
                          child: Icon(quest.isCompleted ? Icons.check_circle_rounded : Icons.star_rounded, color: quest.isCompleted ? Colors.green : theme.primaryColor),
                        ),
                        title: Row(
                           children: [
                              Expanded(child: Text(quest.title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color))),
                              Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                 decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                 ),
                                 child: Text('+${quest.xpReward} XP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 12))
                              )
                           ],
                        ),
                        subtitle: Text(quest.description, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                  const Text('Achievements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...profile.achievements.map((achievement) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: achievement.isUnlocked ? Colors.amber.withOpacity(0.5) : theme.dividerColor, width: 0.5),
                        boxShadow: [
                           if (achievement.isUnlocked)
                              BoxShadow(color: Colors.amber.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        children: [
                           CircleAvatar(
                              backgroundColor: achievement.isUnlocked ? Colors.amber.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                              radius: 24,
                              child: Text(achievement.icon, style: const TextStyle(fontSize: 24)),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                              child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                    Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                          Text(achievement.title, style: TextStyle(fontWeight: FontWeight.bold, color: achievement.isUnlocked ? theme.textTheme.bodyMedium?.color : Colors.grey)),
                                          if (achievement.isUnlocked)
                                            const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 16)
                                          else
                                            Text('${achievement.currentProgress.toStringAsFixed(0)} / ${achievement.targetProgress.toStringAsFixed(0)} ${achievement.unit}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                                       ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(achievement.description, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                       borderRadius: BorderRadius.circular(4),
                                       child: LinearProgressIndicator(
                                          value: achievement.progressPercentage,
                                          minHeight: 6,
                                          backgroundColor: theme.dividerColor.withOpacity(0.1),
                                          valueColor: AlwaysStoppedAnimation<Color>(achievement.isUnlocked ? Colors.amber : theme.primaryColor),
                                       ),
                                    )
                                 ],
                              )
                           )
                        ]
                      )
                    );
                  }),
                ],
              )
            )
          ]
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    double totalBalance,
    bool isNetWorth,
    ValueChanged<bool> onToggle, {
    Key? key,
  }) {
    final theme = Theme.of(context);
    final cardColor = theme.primaryColor;
    final contentColor = theme.colorScheme.onPrimary;

    return AnimatedScale(
      key: key,
      scale: _showGlow ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(_showGlow ? 0.3 : 0.1),
              blurRadius: _showGlow ? 40 : 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNetWorth ? 'TOTAL NET WORTH' : 'TOTAL BALANCE',
                      style: TextStyle(
                        color: contentColor.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isNetWorth
                          ? 'INCLUDES EXCLUDED WALLETS'
                          : 'SPENDABLE BALANCE ONLY',
                      style: TextStyle(
                        color: contentColor.withOpacity(0.3),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => onToggle(!isNetWorth),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: contentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: contentColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isNetWorth
                          ? Icons.account_balance_rounded
                          : Icons.payments_rounded,
                      color: contentColor.withOpacity(0.5),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AnimatedCountText(
              value: totalBalance,
              prefix: '₱',
              style: theme.textTheme.displayMedium?.copyWith(
                color: contentColor,
                fontSize: 42,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: contentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'LIVE UPDATES',
                style: TextStyle(
                  color: contentColor.withOpacity(0.4),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityHeader(BuildContext context, {Key? key}) {
    final theme = Theme.of(context);
    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'RECENT ACTIVITY',
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            shape: BoxShape.circle,
            border: Border.all(color: theme.dividerColor, width: 0.5),
          ),
          child: Icon(
            Icons.horizontal_rule_rounded,
            size: 14,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.blur_on_rounded, size: 48, color: theme.dividerColor),
            const SizedBox(height: 16),
            Text(
              'No activities recorded yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    List<Transaction> transactions,
  ) {
    final sortedTx = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final topTx = sortedTx.take(5).toList();

    final List<dynamic> items = [];
    DateTime? lastDate;
    for (final tx in topTx) {
      if (lastDate == null || !isSameDay(lastDate, tx.date)) {
        items.add(tx.date);
        lastDate = tx.date;
      }
      items.add(tx);
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is DateTime) {
          return buildDateHeader(context, item);
        }
        final tx = item as Transaction;
        
        final isFirstTx = topTx.isNotEmpty && tx == topTx.first;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SlideInListItem(
            index: index,
            child: TransactionCard(
              key: isFirstTx ? widget.sampleTransactionKey : null,
              tx: tx, 
              onRefresh: widget.onRefresh
            ),
          ),
        );
      },
    );
  }
}
