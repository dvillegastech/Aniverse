import 'dart:io';
import 'package:flutter/material.dart';
import 'package:icloud_storage_sync/icloud_storage_sync.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'cloud_backup_service.dart';

/// Represents the status of iCloud availability and permissions
class ICloudStatus {
  final bool isAvailable;
  final bool isSignedIn;
  final bool hasPermission;
  final String? errorMessage;

  const ICloudStatus({
    required this.isAvailable,
    required this.isSignedIn,
    required this.hasPermission,
    this.errorMessage,
  });

  bool get isReady => isAvailable && isSignedIn && hasPermission;
}

/// Diagnostic information for iCloud setup
class ICloudDiagnostics {
  final String containerID;
  final String bundleIdentifier;
  final bool isIOSPlatform;
  final bool isMacOSPlatform;
  final List<String> entitlementContainers;
  final String? lastError;

  const ICloudDiagnostics({
    required this.containerID,
    required this.bundleIdentifier,
    required this.isIOSPlatform,
    required this.isMacOSPlatform,
    required this.entitlementContainers,
    this.lastError,
  });
}

class ICloudBackupService extends CloudBackupService {
  // Use the configured container but with Documents folder for visibility
  static const String _containerID = 'iCloud.com.dvillegas.mangayomi';
  static const String _backupFolder = 'Documents/Aniverse/Backups';
  
  final IcloudStorageSync _icloudSync = IcloudStorageSync();
  
  @override
  String get serviceName => 'iCloud';
  
  @override
  IconData get serviceIcon => Icons.cloud;
  
  @override
  bool get isAvailable => Platform.isIOS || Platform.isMacOS;
  
  @override
  Future<bool> isAuthenticated() async {
    debugPrint('🔍 Checking iCloud authentication...');

    if (!isAvailable) {
      debugPrint('❌ iCloud not available on this platform');
      return false;
    }

    // For simulator/emulator, return false since iCloud doesn't work
    if (Platform.isIOS) {
      try {
        // This will help identify if we're on simulator
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        if (iosInfo.isPhysicalDevice == false) {
          debugPrint('❌ iCloud not available on iOS Simulator');
          return false;
        }
        debugPrint('✅ Running on physical iOS device');
      } catch (e) {
        debugPrint('⚠️ Could not determine device type: $e');
      }
    }

    try {
      debugPrint('🔍 Testing container access with ID: $_containerID');
      // Check if iCloud is available by trying to get files
      final files = await _icloudSync.getCloudFiles(containerId: _containerID);
      debugPrint('✅ iCloud container accessible, found ${files.length} files');

      // Print some diagnostic info
      debugPrint('📋 Container contents:');
      for (final file in files.take(5)) { // Show first 5 files
        debugPrint('  - ${file.relativePath} (${file.sizeInBytes} bytes)');
      }
      if (files.length > 5) {
        debugPrint('  ... and ${files.length - 5} more files');
      }

      return true;
    } catch (e) {
      // Always return false if there's any error
      debugPrint('❌ Failed to access iCloud container: $e');

      // Try alternative container formats for debugging
      debugPrint('🔍 Trying alternative container formats...');
      try {
        final altFiles = await _icloudSync.getCloudFiles(containerId: 'iCloud.com.dvillegas.mangayomi');
        debugPrint('✅ Alternative format (private container) worked! Found ${altFiles.length} files');
      } catch (altE) {
        debugPrint('❌ Alternative format also failed: $altE');
      }

      return false;
    }
  }
  
  @override
  Future<bool> authenticate() async {
    // iCloud doesn't require explicit authentication on iOS
    // It uses the device's iCloud account
    return await isAuthenticated();
  }

