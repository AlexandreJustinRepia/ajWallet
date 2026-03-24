import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import '../services/ai_assistant_service.dart';
import '../services/achievement_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AIAssistantView extends StatefulWidget {
  const AIAssistantView({super.key});

  @override
  State<AIAssistantView> createState() => _AIAssistantViewState();
}

class _AIAssistantViewState extends State<AIAssistantView> with SingleTickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  AIResponse? _response;
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showTutorial = false;

  final List<String> _suggestions = [
    "Check my runway",
    "What if I save ₱100 more per day?",
    "Detect subscriptions",
    "Show my debt status",
    "How much did I earn this month?",
    "Suggest a food budget",
    "Should I pay my loan today?",
    "Find my biggest expense",
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _checkTutorial();
  }

  void _checkTutorial() {
    final box = Hive.box('achievements');
    if (mounted) {
      setState(() {
        _showTutorial = !box.containsKey('tutorial_seen');
      });
    }
  }

  void _dismissTutorial() {
    final box = Hive.box('achievements');
    box.put('tutorial_seen', true);
    setState(() => _showTutorial = false);
    AchievementService.unlock('explorer');
  }

  @override
  void dispose() {
    _queryController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleQuery(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isProcessing = true;
      _response = null;
    });

    // Subtle delay for "processing" feel
    await Future.delayed(const Duration(milliseconds: 600));

    final account = SessionService.activeAccount;
    if (account == null) return;

    final accountKey = account.key as int;
    final transactions = DatabaseService.getTransactions(accountKey);
    final goals = DatabaseService.getGoals(accountKey);
    final debts = DatabaseService.getDebts(accountKey);
    final budgets = DatabaseService.getBudgets(accountKey);

    final response = AIAssistantService.processQuery(
      query: query,
      transactions: transactions,
      balance: account.budget,
      goals: goals,
      debts: debts,
      budgets: budgets,
    );

    if (mounted) {
      setState(() {
        _response = response;
        _isProcessing = false;
        if (_showTutorial) _dismissTutorial(); // Dismiss tutorial on first query
      });
      _animationController.forward(from: 0);

      // Check Achievements
      final newMilestones = AchievementService.checkStreaks(transactions, budgets);
      final debtMilestones = AchievementService.checkDebtCompletion(debts);
      final allNew = [...newMilestones, ...debtMilestones];

      if (allNew.isNotEmpty && mounted) {
        for (var ach in allNew) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text(ach.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UNLOCKED: ${ach.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(ach.description, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _handleAction(AIAction action) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action: ${action.label}')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: ListView(
              reverse: true, // Results appear on top of input
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                // Input section and suggestions logically at the bottom of the scroll
                const SizedBox(height: 24),
                _buildSuggestions(),
                
                if (_showTutorial) ...[
                  const SizedBox(height: 32),
                  _buildTutorialCard(theme),
                ],

                const SizedBox(height: 40),
                
                // Results and insights
                if (_response != null)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildResponseArea(theme),
                  )
                else if (_isProcessing)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)),
                  )
                else
                  _buildQuickInsights(theme),
              ],
            ),
          ),
          _buildInputSection(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AI Assistant',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                        InkWell(
                          onTap: () => setState(() => _showTutorial = true),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.help_outline, size: 14, color: theme.primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Help',
                                  style: TextStyle(fontSize: 10, color: theme.primaryColor, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
                const Text(
                  'Financial Intelligence Engine',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            _buildStatusBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 12, color: Colors.grey),
          SizedBox(width: 4),
          Text(
            'Offline • Secure',
            style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.dividerColor, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _queryController,
                onSubmitted: _handleQuery,
                decoration: const InputDecoration(
                  hintText: 'Ask about your finances...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _handleQuery(_queryController.text),
              icon: Icon(Icons.auto_awesome, color: theme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestions.map((s) => _buildSuggestionChip(s)).toList(),
    );
  }

  Widget _buildSuggestionChip(String label) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        _queryController.text = label;
        _handleQuery(label);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildTutorialCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor.withOpacity(0.1), theme.primaryColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.primaryColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: theme.primaryColor),
              const SizedBox(width: 12),
              const Text('How to use AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _dismissTutorial,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTutorialStep(Icons.auto_graph, "Simulation", "Ask 'What if I save more?' to see future impacts."),
          _buildTutorialStep(Icons.account_balance_wallet, "Budgets", "Ask 'Suggest a budget' for personalized limits."),
          _buildTutorialStep(Icons.warning_amber_rounded, "Risk", "The AI warns you if debt payments threaten your cashflow."),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _dismissTutorial,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Get Started'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialStep(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseArea(ThemeData theme) {
    final emerald = const Color(0xFF2E7D32);
    final crimson = const Color(0xFFB71C1C);
    final cobalt = const Color(0xFF1976D2);
    
    Color color = _response!.isPositive ? emerald : crimson;
    if (_response!.tone == AITone.strict) color = crimson;
    if (_response!.tone == AITone.encouraging) color = cobalt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _response!.result,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _response!.insight,
            style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 14, color: color),
              const SizedBox(width: 8),
              Text(
                'Proprietary Intelligence Engine',
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (_response!.actions != null && _response!.actions!.isNotEmpty) ...[
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _response!.actions!.map((action) {
                return ElevatedButton(
                  onPressed: () => _handleAction(action),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withOpacity(0.1),
                    foregroundColor: color,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: color.withOpacity(0.3)),
                    ),
                  ),
                  child: Text(action.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickInsights(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ANALYTICS',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        _buildInsightMiniCard(
          'Cashflow Forecast',
          'AI is projecting your runway.',
          Icons.trending_up_rounded,
          const Color(0xFF2E7D32),
        ),
        const SizedBox(height: 12),
        _buildInsightMiniCard(
          'Strategic Optimization',
          '2 new strategies detected.',
          Icons.auto_fix_high,
          const Color(0xFF1976D2),
        ),
      ],
    );
  }

  Widget _buildInsightMiniCard(String title, String subtitle, IconData icon, Color accent) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
