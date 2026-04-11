import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import '../services/ai_assistant_service.dart';
import '../services/achievement_service.dart';
import '../models/transaction_model.dart';
import '../models/wallet.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'onboarding_overlay.dart';

class AIAssistantView extends StatefulWidget {
  const AIAssistantView({super.key});

  @override
  State<AIAssistantView> createState() => _AIAssistantViewState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  final AIResponse? response;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.response,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class _AIAssistantViewState extends State<AIAssistantView> with SingleTickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;
  bool _showTutorial = false;

  // Tutorial GlobalKeys
  final _headerKey = GlobalKey();
  final _inputKey = GlobalKey();
  final _suggestionsKey = GlobalKey();
  final _analyticsKey = GlobalKey();

  final List<String> _suggestions = [
    "How much money do I have?",
    "Check my runway",
    "What if I save ₱100 more per day?",
    "Detect subscriptions",
    "Show my debt status",
    "How much did I earn this month?",
    "Find my biggest expense",
    "30 grab",
    "15 jeep",
    "25 tricycle",
    "50 taxi",
    "80 joyride",
    "25 water",
    "15 energen",
    "100 pet food",
    "500 food and drinks mcdo",
  ];

  @override
  void initState() {
    super.initState();
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
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleQuery(String query) async {
    if (query.trim().isEmpty) return;
    
    final userText = query.trim();
    _queryController.clear();

    setState(() {
      _messages.insert(0, ChatMessage(text: userText, isUser: true));
      _isProcessing = true;
    });

    _scrollToBottom();
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
    final wallets = DatabaseService.getWallets(accountKey);
    final totalBalance = wallets
        .where((w) => !w.isExcluded)
        .fold(0.0, (sum, w) => sum + w.balance);

    final response = AIAssistantService.processQuery(
      query: userText,
      transactions: transactions,
      balance: totalBalance,
      wallets: wallets,
      goals: goals,
      debts: debts,
      budgets: budgets,
    );

    if (mounted) {
      setState(() {
        _messages.insert(0, ChatMessage(text: response.insight, isUser: false, response: response));
        _isProcessing = false;
        if (_showTutorial) _dismissTutorial();
      });
      _scrollToBottom();
      
      // Check Achievements (Keep existing achievement logic)
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
          _messages.insert(0, ChatMessage(
            text: "Saved! ✅ Successfully recorded ₱${transaction.amount.toStringAsFixed(0)} to your ${transaction.category} history.",
            isUser: false,
          ));
        });
        _scrollToBottom();
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
              child: _messages.isEmpty && !_isProcessing
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length + (_isProcessing ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isProcessing && index == 0) {
                         return _buildProcessingIndicator();
                      }
                      final msgIndex = _isProcessing ? index - 1 : index;
                      final message = _messages[msgIndex];
                      return _buildMessageBubble(message, theme);
                    },
                  ),
            ),
            _buildInputSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, size: 48, color: theme.primaryColor),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'How can I help you today?',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ask about your spending, runway, or simulate financial scenarios.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 40),
        Container(key: _analyticsKey, child: _buildQuickInsights(theme)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildProcessingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(key: _suggestionsKey, child: _buildSuggestions()),
            const SizedBox(height: 12),
            Container(
              key: _inputKey,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _handleQuery(_queryController.text),
                      icon: Icon(Icons.send_rounded, color: theme.colorScheme.onPrimary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _buildSuggestionChip(_suggestions[index]),
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _handleQuery(label),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: theme.primaryColor, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(left: 64, bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } else {
      final response = message.response;
      if (response == null) {
        // Simple AI text message (e.g. "Saved!")
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(right: 64, bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        );
      }

      final emerald = const Color(0xFF2E7D32);
      final crimson = const Color(0xFFB71C1C);
      final cobalt = const Color(0xFF1976D2);
      
      Color accentColor = response.isPositive ? emerald : crimson;
      if (response.tone == AITone.strict) accentColor = crimson;
      if (response.tone == AITone.encouraging) accentColor = cobalt;

      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(right: 32, bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: accentColor.withValues(alpha: 0.15), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(6),
                     decoration: BoxDecoration(
                       color: accentColor.withValues(alpha: 0.1),
                       shape: BoxShape.circle,
                     ),
                     child: Icon(Icons.auto_awesome, size: 14, color: accentColor),
                   ),
                   const SizedBox(width: 8),
                   Flexible(
                     child: Text(
                       response.result,
                       style: theme.textTheme.titleMedium?.copyWith(
                         fontWeight: FontWeight.bold,
                         color: accentColor,
                       ),
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 12),
              if (response.intent == AIIntent.quickAddTransaction) ...[
                _buildQuickAddPreview(theme, accentColor, response),
                const SizedBox(height: 12),
              ],
              Text(
                response.insight,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (response.seriesData != null && response.seriesData!.isNotEmpty) ...[
                const SizedBox(height: 24),
                _MiniSparkLine(data: response.seriesData!, color: accentColor),
                const SizedBox(height: 8),
                const Text(
                  '7-Day Spending Trend',
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
              if (response.actions != null && response.actions!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: response.actions!.map((action) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleAction(action),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            action.label,
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      );
    }
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
          Icons.trending_up, 
          const Color(0xFF2E7D32),
          onTap: () => _handleQuery("Check my runway"),
        ),
        const SizedBox(height: 12),
        _buildInsightMiniCard(
          'Strategic Optimization', 
          '2 new strategies detected.', 
          Icons.auto_fix_high, 
          const Color(0xFF1976D2),
          onTap: () => _handleQuery("Show my financial status"),
        ),
      ],
    );
  }

  Widget _buildInsightMiniCard(String title, String subtitle, IconData icon, Color accent, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: theme.dividerColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddPreview(ThemeData theme, Color color, AIResponse response) {
    final payload = response.payload;
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