  /// Check iCloud status and provide detailed error information
  Future<ICloudStatus> checkICloudStatus() async {
    if (!isAvailable) {
      return ICloudStatus(
        isAvailable: false,
        isSignedIn: false,
        hasPermission: false,
        errorMessage: 'iCloud is not available on this platform',
      );
    }

    try {
      await _icloudSync.getCloudFiles(containerId: _containerID);
      return ICloudStatus(
        isAvailable: true,
        isSignedIn: true,
        hasPermission: true,
        errorMessage: null,
      );
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      debugPrint('iCloud error details: $e');

      if (errorMessage.contains('invalid containerid') ||
          errorMessage.contains('invalid container') ||
          errorMessage.contains('container') && errorMessage.contains('invalid')) {
        return ICloudStatus(
          isAvailable: true,
          isSignedIn: true,
          hasPermission: false,
          errorMessage: 'Invalid container ID ($_containerID). Check app entitlements configuration and ensure container is properly configured in Apple Developer Console.',
        );
      } else if (errorMessage.contains('not signed in') ||
                 errorMessage.contains('user is not signed in')) {
        return ICloudStatus(
          isAvailable: true,
          isSignedIn: false,
          hasPermission: false,
          errorMessage: 'User is not signed in to iCloud. Please sign in through Settings > [Your Name] > iCloud.',
        );
      } else if (errorMessage.contains('disabled icloud permission') ||
                 errorMessage.contains('permission') && errorMessage.contains('disabled')) {
        return ICloudStatus(
          isAvailable: true,
          isSignedIn: true,
          hasPermission: false,
          errorMessage: 'iCloud permission is disabled for this app. Enable it in Settings > [Your Name] > iCloud > Apps Using iCloud.',
        );
      } else {
        return ICloudStatus(
          isAvailable: true,
          isSignedIn: false,
          hasPermission: false,
          errorMessage: 'iCloud error: ${e.toString()}. Container ID: $_containerID',
        );
      }
    }
  }

  /// Get detailed diagnostic information for troubleshooting
  Future<ICloudDiagnostics> getDiagnostics() async {
    String? lastError;

    try {
      await _icloudSync.getCloudFiles(containerId: _containerID);
    } catch (e) {
      lastError = e.toString();
    }

    return ICloudDiagnostics(
      containerID: _containerID,
      bundleIdentifier: 'com.dvillegas.mangayomi', // This should match your actual bundle ID
      isIOSPlatform: Platform.isIOS,
      isMacOSPlatform: Platform.isMacOS,
      entitlementContainers: ['iCloud.com.dvillegas.mangayomi'], // From entitlements
      lastError: lastError,
    );
  }

  /// Print comprehensive diagnostic information
  Future<void> printDiagnostics() async {
    final diagnostics = await getDiagnostics();
    final status = await checkICloudStatus();

    debugPrint('=== iCloud Diagnostics ===');
    debugPrint('Container ID: ${diagnostics.containerID}');
    debugPrint('Bundle ID: ${diagnostics.bundleIdentifier}');
    debugPrint('Platform: iOS=${diagnostics.isIOSPlatform}, macOS=${diagnostics.isMacOSPlatform}');
    debugPrint('Entitlement Containers: ${diagnostics.entitlementContainers}');
    debugPrint('Service Available: ${isAvailable}');
    debugPrint('Status: Available=${status.isAvailable}, SignedIn=${status.isSignedIn}, HasPermission=${status.hasPermission}');
    debugPrint('Status Ready: ${status.isReady}');
    debugPrint('Status Error: ${status.errorMessage}');
    debugPrint('Last Error: ${diagnostics.lastError}');
    debugPrint('========================');

    // Provide troubleshooting suggestions
    if (!status.isReady) {
      debugPrint('=== Troubleshooting Suggestions ===');

      if (!status.isSignedIn) {
        debugPrint('1. Sign in to iCloud: Settings > [Your Name] > Sign In');
      }

      if (!status.hasPermission) {
        debugPrint('2. Enable iCloud for this app: Settings > [Your Name] > iCloud > Apps Using iCloud > Aniverse');
        debugPrint('3. Check that iCloud Drive is enabled: Settings > [Your Name] > iCloud > iCloud Drive');
      }

      if (diagnostics.lastError?.toLowerCase().contains('container') == true) {
        debugPrint('4. Container issue detected:');
        debugPrint('   - Ensure the app is properly signed with the correct provisioning profile');
        debugPrint('   - Verify the container "${diagnostics.containerID}" exists in Apple Developer Console');
        debugPrint('   - Check that the container is associated with your App ID');
      }

      debugPrint('================================');
    }
  }

