import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../services/database_service.dart';
import '../models/goal.dart';
import '../models/transaction_model.dart';
import '../models/wallet.dart';
import '../widgets/calculator_input.dart';

class FundGoalScreen extends StatefulWidget {
  final int accountKey;
  final Goal goal;
  final bool isWithdrawing;

  const FundGoalScreen({
    super.key,
    required this.accountKey,
    required this.goal,
    this.isWithdrawing = false,
  });

  @override
  State<FundGoalScreen> createState() => _FundGoalScreenState();
}

class _FundGoalScreenState extends State<FundGoalScreen> {
  final _amountController = TextEditingController();
  int? _selectedWalletKey;
  List<Wallet> _wallets = [];
  late ConfettiController _confettiController;
  bool _isPlayingConfetti = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _wallets = DatabaseService.getWallets(widget.accountKey).where((w) => !w.isExcluded).toList();
    if (_wallets.isNotEmpty) {
      _selectedWalletKey = _wallets.first.key as int;
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _save() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    if (_selectedWalletKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a wallet')));
      return;
    }

    // Validation
    if (widget.isWithdrawing) {
      if (amount > widget.goal.savedAmount) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot withdraw more than the saved amount')));
        return;
      }
    } else {
      final wallet = _wallets.firstWhere((w) => w.key == _selectedWalletKey);
      if (amount > wallet.balance) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Insufficient balance in ${wallet.name}')));
        return;
      }
    }

    // Create the transaction
    final tx = Transaction(
      title: widget.isWithdrawing ? 'Goal Withdrawal' : 'Goal Contribution',
      amount: amount,
      date: DateTime.now(),
      category: 'Savings',
      description: widget.isWithdrawing ? 'Withdrew from ${widget.goal.name}' : 'Saved for ${widget.goal.name}',
      type: widget.isWithdrawing ? TransactionType.income : TransactionType.expense,
      accountKey: widget.accountKey,
      walletKey: _selectedWalletKey,
      goalKey: widget.goal.key as int,
    );

    await DatabaseService.saveTransaction(tx);

    if (mounted) {
      // Check if goal reached
      if (!widget.isWithdrawing && widget.goal.targetAmount > 0 && 
          (widget.goal.savedAmount + amount) >= widget.goal.targetAmount) {
        setState(() => _isPlayingConfetti = true);
        _confettiController.play();
        
        // Wait for confetti to finish before popping
        await Future.delayed(const Duration(seconds: 2));
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionText = widget.isWithdrawing ? 'Withdraw' : 'Save';

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text('$actionText: ${widget.goal.name}'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isWithdrawing 
                  ? 'Withdraw funds back to your wallet' 
                  : 'Move funds from your wallet to this goal',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            Text(widget.isWithdrawing ? 'Deposit to Wallet' : 'Source Wallet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedWalletKey,
                  isExpanded: true,
                  hint: const Text('Select Wallet'),
                  items: _wallets.map((wallet) {
                    return DropdownMenuItem<int>(
                      value: wallet.key as int,
                      child: Text('${wallet.name} (₱${wallet.balance.toStringAsFixed(2)})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedWalletKey = val),
                ),
              ),
            ),

            const SizedBox(height: 32),

            CalculatorInputField(
              label: 'Amount',
              initialValue: double.tryParse(_amountController.text),
              onChanged: (val) => setState(() => _amountController.text = val.toStringAsFixed(2)),
              validator: (_) => null,
            ),
            
            const SizedBox(height: 8),
            if (widget.isWithdrawing)
              Text(
                'Available to withdraw: ₱${widget.goal.savedAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isPlayingConfetti ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isWithdrawing ? const Color(0xFFF57C00) : const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isPlayingConfetti
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Confirm $actionText',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );

    return Stack(
      children: [
        scaffold,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Color(0xFF2E7D32), Color(0xFF00796B), Color(0xFFF57C00), Color(0xFFC62828)],
          ),
        ),
      ],
    );
  }
}
