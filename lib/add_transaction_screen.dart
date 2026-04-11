import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/database_service.dart';
import 'models/transaction_model.dart';
import '../models/wallet.dart';
import '../models/budget.dart';
import '../models/debt.dart';
import 'package:hive/hive.dart';
import 'widgets/calculator_input.dart';
import 'widgets/onboarding_overlay.dart';

class AddTransactionScreen extends StatefulWidget {
  final int accountKey;
  final Transaction? existingTransaction;
  
  // Initial planning keys
  final int? initialGoalKey;
  final int? initialBudgetKey;
  final int? initialDebtKey;
  final TransactionType? initialType;
  
  final bool isTutorialMode;

  const AddTransactionScreen({
    super.key, 
    required this.accountKey, 
    this.existingTransaction,
    this.initialGoalKey,
    this.initialBudgetKey,
    this.initialDebtKey,
    this.initialType,
    this.isTutorialMode = false,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _chargeController = TextEditingController();

  // Tutorial Keys
  final _typeKey = GlobalKey();
  final _walletKey = GlobalKey();
  final _amountKey = GlobalKey();
  final _categoryKey = GlobalKey();
  final _noteKey = GlobalKey();
  final _dateKey = GlobalKey();
  final _saveKey = GlobalKey();

  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  bool _isManualDate = false;
  String _selectedCategory = 'Food & Drinks';
  int? _selectedWalletKey;
  int? _selectedToWalletKey; // For Transfers

  List<Budget> _budgets = [];
  List<Transaction> _transactions = [];
  List<Debt> _debts = [];

  int? _selectedGoalKey;
  int? _selectedBudgetKey;
  int? _selectedDebtKey;

  // Tutorial State
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _budgets = DatabaseService.getBudgets(widget.accountKey);
    _transactions = DatabaseService.getTransactions(widget.accountKey);
    _debts = DatabaseService.getDebts(widget.accountKey);
    
    if (widget.isTutorialMode) {
      _showTutorial = true;
      _selectedType = TransactionType.expense;
      _amountController.text = '250.00';
      _selectedCategory = 'Food & Drinks';
      _descriptionController.text = 'Grocery Run';
      _selectedDate = DateTime.now();
      _isManualDate = true;
      _checkTutorial(); // still call this just in case, but rely on isTutorialMode mostly.
    } else {
      _checkTutorial();
    }
    
    if (widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      _selectedType = tx.type;
      _selectedDate = tx.date;
      _selectedCategory = tx.category;
      _selectedWalletKey = tx.walletKey;
      _selectedToWalletKey = tx.toWalletKey;
      _amountController.text = tx.amount.toStringAsFixed(2);
      _descriptionController.text = tx.description;
      if (tx.charge != null && tx.charge! > 0) {
        _chargeController.text = tx.charge!.toStringAsFixed(2);
      }
      _isManualDate = true;
      _selectedGoalKey = tx.goalKey;
      _selectedBudgetKey = tx.budgetKey;
      _selectedDebtKey = tx.debtKey;
    } else {
      final wallets = DatabaseService.getWallets(widget.accountKey);
      try {
        _selectedWalletKey = wallets.firstWhere((w) => w.name.toLowerCase() == 'cash').key as int;
      } catch (_) {
        if (wallets.isNotEmpty) _selectedWalletKey = wallets.first.key as int;
      }
      
      // Use initial values if provided
      if (widget.initialType != null) {
        _selectedType = widget.initialType!;
        _selectedCategory = _selectedType == TransactionType.income ? 'Salary' : 'Food & Drinks';
      }
      _selectedGoalKey = widget.initialGoalKey;
      _selectedBudgetKey = widget.initialBudgetKey;
      _selectedDebtKey = widget.initialDebtKey;
    }
  }

  void _checkTutorial() async {
    final box = await Hive.openBox('settings');
    final hasSeen = box.get('has_seen_tx_tutorial', defaultValue: false);
    if (!hasSeen && widget.existingTransaction == null) {
      setState(() => _showTutorial = true);
    }
  }

  void _dismissTutorial() async {
    final box = await Hive.openBox('settings');
    await box.put('has_seen_tx_tutorial', true);
    setState(() => _showTutorial = false);
  }

  final Map<String, IconData> _expenseCategories = {
    'Food & Drinks': Icons.fastfood,
    'Transportation': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Entertainment': Icons.movie,
    'Health': Icons.medical_services,
    'Utilities': Icons.home,
    'Education': Icons.school,
    'Pet Food': Icons.pets,
    'Others': Icons.more_horiz,
  };

  final Map<String, IconData> _incomeCategories = {
    'Salary': Icons.work,
    'Bonus': Icons.card_giftcard,
    'Dividend': Icons.pie_chart,
    'Gift': Icons.redeem,
    'Investment': Icons.trending_up,
    'Others': Icons.more_horiz,
  };

  Map<String, IconData> get _currentCategories => 
    _selectedType == TransactionType.income ? _incomeCategories : _expenseCategories;

  String? _getBudgetStatus(String category) {
    if (_selectedType != TransactionType.expense) return null;
    
    final now = DateTime.now();
    try {
      final budget = _budgets.firstWhere(
        (b) => b.category == category && b.month == now.month && b.year == now.year
      );
      
      final spent = _transactions
          .where((tx) => tx.type == TransactionType.expense && tx.category == category && tx.date.month == now.month && tx.date.year == now.year)
          .fold(0.0, (sum, tx) => sum + tx.amount);
          
      final remaining = budget.amountLimit - spent;
      return ' (₱${remaining.toStringAsFixed(0)} left)';
    } catch (_) {
      return null;
    }
  }

  List<String> _getSafetyAlerts() {
    List<String> alerts = [];
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final now = DateTime.now();

    // 1. Budget Exceed Warning
    if (_selectedType == TransactionType.expense && amount > 0) {
      try {
        final budget = _budgets.firstWhere(
            (b) => b.category == _selectedCategory && b.month == now.month && b.year == now.year);
        
        final spent = _transactions
            .where((tx) => tx.type == TransactionType.expense && tx.category == _selectedCategory && tx.date.month == now.month && tx.date.year == now.year)
            .fold(0.0, (sum, tx) => sum + tx.amount);
            
        final remaining = budget.amountLimit - spent;
        if (amount > remaining && remaining > 0) {
          alerts.add("⚠️ You're about to exceed your $_selectedCategory budget!");
        } else if (amount <= remaining && (remaining - amount) <= 500 && (remaining - amount) > 0) {
           alerts.add("💡 You'll only have ₱${(remaining - amount).toStringAsFixed(0)} left for your $_selectedCategory budget.");
        }
      } catch (_) {}
    }

    // 2. Debts Due Soon
    final dueSoonDebts = _debts.where((d) {
       if (d.dueDate == null || d.isOwedToMe || (d.totalAmount - d.paidAmount) <= 0) return false;
       final diff = d.dueDate!.difference(now).inDays;
       return diff >= 0 && diff <= 3;
    });

    for (var d in dueSoonDebts) {
       final diff = d.dueDate!.difference(now).inDays;
       final timeWords = diff == 0 ? "today" : diff == 1 ? "tomorrow" : "in $diff days";
       alerts.add("🔔 Debt due $timeWords: ${d.personName} (₱${(d.totalAmount - d.paidAmount).toStringAsFixed(0)})");
    }

    return alerts;
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedWalletKey == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a wallet')));
        return;
      }

      if (_selectedType == TransactionType.transfer &&
          _selectedToWalletKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a destination wallet')),
        );
        return;
      }

