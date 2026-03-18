import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/database_service.dart';
import 'models/transaction_model.dart';
import 'models/wallet.dart';

class AddTransactionScreen extends StatefulWidget {
  final int accountKey;
  const AddTransactionScreen({super.key, required this.accountKey});

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
  String _selectedCategory = 'Food & Drinks';
  int? _selectedWalletKey;
  int? _selectedToWalletKey; // For Transfers

  final Map<String, IconData> _categories = {
    'Food & Drinks': Icons.fastfood,
    'Transportation': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Entertainment': Icons.movie,
    'Health': Icons.medical_services,
    'Utilities': Icons.home,
    'Salary': Icons.payments,
    'Others': Icons.more_horiz,
  };

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedWalletKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a wallet')));
        return;
      }

      if (_selectedType == TransactionType.transfer && _selectedToWalletKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a destination wallet')));
        return;
      }

      final transaction = Transaction(
        title: _selectedType == TransactionType.transfer ? 'Transfer' : _selectedCategory,
        amount: double.parse(_amountController.text),
        charge: double.tryParse(_chargeController.text),
        date: _selectedDate,
        category: _selectedType == TransactionType.transfer ? 'Transfer' : _selectedCategory,
        description: _descriptionController.text,
        type: _selectedType,
        accountKey: widget.accountKey,
        walletKey: _selectedWalletKey,
        toWalletKey: _selectedToWalletKey,
      );

      await DatabaseService.saveTransaction(transaction);
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
        title: const Text('Add Transaction'),
        elevation: 0,
      ),
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
                  _typeButton('Transfer', TransactionType.transfer, Colors.blue),
                ],
              ),
              const SizedBox(height: 32),
              
              // Wallet Selector (Source)
              Text(_selectedType == TransactionType.transfer ? 'From Wallet' : 'Wallet', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildWalletDropdown(
                _selectedType == TransactionType.transfer 
                    ? DatabaseService.getWallets(widget.accountKey) // All wallets for transfer
                    : DatabaseService.getWallets(widget.accountKey).where((w) => !w.isExcluded).toList(), // Spendable only for others
                _selectedWalletKey, 
                (val) => setState(() => _selectedWalletKey = val)
              ),
              const SizedBox(height: 24),

              // Destination Wallet (For Transfers)
              if (_selectedType == TransactionType.transfer) ...[
                Text('To Wallet', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildWalletDropdown(
                  DatabaseService.getWallets(widget.accountKey), // All wallets for destination
                  _selectedToWalletKey, 
                  (val) => setState(() => _selectedToWalletKey = val)
                ),
                const SizedBox(height: 24),
              ],
              
              // Amount Field
              Text('Amount', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: "₱ ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter amount';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Charge Field (Optional, for Transfers)
              if (_selectedType == TransactionType.transfer) ...[
                Text('Transfer Charge (Optional)', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _chargeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText: "₱ ",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items: _categories.keys.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Row(
                            children: [
                              Icon(_categories[category], size: 20),
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
              Text('Description (Optional)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add a note...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Date Display (Realtime)
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(_selectedDate)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildWalletDropdown(List<Wallet> wallets, int? selectedKey, ValueChanged<int?> onChanged) {
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
              child: Text('${wallet.name} (₱${wallet.balance.toStringAsFixed(2)})'),
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
        onTap: () => setState(() => _selectedType = type),
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
