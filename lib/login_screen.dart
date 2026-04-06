import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/session_service.dart';
import 'services/security_service.dart';
import 'dashboard_screen.dart';
import 'pin_setup_screen.dart';
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
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Forgot PIN?', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Notice:',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'For your protection, all data is stored locally and encrypted. If you cannot remember your PIN, you must prove your identity or reset the account.',
              style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 13),
            ),
          ],
        ),
        actions: [
          Column(
            children: [
              if (widget.account.isBiometricEnabled && _canCheckBiometrics)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        
                        // Small delay to allow dialog to close before system prompt
                        await Future.delayed(const Duration(milliseconds: 300));
                        
                        final success = await SecurityService.authenticateWithBiometrics(
                          reason: 'Verify your identity to reset your PIN.',
                        );
                        
                        if (success) {
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PinSetupScreen(
                                  isFromSettings: true,
                                  isResetting: true,
                                  account: widget.account,
                                ),
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Biometric verification failed.')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Reset PIN via Biometrics'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _showDeleteAccountConfirmation();
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Reset Account (Wipe Data)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancel', style: TextStyle(color: textColor.withOpacity(0.5))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    showDialog(
      context: context,
      builder: (confContext) => AlertDialog(
        title: Text('Wipe Account Data?', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
        content: Text(
          'This will permanently delete all transactions, wallets, and settings for "${widget.account.name}". This action cannot be undone.',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confContext),
            child: Text('Cancel', style: TextStyle(color: textColor.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(confContext);
              await DatabaseService.wipeAccountData(widget.account.key as int);
              await DatabaseService.deleteAccount(widget.account);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account wiped and deleted.')),
                );
                Navigator.pop(context, true); // Return true to signal list refresh
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Wipe & Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
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
