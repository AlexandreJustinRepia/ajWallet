import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String latestVersion;
  final int buildNumber;
  final String downloadUrl;
  final String releaseNotes;

  UpdateInfo({
    required this.latestVersion,
    required this.buildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion: json['latest_version'] ?? '1.0.0',
      buildNumber: json['build_number'] ?? 1,
      downloadUrl: json['download_url'] ?? '',
      releaseNotes: json['release_notes'] ?? '',
    );
  }
}

class UpdateService {
  static const String _versionUrl = 'https://raw.githubusercontent.com/AlexandreJustinRepia/RootEXP/main/version.json';
  
  static final ValueNotifier<UpdateInfo?> updateNotifier = ValueNotifier<UpdateInfo?>(null);
  static final Connectivity _connectivity = Connectivity();

  static Future<void> init() async {
    // Check initially
    _checkUpdate();

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        _checkUpdate();
      }
    });
  }

  static Future<void> _checkUpdate() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty || results.contains(ConnectivityResult.none)) return;

      final response = await http.get(Uri.parse(_versionUrl));
      if (response.statusCode == 200) {
        final updateInfo = UpdateInfo.fromJson(jsonDecode(response.body));
        final packageInfo = await PackageInfo.fromPlatform();
        
        final currentVersion = packageInfo.version;
        final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

        bool hasUpdate = isVersionNewer(updateInfo.latestVersion, currentVersion) || 
                         (updateInfo.latestVersion == currentVersion && updateInfo.buildNumber > currentBuild);

        if (hasUpdate) {
          updateNotifier.value = updateInfo;
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  static bool isVersionNewer(String latest, String current) {
    List<int> latestParts = latest.split('.').map(int.parse).toList();
    List<int> currentParts = current.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return latestParts.length > currentParts.length;
  }

  static Future<void> launchDownload() async {
    if (updateNotifier.value != null) {
      final url = Uri.parse(updateNotifier.value!.downloadUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }
}
