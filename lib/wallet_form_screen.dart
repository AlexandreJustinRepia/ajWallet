import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'models/wallet.dart';
import 'widgets/calculator_input.dart';

class WalletFormScreen extends StatefulWidget {
  final int accountKey;
  final Wallet? wallet; // If provided, we are editing

  const WalletFormScreen({
    super.key, 
    required this.accountKey, 
    this.wallet,
  });

  @override
  State<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends State<WalletFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late String _selectedType;
  late bool _isExcluded;

  final List<String> _walletTypes = ['Wallet', 'Cash', 'ATM', 'E-Wallet', 'Bank', 'Savings', 'Others'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wallet?.name ?? '');
    _balanceController = TextEditingController(text: widget.wallet?.balance.toString() ?? '0');
    _selectedType = widget.wallet?.type ?? 'Wallet';
    _isExcluded = widget.wallet?.isExcluded ?? false;
  }

  void _saveWallet() async {
    if (_formKey.currentState!.validate()) {
      if (widget.wallet != null) {
        // Edit existing
        widget.wallet!.name = _nameController.text;
        widget.wallet!.balance = double.parse(_balanceController.text);
        widget.wallet!.type = _selectedType;
        widget.wallet!.isExcluded = _isExcluded;
        await DatabaseService.updateWallet(widget.wallet!);
      } else {
        // Create new
        final wallet = Wallet(
          name: _nameController.text,
          balance: double.parse(_balanceController.text),
          type: _selectedType,
          accountKey: widget.accountKey,
          isExcluded: _isExcluded,
        );
        await DatabaseService.saveWallet(wallet);
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.wallet != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(isEditing ? 'Edit Wallet' : 'Add Wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wallet Name', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g., G-Cash, BDO, Cash',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 24),
              CalculatorInputField(
                label: 'Balance',
                initialValue: double.tryParse(_balanceController.text),
                onChanged: (val) => setState(() => _balanceController.text = val.toStringAsFixed(2)),
                validator: (value) => value == null || value.isEmpty ? 'Enter balance' : null,
              ),
              const SizedBox(height: 24),
              Text('Type', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _walletTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Exclude from Total Balance'),
                subtitle: const Text('This wallet\'s money will not be counted in your dashboard total.'),
                value: _isExcluded,
                onChanged: (val) => setState(() => _isExcluded = val),
                activeColor: theme.primaryColor,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveWallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(isEditing ? 'Update Wallet' : 'Save Wallet', style: TextStyle(color: theme.scaffoldBackgroundColor, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
