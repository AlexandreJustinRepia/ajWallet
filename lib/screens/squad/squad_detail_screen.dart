import 'package:flutter/material.dart';
import '../../models/squad.dart';
import '../../services/database_service.dart';
import '../../services/squad_service.dart';
import '../../services/session_service.dart';
import '../../models/squad_member.dart';
import '../../models/squad_transaction.dart';
import 'add_squad_transaction_screen.dart';
import 'settle_up_screen.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/onboarding_overlay.dart';
import '../../models/wallet.dart';

class SquadDetailScreen extends StatefulWidget {
  final Squad squad;
  const SquadDetailScreen({super.key, required this.squad});

  @override
  State<SquadDetailScreen> createState() => _SquadDetailScreenState();
}

class _SquadDetailScreenState extends State<SquadDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey _summaryKey = GlobalKey(); // Button key
  final GlobalKey _summaryCaptureKey = GlobalKey(); // Capture key
  final GlobalKey _receiptCaptureKey = GlobalKey(); // Capture key
  final GlobalKey _helpKey = GlobalKey();
  final GlobalKey _settleKey = GlobalKey();
  final GlobalKey _splitKey = GlobalKey();
  final GlobalKey _activityTabKey = GlobalKey();
  
  bool _isSharingSummary = false;
  bool _isTutorialActive = false;
  SquadTransaction? _txToCapture; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final squadKey = widget.squad.key as int;
    final balances = SquadService.calculateBalances(squadKey);

    return Stack(
      children: [
        // GHOST SQUAD SUMMARY (Hidden but used for capture)
        Positioned(
          left: -10000,
          child: RepaintBoundary(
            key: _summaryCaptureKey,
            child: _SquadSummaryWidget(
              squad: widget.squad,
              balances: balances,
              members: DatabaseService.getSquadMembers(squadKey),
            ),
          ),
        ),

        // GHOST RECEIPT (Hidden but used for capture from anywhere)
        if (_txToCapture != null)
          Positioned(
            left: -10000,
            child: RepaintBoundary(
              key: _receiptCaptureKey,
              child: _InvoiceWidget(
                tx: _txToCapture!,
                members: DatabaseService.getSquadMembers(squadKey),
                payerName: DatabaseService.getSquadMembers(squadKey)
                    .firstWhere((m) => m.key == _txToCapture!.payerMemberKey, 
                    orElse: () => DatabaseService.getSquadMembers(squadKey).first).name,
                billRemaining: _calculateBillRemaining(_txToCapture!, DatabaseService.getSquadMembers(squadKey)),
              ),
            ),
          ),

        // MAIN APP UI
        OnboardingOverlay(
          visible: _isTutorialActive,
          onFinish: () => setState(() => _isTutorialActive = false),
          steps: [
            OnboardingStep(
              title: 'Welcome to Squad',
              description: 'Manage group expenses and share premium RootEXP picture receipts with ease.',
            ),
            OnboardingStep(
              targetKey: _helpKey,
              title: 'Help & Tutorials',
              description: 'Tap this icon anytime to replay this guide and discover new features.',
            ),
            OnboardingStep(
              targetKey: _summaryKey,
              title: 'Squad Status Report',
              description: 'Capture and share a high-contrast visual of the whole squad\'s financial standing.',
            ),
            OnboardingStep(
              targetKey: _splitKey,
              title: 'Quick Split',
              description: 'Add new group expenses and choose how to divide the cost among members.',
            ),
          ],
          child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 20),
                title: Text(
                  widget.squad.name,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  color: theme.scaffoldBackgroundColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 80),
                      Text(
                        'TOTAL SQUAD NET',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${balances.net >= 0 ? "+" : ""}₱${balances.net.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatChip(
                            label: 'Owed to you',
                            amount: balances.youAreOwed,
                            color: theme.colorScheme.tertiary,
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            label: 'You owe',
                            amount: balances.youOwe,
                            color: theme.colorScheme.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              actions: [
                if (_isSharingSummary)
                  const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                if (!_isSharingSummary)
                IconButton(
                  key: _helpKey,
                  icon: const Icon(Icons.help_outline_rounded),
                  onPressed: () => setState(() => _isTutorialActive = true),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editSquadName(),
                ),
                IconButton(
                  key: _summaryKey,
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _shareSquadSummaryImage(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: theme.colorScheme.error,
                  onPressed: () => _confirmDeleteSquad(),
                ),
              ],
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: theme.primaryColor,
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.5),
                  tabs: const [
                    Tab(text: 'ACTIVITY'),
                    Tab(text: 'BALANCES'),
                  ],
                ),
                theme.scaffoldBackgroundColor,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _ActivityTab(
              key: _activityTabKey,
              squad: widget.squad,
              onRefresh: _refresh,
              onShare: _shareActivityImage,
            ),
            _BalancesTab(squad: widget.squad, onRefresh: _refresh),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            key: _settleKey,
            heroTag: 'settle',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettleUpScreen(squad: widget.squad),
                ),
              );
              if (result == true) {
                _refresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settlement recorded successfully!'),
                    ),
                  );
                }
              }
            },
            label: const Text('Settle Up'),
            icon: const Icon(Icons.handshake_rounded),
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            key: _splitKey,
            heroTag: 'split',
            onPressed: () async {
              final accountKey = SessionService.activeAccount?.key as int?;
              if (accountKey == null) return;
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddSquadTransactionScreen(
                    squad: widget.squad,
                    accountKey: accountKey,
                  ),
                ),
              );
              if (result == true) _refresh();
            },
            label: const Text('Split Bill'),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    ),
  ),
  ],
);
  }

  void _confirmDeleteSquad() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Squad?'),
        content: const Text(
          'This will permanently remove this squad and all its splitting data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deleteSquad(widget.squad);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void _editSquadName() {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: widget.squad.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Squad Name', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter new squad name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.dividerColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final newName = controller.text.trim();
                widget.squad.name = newName;
                await DatabaseService.updateSquad(widget.squad);
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save', style: TextStyle(color: theme.scaffoldBackgroundColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _shareSquadSummaryImage() async {
    setState(() => _isSharingSummary = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Preparing Squad Summary...'), duration: Duration(seconds: 1)),
    );

    // Give it a frame to render
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final boundary = _summaryCaptureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw 'Could not find summary boundary';

      final ui.Image image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw 'Could not get byte data';

      final bytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Squad_Summary_${widget.squad.name.replaceAll(' ', '_')}.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Financial Status for ${widget.squad.name}',
      );
    } catch (e) {
      debugPrint('Error sharing squad summary: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to share summary: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSharingSummary = false);
    }
  }

  void _shareActivityImage(SquadTransaction tx) async {
    setState(() => _txToCapture = tx);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Preparing Receipt...'), duration: Duration(seconds: 1)),
    );

    // Give it two frames to ensure the ghost is built with the new TX
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      final boundary = _receiptCaptureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw 'Could not find receipt boundary';

      final ui.Image image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw 'Could not get byte data';

      final bytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Receipt_${tx.title.replaceAll(' ', '_')}.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Receipt for ${tx.title} - Squad Splitting',
      );
    } catch (e) {
      debugPrint('Error sharing receipt: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to share receipt: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _txToCapture = null);
      }
    }
  }

  Map<int, double> _calculateBillRemaining(SquadTransaction tx, List<SquadMember> members) {
    if (tx.isSettlement) return {}; 

    final allTxs = DatabaseService.getSquadTransactions(tx.squadKey);
    final relatedPayments = allTxs.where((t) => t.isSettlement && t.relatedBillKey == tx.key).toList();
    final bills = allTxs.where((t) => !t.isSettlement).toList()..sort((a, b) => a.date.compareTo(b.date));

    Map<int, double> remainingMap = {};

    for (var member in members) {
      final memberKey = member.key as int;
      if (!tx.memberSplits.containsKey(memberKey)) continue;

      double share = tx.memberSplits[memberKey]!;
      if (tx.splitType == SplitType.percentage) {
        share = (share / 100) * tx.amount;
      } else if (tx.splitType == SplitType.equal) {
        share = tx.amount / tx.memberSplits.length;
      }

      if (memberKey == tx.payerMemberKey) {
        remainingMap[memberKey] = 0.0;
        continue;
      }

      final explicit = relatedPayments
          .where((p) => p.payerMemberKey == memberKey)
          .map((p) => p.amount)
          .fold(0.0, (a, b) => a + b);

      double totalP = allTxs
          .where((t) => t.isSettlement && t.payerMemberKey == memberKey)
          .map((t) => t.amount)
          .fold(0.0, (a, b) => a + b);
      
      double prevS = 0;
      for (var b in bills) {
        if (b.key == tx.key) break;
        if (b.memberSplits.containsKey(memberKey)) {
          double s = b.memberSplits[memberKey]!;
          if (b.splitType == SplitType.percentage) {
            s = (s / 100) * b.amount;
          } else if (b.splitType == SplitType.equal) {
            s = b.amount / b.memberSplits.length;
          }
          prevS += s;
        }
      }

      final availC = (totalP - prevS - explicit).clamp(0.0, double.infinity);
      final attrA = availC.clamp(0.0, (share - explicit).clamp(0.0, double.infinity));
      
      remainingMap[memberKey] = (share - explicit - attrA).clamp(0.0, double.infinity);
    }

    return remainingMap;
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _StatChip({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: ₱${amount.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  final Squad squad;
  final VoidCallback onRefresh;
  final Function(SquadTransaction) onShare;

  const _ActivityTab({
    super.key,
    required this.squad,
    required this.onRefresh,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txs = DatabaseService.getSquadTransactions(squad.key as int);
    final members = DatabaseService.getSquadMembers(squad.key as int);

    if (txs.isEmpty) {
      return Center(
        child: Text('No transactions yet', style: TextStyle(color: theme.dividerColor)),
      );
    }

    // Only show bills (non-settlements) in the main activity tab
    final sortedTxs = txs.where((tx) => !tx.isSettlement).toList()..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sortedTxs.length,
      itemBuilder: (context, index) {
        final tx = sortedTxs[index];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor, width: 0.5),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              child: Icon(
                Icons.receipt_long_rounded,
                color: theme.primaryColor,
                size: 20,
              ),
            ),
            title: Text(
              tx.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat('MMMM dd, yyyy').format(tx.date),
              style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.share_outlined, size: 20, color: theme.primaryColor),
                  onPressed: () => onShare(tx),
                ),
                Text(
                  '₱${tx.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => _ActivityDetailSheet(
                  tx: tx, 
                  members: members, 
                  onRefresh: onRefresh,
                  onShare: onShare,
                ),
              );
            },
            onLongPress: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Transaction?'),
                  content: const Text('This will undo the balance effect.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                await DatabaseService.deleteSquadTransaction(tx);
                onRefresh();
              }
            },
          ),
        );
      },
    );
  }
}

