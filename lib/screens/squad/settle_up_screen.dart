import 'package:flutter/material.dart';
import '../../models/squad.dart';
import '../../models/squad_member.dart';
import '../../models/squad_transaction.dart';
import '../../models/wallet.dart';
import '../../services/database_service.dart';

class SettleUpScreen extends StatefulWidget {
  final Squad squad;
  const SettleUpScreen({super.key, required this.squad});

  @override
  State<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends State<SettleUpScreen> {
  final _amountController = TextEditingController();
  late List<SquadMember> _members;
  int? _fromMemberKey; // Payer
  int? _toMemberKey; // Payee
  int? _selectedWalletKey;
  List<Wallet> _wallets = [];

  @override
  void initState() {
    super.initState();
    _members = DatabaseService.getSquadMembers(widget.squad.key as int);
    _wallets = DatabaseService.getWallets(widget.squad.accountKey);
    
    // Default: "You" is the Payer (From)
    final you = _members.cast<SquadMember?>().firstWhere((m) => m?.isYou ?? false, orElse: () => null);
    _fromMemberKey = you?.key as int? ?? _members.first.key as int?;
    
    // Default: someone else is the Payee (To)
    _toMemberKey = _members.firstWhere((m) => m.key != _fromMemberKey).key as int?;
  }

  void _saveSettlement() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || _fromMemberKey == null || _toMemberKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount and members')),
      );
      return;
    }

    final fromMember = _members.firstWhere((m) => m.key == _fromMemberKey);
    final toMember = _members.firstWhere((m) => m.key == _toMemberKey);

    final tx = SquadTransaction(
      title: '${fromMember.name} paid ${toMember.name}',
      amount: amount,
      date: DateTime.now(),
      squadKey: widget.squad.key as int,
      payerMemberKey: _fromMemberKey!,
      splitType: SplitType.equal,
      memberSplits: {_toMemberKey!: 0}, // Equal split among only the payee
      isSettlement: true,
      walletKey: _selectedWalletKey,
    );

    await DatabaseService.saveSquadTransaction(tx);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settle Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.handshake_rounded, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            
            // From Person
            _MemberSelector(
              label: 'WHO PAID?',
              members: _members,
              selectedKey: _fromMemberKey,
              onSelected: (key) => setState(() {
                _fromMemberKey = key;
                if (_fromMemberKey == _toMemberKey) {
                  _toMemberKey = _members.firstWhere((m) => m.key != key).key as int?;
                }
              }),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.arrow_downward_rounded, color: Colors.grey),
            ),
            
            // To Person
            _MemberSelector(
              label: 'WHO RECEIVED?',
              members: _members,
              selectedKey: _toMemberKey,
              onSelected: (key) => setState(() {
                _toMemberKey = key;
                if (_toMemberKey == _fromMemberKey) {
                  _fromMemberKey = _members.firstWhere((m) => m.key != key).key as int?;
                }
              }),
            ),
            
            const SizedBox(height: 32),
            
            // Amount
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                hintText: 'Amount ₱0.00',
                filled: true,
                fillColor: theme.cardColor,
                prefixIcon: const Icon(Icons.payments_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 24),

            // Wallet Selection
            Builder(
              builder: (context) {
                final fromMember = _members.firstWhere((m) => m.key == _fromMemberKey);
                final toMember = _members.firstWhere((m) => m.key == _toMemberKey);
                final showWallet = fromMember.isYou || toMember.isYou;

                if (!showWallet) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEDUCT FROM / ADD TO WALLET',
                      style: theme.textTheme.labelLarge?.copyWith(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor, width: 0.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedWalletKey,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          hint: const Text('Select wallet', style: TextStyle(fontSize: 14)),
                          items: _wallets
                              .map((w) => DropdownMenuItem(
                                    value: w.key as int,
                                    child: Text(w.name),
                                  ))
                              .toList()
                            ..add(const DropdownMenuItem(value: null, child: Text("Don't link to wallet"))),
                          onChanged: (val) => setState(() => _selectedWalletKey = val),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
          onPressed: _saveSettlement,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Record Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _MemberSelector extends StatelessWidget {
  final String label;
  final List<SquadMember> members;
  final int? selectedKey;
  final Function(int) onSelected;

  const _MemberSelector({
    required this.label,
    required this.members,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIdx = members.indexWhere((m) => m.key == selectedKey);
    final selectedMember = selectedIdx != -1 ? members[selectedIdx] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor, width: 0.5),
          ),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(selectedMember?.name[0] ?? '?'),
            ),
            title: Text(selectedMember?.name ?? 'Select Member', style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.swap_vert_rounded),
            onTap: () => _showPicker(context),
          ),
        ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: members.length,
        itemBuilder: (context, index) {
          final m = members[index];
          return ListTile(
            leading: CircleAvatar(child: Text(m.name[0])),
            title: Text(m.name),
            selected: m.key == selectedKey,
            onTap: () {
              final key = m.key as int?;
              if (key != null) {
                onSelected(key);
              }
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
