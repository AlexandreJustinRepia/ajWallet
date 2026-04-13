import 'dart:async';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import '../models/wallet.dart';
import '../widgets/animated_count_text.dart';
import '../widgets/slide_in_list_item.dart';
import '../widgets/quick_add_input.dart';
import '../widgets/transaction_card.dart';
import '../widgets/gamification_counter.dart';
import '../services/financial_insights_service.dart';
import '../services/gamification_service.dart';
import '../models/transaction_model.dart';
import 'insight_card.dart';
import 'dashboard_helpers.dart';
import 'shop_view.dart';

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
    final realWallets = account != null
        ? DatabaseService.getWallets(account.key as int)
        : <Wallet>[];

    if (realWallets.isNotEmpty) {
      _tutorialWallets = realWallets
          .map(
            (w) => Wallet(
              name: 'Demo ${w.name}',
              balance: w.balance,
              // If initial balance is too small for a 250 deduction, use 10,000
              type: w.type,
              accountKey: 999,
            ),
          )
          .toList();

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
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = SessionService.activeAccount;

    List<Transaction> transactions;
    List<Wallet> wallets;

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
    }

    final double totalBalance = wallets
        .where((w) => _isNetWorthMode || !w.isExcluded)
        .fold(0, (sum, wallet) => sum + wallet.balance);

    final insights = FinancialInsightsService.generateInsights(
      transactions,
      totalBalance,
    );

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

    final gamification = GamificationService.generateGlobalProfile();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, account?.name ?? 'User', gamification),
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
              onTutorialSubmit: widget.isTutorialActive
                  ? (t) async {
                      setState(() {
                        _tutorialTransactions.insert(0, t);
                        if (_tutorialWallets.isNotEmpty) {
                          _tutorialWallets[0].balance -= t.amount;
                        }
                      });
                    }
                  : null,
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
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
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
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 280,
            child: InsightCard(insight: insights[index]),
          );
        },
      ),
    );
  }

  String _getGrowthEmoji(int days) {
    if (days >= 7) return '🌳';
    if (days >= 4) return '🌿';
    return '🌱';
  }

  Widget _buildHeader(
    BuildContext context,
    String name,
    GamificationProfile profile,
  ) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Day,',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.5,
                  ),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _GamingBadge(
          profile: profile,
          onTap: () => _showGamificationSheet(context, profile, theme),
        ),
      ],
    );
  }

  void _showGamificationSheet(
    BuildContext context,
    GamificationProfile profile,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GamificationSheet(
        profile: profile,
        theme: theme,
        growthEmoji: _getGrowthEmoji(profile.streakDays),
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
              color: cardColor.withValues(alpha: _showGlow ? 0.3 : 0.1),
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
                        color: contentColor.withValues(alpha: 0.5),
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
                        color: contentColor.withValues(alpha: 0.3),
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
                      color: contentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: contentColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isNetWorth
                          ? Icons.account_balance_rounded
                          : Icons.payments_rounded,
                      color: contentColor.withValues(alpha: 0.5),
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
                color: contentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'LIVE UPDATES',
                style: TextStyle(
                  color: contentColor.withValues(alpha: 0.4),
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
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
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
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
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
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.4,
                ),
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
              onRefresh: widget.onRefresh,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gamification bottom sheet with live daily-quest countdown
// ─────────────────────────────────────────────────────────────────────────────

class _GamificationSheet extends StatefulWidget {
  final GamificationProfile profile;
  final ThemeData theme;
  final String growthEmoji;

  const _GamificationSheet({
    required this.profile,
    required this.theme,
    required this.growthEmoji,
  });

  @override
  State<_GamificationSheet> createState() => _GamificationSheetState();
}

class _GamificationSheetState extends State<_GamificationSheet> {
  late Duration _timeUntilReset;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _timeUntilReset = _calcTimeUntilMidnight();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _timeUntilReset = _calcTimeUntilMidnight());
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Duration _calcTimeUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _showRewardsGuide() {
    final theme = widget.theme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Earnings Guide',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildGuideSection('Base Rewards', [
                    _GuideItem('Log Transaction', '+10 XP', '+2 Coins'),
                    _GuideItem('Set a Budget', '+50 XP', '-'),
                    _GuideItem('Goal Completed', '+100 XP', '+50 Coins'),
                    _GuideItem('Debt Paid Off', '+50 XP', '+25 Coins'),
                    _GuideItem('Active Day', '+20 XP', '+5 Coins'),
                    _GuideItem('7-Day Streak', '-', '+50 Coins'),
                  ]),
                  const SizedBox(height: 24),
                  _buildGuideSection('Daily Quests', [
                    _GuideItem('Daily Tracker', '+20 XP', '+5 Coins'),
                    _GuideItem('Future Planner', '+10 XP', '+2 Coins'),
                    _GuideItem('Wealth Builder', '+35 XP', '+10 Coins'),
                  ]),
                  const SizedBox(height: 24),
                  _buildGuideSection('Challenges', [
                    _GuideItem('Weekly Saver', '+60 XP', '+30 Coins'),
                    _GuideItem('No-Spend Weekend', '+40 XP', '+20 Coins'),
                    _GuideItem('Budget Master', '+70 XP', '+50 Coins'),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideSection(String title, List<_GuideItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(item.label, style: const TextStyle(fontSize: 14)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.xp,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        size: 10,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.coins,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final theme = widget.theme;
    final growthColor = Colors.green[600]!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24).copyWith(top: 0),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.amber.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 40,
                        color: Colors.amber,
                      ),
                    ),
                    IconButton(
                      onPressed: _showRewardsGuide,
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.help_outline_rounded,
                          size: 16,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GamificationCounter(
                  value: profile.level,
                  prefix: 'Level ',
                  unit: ' Saver',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GamificationCounter(
                      value: profile.xp,
                      unit: ' Total XP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '•',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GamificationCounter(
                      value: profile.coins,
                      unit: ' Coins',
                      icon: Icons.monetization_on_rounded,
                      color: Colors.amber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: profile.progressToNextLevel,
                    minHeight: 12,
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level ${profile.level}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${500 - (profile.xp % 500)} XP to Level ${profile.level + 1}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
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
                // ── Growth Chain ──────────────────────────────────────────
                const Text(
                  'Active Growth Chain',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: growthColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: growthColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.growthEmoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${profile.streakDays} Days Growth Chain!',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: growthColor,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'You have logged an activity or stayed within budget for ${profile.streakDays} consecutive days.',
                              style: TextStyle(
                                fontSize: 12,
                                color: growthColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Daily Quests with countdown ───────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s Quests',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 12,
                            color: theme.primaryColor.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Resets in ${_formatDuration(_timeUntilReset)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor.withValues(alpha: 0.8),
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...profile.dailyQuests.map((quest) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: quest.isCompleted
                            ? Colors.green.withValues(alpha: 0.5)
                            : theme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: quest.isCompleted
                            ? Colors.green.withValues(alpha: 0.2)
                            : theme.primaryColor.withValues(alpha: 0.1),
                        child: Icon(
                          quest.isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.star_rounded,
                          color: quest.isCompleted
                              ? Colors.green
                              : theme.primaryColor,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              quest.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '+${quest.xpReward} XP',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.monetization_on_rounded,
                                  size: 10,
                                  color: Colors.amber,
                                ),
                                Text(
                                  ' ${quest.coinReward}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        quest.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 32),

                const Text(
                  'Weekly & Monthly Challenges',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...profile.challenges.map((challenge) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: challenge.isCompleted
                            ? Colors.green.withValues(alpha: 0.5)
                            : theme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: challenge.isCompleted
                            ? Colors.green.withValues(alpha: 0.2)
                            : theme.primaryColor.withValues(alpha: 0.1),
                        child: Icon(
                          challenge.isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.flag_rounded,
                          color: challenge.isCompleted
                              ? Colors.green
                              : theme.primaryColor,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              challenge.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${challenge.xpReward} XP',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            challenge.progress,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // ── Shop Button ───────────────────────────────────────────
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber[600]!, Colors.orange[600]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ShopView(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.store_rounded, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'OPEN REWARDS SHOP',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Achievements ──────────────────────────────────────────
                const Text(
                  'Achievements',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...profile.achievements.map((achievement) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: achievement.isUnlocked
                            ? Colors.amber.withValues(alpha: 0.5)
                            : theme.dividerColor,
                        width: 0.5,
                      ),
                      boxShadow: [
                        if (achievement.isUnlocked)
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: achievement.isUnlocked
                              ? Colors.amber.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.1),
                          radius: 24,
                          child: Text(
                            achievement.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    achievement.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: achievement.isUnlocked
                                          ? theme.textTheme.bodyMedium?.color
                                          : Colors.grey,
                                    ),
                                  ),
                                  if (achievement.isUnlocked)
                                    const Icon(
                                      Icons.workspace_premium_rounded,
                                      color: Colors.amber,
                                      size: 16,
                                    )
                                  else
                                    Text(
                                      '${achievement.currentProgress.toStringAsFixed(0)} / ${achievement.targetProgress.toStringAsFixed(0)} ${achievement.unit}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                achievement.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: achievement.progressPercentage,
                                  minHeight: 6,
                                  backgroundColor: theme.dividerColor
                                      .withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    achievement.isUnlocked
                                        ? Colors.amber
                                        : theme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideItem {
  final String label;
  final String xp;
  final String coins;
  _GuideItem(this.label, this.xp, this.coins);
}

class _GamingBadge extends StatefulWidget {
  final GamificationProfile profile;
  final VoidCallback onTap;

  const _GamingBadge({required this.profile, required this.onTap});

  @override
  State<_GamingBadge> createState() => _GamingBadgeState();
}

class _GamingBadgeState extends State<_GamingBadge> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final profile = widget.profile;
    
    // Theme-derived colors
    final primaryColor = colorScheme.primary;
    final onPrimaryColor = colorScheme.onPrimary;
    final secondaryColor = colorScheme.secondary;
    final growthColor = colorScheme.tertiary; // Success color in this theme system
    final surfaceColor = colorScheme.surface;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                primaryColor.withValues(alpha: isDark ? 0.05 : 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : primaryColor.withValues(alpha: 0.05),
                blurRadius: 8,
                spreadRadius: -2,
              ),
              if (_isPressed)
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: profile.progressToNextLevel),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 3,
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${profile.level}',
                          style: TextStyle(
                            color: onPrimaryColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'LVL ',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                        ),
                      ),
                      Text(
                        '${profile.level}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.shield_rounded, size: 10, color: secondaryColor.withValues(alpha: 0.6)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      GamificationCounter(
                        value: profile.coins,
                        color: Colors.amber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.amber,
                        ),
                        icon: Icons.monetization_on_rounded,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${profile.streakDays}d',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: growthColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
