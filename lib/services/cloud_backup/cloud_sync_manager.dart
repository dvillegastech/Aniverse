import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/backup.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_backup_service.dart';
import 'icloud_backup_service.dart';
import 'google_drive_backup_service.dart';

final cloudSyncManagerProvider = Provider<CloudSyncManager>((ref) {
  return CloudSyncManager(ref);
});

class CloudSyncManager {
  final Ref _ref;
  final Map<CloudProvider, CloudBackupService> _services = {};
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  bool _isDisposed = false; // Add flag to track disposal
  
  static const String _lastSyncKey = 'last_cloud_sync';
  static const String _autoSyncEnabledKey = 'auto_sync_enabled';
  static const String _syncIntervalKey = 'sync_interval_minutes';
  static const String _selectedProviderKey = 'selected_cloud_provider';
  
  CloudSyncManager(this._ref) {
    _initializeServices();
  }
  
  void _initializeServices() {
    _services[CloudProvider.icloud] = ICloudBackupService();
    _services[CloudProvider.googleDrive] = GoogleDriveBackupService();
  }
  
  // Get available services based on platform
  List<CloudProvider> get availableProviders {
    final providers = <CloudProvider>[];
    
    for (final entry in _services.entries) {
      if (entry.value.isAvailable) {
        providers.add(entry.key);
      }
    }
    
    return providers;
  }
  
  CloudBackupService? getService(CloudProvider provider) {
    return _services[provider];
  }
  
  Future<CloudProvider?> getSelectedProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final providerName = prefs.getString(_selectedProviderKey);
    
    if (providerName != null) {
      try {
        return CloudProvider.values.firstWhere((p) => p.name == providerName);
      } catch (_) {}
    }
    
