import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/session_service.dart';
import 'services/security_service.dart';
import 'dashboard_screen.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isFromSettings;
  const PinSetupScreen({super.key, this.isFromSettings = false});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _fakePinController = TextEditingController();
  bool _isButtonPressed = false;
  bool _canCheckBiometrics = false;
  bool _useBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canCheck = await SecurityService.canAuthenticateWithBiometrics();
    if (!mounted) return;
    setState(() {
      _canCheckBiometrics = canCheck;
    });
  }

  void _savePin() async {
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    if (pin.length != 4 || confirmPin.length != 4) {
      _showError('PIN must be 4 digits');
      return;
    }

    if (pin != confirmPin) {
      _showError('PINs do not match');
      return;
    }

    if (_fakePinController.text.isNotEmpty && pin == _fakePinController.text) {
      _showError('Original and Fake PIN cannot be the same');
      return;
    }

    final account = SessionService.activeAccount;
    if (account != null) {
      account.pin = pin;
      account.isBiometricEnabled = _useBiometrics;
      if (_fakePinController.text.isNotEmpty) {
        account.fakePin = _fakePinController.text;
      }
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
      SnackBar(content: Text(message), backgroundColor: Colors.red[900]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = textColor.withOpacity(0.5);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (widget.isFromSettings)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: hintColor, fontWeight: FontWeight.bold)),
            )
          else
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Secure your account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a 4-digit PIN for extra security.',
                style: TextStyle(fontSize: 16, color: hintColor),
              ),
              const SizedBox(height: 40),
              _buildPinField('Enter PIN', _pinController),
              const SizedBox(height: 24),
              _buildPinField('Confirm PIN', _confirmPinController),
              const SizedBox(height: 32),
              Text(
                'Fake Vault PIN (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a secondary PIN to open a dummy account under duress.',
                style: TextStyle(fontSize: 14, color: hintColor),
              ),
              const SizedBox(height: 16),
              _buildPinField('Fake PIN', _fakePinController),
              const SizedBox(height: 32),
              if (_canCheckBiometrics)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Enable Biometrics (Face ID / Fingerprint)',
                        style: TextStyle(fontSize: 14, color: textColor),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _useBiometrics,
                      onChanged: (val) async {
                        if (val) {
                          // 1. Validate PIN
                          final pin = _pinController.text;
                          final confirmPin = _confirmPinController.text;

                          if (pin.length != 4 || confirmPin.length != 4) {
                            _showError('Set your 4-digit PIN first.');
                            return;
                          }
                          if (pin != confirmPin) {
                            _showError('PINs do not match.');
                            return;
                          }

                          // 2. Perform verification scan
                          final canAuth = await SecurityService.canAuthenticateWithBiometrics();
                          if (!canAuth) {
                            _showError('Biometrics not available or not set up.');
                            return;
                          }

                          final success = await SecurityService.authenticateWithBiometrics(
                            reason: 'Verify your identity to enable biometric login.',
                          );

                          if (success) {
                            setState(() => _useBiometrics = true);
                          } else {
                            _showError('Biometric verification failed.');
                          }
                        } else {
                          setState(() => _useBiometrics = false);
                        }
                      },
                      activeColor: theme.primaryColor,
                    ),
                  ],
                ),
              const SizedBox(height: 48),
              GestureDetector(
                onTapDown: (_) => setState(() => _isButtonPressed = true),
                onTapUp: (_) => setState(() => _isButtonPressed = false),
                onTapCancel: () => setState(() => _isButtonPressed = false),
                onTap: _savePin,
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
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Finish Setup',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinField(String hint, TextEditingController controller) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = textColor.withOpacity(0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: hintColor)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: TextField(
            controller: controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            style: TextStyle(
                fontSize: 24, letterSpacing: 16, fontWeight: FontWeight.bold, color: textColor),
            decoration: InputDecoration(
                counterText: '', border: InputBorder.none, hintStyle: TextStyle(color: hintColor)),
          ),
        ),
      ],
    );
  }
}
