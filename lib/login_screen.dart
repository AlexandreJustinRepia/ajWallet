import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/session_service.dart';
import 'services/security_service.dart';
import 'dashboard_screen.dart';
import 'models/account.dart';

class LoginScreen extends StatefulWidget {
  final Account account;
  const LoginScreen({super.key, required this.account});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _canCheckBiometrics = false;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    debugPrint('Checking biometrics for account: ${widget.account.name}');
    debugPrint('Is biometric enabled: ${widget.account.isBiometricEnabled}');
    
    if (!widget.account.isBiometricEnabled) return;

    // Small delay to ensure the screen is settled and avoid race conditions with platform channels
    await Future.delayed(const Duration(milliseconds: 500));

    final canCheck = await SecurityService.canAuthenticateWithBiometrics();
    debugPrint('Can authenticate with biometrics: $canCheck');
    
    if (!mounted) return;
    setState(() {
      _canCheckBiometrics = canCheck;
    });

    if (_canCheckBiometrics) {
      debugPrint('Triggering automatic biometric authentication...');
      _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isLocked) return;
    
    final authenticated = await SecurityService.authenticateWithBiometrics(
      reason: 'Authenticate to access ${widget.account.name}',
    );

    if (authenticated && mounted) {
      SessionService.setActiveAccount(widget.account);
      _navigateToDashboard();
    }
  }

  Future<void> _verifyPin() async {
    if (SecurityService.isLockedOut) {
      _showLockoutMessage();
      return;
    }

    final enteredPin = _pinController.text;
    final result = await SecurityService.verifyPin(enteredPin, widget.account);

    if (result == AuthResult.success) {
      SessionService.setActiveAccount(widget.account);
      _navigateToDashboard();
    } else if (result == AuthResult.fakeSuccess) {
      final fakeAccount = DatabaseService.getFakeAccount(widget.account.name);
      if (fakeAccount != null) {
        SessionService.setActiveAccount(fakeAccount);
        _navigateToDashboard();
      } else {
        // If fake account doesn't exist yet, just login to a clean state or show success
        SessionService.setActiveAccount(Account(name: '${widget.account.name} (Private)', isFake: true));
        _navigateToDashboard();
      }
    } else if (result == AuthResult.lockedOut) {
      if (widget.account.isWipeEnabled) {
        await SecurityService.wipeData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Security wipe triggered due to too many attempts.')),
          );
        }
      }
      setState(() => _isLocked = true);
      _showLockoutMessage();
    } else {
      setState(() {
        _pinController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incorrect PIN. ${widget.account.maxFailedAttempts - SecurityService.failedAttempts} attempts remaining.'),
          backgroundColor: Colors.red[900],
        ),
      );
    }
  }

  void _showLockoutMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Too many failed attempts. Locked out for ${SecurityService.remainingLockoutTime?.inMinutes ?? 5} minutes.'),
        backgroundColor: Colors.red[900],
      ),
    );
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Forgot PIN?'),
        content: const Text(
          'For security, offline data cannot be recovered without the PIN. '
          'You may need to delete this account and start over if you cannot remember it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
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
        leading: BackButton(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(Icons.lock_outline, size: 64, color: textColor),
              const SizedBox(height: 24),
              Text(
                'Welcome Back, ${widget.account.name}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your PIN to continue',
                style: TextStyle(fontSize: 16, color: hintColor),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _isLocked ? theme.colorScheme.error.withOpacity(0.1) : theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isLocked ? theme.colorScheme.error.withOpacity(0.5) : theme.dividerColor),
                ),
                child: TextField(
                  controller: _pinController,
                  enabled: !_isLocked,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    letterSpacing: 16,
                    fontWeight: FontWeight.bold,
                    color: _isLocked ? hintColor : textColor,
                  ),
                  onChanged: (value) {
                    if (value.length == 4) {
                      _verifyPin();
                    }
                  },
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: '••••',
                    hintStyle: TextStyle(color: hintColor, letterSpacing: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_canCheckBiometrics && !_isLocked)
                IconButton(
                  icon: Icon(Icons.fingerprint, size: 48, color: textColor),
                  onPressed: _authenticateWithBiometrics,
                ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _showForgotPinDialog,
                child: Text(
                  'Forgot PIN?',
                  style: TextStyle(color: hintColor, fontWeight: FontWeight.w600),
                ),
              ),
              if (_isLocked)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Security Lockout Active',
                    style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
