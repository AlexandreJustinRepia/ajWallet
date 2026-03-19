import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'models/account.dart';
import 'models/wallet.dart';
import 'pin_setup_screen.dart';
import 'services/session_service.dart';

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

  void _showBalanceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BalanceModal(
        controller: _balanceController,
        onComplete: _finishSetup,
      ),
    );
  }

  void _finishSetup() async {
    final name = _accountNameController.text.trim();
    final balance = double.tryParse(_balanceController.text) ?? 0.0;

    // 1. Save Account
    final account = Account(name: name);
    await DatabaseService.saveAccount(account);

    // 2. Get the saved account to get its key
    final savedAccount = DatabaseService.getLatestAccount();
    if (savedAccount != null) {
      SessionService.setActiveAccount(savedAccount);
      
      // 3. Create Default Wallet
      final defaultWallet = Wallet(
        name: 'Cash',
        balance: balance,
        type: 'Cash',
        accountKey: savedAccount.key as int,
      );
      await DatabaseService.saveWallet(defaultWallet);
    }

    if (mounted) {
      Navigator.pop(context); // Close modal
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PinSetupScreen()),
        (route) => false,
      );
    }
  }

  void _createAccount() {
    final name = _accountNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an account name')));
      return;
    }
    _showBalanceModal();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              Text('New Account', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 8),
              const Text('Give your budget account a name to get started.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 48),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isFocused ? theme.primaryColor : Colors.grey[300]!,
                    width: _isFocused ? 2.0 : 1.0,
                  ),
                ),
                child: TextField(
                  controller: _accountNameController,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(hintText: 'Account Name', border: InputBorder.none),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTapDown: (_) => setState(() => _isButtonPressed = true),
                onTapUp: (_) => setState(() => _isButtonPressed = false),
                onTapCancel: () => setState(() => _isButtonPressed = false),
                onTap: _createAccount,
                child: AnimatedScale(
                  scale: _isButtonPressed ? 0.98 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          color: theme.scaffoldBackgroundColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text('You can set a PIN later for extra security', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceModal extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onComplete;

  const _BalanceModal({required this.controller, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(32, 32, 32, 32 + bottomPadding),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Initial Balance',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'How much money do you have right now? This will be added to your first wallet.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Text('₱', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: '0'),
                    autofocus: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.scaffoldBackgroundColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Complete Setup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
