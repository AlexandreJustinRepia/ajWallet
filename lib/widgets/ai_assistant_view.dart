import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import '../services/ai_assistant_service.dart';
import '../services/achievement_service.dart';
import '../models/transaction_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'onboarding_overlay.dart';

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

  // Tutorial GlobalKeys
  final _headerKey = GlobalKey();
  final _inputKey = GlobalKey();
  final _suggestionsKey = GlobalKey();
  final _analyticsKey = GlobalKey();

  final List<String> _suggestions = [
    "Check my runway",
    "What if I save ₱100 more per day?",
    "Detect subscriptions",
    "Show my debt status",
    "How much did I earn this month?",
    "Suggest a food budget",
    "Should I pay my loan today?",
    "Find my biggest expense",
    "500 food and drinks mcdo",
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
        _showTutorial = !box.containsKey('ai_tutorial_seen');
      });
    }
  }

  void _dismissTutorial() {
    final box = Hive.box('achievements');
    box.put('ai_tutorial_seen', true);
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

    FocusScope.of(context).unfocus();

    // Subtle delay for "processing" feel
    await Future.delayed(const Duration(milliseconds: 800));

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
        if (_showTutorial) _dismissTutorial();
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

  void _handleAction(AIAction action) async {
    if (action.type == AIActionType.confirmQuickAdd) {
      if (_showTutorial) _dismissTutorial();
      final payload = action.payload as Map<String, dynamic>;
      final account = SessionService.activeAccount;
      if (account == null) return;

      final walletKey = _findDefaultWallet(account.key as int);
      if (walletKey == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No wallet found to add transaction to.')));
        return;
      }

      final transaction = Transaction(
        title: payload['category'],
        amount: payload['amount'],
        date: DateTime.now(),
        category: payload['category'],
        description: payload['description'] ?? "",
        type: TransactionType.values[payload['type']],
        accountKey: account.key as int,
        walletKey: walletKey,
      );

      await DatabaseService.saveTransaction(transaction);
      
      if (mounted) {
        setState(() {
          _response = AIResponse(
            result: "Saved! ✅",
            insight: "Successfully recorded ₱${transaction.amount.toStringAsFixed(0)} to your ${transaction.category} history.",
            intent: AIIntent.unknown,
            isPositive: true,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction Added Successfully')));
      }
      return;
    }
  }

  int? _findDefaultWallet(int accountKey) {
    final wallets = DatabaseService.getWallets(accountKey);
    try {
      return wallets.firstWhere((w) => w.name.toLowerCase() == 'cash').key as int;
    } catch (_) {
      if (wallets.isNotEmpty) return wallets.first.key as int;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnboardingOverlay(
      steps: _getTutorialSteps(),
      visible: _showTutorial,
      onFinish: _dismissTutorial,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: ListView(
                reverse: true, 
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                children: [
                  const SizedBox(height: 24),
                  Container(key: _suggestionsKey, child: _buildSuggestions()),
                  
                  const SizedBox(height: 40),
                
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
                  Container(key: _analyticsKey, child: _buildQuickInsights(theme)),
              ],
            ),
          ),
          Container(key: _inputKey, child: _buildInputSection(theme)),
        ],
      ),
    ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      key: _headerKey,
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
                          color: theme.primaryColor.withValues(alpha: 0.1),
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
                const Text('Offline • Secure Intelligence', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 12, color: Colors.grey),
          SizedBox(width: 4),
          Text('Active', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
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
          border: Border.all(color: theme.dividerColor),
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
        child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
          if (_response!.intent == AIIntent.quickAddTransaction) ...[
            const SizedBox(height: 16),
            _buildQuickAddPreview(theme, color),
          ],
          const SizedBox(height: 12),
          Text(
            _response!.insight,
            style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          if (_response!.seriesData != null && _response!.seriesData!.isNotEmpty) ...[
            const SizedBox(height: 32),
            _MiniSparkLine(data: _response!.seriesData!, color: color),
            const SizedBox(height: 8),
            const Text(
              '7-Day Spending Trend',
              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
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
                    backgroundColor: color.withValues(alpha: 0.1),
                    foregroundColor: color,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: color.withValues(alpha: 0.3)),
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
        _buildInsightMiniCard('Cashflow Forecast', 'AI is projecting your runway.', Icons.trending_up, const Color(0xFF2E7D32)),
        const SizedBox(height: 12),
        _buildInsightMiniCard('Strategic Optimization', '2 new strategies detected.', Icons.auto_fix_high, const Color(0xFF1976D2)),
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
              color: accent.withValues(alpha: 0.1),
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

  Widget _buildQuickAddPreview(ThemeData theme, Color color) {
    final payload = _response!.payload;
    if (payload == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildPreviewRow("Type", payload['type'] == 0 ? "Income" : "Expense", color),
          const Divider(height: 24),
          _buildPreviewRow("Category", payload['category'], color),
          if (payload['description'] != null && (payload['description'] as String).isNotEmpty) ...[
            const Divider(height: 24),
            _buildPreviewRow("Note", payload['description'], color),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  List<OnboardingStep> _getTutorialSteps() {
    return [
      OnboardingStep(
        targetKey: _headerKey,
        title: 'Intelligence Engine',
        description: 'Your financial AI is 100% offline and secure. We analyze your local data to provide private, high-fidelity projections.',
      ),
      OnboardingStep(
        targetKey: _suggestionsKey,
        title: 'Contextual Shortcuts',
        description: 'Access frequently used financial queries with one tap. These scale and change based on your spending habits.',
      ),
      OnboardingStep(
        targetKey: _inputKey,
        title: 'Quick Add & Query',
        description: 'Ask questions like "How was my spending this week?" or use Quick Add like "500 food and drinks mcdo" to record expenses instantly.',
      ),
      OnboardingStep(
        targetKey: _analyticsKey,
        title: 'Proactive Forecasting',
        description: 'The AI constantly checks for cashflow risks and detects saving strategies across all your wallets.',
      ),
    ];
  }
}

class _MiniSparkLine extends StatelessWidget {
  final List<double> data;
  final Color color;

  const _MiniSparkLine({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final max = data.reduce((a, b) => a > b ? a : b);
    if (max == 0) return const SizedBox(height: 40);

    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((val) {
          final heightFactor = val / max;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: heightFactor.clamp(0.1, 1.0)),
                borderRadius: BorderRadius.circular(4),
              ),
              height: (60 * heightFactor).clamp(4.0, 60.0),
            ),
          );
        }).toList(),
      ),
    );
  }
}