  /// Alternative method to test iCloud connectivity with different approaches
  Future<void> testICloudConnectivity() async {
    debugPrint('=== Testing iCloud Connectivity ===');

    // Test 1: Try with the configured container
    debugPrint('Test 1: Using configured container ID: $_containerID');
    try {
      final files = await _icloudSync.getCloudFiles(containerId: _containerID);
      debugPrint('✅ Success: Found ${files.length} files');
    } catch (e) {
      debugPrint('❌ Failed: $e');
    }

    // Test 2: Try with a simpler container format
    debugPrint('Test 2: Attempting with alternative container format...');
    try {
      // Try without the iCloud prefix
      final files = await _icloudSync.getCloudFiles(containerId: 'com.dvillegas.mangayomi');
      debugPrint('✅ Success with alternative format: Found ${files.length} files');
    } catch (e) {
      debugPrint('❌ Failed with alternative format: $e');
    }

    debugPrint('=================================');
  }
  
  @override
  Future<void> signOut() async {
    // iCloud uses system account, no sign out needed
  }
  
  @override
  Future<void> uploadBackup(String localPath, {Function(double)? onProgress}) async {
    debugPrint('🔵 Starting iCloud upload for: $localPath');

    if (!await isAuthenticated()) {
      throw Exception('iCloud not available');
    }

    final file = File(localPath);
    final fileName = 'aniverse_backup_${DateTime.now().millisecondsSinceEpoch}.backup';
    final destinationPath = '$_backupFolder/$fileName';

    debugPrint('🔵 Container ID: $_containerID');
    debugPrint('🔵 Destination path: $destinationPath');
    debugPrint('🔵 File size: ${file.lengthSync()} bytes');

    try {
      // First, let's test if we can list files to verify container access
      debugPrint('🔵 Testing container access...');
      final existingFiles = await _icloudSync.getCloudFiles(containerId: _containerID);
      debugPrint('🔵 Found ${existingFiles.length} existing files in container');

      debugPrint('🔵 Starting upload...');
      await _icloudSync.upload(
        containerId: _containerID,
        filePath: localPath,
        destinationRelativePath: destinationPath,
        onProgress: onProgress != null ? (stream) {
          stream.listen(
            (progress) {
              onProgress(progress);
              debugPrint('iCloud upload progress: ${(progress * 100).toStringAsFixed(1)}%');
            },
          );
        } : null,
      );

      debugPrint('🔵 Upload completed, saving metadata...');

      // Save metadata
      final metadata = {
        'deviceId': await _getDeviceId(),
        'appVersion': await _getAppVersion(),
        'backupVersion': '2',
        'createdAt': DateTime.now().toIso8601String(),
        'sizeInBytes': file.lengthSync(),
      };

      await _saveMetadata(fileName, metadata);

      debugPrint('🔵 Metadata saved, verifying upload...');

      // Verify the file was uploaded
      final filesAfterUpload = await _icloudSync.getCloudFiles(containerId: _containerID);
      final uploadedFile = filesAfterUpload.where((f) => f.relativePath?.endsWith(fileName) ?? false).firstOrNull;

      if (uploadedFile != null) {
        debugPrint('✅ Upload verified! File found at: ${uploadedFile.relativePath}');
        debugPrint('✅ File size: ${uploadedFile.sizeInBytes} bytes');
      } else {
        debugPrint('❌ Upload verification failed - file not found in container');
        // List all files to see what's actually there
        debugPrint('📋 All files in container:');
        for (final f in filesAfterUpload) {
          debugPrint('  - ${f.relativePath} (${f.sizeInBytes} bytes)');
        }
      }

    } catch (e) {
      debugPrint('❌ iCloud upload failed: $e');
      throw Exception('Failed to upload backup to iCloud: $e');
    }
  }
  
  @override
  Future<List<CloudBackupInfo>> listBackups() async {
    if (!await isAuthenticated()) {
      return [];
    }
    
    try {
      final files = await _icloudSync.getCloudFiles(
        containerId: _containerID,
      );
      
      final backupFiles = files.where((file) => 
        (file.relativePath?.startsWith(_backupFolder) ?? false) &&
        (file.relativePath?.endsWith('.backup') ?? false)
      ).toList();
      
      final backups = <CloudBackupInfo>[];
      
      for (final file in backupFiles) {
        final fileName = file.relativePath?.split('/').last ?? '';
        final metadata = await _loadMetadata(fileName);
        
        backups.add(CloudBackupInfo(
          id: fileName,
          name: fileName,
          createdAt: file.fileDate ?? DateTime.now(),
          modifiedAt: file.lastSyncDt ?? DateTime.now(),
          sizeInBytes: file.sizeInBytes,
          metadata: metadata,
        ));
      }
      
      // Sort by creation date, newest first
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return backups;
    } catch (e) {
      debugPrint('Failed to list iCloud backups: $e');
      return [];
    }
  }
  
