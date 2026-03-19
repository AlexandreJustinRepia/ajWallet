import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/database_service.dart';
import 'models/transaction_model.dart';
import '../models/wallet.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/debt.dart';
import 'package:hive/hive.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPlanningEntities();
    
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
          elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction Type Selector
              Row(
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
              _buildWalletDropdown(
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
              Text('Amount', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: "₱ ",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter amount';
                  if (double.tryParse(value) == null)
                    return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Charge Field (Optional, for Transfers)
              if (_selectedType == TransactionType.transfer) ...[
                Text(
                  'Transfer Charge (Optional)',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _chargeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText: "₱ ",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 24),

              // Category Picker (Hidden for transfers as it's just moving money)
              if (_selectedType != TransactionType.transfer) ...[
                Text('Category', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
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
                  const Text('Manual Date Entry', style: TextStyle(fontWeight: FontWeight.w500)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
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
