import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/session_service.dart';
import 'services/backup_service.dart';
import 'services/security_service.dart';
import 'models/account.dart';
import 'models/backup_history.dart';
import 'pin_setup_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  late Account _account;
  List<BackupHistory> _backupHistory = [];

  @override
  void initState() {
    super.initState();
    _account = SessionService.activeAccount!;
    _backupHistory = DatabaseService.getBackupHistory(_account.key as int);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Security Settings'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionTitle('Authentication'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.password_rounded, color: theme.primaryColor),
            title: Text(
              _account.pin == null || _account.pin!.isEmpty
                  ? 'Set PIN'
                  : 'Change PIN',
            ),
            subtitle: Text(
              _account.pin == null || _account.pin!.isEmpty
                  ? 'Create a 4-digit PIN for offline security.'
                  : 'Update your current vault sequence.',
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => const PinSetupScreen(isFromSettings: true),
                ),
              );
              setState(() {
                _account = SessionService.activeAccount!;
              });
            },
          ),
          _buildSwitchTile(
            'Biometric Login',
            'Use fingerprint or face ID to unlock.',
            _account.isBiometricEnabled,
            (val) async {
              if (val) {
                // If there's no PIN set, we shouldn't allow biometrics
                if (_account.pin == null || _account.pin!.isEmpty) {
                  _showPinRequiredDialog();
                  return;
                }

                final canAuth =
                    await SecurityService.canAuthenticateWithBiometrics();
                if (!canAuth) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Biometrics not available or not set up.',
                        ),
                      ),
                    );
                  }
                  return;
                }

                final success =
                    await SecurityService.authenticateWithBiometrics(
                      reason: 'Verify your identity to enable biometric login.',
                    );

                if (success) {
                  setState(() => _account.isBiometricEnabled = true);
                  await DatabaseService.updateAccount(_account);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Biometric verification failed.'),
                      ),
                    );
                  }
                }
              } else {
                setState(() => _account.isBiometricEnabled = false);
                await DatabaseService.updateAccount(_account);
              }
            },
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Protection'),
          _buildSwitchTile(
            'Data Wipe',
            'Wipe all data after ${_account.maxFailedAttempts} failed attempts.',
            _account.isWipeEnabled,
            (val) async {
              setState(() => _account.isWipeEnabled = val);
              await DatabaseService.updateAccount(_account);
            },
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
              onChanged: (val) async {
                if (val != null) {
                  setState(() => _account.autoLockDurationSeconds = val);
                  await DatabaseService.updateAccount(_account);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Data Management'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.cloud_upload_outlined,
              color: theme.primaryColor,
            ),
            title: const Text('Export Backup'),
            subtitle: const Text('Encrypt and save your data offline.'),
            onTap: () => _handleBackup(context, isExport: true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.cloud_download_outlined,
              color: theme.primaryColor,
            ),
            title: const Text('Import Backup'),
            subtitle: const Text('Restore data from an encrypted file.'),
            onTap: () => _handleBackup(context, isExport: false),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Backup History'),
          _buildBackupHistoryList(),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Save Changes',
              style: TextStyle(
                color: theme.scaffoldBackgroundColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackup(
    BuildContext context, {
    required bool isExport,
  }) async {
    final theme = Theme.of(context);
    final pinController = TextEditingController();

    bool hasPin = _account.pin != null && _account.pin!.isNotEmpty;
    bool hasBio = _account.isBiometricEnabled;
    bool needsAuth = hasPin || hasBio;

    String pinToUse;
    if (!needsAuth) {
      pinToUse = BackupService.defaultPin;
    } else {
      bool useBiometric = false;
      final pinConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(isExport ? 'Export Backup' : 'Import Backup'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isExport
                      ? 'Authenticate to encrypt the backup file.'
                      : 'Enter the PIN used to encrypt this backup or use biometric.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                if (!useBiometric)
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
                if (hasBio && !useBiometric) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final success =
                          await SecurityService.authenticateWithBiometrics(
                        reason:
                            'Authenticate to ${isExport ? 'export' : 'import'} backup.',
                      );
                      if (success) {
                        setState(() => useBiometric = true);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Biometric authentication failed.'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Use Biometric'),
                  ),
                ],
                if (useBiometric)
                  const Text(
                    'Biometric authentication successful.',
                    style: TextStyle(color: Colors.green),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(isExport ? 'Export' : 'Import'),
              ),
            ],
          ),
        ),
      );

      if (pinConfirmed != true) return;

      if (useBiometric) {
        pinToUse = _account.pin!;
      } else {
        final enteredPin = pinController.text;
        if (enteredPin.length != 4) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter a 4-digit PIN.')),
            );
          }
          return;
        }
        if (isExport && hasPin && enteredPin != _account.pin) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incorrect PIN. Export aborted.')),
            );
          }
          return;
        }
        pinToUse = enteredPin;
      }
    }

    if (isExport) {
      final success = await BackupService.exportBackup(
        pinToUse,
        _account.key as int,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Backup exported successfully' : 'Export failed',
            ),
          ),
        );
        _refreshBackupHistory();
      }
    } else {
      final success = await BackupService.importBackup(
        pinToUse,
        _account.key as int,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data restored successfully into this account.'),
            ),
          );
          setState(() {
            _account = SessionService.activeAccount!;
          });
          _refreshBackupHistory();
          if (mounted) Navigator.pop(context, true);
        } else {
          _refreshBackupHistory();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Import failed. Check your PIN or file integrity.',
              ),
            ),
          );
        }
      }
    }
  }

  void _refreshBackupHistory() {
    setState(() {
      _backupHistory = DatabaseService.getBackupHistory(_account.key as int);
    });
  }

  Widget _buildBackupHistoryList() {
    if (_backupHistory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          'No backup history yet.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      );
    }

    return Column(
      children: _backupHistory.map((history) {
        final icon = history.type == 'export' ? Icons.upload_file : Icons.download;
        final color = history.success ? Colors.green : Colors.red;
        final status = history.success ? 'Success' : 'Failed';
        final typeLabel = history.type == 'export' ? 'Export' : 'Import';
        final formattedDate = history.timestamp.toLocal().toString().split('.').first;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(icon, color: color),
            title: Text('$typeLabel • $status'),
            subtitle: Text(
              '$formattedDate${history.filePath != null ? '\n${history.filePath}' : ''}',
            ),
            isThreeLine: history.filePath != null,
          ),
        );
      }).toList(),
    );
  }

  void _showPinRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'PIN Required',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'A backup PIN must be set before you can enable biometric login. This ensures you can always access your vault.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Not Now', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const PinSetupScreen(isFromSettings: true),
                ),
              );
              // Refresh account status after returning from setup
              setState(() {
                _account = SessionService.activeAccount!;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Set PIN Now',
              style: TextStyle(color: Colors.white),
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
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }
}
