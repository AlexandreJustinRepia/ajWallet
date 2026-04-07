import 'package:flutter_test/flutter_test.dart';
import 'package:aj_wallet/services/update_service.dart';

void main() {
  group('UpdateService', () {
    test('isVersionNewer handles basic semantic versions', () {
      expect(UpdateService.isVersionNewer('1.0.1', '1.0.0'), isTrue);
      expect(UpdateService.isVersionNewer('1.1.0', '1.0.9'), isTrue);
      expect(UpdateService.isVersionNewer('2.0.0', '1.9.9'), isTrue);
      
      expect(UpdateService.isVersionNewer('1.0.0', '1.0.1'), isFalse);
      expect(UpdateService.isVersionNewer('1.0.0', '1.1.0'), isFalse);
      expect(UpdateService.isVersionNewer('1.0.0', '1.0.0'), isFalse);
    });

    test('isVersionNewer handles differing version lengths', () {
      expect(UpdateService.isVersionNewer('1.1', '1.1.0'), isFalse);
      expect(UpdateService.isVersionNewer('1.1.1', '1.1'), isTrue);
    });

    group('UpdateInfo.fromJson resilience', () {
      test('handles standard JSON correctly', () {
        final json = {
          'latest_version': '1.2.3',
          'build_number': 42,
          'download_url': 'https://example.com/app.apk',
          'release_notes': 'Bug fixes'
        };
        final info = UpdateInfo.fromJson(json);
        
        expect(info.latestVersion, '1.2.3');
        expect(info.buildNumber, 42);
        expect(info.downloadUrl, 'https://example.com/app.apk');
        expect(info.releaseNotes, 'Bug fixes');
      });

      test('provides defaults for missing fields', () {
        final json = <String, dynamic>{};
        final info = UpdateInfo.fromJson(json);
        
        expect(info.latestVersion, '1.0.0');
        expect(info.buildNumber, 1);
        expect(info.downloadUrl, '');
        expect(info.releaseNotes, '');
      });

      test('handles partial JSON', () {
        final json = {'latest_version': '2.0.0'};
        final info = UpdateInfo.fromJson(json);
        
        expect(info.latestVersion, '2.0.0');
        expect(info.buildNumber, 1);
        expect(info.downloadUrl, '');
      });
    });
  });
}