      if (_selectedType == TransactionType.expense || _selectedType == TransactionType.transfer) {
        final amount = double.parse(_amountController.text);
        final charge = double.tryParse(_chargeController.text) ?? 0.0;
        final totalNeeded = amount + charge;
        
        final wallets = DatabaseService.getWallets(widget.accountKey);
        final wallet = wallets.firstWhere((w) => w.key == _selectedWalletKey);
        
        double availableBalance = wallet.balance;
        if (widget.existingTransaction != null) {
          final tx = widget.existingTransaction!;
          if (tx.walletKey == _selectedWalletKey && (tx.type == TransactionType.expense || tx.type == TransactionType.transfer)) {
            availableBalance += tx.amount + (tx.charge ?? 0.0);
          } else if (tx.toWalletKey == _selectedWalletKey && tx.type == TransactionType.transfer) {
            availableBalance -= tx.amount;
          } else if (tx.walletKey == _selectedWalletKey && tx.type == TransactionType.income) {
            availableBalance -= tx.amount;
          }
        }
        
        if (availableBalance < totalNeeded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Insufficient balance in ${wallet.name}')),
          );
          return;
        }
      }

      // Mark tutorial as seen if saved
      if (_showTutorial) _dismissTutorial();

      if (widget.existingTransaction != null) {
        final existing = widget.existingTransaction!;
        // Capture old state for DatabaseService.updateTransaction
        final oldTx = Transaction(
          title: existing.title,
          amount: existing.amount,
          date: existing.date,
          category: existing.category,
          description: existing.description,
          type: existing.type,
          accountKey: existing.accountKey,
          walletKey: existing.walletKey,
          toWalletKey: existing.toWalletKey,
          charge: existing.charge,
          goalKey: existing.goalKey,
          budgetKey: existing.budgetKey,
          debtKey: existing.debtKey,
        );

        // Update existing object's fields
        existing.title = _selectedType == TransactionType.transfer
            ? 'Transfer'
            : _selectedCategory;
        existing.amount = double.parse(_amountController.text);
        existing.charge = double.tryParse(_chargeController.text);
        existing.date = _selectedDate;
        existing.category = _selectedType == TransactionType.transfer
            ? 'Transfer'
            : _selectedCategory;
        existing.description = _descriptionController.text;
        existing.type = _selectedType;
        existing.walletKey = _selectedWalletKey;
        existing.toWalletKey = _selectedToWalletKey;
        existing.goalKey = _selectedGoalKey;
        existing.budgetKey = _selectedBudgetKey;
        existing.debtKey = _selectedDebtKey;

        await DatabaseService.updateTransaction(oldTx, existing);
      } else {
        final transaction = Transaction(
          title: _selectedType == TransactionType.transfer
              ? 'Transfer'
              : _selectedCategory,
          amount: double.parse(_amountController.text),
          charge: double.tryParse(_chargeController.text),
          date: _selectedDate,
          category: _selectedType == TransactionType.transfer
              ? 'Transfer'
              : _selectedCategory,
          description: _descriptionController.text,
          type: _selectedType,
          accountKey: widget.accountKey,
          walletKey: _selectedWalletKey,
          toWalletKey: _selectedToWalletKey,
          goalKey: _selectedGoalKey,
          budgetKey: _selectedBudgetKey,
          debtKey: _selectedDebtKey,
        );
        await DatabaseService.saveTransaction(transaction);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _chargeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tutorialSteps = [
      OnboardingStep(
        targetKey: _typeKey,
        title: 'Transaction Type',
        description: 'You can change the type of transaction anytime.',
      ),
      OnboardingStep(
        targetKey: _amountKey,
        title: 'Amount',
        description: 'Update the amount if needed.',
      ),
      OnboardingStep(
        targetKey: _walletKey,
        title: 'Wallet',
        description: 'Choose the correct wallet for this transaction.',
      ),
      OnboardingStep(
        targetKey: _categoryKey,
        title: 'Category',
        description: 'Update the category to better organize your records.',
      ),
      OnboardingStep(
        targetKey: _noteKey,
        title: 'Description',
        description: 'Edit or add notes for more details (optional).',
      ),
      OnboardingStep(
        targetKey: _dateKey,
        title: 'Date & Time',
        description: 'You can manually change the date of this transaction.',
      ),
      OnboardingStep(
        targetKey: _saveKey,
        title: 'Update Transaction',
        description: 'Save your changes to update the transaction.',
      ),
    ];

    return OnboardingOverlay(
      steps: tutorialSteps,
      visible: _showTutorial,
      onFinish: () {
        _dismissTutorial();
        if (widget.isTutorialMode && mounted) {
           Navigator.pop(context); // Automatically pop for the bridged workflow!
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
            title: Text(widget.existingTransaction == null
                ? 'Add Transaction'
                : 'Edit Transaction'),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () => setState(() {
                  _showTutorial = true;
                }),
              ),
            ],
            elevation: 0),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  if (_getSafetyAlerts().isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha:0.1),
                        border: Border.all(color: Colors.orange.withValues(alpha:0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _getSafetyAlerts().map((alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            alert,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                  // Transaction Type Selector
                  Row(
                    key: _typeKey,
                    children: [
                      _typeButton('Income', TransactionType.income, Colors.green),
                      const SizedBox(width: 8),
                      _typeButton('Expense', TransactionType.expense, Colors.red),
                      const SizedBox(width: 8),
                      _typeButton(
                        'Transfer',
                        TransactionType.transfer,
                        Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Wallet Selector (Source)
                  Text(
                    _selectedType == TransactionType.transfer ? 'From' : 'Wallet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    key: _walletKey,
                    child: _buildWalletDropdown(
                      _selectedType == TransactionType.transfer
                          ? DatabaseService.getWallets(
                              widget.accountKey,
                            ) // All wallets for transfer
                          : DatabaseService.getWallets(widget.accountKey)
                                .where((w) => !w.isExcluded)
                                .toList(), // Spendable only for others
                      _selectedWalletKey,
                      (val) => setState(() => _selectedWalletKey = val),
                    ),
                  ),

                  // Destination Wallet (For Transfers)
                  if (_selectedType == TransactionType.transfer) ...[
                    Center(
                      child: IconButton(
                        icon: Icon(Icons.swap_vert_rounded, color: theme.primaryColor, size: 32),
                        onPressed: () {
                          setState(() {
                            final temp = _selectedWalletKey;
                            _selectedWalletKey = _selectedToWalletKey;
                            _selectedToWalletKey = temp;
                          });
                        },
                      ),
                    ),
                    Text('To', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildWalletDropdown(
                      DatabaseService.getWallets(
                        widget.accountKey,
                      ), // All wallets for destination
                      _selectedToWalletKey,
                      (val) => setState(() => _selectedToWalletKey = val),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    const SizedBox(height: 24),
                  ],

                  // Amount Field
                  Container(
                    key: _amountKey,
                    child: CalculatorInputField(
                      label: 'Amount',
                      initialValue: double.tryParse(_amountController.text),
                      onChanged: (val) => setState(() => _amountController.text = val.toStringAsFixed(2)),
                      validator: (value) {
                        if (value == null || value == '0' || value.isEmpty) return 'Enter amount';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Charge Field (Optional, for Transfers)
                  if (_selectedType == TransactionType.transfer) ...[
                    CalculatorInputField(
                      label: 'Transfer Charge (Optional)',
                      initialValue: double.tryParse(_chargeController.text),
                      onChanged: (val) => setState(() => _chargeController.text = val.toStringAsFixed(2)),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 24),

                  // Category Picker (Hidden for transfers as it's just moving money)
                  if (_selectedType != TransactionType.transfer) ...[
                    Text('Category', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Container(
                      key: _categoryKey,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currentCategories.containsKey(_selectedCategory) 
                              ? _selectedCategory 
                              : _currentCategories.keys.first,
                          isExpanded: true,
                          dropdownColor: theme.cardColor,
                          items: _currentCategories.keys.map((String category) {
                            final budgetStat = _getBudgetStatus(category);
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(_currentCategories[category], size: 20, color: theme.primaryColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(category),
                                        if (budgetStat != null) ...[
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              budgetStat,
                                              style: TextStyle(
                                                color: budgetStat.contains('-') ? Colors.red : Colors.grey,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => _selectedCategory = newValue);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description Field
                  Text(
                    'Description (Optional)',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    key: _noteKey,
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Add a note...',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Manual Date Toggle
                  Container(
                    key: _dateKey,
                    child: Row(
                      children: [
                        const Icon(Icons.history_toggle_off_rounded, size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text('Manual Date Entry', 
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500
                          )
                        ),
                        const Spacer(),
                        Switch(
                          value: _isManualDate,
                          onChanged: (val) {
                            setState(() {
                              _isManualDate = val;
                              if (!val) _selectedDate = DateTime.now();
                            });
                          },
                          activeThumbImage: null, // to specify thumb if needed or just use activeColor alternative
                          activeThumbColor: theme.primaryColor, 
                          // Flutter 3.31 deprecates activeColor in favor of thumbIcon/trackColor 
                          // we'll just use activeColor as standard if it's simpler
                          activeTrackColor: theme.primaryColor.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                  if (_isManualDate) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final currentContext = context;
                        final pickedDate = await showDatePicker(
                          context: currentContext,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          if (!mounted) return;
                          final pickedTime = await showTimePicker(
                            context: currentContext,
                            initialTime: TimeOfDay.fromDateTime(_selectedDate),
                          );
                          if (pickedTime != null) {
                            if (!mounted) return;
                            setState(() {
                              _selectedDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event, size: 20, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('EEEE, MMM dd, yyyy • hh:mm a').format(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit_rounded, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Recorded as Today, ${DateFormat('hh:mm a').format(_selectedDate)}',
                        style: TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontSize: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    key: _saveKey,
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Save Transaction',
                        style: TextStyle(
                          color: theme.scaffoldBackgroundColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }


  Widget _buildWalletDropdown(
    List<Wallet> wallets,
    int? selectedKey,
    ValueChanged<int?> onChanged,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedKey,
          isExpanded: true,
          hint: const Text('Select Wallet'),
          items: wallets.map((wallet) {
            return DropdownMenuItem<int>(
              value: wallet.key as int,
              child: Text(
                '${wallet.name} (₱${wallet.balance.toStringAsFixed(2)})',
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _typeButton(String label, TransactionType type, Color color) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _selectedType = type;
          _selectedCategory = type == TransactionType.income ? 'Salary' : 'Food & Drinks';
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            border: Border.all(color: isSelected ? color : Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
