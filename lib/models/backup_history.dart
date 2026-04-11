class BackupHistory {
  int? key;
  int accountKey;
  String type; // "export" or "import"
  DateTime timestamp;
  String? filePath;
  bool success;

  BackupHistory({
    this.key,
    required this.accountKey,
    required this.type,
    required this.timestamp,
    this.filePath,
    required this.success,
  });

  Map<String, dynamic> toMap() => {
        'key': key,
        'accountKey': accountKey,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'filePath': filePath,
        'success': success,
      };

  factory BackupHistory.fromMap(Map<String, dynamic> map) {
    return BackupHistory(
      key: map['key'],
      accountKey: map['accountKey'],
      type: map['type'],
      timestamp: DateTime.parse(map['timestamp']),
      filePath: map['filePath'],
      success: map['success'],
    );
  }
}