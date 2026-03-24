import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import '../services/ai_assistant_service.dart';
import '../services/achievement_service.dart';

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

  final List<String> _suggestions = [
    "How much did I earn this month?",
    "Show my debt status",
    "How is my savings goal going?",
    "Give me financial advice",
    "What is my savings rate?",
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
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

    // Suble delay for "processing" feel
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
      });
      _animationController.forward(from: 0);

      // Check Achievements
      final newAchievements = AchievementService.checkStreaks(transactions, budgets);
      if (newAchievements.isNotEmpty) {
        for (var ach in newAchievements) {
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
    switch (action.type) {
      case AIActionType.createGoal:
        // Navigator.push(context, MaterialPageRoute(builder: (context) => const GoalFormScreen()));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action: ${action.label} (Not implemented yet - would open Goal Form)')));
        break;
      case AIActionType.setLimit:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action: ${action.label} (Not implemented yet - would open Budget Form)')));
        break;
      case AIActionType.viewTransactions:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action: ${action.label} (Filtering results...)')));
        break;
      case AIActionType.manageSubscription:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action: ${action.label}')));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildHeader(theme),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputSection(theme),
                const SizedBox(height: 24),
                _buildSuggestions(),
                const SizedBox(height: 40),
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey))
                else if (_response != null)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildResponseArea(theme),
                  )
                else
                  _buildQuickInsights(theme),
              ],
            ),
          ),
        ),
      ],
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
                      'AI Assistant',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Financial Intelligence Engine',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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

  Widget _buildResponseArea(ThemeData theme) {
    final emerald = const Color(0xFF2E7D32);
    final crimson = const Color(0xFFB71C1C);
    final cobalt = const Color(0xFF1976D2);
    
    Color color = _response!.isPositive ? emerald : crimson;
    if (_response!.tone == AITone.strict) color = crimson;
    if (_response!.tone == AITone.encouraging) color = cobalt;

    final result = _response!.result;

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
                'Data verified from local ledger',
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          'Weekly Pace',
          'Spending is slightly optimized.',
          Icons.trending_down_rounded,
          const Color(0xFF2E7D32),
        ),
        const SizedBox(height: 12),
        _buildInsightMiniCard(
          'Portfolio Balance',
          'All accounts are currently in sync.',
          Icons.sync_rounded,
          Colors.grey,
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
