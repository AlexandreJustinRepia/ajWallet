import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/session_service.dart';
import 'dashboard_screen.dart';
import 'models/account.dart';
import 'widgets/pin_input_widget.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isFromSettings;
  final bool isResetting;
  final Account? account;

  const PinSetupScreen({
    super.key, 
    this.isFromSettings = false, 
    this.isResetting = false,
    this.account,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  String? _firstPin;
  bool _isConfirming = false;


  void _handlePinComplete(String pin) {
    if (!_isConfirming) {
      // First step: Store PIN and move to confirmation
      setState(() {
        _firstPin = pin;
        _isConfirming = true;
      });
      _pinController.clear();
    } else {
      // Second step: Verify and save
      if (pin == _firstPin) {
        _savePin(pin);
      } else {
        _showError('PINs do not match. Try again.');
        setState(() {
          _isConfirming = false;
          _firstPin = null;
        });
        _pinController.clear();
      }
    }
  }

  void _savePin(String pin) async {
    final account = widget.account ?? SessionService.activeAccount;
    if (account != null) {
      account.pin = pin;
      await DatabaseService.updateAccount(account);
      SessionService.setActiveAccount(account);
      
      if (mounted) {
        if (widget.isFromSettings) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: Colors.red[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = textColor.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: _isConfirming 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => setState(() {
                _isConfirming = false;
                _pinController.clear();
              }),
            )
          : (widget.isFromSettings ? const BackButton() : null),
        actions: [
          if (!widget.isFromSettings && !_isConfirming)
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                );
              },
              child: Text('Skip', style: TextStyle(color: hintColor, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Padding(
            key: ValueKey<bool>(_isConfirming),
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text(
                  _isConfirming ? 'Verify your PIN' : (widget.isResetting ? 'Reset your PIN' : 'Create a PIN'),
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor),
                ),
                const SizedBox(height: 12),
                Text(
                  _isConfirming 
                    ? 'Please repeat the 4-digit sequence to confirm.'
                    : 'Enter 4 digits to secure your vault.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: hintColor),
                ),
                const SizedBox(height: 60),
                PinInputWidget(
                  controller: _pinController,
                  onCompleted: _handlePinComplete,
                ),
                const Spacer(),
                const Text(
                  'Your PIN is stored locally and encrypted.\nNever share it with anyone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
