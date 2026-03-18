import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/session_service.dart';
import 'models/account.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  late Account _account;

  @override
  void initState() {
    super.initState();
    _account = SessionService.activeAccount!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Security Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionTitle('Authentication'),
          _buildSwitchTile(
            'Biometric Login',
            'Use fingerprint or face ID to unlock.',
            _account.isBiometricEnabled,
            (val) => setState(() => _account.isBiometricEnabled = val),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Protection'),
          _buildSwitchTile(
            'Data Wipe',
            'Wipe all data after ${_account.maxFailedAttempts} failed attempts.',
            _account.isWipeEnabled,
            (val) => setState(() => _account.isWipeEnabled = val),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Auto-Lock'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Lock After Inactivity'),
            subtitle: Text('${_account.autoLockDurationSeconds ~/ 60} minutes'),
            trailing: DropdownButton<int>(
              value: _account.autoLockDurationSeconds,
              items: [30, 60, 300, 600, 1800].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value < 60 ? '$value sec' : '${value ~/ 60} min'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _account.autoLockDurationSeconds = val);
                }
              },
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService.updateAccount(_account);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Security settings saved')),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Save Changes',
              style: TextStyle(color: theme.scaffoldBackgroundColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }
}
