import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'models/account.dart';
import 'models/wallet.dart';
import 'pin_setup_screen.dart';
import 'services/session_service.dart';
import 'widgets/calculator_input.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController(text: '0');
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _balanceController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _finishSetup() async {
    final name = _accountNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an account name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final balance = double.tryParse(_balanceController.text) ?? 0.0;

    // 1. Save Account
    final account = Account(name: name);
    final accountKey = await DatabaseService.saveAccount(account);

    // 2. Set Active Account
    final savedAccount = DatabaseService.getAccounts().firstWhere((a) => a.key == accountKey);
    SessionService.setActiveAccount(savedAccount);
    
    // 3. Create Default Wallet
    final defaultWallet = Wallet(
      name: 'Cash',
      balance: balance,
      type: 'Cash',
      accountKey: accountKey,
    );
    await DatabaseService.saveWallet(defaultWallet);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PinSetupScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: theme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'Create\nAccount',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -1.0,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Set up a new workspace for your finances.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 48),
              
              // Refined Input Cards
              _buildInputLabel('ACCOUNT NAME'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isFocused ? theme.primaryColor : theme.dividerColor,
                    width: _isFocused ? 2.0 : 1.0,
                  ),
                ),
                child: TextField(
                  controller: _accountNameController,
                  focusNode: _focusNode,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Personal Savings',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              
              _buildInputLabel('INITIAL BALANCE'),
              const SizedBox(height: 8),
              CalculatorInputField(
                label: 'Starting Amount',
                initialValue: double.tryParse(_balanceController.text),
                onChanged: (val) =>
                    setState(() => _balanceController.text = val.toStringAsFixed(2)),
              ),
              
              const SizedBox(height: 48),
              
              // Premium Primary Button
              GestureDetector(
                onTapDown: (_) => setState(() => _isButtonPressed = true),
                onTapUp: (_) => setState(() => _isButtonPressed = false),
                onTapCancel: () => setState(() => _isButtonPressed = false),
                onTap: _finishSetup,
                child: AnimatedScale(
                  scale: _isButtonPressed ? 0.98 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Security settings can be adjusted later',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