  @override
  Future<void> downloadBackup(String backupId, String localPath, {Function(double)? onProgress}) async {
    if (!await isAuthenticated()) {
      throw Exception('iCloud not available');
    }
    
    try {
      // Download the file directly to the specified local path
      await _icloudSync.download(
        containerId: _containerID,
        relativePath: '$_backupFolder/$backupId',
        destinationFilePath: localPath,
        onProgress: onProgress != null ? (stream) {
          stream.listen(
            (progress) {
              onProgress(progress);
              debugPrint('iCloud download progress: ${(progress * 100).toStringAsFixed(1)}%');
            },
          );
        } : null,
      );
      
      debugPrint('Successfully downloaded backup from iCloud: $backupId');
    } catch (e) {
      throw Exception('Failed to download backup from iCloud: $e');
    }
  }
  
  @override
  Future<void> deleteBackup(String backupId) async {
    if (!await isAuthenticated()) {
      throw Exception('iCloud not available');
    }
    
    try {
      await _icloudSync.delete(
        containerId: _containerID,
        relativePath: '$_backupFolder/$backupId',
      );
      
      // Delete metadata
      await _icloudSync.delete(
        containerId: _containerID,
        relativePath: '$_backupFolder/$backupId.meta',
      );
    } catch (e) {
      throw Exception('Failed to delete backup from iCloud: $e');
    }
  }
  
  @override
  Future<CloudBackupInfo?> getLatestBackup() async {
    final backups = await listBackups();
    return backups.isNotEmpty ? backups.first : null;
  }
  
  @override
  Future<bool> hasNewerBackup(DateTime lastSyncTime) async {
    final latest = await getLatestBackup();
    return latest != null && latest.modifiedAt.isAfter(lastSyncTime);
  }
  
  // Helper methods
  Future<void> _saveMetadata(String fileName, Map<String, dynamic> metadata) async {
    final metadataContent = metadata.entries
        .map((e) => '${e.key}=${e.value}')
        .join('\n');
    
    final tempFile = File('${Directory.systemTemp.path}/$fileName.meta');
    await tempFile.writeAsString(metadataContent);
    
    try {
      await _icloudSync.upload(
        containerId: _containerID,
        filePath: tempFile.path,
        destinationRelativePath: '$_backupFolder/$fileName.meta',
      );
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }
  
  Future<Map<String, dynamic>?> _loadMetadata(String fileName) async {
    try {
      // Create temp file path for metadata
      final tempFile = File('${Directory.systemTemp.path}/$fileName.meta');
      
      // Download metadata file to temp location
      await _icloudSync.download(
        containerId: _containerID,
        relativePath: '$_backupFolder/$fileName.meta',
        destinationFilePath: tempFile.path,
      );
      
      // Check if file was downloaded
      if (!await tempFile.exists()) {
        debugPrint('No metadata found for $fileName');
        return null;
      }
      
      // Read and parse metadata
      final metadataContent = await tempFile.readAsString();
      final metadata = <String, dynamic>{};
      
      for (final line in metadataContent.split('\n')) {
        if (line.contains('=')) {
          final parts = line.split('=');
          if (parts.length == 2) {
            metadata[parts[0]] = parts[1];
          }
        }
      }
      
      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      return metadata.isNotEmpty ? metadata : null;
    } catch (e) {
      // If download fails, return basic metadata
      debugPrint('Failed to load metadata: $e');
      return {
        'backupVersion': '2',
        'createdAt': DateTime.now().toIso8601String(),
      };
    }
  }
  
  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'ios_unknown';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return macInfo.systemGUID ?? 'macos_unknown';
      }
      
      return 'unknown_device';
    } catch (e) {
      return 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      return '1.0.0';
    }
  }
}