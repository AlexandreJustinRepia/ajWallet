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
import 'services/attachment_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'models/category.dart';
import 'services/auto_categorization_service.dart';



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
  final _manageCategoriesKey = GlobalKey();
  final _attachmentsKey = GlobalKey();

  bool _userManuallySelectedCategory = false;




  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  bool _isManualDate = false;
  String _selectedCategory = 'Others';
  List<Category> _availableCategories = [];

  int? _selectedWalletKey;
  int? _selectedToWalletKey; // For Transfers

  List<Budget> _budgets = [];
  List<Transaction> _transactions = [];
  List<Debt> _debts = [];

  int? _selectedGoalKey;
  int? _selectedBudgetKey;
  int? _selectedDebtKey;
  List<String> _attachmentPaths = [];

  // Tutorial State
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_onDescriptionChanged);

    _budgets = DatabaseService.getBudgets(widget.accountKey);
    _transactions = DatabaseService.getTransactions(widget.accountKey);
    _debts = DatabaseService.getDebts(widget.accountKey);
    _refreshCategories();

    
    if (widget.isTutorialMode) {
      _showTutorial = true;
      _selectedType = TransactionType.expense;
      _amountController.text = '250.00';
      _selectedCategory = 'Food & Drinks';
      _refreshCategories();
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
      _attachmentPaths = List<String>.from(tx.attachmentPaths ?? []);
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
        _refreshCategories();
        if (_availableCategories.isNotEmpty) {
           _selectedCategory = _availableCategories.any((c) => c.name == 'Salary') && _selectedType == TransactionType.income 
               ? 'Salary' 
               : _availableCategories.any((c) => c.name == 'Food & Drinks') && _selectedType == TransactionType.expense
                   ? 'Food & Drinks'
                   : _availableCategories.first.name;
        }
      }

      _selectedGoalKey = widget.initialGoalKey;
      _selectedBudgetKey = widget.initialBudgetKey;
      _selectedDebtKey = widget.initialDebtKey;
    }
  }

  void _refreshCategories() {
    setState(() {
      _availableCategories = DatabaseService.getCategories(_selectedType);
      
      // Ensure selected category is valid for the current type
      if (!_availableCategories.any((c) => c.name == _selectedCategory)) {
        if (_availableCategories.isNotEmpty) {
           // Try to find a sensible default
           if (_selectedType == TransactionType.income && _availableCategories.any((c) => c.name == 'Salary')) {
             _selectedCategory = 'Salary';
           } else if (_selectedType == TransactionType.expense && _availableCategories.any((c) => c.name == 'Food & Drinks')) {
             _selectedCategory = 'Food & Drinks';
           } else {
             _selectedCategory = _availableCategories.first.name;
           }
        } else {
          _selectedCategory = 'Others';
        }
      }
    });
  }

  void _onDescriptionChanged() {
    if (_userManuallySelectedCategory) return;
    if (_descriptionController.text.length < 3) return;

    final prediction = AutoCategorizationService.predictCategory(
      _descriptionController.text,
      _selectedType,
    );

    if (prediction != null && prediction != _selectedCategory) {
      if (_availableCategories.any((c) => c.name == prediction)) {
        setState(() {
          _selectedCategory = prediction;
        });
      }
    }
  }


  void _checkTutorial() async {
    final box = await Hive.openBox('settings');
    final hasSeen = box.get('has_seen_tx_tutorial', defaultValue: false);
    if (!hasSeen && widget.existingTransaction == null) {
      setState(() => _showTutorial = true);
    }
  }

  void _markTutorialSeen() async {
    final box = await Hive.openBox('settings');
    await box.put('has_seen_tx_tutorial', true);
  }

  void _dismissTutorial() {
    setState(() => _showTutorial = false);
    _markTutorialSeen();
  }

  // Removed hardcoded maps in favor of DatabaseService.getCategories


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
        existing.attachmentPaths = _attachmentPaths;

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
          attachmentPaths: _attachmentPaths,
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
    _descriptionController.removeListener(_onDescriptionChanged);
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
        description: 'Choose if this is an Expense, Income, or Transfer.',
      ),
      OnboardingStep(
        targetKey: _manageCategoriesKey,
        title: 'Manage Categories',
        description: 'Customize your categories! Add new ones, edit icons, or drag them into your favorite order.',
      ),

      OnboardingStep(
        targetKey: _amountKey,
        title: 'Amount',
        description: 'Enter the transaction amount using the calculator.',
      ),
      OnboardingStep(
        targetKey: _walletKey,
        title: 'Source Wallet',
        description: 'Select the wallet for this transaction.',
      ),
      OnboardingStep(
        targetKey: _categoryKey,
        title: 'Category',
        description: 'Select the category to stay organized.',
      ),
      OnboardingStep(
        targetKey: _noteKey,
        title: 'Description',
        description: 'Add a small note if you want.',
      ),
      OnboardingStep(
        targetKey: _dateKey,
        title: 'Transaction Date',
        description: 'You can change the date if this happened in the past.',
      ),
      OnboardingStep(
        targetKey: _attachmentsKey,
        title: 'Attachments',
        description: 'Attach photos, receipts, or documents to your transaction for better record keeping.',
      ),
      OnboardingStep(
        targetKey: _saveKey,
        title: 'Save Transaction',
        description: 'Tap Save to record your transaction!',
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
                        color: const Color(0xFFF57C00).withValues(alpha:0.1), // Botanical Gold
                        border: Border.all(color: const Color(0xFFF57C00).withValues(alpha:0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _getSafetyAlerts().map((alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            alert,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF57C00)),
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                  // Transaction Type Selector
                  Row(
                    key: _typeKey,
                    children: [
                      _typeButton('Income', TransactionType.income, const Color(0xFF2E7D32)), // Forest Green
                      const SizedBox(width: 8),
                      _typeButton('Expense', TransactionType.expense, const Color(0xFFC62828)), // Deep Red
                      const SizedBox(width: 8),
                      _typeButton(
                        'Transfer',
                        TransactionType.transfer,
                        const Color(0xFF00796B), // Botanical Teal
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_selectedType != TransactionType.transfer)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        key: _manageCategoriesKey,
                        onPressed: () async {

                          await Navigator.pushNamed(context, '/category_settings');
                          _refreshCategories();
                        },
                        icon: const Icon(Icons.settings_outlined, size: 14),
                        label: const Text('Manage Categories', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                
                  const SizedBox(height: 16),

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
                          value: _selectedCategory,
                          isExpanded: true,
                          dropdownColor: theme.cardColor,
                          items: _availableCategories.map((Category cat) {
                            final category = cat.name;
                            final budgetStat = _getBudgetStatus(category);
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(cat.icon, size: 20, color: theme.primaryColor),
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
                                                color: budgetStat.contains('-') ? const Color(0xFFC62828) : Colors.grey,
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
                              setState(() {
                                _selectedCategory = newValue;
                                _userManuallySelectedCategory = true;
                              });
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
                          if (!context.mounted) return;
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_selectedDate),
                          );
                          if (pickedTime != null) {
                            if (!context.mounted) return;
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

                  // Attachments Section
                  Text('ATTACHMENTS (OPTIONAL)', 
                    key: _attachmentsKey,
                    style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w900, fontSize: 10, color: theme.textTheme.labelLarge?.color?.withValues(alpha: 0.6))),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._attachmentPaths.map((path) => Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: 4,
                                top: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _attachmentPaths.remove(path));
                                    AttachmentService.deleteAttachment(path);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                        GestureDetector(
                          onTap: () => _pickAttachment(),
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor, width: 0.5),
                            ),
                            child: Icon(Icons.add_a_photo_rounded, color: theme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
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

  void _pickAttachment() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('Pick Attachment', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: const Text('Camera'),
            onTap: () async {
              Navigator.pop(context);
              final path = await AttachmentService.pickAndStoreImage(ImageSource.camera);
              if (path != null) setState(() => _attachmentPaths.add(path));
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Gallery'),
            onTap: () async {
              Navigator.pop(context);
              final path = await AttachmentService.pickAndStoreImage(ImageSource.gallery);
              if (path != null) setState(() => _attachmentPaths.add(path));
            },
          ),
          const SizedBox(height: 16),
        ],
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
    final isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = type;
            _refreshCategories();
          });
        },
        borderRadius: BorderRadius.circular(12),
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
