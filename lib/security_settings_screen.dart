import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/session_service.dart';
import 'services/backup_service.dart';
import 'models/account.dart';
import 'login_screen.dart';
import 'pin_setup_screen.dart';

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
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.password_rounded, color: theme.primaryColor),
            title: Text(_account.pin == null || _account.pin!.isEmpty ? 'Set PIN' : 'Change PIN'),
            subtitle: Text(_account.pin == null || _account.pin!.isEmpty 
                ? 'Create a 4-digit PIN for offline security.' 
                : 'Update your current vault sequence.'),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (c) => const PinSetupScreen(isFromSettings: true)));
              setState(() {
                _account = SessionService.activeAccount!;
              });
            },
          ),
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
          const SizedBox(height: 16),
          _buildSectionTitle('Data Management'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.cloud_upload_outlined, color: theme.primaryColor),
            title: const Text('Export Backup'),
            subtitle: const Text('Encrypt and save your data offline.'),
            onTap: () => _handleBackup(context, isExport: true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.cloud_download_outlined, color: theme.primaryColor),
            title: const Text('Import Backup'),
            subtitle: const Text('Restore data from an encrypted file.'),
            onTap: () => _handleBackup(context, isExport: false),
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

  Future<void> _handleBackup(BuildContext context, {required bool isExport}) async {
    final theme = Theme.of(context);
    final pinController = TextEditingController();

    final pinConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isExport ? 'Export Backup' : 'Import Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isExport 
                ? 'Enter your PIN to encrypt the backup file.' 
                : 'Enter the PIN used to encrypt this backup.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                hintText: 'Enter 4-digit PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isExport ? 'Export' : 'Import'),
          ),
        ],
      ),
    );

    if (pinConfirmed == true && pinController.text.length == 4) {
      if (isExport) {
        final success = await BackupService.exportBackup(pinController.text, _account.key as int);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(success ? 'Backup exported successfully' : 'Export failed')),
          );
        }
      } else {
        final success = await BackupService.importBackup(pinController.text);
        if (mounted) {
          if (success) {
            final restoredAccount = DatabaseService.getLatestAccount();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data restored successfully.')),
            );
            
            if (restoredAccount != null) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen(account: restoredAccount)),
                (route) => false,
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Import failed. Check your PIN or file integrity.')),
            );
          }
        }
      }
    }
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
