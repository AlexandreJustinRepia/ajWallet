import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/gamification_service.dart';
import '../../../widgets/gamification_counter.dart';
import '../../shop_view.dart';

class GamificationSheet extends StatefulWidget {
  final GamificationProfile profile;
  final ThemeData theme;
  final String growthEmoji;

  const GamificationSheet({
    super.key,
    required this.profile,
    required this.theme,
    required this.growthEmoji,
  });

  @override
  State<GamificationSheet> createState() => _GamificationSheetState();
}

class _GamificationSheetState extends State<GamificationSheet> {
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
                      onPressed: () => _showRewardsGuide(context, theme),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s Quests',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...profile.dailyQuests.map((quest) => _buildQuestCard(quest, theme)),
                const SizedBox(height: 32),
                const Text(
                  'Weekly & Monthly Challenges',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...profile.challenges.map((challenge) => _buildChallengeCard(challenge, theme)),
                const SizedBox(height: 24),
                _buildShopButton(context),
                const SizedBox(height: 32),
                const Text(
                  'Achievements',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...profile.achievements.map((achievement) => _buildAchievementCard(achievement, theme)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(DailyQuest quest, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: quest.isCompleted ? Colors.green.withValues(alpha: 0.5) : theme.dividerColor,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: quest.isCompleted ? Colors.green.withValues(alpha: 0.2) : theme.primaryColor.withValues(alpha: 0.1),
          child: Icon(
            quest.isCompleted ? Icons.check_circle_rounded : Icons.star_rounded,
            color: quest.isCompleted ? Colors.green : theme.primaryColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                quest.title,
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color),
              ),
            ),
            _buildRewardBadge(quest.xpReward, quest.coinReward),
          ],
        ),
        subtitle: Text(
          quest.description,
          style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  Widget _buildChallengeCard(MidTermChallenge challenge, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: challenge.isCompleted ? Colors.green.withValues(alpha: 0.5) : theme.dividerColor,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: challenge.isCompleted ? Colors.green.withValues(alpha: 0.2) : theme.primaryColor.withValues(alpha: 0.1),
          child: Icon(
            challenge.isCompleted ? Icons.check_circle_rounded : Icons.flag_rounded,
            color: challenge.isCompleted ? Colors.green : theme.primaryColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                challenge.title,
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color),
              ),
            ),
            _buildXPBadge(challenge.xpReward),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge.description,
              style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 4),
            Text(
              challenge.progress,
              style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardBadge(int xp, int coins) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text('+$xp XP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 10)),
          const SizedBox(width: 4),
          const Icon(Icons.monetization_on_rounded, size: 10, color: Colors.amber),
          Text(' $coins', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildXPBadge(int xp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('+$xp XP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 12)),
    );
  }

  Widget _buildShopButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.amber[600]!, Colors.orange[600]!]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopView()));
          },
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('OPEN REWARDS SHOP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isUnlocked ? Colors.amber.withValues(alpha: 0.5) : theme.dividerColor,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: achievement.isUnlocked ? Colors.amber.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
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
                    if (achievement.isUnlocked) const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text(achievement.description, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: achievement.progressPercentage,
                    minHeight: 6,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(achievement.isUnlocked ? Colors.amber : theme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRewardsGuide(BuildContext context, ThemeData theme) {
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
            Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Earnings Guide', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
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
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: Text(item.label, style: const TextStyle(fontSize: 14))),
              _buildGuideRewardBadge(item.xp, item.coins),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildGuideRewardBadge(String xp, String coins) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(xp, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Icon(Icons.monetization_on_rounded, size: 10, color: Colors.amber),
            const SizedBox(width: 4),
            Text(coins, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
          ]),
        ),
      ],
    );
  }
}

class _GuideItem {
  final String label;
  final String xp;
  final String coins;
  _GuideItem(this.label, this.xp, this.coins);
}