class _BalancesTab extends StatelessWidget {
  final Squad squad;
  final VoidCallback onRefresh;

  const _BalancesTab({required this.squad, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final members = DatabaseService.getSquadMembers(squad.key as int);
    final balances = SquadService.calculateBalances(squad.key as int);

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final balance = balances.memberNetBalances[member.key as int] ?? 0.0;
        final isPositive = balance > 0;
        final isNegative = balance < 0;
        final txs = DatabaseService.getSquadTransactions(squad.key as int);
        final hasActivity = txs.any((t) => t.payerMemberKey == member.key || t.memberSplits.containsKey(member.key as int));

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => _MemberDetailSheet(
                member: member, 
                allTransactions: txs,
                netBalance: balance,
                onRefresh: onRefresh,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPositive 
                  ? theme.colorScheme.tertiary.withValues(alpha: 0.3)
                  : (isNegative ? theme.colorScheme.error.withValues(alpha: 0.3) : theme.dividerColor),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isPositive 
                    ? theme.colorScheme.tertiary.withValues(alpha: 0.1)
                    : (isNegative ? theme.colorScheme.error.withValues(alpha: 0.1) : theme.dividerColor.withValues(alpha: 0.1)),
                child: Text(
                  member.name[0].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPositive 
                        ? theme.colorScheme.tertiary
                        : (isNegative ? theme.colorScheme.error : theme.textTheme.bodyMedium?.color),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (member.isYou) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('YOU', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      isPositive 
                          ? 'gets back ₱${balance.toStringAsFixed(2)}'
                          : (isNegative ? 'owes ₱${balance.abs().toStringAsFixed(2)}' : (hasActivity ? 'all settled' : 'no activity yet')),
                      style: TextStyle(
                        fontSize: 12,
                        color: isPositive 
                            ? theme.colorScheme.tertiary
                            : (isNegative ? theme.colorScheme.error : theme.dividerColor),
                      ),
                    ),
                  ],
                ),
              ),
              if (isNegative)
                Icon(Icons.arrow_downward_rounded, color: theme.colorScheme.error, size: 16),
              if (isPositive)
                Icon(Icons.arrow_upward_rounded, color: theme.colorScheme.tertiary, size: 16),
            ],
          ),
        ),
      );
    },
    );
  }
}

