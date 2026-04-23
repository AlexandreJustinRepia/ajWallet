import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/debt.dart';
import '../models/wallet.dart';
import '../models/transaction_model.dart';
import '../widgets/calculator_input.dart';
import '../widgets/onboarding_overlay.dart';
import 'package:hive/hive.dart';

class AddDebtScreen extends StatefulWidget {
  final int accountKey;
  final bool isTutorialMode;
  const AddDebtScreen({super.key, required this.accountKey, this.isTutorialMode = false});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isOwedToMe = true;
  bool _affectWallet = true;
  DateTime? _dueDate;
  int? _selectedWalletKey;
  List<Wallet> _wallets = [];

  final GlobalKey _typeKey = GlobalKey();
  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _amountKey = GlobalKey();
  final GlobalKey _walletKey = GlobalKey();
  final GlobalKey _saveKey = GlobalKey();
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
    if (widget.isTutorialMode) {
      _personController.text = 'John Doe';
      _amountController.text = '500';
    }
    _checkTutorial();
  }

  void _checkTutorial() async {
    final box = await Hive.openBox('settings');
    final hasSeen = box.get('has_seen_debt_tutorial', defaultValue: false);
    if (!hasSeen) {
      if (mounted) setState(() => _showTutorial = true);
    }
  }

  void _markTutorialSeen() async {
    final box = await Hive.openBox('settings');
    await box.put('has_seen_debt_tutorial', true);
  }

  void _loadWallets() {
    if (widget.isTutorialMode) {
      final fakeOptions = [Wallet(name: 'Cash', balance: 5000, type: 'Cash', accountKey: widget.accountKey)];
      setState(() {
        _wallets = fakeOptions;
        _selectedWalletKey = null; // Fake wallets don't have hive keys.
      });
      return;
    }

    final wallets = DatabaseService.getWallets(widget.accountKey);
    setState(() {
      _wallets = wallets.where((w) => !w.isExcluded).toList();
      if (_wallets.isNotEmpty) {
        try {
          _selectedWalletKey = _wallets.firstWhere((w) => w.name.toLowerCase() == 'cash').key as int;
        } catch (_) {
          _selectedWalletKey = _wallets.first.key as int;
        }
      }
    });
  }

  void _saveDebt() async {
    if (_formKey.currentState!.validate()) {
      if (_affectWallet && _selectedWalletKey == null && !widget.isTutorialMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a wallet')),
        );
        return;
      }

      final amount = double.parse(_amountController.text);

      // 1. Create the Debt object.
      // If _affectWallet is true, totalAmount starts at 0 and the Transaction increments it.
      // If false, we set totalAmount directly to amount and skip the Transaction.
      final debt = Debt(
        personName: _personController.text.trim(),
        totalAmount: _affectWallet ? 0.0 : amount, 
        paidAmount: 0.0,
        accountKey: widget.accountKey,
        isOwedToMe: _isOwedToMe,
        dueDate: _dueDate,
        description: _descriptionController.text.trim(),
      );

      final debtKey = await DatabaseService.saveDebt(debt);

      if (_affectWallet) {
        // 2. Create the initial Transaction
        final transaction = Transaction(
          title: _descriptionController.text.isNotEmpty 
              ? '${_descriptionController.text.trim()} (${debt.personName})'
              : (_isOwedToMe ? 'Lent to ${debt.personName}' : 'Borrowed from ${debt.personName}'),
          amount: amount,
          date: DateTime.now(),
          category: _isOwedToMe ? 'Lend' : 'Borrow',
          description: 'Initial transaction for debt record',
          type: _isOwedToMe ? TransactionType.expense : TransactionType.income,
          accountKey: widget.accountKey,
          walletKey: _selectedWalletKey,
          debtKey: debtKey,
        );

        await DatabaseService.saveTransaction(transaction);
      }

      if (mounted) Navigator.pop(context, true);
    }
  }

  void _scrollTo(GlobalKey key) {
    final currentContext = key.currentContext;
    if (currentContext != null) {
      Scrollable.ensureVisible(
        currentContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: 0.5,
      );
    }
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnboardingOverlay(
      visible: widget.isTutorialMode || _showTutorial,
      steps: [
        OnboardingStep(
          targetKey: _typeKey,
          title: 'Transaction Type',
          description: 'Choose the type of transaction.',
          onStepEnter: () => _scrollTo(_typeKey),
        ),
        OnboardingStep(
          targetKey: _nameKey,
          title: 'Person Name',
          description: 'Enter who the transaction is with.',
          onStepEnter: () => _scrollTo(_nameKey),
        ),
        OnboardingStep(
          targetKey: _amountKey,
          title: 'Amount',
          description: 'Enter the amount.',
          onStepEnter: () => _scrollTo(_amountKey),
        ),
        OnboardingStep(
          targetKey: _walletKey,
          title: 'Wallet Selection',
          description: 'Select the wallet involved.',
          onStepEnter: () => _scrollTo(_walletKey),
        ),
        OnboardingStep(
          targetKey: _saveKey,
          title: 'Save Record',
          description: 'Save to record it.',
          onStepEnter: () => _scrollTo(_saveKey),
        ),
      ],
      onFinish: () {
        _markTutorialSeen();
        if (widget.isTutorialMode) {
          if (mounted) Navigator.pop(context);
        } else {
          setState(() => _showTutorial = false);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Add Debt/Loan'), 
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => setState(() => _showTutorial = true),
            ),
          ],
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                key: _typeKey,
                child: Row(
                  children: [
                    Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isOwedToMe = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _isOwedToMe ? theme.primaryColor : theme.cardColor,
                          border: Border.all(color: _isOwedToMe ? theme.primaryColor : theme.dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'I gave money',
                            style: TextStyle(
                              color: _isOwedToMe ? theme.scaffoldBackgroundColor : theme.textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isOwedToMe = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: !_isOwedToMe ? theme.colorScheme.error : theme.cardColor,
                          border: Border.all(color: !_isOwedToMe ? theme.colorScheme.error : theme.dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'I borrowed money',
                            style: TextStyle(
                              color: !_isOwedToMe ? theme.scaffoldBackgroundColor : theme.textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ),
              const SizedBox(height: 32),
              Text(_isOwedToMe ? 'Who owes you?' : 'Who do you owe?', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                key: _nameKey,
                controller: _personController,
                decoration: InputDecoration(
                  hintText: 'Person or Bank Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 24),
              Text('Agenda (Optional)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'e.g. House Rent, Grocery, etc.',
                  prefixIcon: const Icon(Icons.label_outline_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              CalculatorInputField(
                key: _amountKey,
                label: 'Total Amount',
                initialValue: double.tryParse(_amountController.text),
                onChanged: (val) => setState(() => _amountController.text = val.toStringAsFixed(2)),
                validator: (val) {
                  if (val == null || val == '0' || val.isEmpty) return 'Enter amount';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Include in Wallet Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Are you sure you want to include this amount in your wallet balance?', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                value: _affectWallet,
                activeThumbColor: theme.primaryColor,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _affectWallet = val),
              ),
              if (_affectWallet) ...[
                const SizedBox(height: 16),
                Text('Select Wallet', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  key: _walletKey,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedWalletKey,
                      isExpanded: true,
                      hint: const Text('Select Wallet'),
                      dropdownColor: theme.cardColor,
                      items: _wallets.map((wallet) {
                        return DropdownMenuItem<int>(
                          value: widget.isTutorialMode ? null : wallet.key as int,
                          child: Text(
                            '${wallet.name} (₱${wallet.balance.toStringAsFixed(2)})',
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedWalletKey = val),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text('Due Date (Optional)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 12),
                      Text(_dueDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_dueDate!)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  key: _saveKey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isOwedToMe ? theme.primaryColor : theme.colorScheme.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _saveDebt,
                  child: Text('Save Record', style: TextStyle(color: theme.scaffoldBackgroundColor, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
