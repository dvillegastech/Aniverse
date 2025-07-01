import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/services/cloud_backup/google_drive_backup_service.dart';

void main() {
  group('GoogleDriveBackupService', () {
    late GoogleDriveBackupService service;

    setUp(() {
      service = GoogleDriveBackupService();
    });

    test('should have correct service name', () {
      expect(service.serviceName, equals('Google Drive'));
    });

    test('should have correct service icon', () {
      expect(service.serviceIcon, isNotNull);
    });

    test('should be available on all platforms', () {
      expect(service.isAvailable, isTrue);
    });

    test('should handle authentication gracefully when not configured', () async {
      // This test will pass even if Google Sign In is not configured
      // because we're testing the error handling
      final isAuthenticated = await service.isAuthenticated();
      expect(isAuthenticated, isA<bool>());
    });

    test('should check configuration without crashing', () async {
      // This should not crash even if not properly configured
      final isConfigured = await service.isConfigured();
      expect(isConfigured, isA<bool>());
    });
  });
}