class _MemberDetailSheet extends StatelessWidget {
  final SquadMember member;
  final List<SquadTransaction> allTransactions;
  final double netBalance;
  final VoidCallback onRefresh;
 
  const _MemberDetailSheet({
    required this.member,
    required this.allTransactions,
    required this.netBalance,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
    
    // Filter transactions where this member is involved
    final memberHistory = allTransactions.where((tx) {
      if (tx.isSettlement) {
        // Payer or Payee in settlement
        return tx.payerMemberKey == member.key || tx.memberSplits.containsKey(member.key as int);
      } else {
        // Participant or Payer in bill
        return tx.payerMemberKey == member.key || tx.memberSplits.containsKey(member.key as int);
      }
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final isPositive = netBalance > 0;
    final isNegative = netBalance < 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 24),

          // Member Header
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isPositive ? theme.colorScheme.tertiary.withValues(alpha: 0.1) : (isNegative ? theme.colorScheme.error.withValues(alpha: 0.1) : theme.dividerColor.withValues(alpha: 0.1)),
                child: Text(member.name[0].toUpperCase(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isPositive ? theme.colorScheme.tertiary : (isNegative ? theme.colorScheme.error : theme.textTheme.bodyMedium?.color))),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name + (member.isYou ? ' (YOU)' : ''), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(
                      isPositive 
                          ? 'GETS BACK ${format.format(netBalance)} TOTAL' 
                          : (isNegative ? 'OWES ${format.format(netBalance.abs())}' : (memberHistory.isEmpty ? 'NO ACTIVITY YET' : 'ALL SETTLED')),
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold,
                        color: isPositive ? theme.colorScheme.tertiary : (isNegative ? theme.colorScheme.error : theme.dividerColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          
          if (!member.isYou && netBalance != 0)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleSettleUp(context),
                icon: const Icon(Icons.handshake_rounded, size: 18),
                label: Text(netBalance < 0 ? 'RECORD PAYMENT RECEIVED' : 'RECORD SETTLEMENT PAYOUT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),

          const SizedBox(height: 32),
          Text(
            'PERSON SUMMARY',
            style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w900, fontSize: 10, color: theme.textTheme.labelLarge?.color?.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),

          if (memberHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No history found for this member.', style: TextStyle(color: theme.dividerColor))),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: memberHistory.length,
                itemBuilder: (context, index) {
                  final tx = memberHistory[index];
                  final isPayer = tx.payerMemberKey == member.key;
                  
                  double amountDisplay = 0;
                  String label = '';
                  IconData icon = Icons.receipt_long_rounded;

                  if (tx.isSettlement) {
                    icon = Icons.handshake_rounded;
                    label = tx.title;
                    // In settlement, either we paid (Negative for the audit trail of debt, but here we just show total flow)
                    // Actually, if we PAID, it's a CREDIT to our balance.
                    amountDisplay = tx.amount; 
                  } else {
                    // It's a bill
                    double share = tx.memberSplits[member.key as int] ?? 0;
                    if (tx.splitType == SplitType.percentage) {
                      share = (share / 100) * tx.amount;
                    } else if (tx.splitType == SplitType.equal) {
                      share = tx.amount / tx.memberSplits.length;
                    }
                    
                    label = tx.title;
                    amountDisplay = share;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: tx.isSettlement ? theme.colorScheme.secondary : theme.primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              Text(
                                DateFormat('MMM dd, yyyy').format(tx.date) + (isPayer && !tx.isSettlement ? ' • (PAID)' : ''),
                                style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              format.format(amountDisplay),
                              style: TextStyle(
                                fontSize: 14, 
                                fontWeight: FontWeight.w900,
                                color: tx.isSettlement ? theme.colorScheme.tertiary : theme.colorScheme.error,
                              ),
                            ),
                            Text(
                              tx.isSettlement ? 'PAYMENT' : 'SHARE',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: theme.dividerColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _handleSettleUp(BuildContext context) async {
    final theme = Theme.of(context);
    final squad = DatabaseService.getSquad(member.squadKey);
    final wallets = squad != null ? DatabaseService.getWallets(squad.accountKey) : <Wallet>[];
    int? selectedWalletKey;
    final amountController = TextEditingController(text: netBalance.abs().toStringAsFixed(0));

    bool isSaving = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(netBalance < 0 ? 'Member Settling Up' : 'Paying Member Back'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₱)', hintText: '0.00'),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('RECORD TO WALLET (OPTIONAL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: selectedWalletKey,
                decoration: InputDecoration(
                  hintText: 'Select Wallet',
                  fillColor: theme.dividerColor.withValues(alpha: 0.05),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: wallets.map((w) => DropdownMenuItem(
                  value: w.key as int,
                  child: Text(w.name),
                )).toList(),
                onChanged: (val) => setDialogState(() => selectedWalletKey = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                final amt = double.tryParse(amountController.text) ?? 0;
                if (amt <= 0) return;

                setDialogState(() => isSaving = true);
                
                try {
                  // Find "You" to be the other side of the settlement
                  final members = DatabaseService.getSquadMembers(member.squadKey);
                  final you = members.firstWhere((m) => m.isYou);

                  final tx = SquadTransaction(
                    title: netBalance < 0 ? 'Settle Up from ${member.name}' : 'Paid back ${member.name}',
                    amount: amt,
                    date: DateTime.now(),
                    squadKey: member.squadKey,
                    payerMemberKey: netBalance < 0 ? member.key as int : you.key as int,
                    splitType: SplitType.equal,
                    memberSplits: {netBalance < 0 ? you.key as int : member.key as int: 0},
                    isSettlement: true,
                    walletKey: selectedWalletKey,
                  );

                  await DatabaseService.saveSquadTransaction(tx);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settlement recorded!'),
                      ),
                    );
                    Navigator.pop(context, true);
                  }
                } catch (_) {
                  // Error handled silently or with fallback
                } finally {
                  if (context.mounted) setDialogState(() => isSaving = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isSaving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Text('Record', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      onRefresh();
    }
  }
}

class _SliverTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabDelegate(this.tabBar, this.backgroundColor);

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_SliverTabDelegate oldDelegate) => false;
}

class _ActivityDetailSheet extends StatefulWidget {
  final SquadTransaction tx;
  final List<SquadMember> members;
  final VoidCallback onRefresh;
  final Function(SquadTransaction) onShare;

  const _ActivityDetailSheet({
    required this.tx,
    required this.members,
    required this.onRefresh,
    required this.onShare,
  });

  @override
  State<_ActivityDetailSheet> createState() => _ActivityDetailSheetState();
}

class _ActivityDetailSheetState extends State<_ActivityDetailSheet> {
  late List<SquadTransaction> _allTxs;
  late List<SquadTransaction> _relatedPayments;
  bool _isSharing = false;

  void _loadData() {
    _allTxs = DatabaseService.getSquadTransactions(widget.tx.squadKey);
    _relatedPayments = _allTxs.where((t) => t.isSettlement && t.relatedBillKey == widget.tx.key).toList();
  }

  double _getPreviousShares(int memberKey) {
    // Sum of all shares dated BEFORE this bill
    final bills = _allTxs.where((t) => !t.isSettlement).toList()..sort((a, b) => a.date.compareTo(b.date));
    double total = 0;
    for (var b in bills) {
      if (b.key == widget.tx.key) break;
      if (b.memberSplits.containsKey(memberKey)) {
        double share = b.memberSplits[memberKey]!;
        if (b.splitType == SplitType.percentage) {
          share = (share / 100) * b.amount;
        } else if (b.splitType == SplitType.equal) {
          share = b.amount / b.memberSplits.length;
        }
        total += share;
      }
    }
    return total;
  }

  double _getExplicitPayments(int memberKey) {
    return _relatedPayments
        .where((p) => p.payerMemberKey == memberKey)
        .map((p) => p.amount)
        .fold(0.0, (a, b) => a + b);
  }

  double _getTotalPayments(int memberKey) {
    return _allTxs
        .where((t) => t.isSettlement && t.payerMemberKey == memberKey)
        .map((t) => t.amount)
        .fold(0.0, (a, b) => a + b);
  }

  void _markAsPaid(SquadMember member, double remainingAmount) async {
    if (remainingAmount < 1.0) return;

    int? selectedWalletKey;
    final squad = DatabaseService.getSquad(widget.tx.squadKey);
    final wallets = squad != null ? DatabaseService.getWallets(squad.accountKey) : <Wallet>[];
    final amountController = TextEditingController(text: remainingAmount.toStringAsFixed(0));
    final theme = Theme.of(context);

    bool isSaving = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Record payment from ${member.name} for this bill.'),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount (₱)', hintText: '0.00'),
              ),
              const SizedBox(height: 20),
              const Text('RECORD TO WALLET (OPTIONAL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: selectedWalletKey,
                decoration: InputDecoration(
                  hintText: 'Select Wallet',
                  fillColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: wallets.map((w) => DropdownMenuItem(
                  value: w.key as int,
                  child: Text(w.name),
                )).toList(),
                onChanged: (val) => setDialogState(() => selectedWalletKey = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                final amt = double.tryParse(amountController.text) ?? 0;
                if (amt <= 0) return;

                setDialogState(() => isSaving = true);

                try {
                  final payment = SquadTransaction(
                    title: 'Payment for ${widget.tx.title}',
                    amount: amt,
                    date: DateTime.now(),
                    squadKey: widget.tx.squadKey,
                    payerMemberKey: member.key as int,
                    splitType: SplitType.equal,
                    memberSplits: {widget.tx.payerMemberKey: 0}, // Move credit to the original bill payer
                    isSettlement: true,
                    relatedBillKey: widget.tx.key as int,
                    walletKey: selectedWalletKey,
                  );

                  await DatabaseService.saveSquadTransaction(payment);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment recorded!'),
                      ),
                    );
                    Navigator.pop(context, true);
                  }
                } catch (_) {
                  // Silent fail or fallback
                } finally {
                  if (context.mounted) setDialogState(() => isSaving = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isSaving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      if (mounted) {
        widget.onRefresh();
      }
    }
  }

  void _onShareRequested() async {
    setState(() => _isSharing = true);
    await widget.onShare(widget.tx);
    if (mounted) setState(() => _isSharing = false);
  }
  @override
  Widget build(BuildContext context) {
    _loadData(); // Re-load data whenever the sheet builds

    final theme = Theme.of(context);
    final payer = widget.members.firstWhere((m) => m.key == widget.tx.payerMemberKey);
    final format = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    // Pre-calculate if any payments (Auto or Linked) exist to show the section
    bool anyPayments = _relatedPayments.isNotEmpty;
    if (!anyPayments) {
      for (var entry in widget.tx.memberSplits.entries) {
        final memberKey = entry.key;
        if (memberKey == widget.tx.payerMemberKey) continue;

        double sh = entry.value;
        if (widget.tx.splitType == SplitType.percentage) {
          sh = (entry.value / 100) * widget.tx.amount;
        } else if (widget.tx.splitType == SplitType.equal) {
          sh = widget.tx.amount / widget.tx.memberSplits.length;
        }

        final explicit = _getExplicitPayments(memberKey);
        final totalP = _getTotalPayments(memberKey);
        final prevS = _getPreviousShares(memberKey);
        final availC = (totalP - prevS - explicit).clamp(0.0, double.infinity);
        final attrA = availC.clamp(0.0, (sh - explicit).clamp(0.0, double.infinity));

        if (attrA >= 1.0) {
          anyPayments = true;
          break;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt_long_rounded, color: theme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tx.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(widget.tx.date),
                      style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              if (!_isSharing)
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  color: theme.primaryColor,
                  onPressed: _onShareRequested,
                ),
            ],
          ),

          const SizedBox(height: 32),

          // Summary Cards
          Row(
            children: [
              _DetailCard(
                label: 'TOTAL AMOUNT',
                value: format.format(widget.tx.amount),
                icon: Icons.payments_rounded,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 12),
              _DetailCard(
                label: 'PAID BY',
                value: payer.name,
                icon: Icons.person_rounded,
                color: theme.colorScheme.tertiary,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Breakdown
          Text(
            'SPLIT BREAKDOWN (${widget.tx.splitType.name.toUpperCase()})',
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              color: theme.textTheme.labelLarge?.color?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...widget.tx.memberSplits.entries.map((entry) {
                    final memberKey = entry.key;
                    final member = widget.members.firstWhere((m) => m.key == memberKey);
                    
                    double sh = entry.value;
                    if (widget.tx.splitType == SplitType.percentage) {
                      sh = (entry.value / 100) * widget.tx.amount;
                    } else if (widget.tx.splitType == SplitType.equal) {
                      sh = widget.tx.amount / widget.tx.memberSplits.length;
                    }

                    final isPayer = memberKey == widget.tx.payerMemberKey;
                    final explicit = _getExplicitPayments(memberKey);
                    final totalP = _getTotalPayments(memberKey);
                    final prevS = _getPreviousShares(memberKey);
                    final availC = (totalP - prevS - explicit).clamp(0.0, double.infinity);
                    final attrA = availC.clamp(0.0, (sh - explicit).clamp(0.0, double.infinity));
                    final remaining = isPayer ? 0.0 : (sh - explicit - attrA).clamp(0.0, double.infinity);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor.withValues(alpha:0.05)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                            child: Text(member.name[0].toUpperCase(), style: TextStyle(fontSize: 10, color: theme.primaryColor, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(member.name + (member.isYou ? ' (You)' : ''), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                if (remaining >= 1.0)
                                  Text('Owes ${format.format(remaining)}', style: TextStyle(fontSize: 11, color: theme.colorScheme.error)),
                                if (remaining < 1.0)
                                  Text(isPayer ? 'Fully Settled (Payer)' : 'Fully Settled', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          if (remaining >= 1.0 && memberKey != widget.tx.payerMemberKey)
                            TextButton(
                              onPressed: () => _markAsPaid(member, remaining),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Settle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          if (remaining < 1.0 && memberKey != widget.tx.payerMemberKey)
                            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                        ],
                      ),
                    );
                  }),

                  // PAYMENT HISTORY SECTION
                  if (anyPayments) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text('SETTLEMENTS', style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w900, fontSize: 10, color: theme.textTheme.labelLarge?.color?.withValues(alpha: 0.6))),
                        const Spacer(),
                        const Icon(Icons.history_rounded, size: 14, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...widget.tx.memberSplits.entries.map((entry) {
                      final memberKey = entry.key;
                      if (memberKey == widget.tx.payerMemberKey) return const SizedBox.shrink();
                      
                      final member = widget.members.firstWhere((m) => m.key == memberKey);
                      double sh = entry.value;
                      if (widget.tx.splitType == SplitType.percentage) {
                        sh = (entry.value / 100) * widget.tx.amount;
                      } else if (widget.tx.splitType == SplitType.equal) {
                        sh = widget.tx.amount / widget.tx.memberSplits.length;
                      }

                      final explicit = _getExplicitPayments(memberKey);
                      final totalP = _getTotalPayments(memberKey);
                      final prevS = _getPreviousShares(memberKey);
                      final availC = (totalP - prevS - explicit).clamp(0.0, double.infinity);
                      final attrA = availC.clamp(0.0, (sh - explicit).clamp(0.0, double.infinity));

                      if (attrA < 1.0) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_fix_high_rounded, size: 12, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text('${member.name} settled ${attrA >= (sh - explicit - 1.0) ? 'share' : 'partially'} (Auto)', style: const TextStyle(fontSize: 12))),
                            Text(format.format(attrA), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                          ],
                        ),
                      );
                    }),
                    ..._relatedPayments.map((p) {
                      final payingMember = widget.members.firstWhere((m) => m.key == p.payerMemberKey);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text('${payingMember.name} settled share (Linked)', style: const TextStyle(fontSize: 12))),
                            Text(format.format(p.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _InvoiceWidget extends StatelessWidget {
  final SquadTransaction tx;
  final List<SquadMember> members;
  final String payerName;
  final Map<int, double>? billRemaining;

  const _InvoiceWidget({
    required this.tx,
    required this.members,
    required this.payerName,
    this.billRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
    
    // Receipt design colors (Clean, High Contrast)
    const bg = Colors.white; 
    final primary = theme.primaryColor;

    return Container(
      width: 400, // Fixed width for consistent high-quality export
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // High Contrast Branding Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RootEXP',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: primary,
                      ),
                    ),
                    Text(
                      'VERIFIED DIGITAL RECEIPT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.grey.shade800, // Much darker label
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified_rounded, size: 24, color: primary),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          Divider(color: Colors.black.withValues(alpha: 0.1), thickness: 2),
          const SizedBox(height: 32),

          // Bill Title (Pure Black)
          Text(
            tx.title.toUpperCase(),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('EEEE, MMMM dd, yyyy • hh:mm a').format(tx.date),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700), // Darker date
          ),
          
          const SizedBox(height: 48),

          // Core Info Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL SETTLEMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(format.format(tx.amount), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.black)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('PRIMARY PAYER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black, // High contrast payer box
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      payerName.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 56),

          // Member Breakdown (High Contrast)
          Row(
            children: [
              Text(
                'MEMBER SPLIT BREAKDOWN',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 1.5),
              ),
              const Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Divider(color: Colors.black12, thickness: 1))),
            ],
          ),
          const SizedBox(height: 24),
          
          ...tx.memberSplits.entries.map((entry) {
            final member = members.firstWhere((m) => m.key == entry.key);
            final isPrimaryPayer = member.key == tx.payerMemberKey;
            double share = entry.value;
            if (tx.splitType == SplitType.percentage) {
              share = (entry.value / 100) * tx.amount;
            } else if (tx.splitType == SplitType.equal) {
              share = tx.amount / tx.memberSplits.length;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isPrimaryPayer ? primary : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      member.name[0].toUpperCase(), 
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        color: isPrimaryPayer ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
                        ),
                        if (isPrimaryPayer)
                          Text('ORIGINAL PAYER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: primary, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  Text(
                    format.format(share),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 64),

          if (billRemaining != null && billRemaining!.isNotEmpty) ...[
            // BILL SETTLEMENT STATUS
            Row(
              children: [
                Text(
                  'SETTLEMENT STATUS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 1.5),
                ),
                const Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Divider(color: Colors.black12, thickness: 1))),
              ],
            ),
            const SizedBox(height: 20),
            ...tx.memberSplits.keys.map((memberKey) {
              final member = members.firstWhere((m) => m.key == memberKey);
              final remaining = billRemaining![memberKey] ?? 0;
              final isFullyPaid = remaining <= 0.01;
              final isPayer = memberKey == tx.payerMemberKey;
              
              final statusColor = (isFullyPaid || isPayer) ? Colors.green.shade700 : Colors.red.shade700;
              final statusText = isPayer ? 'PAID' : (isFullyPaid ? 'PAID' : '₱${remaining.toStringAsFixed(0)}');

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Text(
                      member.name + (member.isYou ? ' (You)' : ''),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 48),
          ],

          // Branding Footer (High Contrast)
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 1.5, width: 40, color: Colors.black.withValues(alpha: 0.05)),
                    const SizedBox(width: 16),
                    Text(
                      'RootEXP',
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.black.withValues(alpha: 0.2),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(height: 1.5, width: 40, color: Colors.black.withValues(alpha: 0.05)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'GENERATED BY RootEXP FINANCIAL • PREMIUM EDITION',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DetailCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SquadSummaryWidget extends StatelessWidget {
  final Squad squad;
  final SquadBalances balances;
  final List<SquadMember> members;

  const _SquadSummaryWidget({
    required this.squad,
    required this.balances,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
    const bg = Colors.white;
    final primary = theme.primaryColor;

    // Calculate total spending manually
    final transactions = DatabaseService.getSquadTransactions(squad.key as int);
    final totalSpending = transactions.where((tx) => !tx.isSettlement).map((tx) => tx.amount).fold(0.0, (a, b) => a + b);

    return Container(
      width: 450,
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(color: bg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Branding Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RootEXP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: primary,
                    ),
                  ),
                  Text(
                    'SQUAD STATUS',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              Icon(Icons.query_stats_rounded, size: 28, color: primary.withValues(alpha: 0.1)),
            ],
          ),
          const SizedBox(height: 32),

          // Squad Identity
          Text(
            squad.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -1),
          ),
          Text(
            DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade400),
          ),

          const SizedBox(height: 40),

          // High Level Stat Card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary.withValues(alpha: 0.08), primary.withValues(alpha: 0.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primary.withValues(alpha: 0.1), width: 2),
            ),
            child: Column(
              children: [
                Text(
                  'TOTAL SQUAD SPENDING',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: primary, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                Text(
                  format.format(totalSpending),
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.black),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Member Standings
          Row(
            children: [
              Text(
                'MEMBER STANDINGS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1.5),
              ),
              const Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Divider())),
            ],
          ),
          const SizedBox(height: 24),

          ...members.map((member) {
            final bal = balances.memberNetBalances[member.key] ?? 0;
            final isCredit = bal >= 0;
            final statusColor = isCredit ? Colors.green.shade600 : Colors.red.shade600;

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.08), width: 1.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    child: Text(
                      member.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name + (member.isYou ? ' (You)' : ''),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(isCredit ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded, size: 10, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              isCredit ? 'PAYER' : 'CURRENTLY OWES',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        format.format(bal.abs()),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        'GROSS',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: statusColor.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 48),

          // Branding Footer
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 1, width: 30, color: Colors.grey.shade200),
                    const SizedBox(width: 16),
                    Text(
                      'Generated by RootEXP',
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.grey.shade300,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(height: 1, width: 30, color: Colors.grey.shade200),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'SQUAD FINANCIAL ANALYTICS • VERSION 2.0',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey.shade200, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
