import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/budget.dart';
import '../widgets/calculator_input.dart';

class AddBudgetScreen extends StatefulWidget {
  final int accountKey;
  const AddBudgetScreen({super.key, required this.accountKey});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food & Drinks';

  final List<String> _categories = [
    'Food & Drinks',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Health',
    'Utilities',
    'Education',
    'Others',
  ];

  void _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final budget = Budget(
        category: _selectedCategory,
        amountLimit: amount,
        accountKey: widget.accountKey,
        month: DateTime.now().month,
        year: DateTime.now().year,
      );

      await DatabaseService.saveBudget(budget);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Add Monthly Budget'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CalculatorInputField(
                label: 'Monthly Limit',
                initialValue: double.tryParse(_amountController.text),
                onChanged: (val) => setState(() => _amountController.text = val.toStringAsFixed(2)),
                validator: (val) {
                  if (val == null || val == '0' || val.isEmpty) return 'Enter limit';
                  return null;
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _saveBudget,
                  child: Text('Save Budget', style: TextStyle(color: theme.scaffoldBackgroundColor, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
