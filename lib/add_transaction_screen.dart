import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/database_service.dart';
import 'models/transaction_model.dart';
import '../models/wallet.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/debt.dart';
import 'package:hive/hive.dart';
import 'widgets/calculator_input.dart';

class AddTransactionScreen extends StatefulWidget {
  final int accountKey;
  final Transaction? existingTransaction;
  
  // Initial planning keys
  final int? initialGoalKey;
  final int? initialBudgetKey;
  final int? initialDebtKey;
  final TransactionType? initialType;

  const AddTransactionScreen({
    super.key, 
    required this.accountKey, 
    this.existingTransaction,
    this.initialGoalKey,
    this.initialBudgetKey,
    this.initialDebtKey,
    this.initialType,
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
  final _saveKey = GlobalKey();

  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  bool _isManualDate = false;
  String _selectedCategory = 'Food & Drinks';
  int? _selectedWalletKey;
  int? _selectedToWalletKey; // For Transfers

  List<Goal> _goals = [];
  List<Budget> _budgets = [];
  List<Debt> _debts = [];

  int? _selectedGoalKey;
  int? _selectedBudgetKey;
  int? _selectedDebtKey;

  // Tutorial State
  bool _showTutorial = false;
  int _tutorialStep = 0;

  @override
  void initState() {
    super.initState();
    _loadPlanningEntities();
    _checkTutorial();
    
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

  void _loadPlanningEntities() {
    _goals = DatabaseService.getGoals(widget.accountKey);
    _budgets = DatabaseService.getBudgets(widget.accountKey);
    _debts = DatabaseService.getDebts(widget.accountKey);
  }

  final Map<String, IconData> _expenseCategories = {
    'Food & Drinks': Icons.fastfood,
    'Transportation': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Entertainment': Icons.movie,
    'Health': Icons.medical_services,
    'Utilities': Icons.home,
    'Education': Icons.school,
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

    return Scaffold(
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
                _tutorialStep = 0;
              }),
            ),
          ],
          elevation: 0),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(_currentCategories[category], size: 20, color: theme.primaryColor),
                                  const SizedBox(width: 12),
                                  Text(category),
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
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add a note...',
                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Planning Linkage ──────────────────────────────────────────
                  Text('Link to Planning (Optional)', style: theme.textTheme.titleMedium?.copyWith(color: theme.primaryColor)),
                  const SizedBox(height: 16),
                  
                  // Goal Selector
                  _buildPlanningDropdown<Goal>(
                    label: 'Savings Goal',
                    items: _goals,
                    value: _selectedGoalKey,
                    itemLabel: (g) => '${g.name} (₱${g.savedAmount.toStringAsFixed(0)}/₱${g.targetAmount.toStringAsFixed(0)})',
                    onChanged: (val) => setState(() => _selectedGoalKey = val),
                    icon: Icons.flag_rounded,
                  ),
                  const SizedBox(height: 16),

                  // Budget Selector
                  _buildPlanningDropdown<Budget>(
                    label: 'Category Budget',
                    items: _budgets,
                    value: _selectedBudgetKey,
                    itemLabel: (b) => '${b.category} (${DateFormat('MMM').format(DateTime(2026, b.month))} - ₱${b.amountLimit.toStringAsFixed(0)})',
                    onChanged: (val) => setState(() => _selectedBudgetKey = val),
                    icon: Icons.pie_chart_rounded,
                  ),
                  const SizedBox(height: 16),

                  // Debt Selector
                  _buildPlanningDropdown<Debt>(
                    label: 'Debt / Loan',
                    items: _debts,
                    value: _selectedDebtKey,
                    itemLabel: (d) => '${d.personName} (${d.isOwedToMe ? 'Owed to me' : 'Borrowed'})',
                    onChanged: (val) => setState(() => _selectedDebtKey = val),
                    icon: Icons.handshake_rounded,
                  ),

                  const SizedBox(height: 32),

                  // Manual Date Toggle
                  Row(
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
                        activeColor: theme.primaryColor,
                      ),
                    ],
                  ),
                  
                  if (_isManualDate) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_selectedDate),
                          );
                          if (pickedTime != null) {
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
                        style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 12),
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
          if (_showTutorial) _buildTutorialOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildTutorialOverlay(ThemeData theme) {
    String message = '';
    GlobalKey? targetKey;

    switch (_tutorialStep) {
      case 0:
        message = "Income, Expense, or Transfer? Pick how your money is moving.";
        targetKey = _typeKey;
        break;
      case 1:
        message = "Choose the wallet you're using for this transaction.";
        targetKey = _walletKey;
        break;
      case 2:
        message = "Tap to enter the amount. Use the built-in calculator for math!";
        targetKey = _amountKey;
        break;
      case 3:
        if (_selectedType == TransactionType.transfer) {
          _tutorialStep++; // Skip category for transfers
          return _buildTutorialOverlay(theme);
        }
        message = "Tag it with a category to track where your money goes.";
        targetKey = _categoryKey;
        break;
      case 4:
        message = "All set? Hit save to update your balances instantly!";
        targetKey = _saveKey;
        break;
    }

    return Container(
      color: Colors.black.withOpacity(0.7),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.primaryColor.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(color: theme.primaryColor.withOpacity(0.2), blurRadius: 40),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: theme.primaryColor, size: 40),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _dismissTutorial,
                          child: const Text('Skip'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (_tutorialStep < 4) {
                                _tutorialStep++;
                                // Scroll to target if needed (simplified here)
                              } else {
                                _dismissTutorial();
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_tutorialStep < 4 ? 'Next' : 'Got it!'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                  "Step ${_tutorialStep + 1} of 5",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanningDropdown<T extends HiveObject>({
    required String label,
    required List<T> items,
    required int? value,
    required String Function(T) itemLabel,
    required ValueChanged<int?> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              hint: Text('None', style: TextStyle(color: Colors.grey.withOpacity(0.5))),
              dropdownColor: theme.cardColor,
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('None')),
                ...items.map((item) {
                  return DropdownMenuItem<int>(
                    value: item.key as int,
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: theme.primaryColor.withOpacity(0.5)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(itemLabel(item), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  );
                }).toList(),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
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
