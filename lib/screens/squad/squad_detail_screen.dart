import 'package:flutter/material.dart';
import '../../models/squad.dart';
import '../../services/database_service.dart';
import '../../services/squad_service.dart';
import '../../services/session_service.dart';
import '../../services/export_service.dart';
import 'package:printing/printing.dart';
import 'add_squad_transaction_screen.dart';
import 'settle_up_screen.dart';
import '../../models/squad_member.dart';
import '../../models/squad_transaction.dart';
import 'package:intl/intl.dart';

class SquadDetailScreen extends StatefulWidget {
  final Squad squad;
  const SquadDetailScreen({super.key, required this.squad});

  @override
  State<SquadDetailScreen> createState() => _SquadDetailScreenState();
}

class _SquadDetailScreenState extends State<SquadDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
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
                      const SizedBox(height: 40),
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
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _exportSquadPdf(),
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
              squad: widget.squad,
              onRefresh: _refresh,
              onShare: _shareActivityPdf,
            ),
            _BalancesTab(squad: widget.squad, onRefresh: _refresh),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'settle',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettleUpScreen(squad: widget.squad),
                ),
              );
              if (result == true) _refresh();
            },
            label: const Text('Settle Up'),
            icon: const Icon(Icons.handshake_rounded),
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
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

  void _exportSquadPdf() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Generating Squad PDF...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final squadKey = widget.squad.key as int;
      final members = DatabaseService.getSquadMembers(squadKey);
      final transactions = DatabaseService.getSquadTransactions(squadKey);
      final balances = SquadService.calculateBalances(squadKey);
      final accountName = SessionService.activeAccount?.name ?? 'Account';

      final pdfBytes = await ExportService.buildSquadPdf(
        widget.squad,
        members,
        transactions,
        balances,
        accountName,
      );

      final fileName = 'Squad_${widget.squad.name.replaceAll(' ', '_')}_Report';
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '$fileName.pdf',
      );
    } catch (e) {
      debugPrint('Error exporting squad PDF: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareActivityPdf(SquadTransaction tx) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Generating Receipt...'), duration: Duration(seconds: 1)),
    );

    try {
      final members = DatabaseService.getSquadMembers(widget.squad.key as int);
      final balances = SquadService.calculateBalances(widget.squad.key as int);
      final accountName = SessionService.activeAccount?.name ?? 'Account';

      final pdfBytes = await ExportService.buildSquadTransactionPdf(
        tx,
        widget.squad,
        members,
        balances,
        accountName,
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Receipt_${tx.title.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      debugPrint('Error sharing activity PDF: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to generate receipt: $e'), backgroundColor: Colors.red),
      );
    }
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
                builder: (context) => _ActivityDetailSheet(tx: tx, members: members, onRefresh: onRefresh),
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
                          : (isNegative ? 'owes ₱${balance.abs().toStringAsFixed(2)}' : 'all settled'),
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

  const _MemberDetailSheet({
    required this.member,
    required this.allTransactions,
    required this.netBalance,
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
                          : (isNegative ? 'OWES ${format.format(netBalance.abs())}' : 'ALL SETTLED'),
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

  const _ActivityDetailSheet({required this.tx, required this.members, required this.onRefresh});

  @override
  State<_ActivityDetailSheet> createState() => _ActivityDetailSheetState();
}

class _ActivityDetailSheetState extends State<_ActivityDetailSheet> {
  late List<SquadTransaction> _allTxs;
  late List<SquadTransaction> _relatedPayments;

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

  void _markAsPaid(SquadMember member, double share) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment?'),
        content: Text('Record ₱${share.toStringAsFixed(0)} payment from ${member.name} for this bill?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final payment = SquadTransaction(
        title: 'Payment for ${widget.tx.title}',
        amount: share,
        date: DateTime.now(),
        squadKey: widget.tx.squadKey,
        payerMemberKey: member.key as int,
        splitType: SplitType.equal,
        memberSplits: {widget.tx.payerMemberKey: 0}, // Move credit to the original bill payer
        isSettlement: true,
        relatedBillKey: widget.tx.key as int,
      );

      await DatabaseService.saveSquadTransaction(payment);
      widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: DatabaseService.squadTxListenable,
      builder: (context, box, _) {
        _loadData(); // Re-load data whenever the box changes

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

            if (attrA > 0.01) {
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
                    final member = widget.members.firstWhere((m) => m.key == entry.key);
                    
                    double share = entry.value;
                    String? subtitle;

                    if (widget.tx.splitType == SplitType.percentage) {
                      share = (entry.value / 100) * widget.tx.amount;
                      subtitle = '${entry.value.toStringAsFixed(0)}%';
                    } else if (widget.tx.splitType == SplitType.equal) {
                      share = widget.tx.amount / widget.tx.memberSplits.length;
                      subtitle = 'Equal share';
                    }

                    final isPayer = member.key == widget.tx.payerMemberKey;

                    // REFINED SMART ATTRIBUTION LOGIC (Avoid Duplicates)
                    final explicitPaid = _getExplicitPayments(member.key as int);
                    final totalGlobalPaid = _getTotalPayments(member.key as int);
                    final previousShares = _getPreviousShares(member.key as int);
                    
                    // Available credit after paying previous bills AND ignoring what's already explicitly linked to this one
                    final availableCredit = (totalGlobalPaid - previousShares - explicitPaid).clamp(0.0, double.infinity);
                    final autoAttrAmount = availableCredit.clamp(0.0, (share - explicitPaid).clamp(0.0, double.infinity));
                    
                    final totalSettledForBill = explicitPaid + autoAttrAmount;
                    final isFull = totalSettledForBill >= (share - 0.01);
                    final isPartial = totalSettledForBill > 0.01 && !isFull;
                    
                    final isSettled = isFull;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                            child: Text(
                              member.name[0].toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name + (member.isYou ? ' (You)' : ''),
                                  style: TextStyle(
                                    fontWeight: isPayer ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                                  if (isPartial)
                                    Text(
                                      '${format.format(totalSettledForBill)} / ${format.format(share)} paid',
                                      style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                                    )
                                  else if (subtitle != null)
                                    Text(subtitle, style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                                ],
                              ),
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                format.format(share),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                              if (!isPayer) ...[
                                const SizedBox(width: 8),
                                if (isSettled)
                                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
                                else
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.blue, size: 20),
                                    onPressed: () => _markAsPaid(member, share),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  if (anyPayments) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'PAYMENTS FOR THIS BILL',
                      style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w900, fontSize: 10, color: theme.colorScheme.tertiary),
                    ),
                    const SizedBox(height: 12),
                    ...widget.tx.memberSplits.entries.map((entry) {
                      final member = widget.members.firstWhere((m) => m.key == entry.key);
                      if (member.key == widget.tx.payerMemberKey) return const SizedBox();

                      // Recalculate logic for the attribution list (FIFO)
                      double sh = entry.value;
                      if (widget.tx.splitType == SplitType.percentage) {
                        sh = (entry.value / 100) * widget.tx.amount;
                      } else if (widget.tx.splitType == SplitType.equal) {
                        sh = widget.tx.amount / widget.tx.memberSplits.length;
                      }

                      final explicit = _getExplicitPayments(member.key as int);
                      final totalP = _getTotalPayments(member.key as int);
                      final prevS = _getPreviousShares(member.key as int);
                      
                      final availC = (totalP - prevS - explicit).clamp(0.0, double.infinity);
                      final attrA = availC.clamp(0.0, (sh - explicit).clamp(0.0, double.infinity));

                      if (attrA <= 0.01) return const SizedBox();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text('${member.name} settled ${attrA >= (sh - explicit - 0.01) ? 'share' : 'partially'} (Auto)', style: const TextStyle(fontSize: 12))),
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
      },
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
