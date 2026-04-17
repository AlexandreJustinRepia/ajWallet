import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/financial_insights_service.dart';
import '../models/budget.dart';
import '../models/transaction_model.dart';
import '../widgets/calculator_input.dart';
import 'package:hive/hive.dart';

import '../widgets/onboarding_overlay.dart';

class AddBudgetScreen extends StatefulWidget {
  final int accountKey;
  final bool isTutorialMode;
  const AddBudgetScreen({super.key, required this.accountKey, this.isTutorialMode = false});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food & Drinks';
  double _suggestedBudget = 0.0;
  List<Transaction> _transactions = [];

  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _amountKey = GlobalKey();
  final GlobalKey _saveKey = GlobalKey();
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _transactions = DatabaseService.getTransactions(widget.accountKey);
    
    if (widget.isTutorialMode) {
      _selectedCategory = 'Food & Drinks';
      _amountController.text = '2000';
    }
    _updateSuggestion();
    _checkTutorial();
  }

  void _checkTutorial() async {
    final box = await Hive.openBox('settings');
    final hasSeen = box.get('has_seen_budget_tutorial', defaultValue: false);
    if (!hasSeen) {
      if (mounted) setState(() => _showTutorial = true);
    }
  }

  void _markTutorialSeen() async {
    final box = await Hive.openBox('settings');
    await box.put('has_seen_budget_tutorial', true);
  }

  void _updateSuggestion() {
    setState(() {
      _suggestedBudget = FinancialInsightsService.suggestBudget(_selectedCategory, _transactions);
    });
  }

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
    return OnboardingOverlay(
      visible: widget.isTutorialMode || _showTutorial,
      steps: [
        OnboardingStep(
          targetKey: _categoryKey,
          title: 'Select Category',
          description: 'Choose a category to set a budget for.',
        ),
        OnboardingStep(
          targetKey: _amountKey,
          title: 'Budget Amount',
          description: 'Enter how much you want to spend for this category.',
        ),
        OnboardingStep(
          targetKey: _saveKey,
          title: 'Save Budget',
          description: 'Save your budget.',
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
          title: const Text('Add Monthly Budget'), 
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
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _selectedCategory = val;
                        _updateSuggestion();
                      }
                    },
                  ),
                ),
              ),
              if (_suggestedBudget > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _amountController.text = _suggestedBudget.toStringAsFixed(2);
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 14, color: theme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Recommended: ₱${_suggestedBudget.toStringAsFixed(0)} (based on past 3 months)',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              CalculatorInputField(
                key: _amountKey,
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
                  key: _saveKey,
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
    ));
  }
}
