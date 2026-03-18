import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'services/database_service.dart';
import 'services/session_service.dart';
import 'dashboard_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _fakePinController = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isButtonPressed = false;
  bool _canCheckBiometrics = false;
  bool _useBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics = await _auth.canCheckBiometrics;
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
    }
    if (!mounted) return;
    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
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

    final account = DatabaseService.getLatestAccount();
    if (account != null) {
      account.pin = pin;
      account.isBiometricEnabled = _useBiometrics;
      if (_fakePinController.text.isNotEmpty) {
        account.fakePin = _fakePinController.text;
      }
      await DatabaseService.updateAccount(account);
      SessionService.setActiveAccount(account);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Secure your account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter a 4-digit PIN for extra security.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              _buildPinField('Enter PIN', _pinController),
              const SizedBox(height: 24),
              _buildPinField('Confirm PIN', _confirmPinController),
              const SizedBox(height: 32),
              const Text(
                'Fake Vault PIN (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter a secondary PIN to open a dummy account under duress.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildPinField('Fake PIN', _fakePinController),
              const SizedBox(height: 32),
              if (_canCheckBiometrics)
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Enable Biometrics (Face ID / Fingerprint)',
                        style: TextStyle(fontSize: 14),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _useBiometrics,
                      onChanged: (val) => setState(() => _useBiometrics = val),
                      activeColor: Colors.black,
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
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Finish Setup',
                        style: TextStyle(
                          color: Colors.white,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            style: const TextStyle(
                fontSize: 24, letterSpacing: 16, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
                counterText: '', border: InputBorder.none),
          ),
        ),
      ],
    );
  }
}