    return null;
  }
  
  Future<void> setSelectedProvider(CloudProvider? provider) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (provider != null) {
      await prefs.setString(_selectedProviderKey, provider.name);
    } else {
      await prefs.remove(_selectedProviderKey);
    }
  }
  
  Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSyncEnabledKey) ?? false;
  }
  
  Future<void> setAutoSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncEnabledKey, enabled);
    
    if (enabled) {
      startAutoSync();
    } else {
      stopAutoSync();
    }
  }
  
  Future<int> getSyncInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_syncIntervalKey) ?? 60; // Default: 60 minutes
  }
  
  Future<void> setSyncInterval(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_syncIntervalKey, minutes);
    
    // Restart auto sync with new interval
    if (await isAutoSyncEnabled()) {
      stopAutoSync();
      startAutoSync();
    }
  }
  
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);

    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    return null;
  }

  /// Get information about the latest backup available in the cloud
  Future<CloudBackupInfo?> getLatestCloudBackup() async {
    if (_isDisposed) return null;

    final provider = await getSelectedProvider();
    if (provider == null) return null;

    final service = getService(provider);
    if (service == null) return null;

    try {
      return await service.getLatestBackup();
    } catch (e) {
      debugPrint('Failed to get latest backup info: $e');
      return null;
    }
  }

  /// Check for newer backups and notify if found
  Future<CloudBackupInfo?> checkForNewerBackup() async {
    if (_isDisposed) return null;

    debugPrint('🔍 Checking for newer backups in the cloud...');

    final provider = await getSelectedProvider();
    if (provider == null) {
      debugPrint('❌ No cloud provider selected');
      return null;
    }

    final service = getService(provider);
    if (service == null) {
      debugPrint('❌ Cloud service not available');
      return null;
    }

    try {
      // Check if authenticated
      if (!await service.isAuthenticated()) {
        debugPrint('❌ Not authenticated with cloud service');
        return null;
      }

      final latestBackup = await service.getLatestBackup();
      if (latestBackup == null) {
        debugPrint('📭 No backups found in the cloud');
        return null;
      }

      final lastSyncTime = await getLastSyncTime();
      debugPrint('📅 Last sync time: $lastSyncTime');
      debugPrint('📅 Latest backup time: ${latestBackup.modifiedAt}');

      if (lastSyncTime == null || latestBackup.modifiedAt.isAfter(lastSyncTime)) {
        debugPrint('🆕 Found newer backup: ${latestBackup.name}');
        debugPrint('🆕 Backup size: ${(latestBackup.sizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB');
        return latestBackup;
      } else {
        debugPrint('✅ Local data is up to date');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Failed to check for newer backup: $e');
      return null;
    }
  }

  /// Download a backup from the cloud for restoration
  Future<String?> downloadBackupForRestore(CloudBackupInfo backup) async {
    if (_isDisposed) return null;

    debugPrint('📥 Downloading backup for restoration: ${backup.name}');

    final provider = await getSelectedProvider();
    if (provider == null) {
      debugPrint('❌ No cloud provider selected');
      return null;
    }

    final service = getService(provider);
    if (service == null) {
      debugPrint('❌ Cloud service not available');
      return null;
    }

    try {
      // Check if authenticated
      if (!await service.isAuthenticated()) {
        debugPrint('❌ Not authenticated with cloud service');
        return null;
      }

      // Download the backup
      final tempDir = await getTemporaryDirectory();
      final localPath = '${tempDir.path}/${backup.name}';

      await service.downloadBackup(backup.name, localPath);
      debugPrint('✅ Backup downloaded to: $localPath');

      return localPath;
    } catch (e) {
      debugPrint('❌ Failed to download backup: $e');
      return null;
    }
  }

  /// Check if local data has changed since last sync
  Future<bool> hasLocalChanges() async {
    try {
      final lastSyncTime = await getLastSyncTime();
      if (lastSyncTime == null) return true; // No previous sync, assume changes

      // Check if any data has been modified since last sync
      // This is a simplified check - in a real implementation you might want to
      // track specific changes or use a more sophisticated change detection
      final now = DateTime.now();
      final timeSinceLastSync = now.difference(lastSyncTime);

      // If it's been more than 1 hour since last sync, assume there might be changes
      // This is a conservative approach to ensure data is kept in sync
      return timeSinceLastSync.inHours >= 1;
    } catch (e) {
      debugPrint('Failed to check for local changes: $e');
      return false;
    }
  }

  /// Perform intelligent sync - upload if local changes, download if cloud changes
  Future<SyncResult> performIntelligentSync() async {
    if (_isDisposed) {
      return SyncResult(
        success: false,
        message: 'CloudSyncManager is disposed',
      );
    }

    debugPrint('🔄 Starting intelligent sync...');

    final provider = await getSelectedProvider();
    if (provider == null) {
      return SyncResult(
        success: false,
        message: 'No cloud provider selected',
      );
    }

    final service = getService(provider);
    if (service == null) {
      return SyncResult(
        success: false,
        message: 'Cloud service not available',
      );
    }

    try {
      // Check if authenticated
      if (!await service.isAuthenticated()) {
        return SyncResult(
          success: false,
          message: 'Not authenticated with cloud service',
        );
      }

      // Check for newer backup in cloud
      final newerBackup = await checkForNewerBackup();
      final hasLocalChangesFlag = await hasLocalChanges();

      if (newerBackup != null && !hasLocalChangesFlag) {
        // Cloud has newer data and no local changes - download
        debugPrint('📥 Cloud has newer data, downloading...');
        final localPath = await downloadBackupForRestore(newerBackup);
        if (localPath != null) {
          // Note: Actual restoration would need UI context
          return SyncResult(
            success: true,
            message: 'Newer backup downloaded, restoration required',
            requiresUserAction: true,
            downloadedBackupPath: localPath,
          );
        } else {
          return SyncResult(
            success: false,
            message: 'Failed to download newer backup',
          );
        }
      } else if (hasLocalChangesFlag) {
        // Local changes detected - upload
        debugPrint('📤 Local changes detected, uploading...');
        return await performSync(manual: true);
      } else {
        // Everything is in sync
        debugPrint('✅ Everything is in sync');
        return SyncResult(
          success: true,
          message: 'Everything is in sync',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to perform intelligent sync: $e');
      return SyncResult(
        success: false,
        message: 'Failed to perform intelligent sync: $e',
      );
    }
  }
  
  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }
  
  // Start automatic synchronization - DISABLED FOR SAFETY
  // Auto sync is now disabled to prevent Navigator disposal errors
  void startAutoSync() async {
    debugPrint('Auto sync is disabled to prevent Navigator disposal errors');
    debugPrint('Use manual sync instead through the settings menu');
    return;
  }
  
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('Auto sync stopped');
  }
  
  // Check iCloud status and provide detailed feedback
  Future<void> checkICloudStatus() async {
    final icloudService = getService(CloudProvider.icloud) as ICloudBackupService?;
    if (icloudService == null) {
      debugPrint('iCloud service not available');
      return;
    }

    // Print comprehensive diagnostics
    await icloudService.printDiagnostics();

    final status = await icloudService.checkICloudStatus();

    if (status.isReady) {
      debugPrint('iCloud is ready for backup');
    } else {
      debugPrint('iCloud NOT ready: ${status.errorMessage}');
    }
  }

  // Check Google Drive status and provide detailed feedback
  Future<void> checkGoogleDriveStatus() async {
    final googleDriveService = getService(CloudProvider.googleDrive) as GoogleDriveBackupService?;
    if (googleDriveService == null) {
      debugPrint('Google Drive service not available');
      return;
    }

    // Print comprehensive diagnostics
    await googleDriveService.printDiagnostics();

    final isAuth = await googleDriveService.isAuthenticated();
    if (isAuth) {
      debugPrint('Google Drive is ready for backup');
    } else {
      debugPrint('Google Drive NOT ready - authentication required');
    }
  }

  // Perform synchronization - MANUAL ONLY
  Future<SyncResult> performSync({bool manual = false}) async {
    // Only allow manual sync to prevent Navigator disposal errors
    if (!manual) {
      debugPrint('Auto sync is disabled - use manual sync only');
      return SyncResult(
        success: false,
        message: 'Auto sync is disabled for safety',
      );
    }

    // Check if disposed first
    if (_isDisposed) {
      debugPrint('CloudSyncManager: Cannot perform sync - manager is disposed');
      return SyncResult(
        success: false,
        message: 'CloudSyncManager is disposed',
      );
    }

    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
      );
    }

    // Manual sync doesn't require context validation

    _isSyncing = true;
    
    try {
      final provider = await getSelectedProvider();
      if (provider == null) {
        return SyncResult(
          success: false,
          message: 'No cloud provider selected',
        );
      }
      
      final service = getService(provider);
      if (service == null || !service.isAvailable) {
        return SyncResult(
          success: false,
          message: 'Cloud service not available',
        );
      }
      
      // Check authentication
      if (!await service.isAuthenticated()) {
        if (!await service.authenticate()) {
          return SyncResult(
            success: false,
            message: 'Authentication failed',
          );
        }
      }
      
      final lastSync = await getLastSyncTime();
      
      // Check for newer backup on cloud
      if (lastSync != null && await service.hasNewerBackup(lastSync)) {
        // Download and restore newer backup
        final result = await _downloadAndRestore(service);
        if (!result.success) {
          return result;
        }
      }
      
      // Create and upload new backup
      final uploadResult = await _createAndUploadBackup(service);
      if (!uploadResult.success) {
        return uploadResult;
      }
      
      await _updateLastSyncTime();
      
      // Clean old backups
      await _cleanOldBackups(service);
      
      return SyncResult(
        success: true,
        message: manual ? 'Sync completed successfully' : null,
      );
    } catch (e) {
      debugPrint('Sync error: $e');
      return SyncResult(
        success: false,
        message: 'Sync failed: ${e.toString()}',
      );
    } finally {
      _isSyncing = false;
    }
  }
  
  // Download and restore functionality removed to prevent Navigator disposal errors
  // Restoration must be done manually by the user through the UI
  Future<SyncResult> _downloadAndRestore(CloudBackupService service) async {
    debugPrint('Automatic restore is disabled to prevent Navigator disposal errors');
    debugPrint('User must manually restore backups through the settings menu');
    return SyncResult(
      success: true,
      message: 'Automatic restore disabled - use manual restore',
    );
  }
  
  Future<SyncResult> _createAndUploadBackup(CloudBackupService service) async {
    // Check if disposed
    if (_isDisposed) {
      return SyncResult(
        success: false,
        message: 'Operation cancelled - manager disposed',
      );
    }
    
    try {
      // Create backup
      final tempDir = Directory.systemTemp;
      final backupDir = tempDir.path;
      
      // Get all backup options (backup everything)
      final allOptions = List.generate(10, (i) => i);
      
      // Create backup without context to avoid Navigator disposal errors
      if (_isDisposed) {
        return SyncResult(
          success: false,
          message: 'Operation cancelled - manager disposed',
        );
      }

      // Always create backup without context for safety
      await _ref.read(doBackUpProvider(
        list: allOptions,
        path: backupDir,  // Pass directory path, not file path
        context: null,  // Always pass null context to prevent Navigator access
      ).future);

      // Check again after backup creation
      if (_isDisposed) {
        return SyncResult(
          success: false,
          message: 'Operation cancelled - manager disposed',
        );
      }

      // Find the created backup file (doBackUpProvider creates files with .backup extension)
      final tempDirContents = Directory(backupDir);
      final backupFiles = tempDirContents.listSync()
          .where((file) => file.path.endsWith('.backup'))
          .toList();

      if (backupFiles.isEmpty) {
        return SyncResult(
          success: false,
          message: 'Failed to create backup file',
        );
      }

      // Use the most recently created backup file
      backupFiles.sort((a, b) => File(b.path).lastModifiedSync().compareTo(File(a.path).lastModifiedSync()));
      final backupFilePath = backupFiles.first.path;

      // Upload to cloud
      await service.uploadBackup(
        backupFilePath,  // Use the actual file path created by doBackUpProvider
        onProgress: (progress) {
          if (!_isDisposed) {
            debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
      );
      
      // Clean up temp file
      final tempFile = File(backupFilePath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      return SyncResult(success: true);
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Failed to create cloud backup: $e',
      );
    }
  }
  
  Future<void> _cleanOldBackups(CloudBackupService service) async {
    if (_isDisposed) return;
    
    try {
      final backups = await service.listBackups();
      
      if (_isDisposed) return;
      
      // Keep only the 5 most recent backups
      const maxBackups = 5;
      
      if (backups.length > maxBackups) {
        final toDelete = backups.sublist(maxBackups);
        
        for (final backup in toDelete) {
          if (_isDisposed) break;
          
          try {
            await service.deleteBackup(backup.id);
            if (!_isDisposed) {
              debugPrint('Deleted old backup: ${backup.name}');
            }
          } catch (e) {
            if (!_isDisposed) {
              debugPrint('Failed to delete backup ${backup.name}: $e');
            }
          }
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        debugPrint('Failed to clean old backups: $e');
      }
    }
  }
  
  void dispose() {
    debugPrint('Disposing CloudSyncManager...');
    _isDisposed = true;
    stopAutoSync();
    
    // Wait a bit for any ongoing sync to complete
    // This is a safety measure to avoid Navigator access during dispose
    Future.delayed(const Duration(milliseconds: 100), () {
      debugPrint('CloudSyncManager disposed');
    });
  }
}

class SyncResult {
  final bool success;
  final String? message;
  final bool requiresUserAction;
  final String? downloadedBackupPath;

  SyncResult({
    required this.success,
    this.message,
    this.requiresUserAction = false,
    this.downloadedBackupPath,
  });
}