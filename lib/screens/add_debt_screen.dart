import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/debt.dart';
import '../widgets/calculator_input.dart';

class AddDebtScreen extends StatefulWidget {
  final int accountKey;
  const AddDebtScreen({super.key, required this.accountKey});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isOwedToMe = true;
  DateTime? _dueDate;

  void _saveDebt() async {
    if (_formKey.currentState!.validate()) {
      final dept = Debt(
        personName: _personController.text.trim(),
        totalAmount: double.parse(_amountController.text),
        paidAmount: 0.0,
        accountKey: widget.accountKey,
        isOwedToMe: _isOwedToMe,
        dueDate: _dueDate,
      );

      await DatabaseService.saveDebt(dept);
      if (mounted) Navigator.pop(context, true);
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
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Add Debt/Loan'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              const SizedBox(height: 32),
              Text(_isOwedToMe ? 'Who owes you?' : 'Who do you owe?', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _personController,
                decoration: InputDecoration(
                  hintText: 'Person or Bank Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 24),
              CalculatorInputField(
                label: 'Total Amount',
                initialValue: double.tryParse(_amountController.text),
                onChanged: (val) => setState(() => _amountController.text = val.toStringAsFixed(2)),
                validator: (val) {
                  if (val == null || val == '0' || val.isEmpty) return 'Enter amount';
                  return null;
                },
              ),
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
    );
  }
}
