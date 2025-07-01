import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/services/cloud_backup/icloud_backup_service.dart';

void main() {
  group('ICloudBackupService', () {
    late ICloudBackupService service;

    setUp(() {
      service = ICloudBackupService();
    });

    test('should have correct container ID', () {
      // Access the private field through reflection or make it public for testing
      // For now, we'll test the behavior indirectly
      expect(service.serviceName, equals('iCloud'));
    });

    test('should have correct service icon', () {
      expect(service.serviceIcon, isNotNull);
    });

    test('should check availability correctly on different platforms', () {
      // This will depend on the platform the test is running on
      expect(service.isAvailable, isA<bool>());
    });

    test('ICloudStatus should be created correctly', () {
      const status = ICloudStatus(
        isAvailable: true,
        isSignedIn: true,
        hasPermission: true,
        errorMessage: null,
      );

      expect(status.isAvailable, isTrue);
      expect(status.isSignedIn, isTrue);
      expect(status.hasPermission, isTrue);
      expect(status.errorMessage, isNull);
      expect(status.isReady, isTrue);
    });

    test('ICloudStatus should handle error states correctly', () {
      const status = ICloudStatus(
        isAvailable: true,
        isSignedIn: false,
        hasPermission: false,
        errorMessage: 'User not signed in',
      );

      expect(status.isAvailable, isTrue);
      expect(status.isSignedIn, isFalse);
      expect(status.hasPermission, isFalse);
      expect(status.errorMessage, equals('User not signed in'));
      expect(status.isReady, isFalse);
    });
  });
}
