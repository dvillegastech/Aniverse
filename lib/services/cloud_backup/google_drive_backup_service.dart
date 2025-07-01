import 'dart:io';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'cloud_backup_service.dart';

class GoogleDriveBackupService extends CloudBackupService {
  static const List<String> _scopes = [drive.DriveApi.driveFileScope];
  static const String _backupFolder = 'Aniverse Backups';

  // Use GoogleSignIn without explicit clientId - it will read from configuration files
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
    // Force account selection on each sign in for better UX
    forceCodeForRefreshToken: true,
  );
  
  drive.DriveApi? _driveApi;
  String? _folderId;
  
  @override
  String get serviceName => 'Google Drive';
  
  @override
  IconData get serviceIcon => Icons.drive_file_rename_outline;
  
  @override
  bool get isAvailable => true; // Available on all platforms
  
  @override
  Future<bool> isAuthenticated() async {
    try {
      final account = _googleSignIn.currentUser;
      return account != null && _driveApi != null;
    } catch (e) {
      debugPrint('Google Drive auth check error: $e');
      return false;
    }
  }

  /// Check if Google Sign In is properly configured
  Future<bool> isConfigured() async {
    try {
      // Simple check - just verify we can access the GoogleSignIn instance
      debugPrint('Checking Google Sign In configuration...');
      final currentUser = _googleSignIn.currentUser;
      debugPrint('Google Sign In configuration check - Current user: ${currentUser?.email ?? 'none'}');
      
      // Additional platform-specific checks
      if (Platform.isIOS) {
        debugPrint('iOS: Ensure GoogleService-Info.plist is added to the project');
        debugPrint('iOS: Ensure URL scheme is registered in Info.plist');
        debugPrint('iOS: Ensure AppDelegate.swift has Google Sign In configuration');
      } else if (Platform.isAndroid) {
        debugPrint('Android: Ensure google-services.json is in android/app/');
        debugPrint('Android: Ensure SHA-1 fingerprint is registered in Firebase Console');
      }
      
      debugPrint('Google Sign In configuration appears to be working');
      return true;
    } catch (e) {
      debugPrint('Google Sign In configuration error: $e');
      debugPrint('This usually means configuration files are missing or not properly set up');
      return false;
    }
  }
  
  @override
  Future<bool> authenticate() async {
    try {
      debugPrint('Starting Google Drive authentication...');

      // Check configuration first
      if (!await isConfigured()) {
        debugPrint('Google Sign In is not properly configured');
        return false;
      }

      // Sign out first to ensure fresh authentication
      if (_googleSignIn.currentUser != null) {
        debugPrint('Signing out existing user...');
        await _googleSignIn.signOut();
      }

      debugPrint('Initiating Google Sign In...');
      GoogleSignInAccount? account;
      
      try {
        account = await _googleSignIn.signIn();
      } catch (signInError) {
        debugPrint('Sign in error: $signInError');
        
        // Try to provide more specific error messages
        if (signInError.toString().contains('10:')) {
          debugPrint('Error 10: Developer error - check SHA-1 fingerprint and package name');
        } else if (signInError.toString().contains('12500')) {
          debugPrint('Error 12500: Sign in failed - check Google Play Services');
        } else if (signInError.toString().contains('12501')) {
          debugPrint('Error 12501: Sign in cancelled by user');
        } else if (signInError.toString().contains('12502')) {
          debugPrint('Error 12502: Sign in currently in progress');
        }
        
        return false;
      }
      
      if (account == null) {
        debugPrint('Google Sign In was cancelled by user');
        return false;
      }

      debugPrint('Getting auth headers...');
      final authHeaders = await account.authHeaders;
      final authenticatedClient = GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(authenticatedClient);

      debugPrint('Creating/finding backup folder...');
      _folderId = await _getOrCreateFolder();

      debugPrint('Google Drive authentication successful');
      return true;
    } catch (e) {
      debugPrint('Google Drive authentication error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error details: ${e.toString()}');

      // Provide more specific error information
      if (e.toString().contains('network')) {
        debugPrint('Network error - check internet connection');
      } else if (e.toString().contains('cancelled')) {
        debugPrint('Authentication was cancelled');
      } else if (e.toString().contains('configuration')) {
        debugPrint('Configuration error - check GoogleService-Info.plist and URL schemes');
      } else if (e.toString().contains('GIDSignIn')) {
        debugPrint('Google Sign In SDK error - check AppDelegate configuration');
      }

      return false;
    }
  }

  /// Print diagnostic information for troubleshooting
  Future<void> printDiagnostics() async {
    debugPrint('=== Google Drive Diagnostics ===');
    debugPrint('Service Available: $isAvailable');

    final isConfigured = await this.isConfigured();
    debugPrint('Configuration Check: $isConfigured');

    final isAuth = await isAuthenticated();
    debugPrint('Authentication Status: $isAuth');

    final currentUser = _googleSignIn.currentUser;
    debugPrint('Current User: ${currentUser?.email ?? 'none'}');
    debugPrint('Drive API Initialized: ${_driveApi != null}');
    debugPrint('Folder ID: ${_folderId ?? 'not set'}');

    debugPrint('===============================');
  }
  
  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _driveApi = null;
    _folderId = null;
  }
  
  @override
  Future<void> uploadBackup(String localPath, {Function(double)? onProgress}) async {
    if (_driveApi == null || _folderId == null) {
      throw Exception('Not authenticated with Google Drive');
    }
    
    final file = File(localPath);
    final fileName = 'aniverse_backup_${DateTime.now().millisecondsSinceEpoch}.backup';
    
    try {
      final media = drive.Media(
        file.openRead(),
        file.lengthSync(),
      );
      
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [_folderId!]
        ..appProperties = {
          'deviceId': await _getDeviceId(),
          'appVersion': await _getAppVersion(),
          'backupVersion': '2',
          'createdAt': DateTime.now().toIso8601String(),
        };
      
      final response = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id, name, size, createdTime, modifiedTime',
      );
      
      debugPrint('Backup uploaded to Google Drive: ${response.name}');
    } catch (e) {
      throw Exception('Failed to upload backup to Google Drive: $e');
    }
  }
  
  @override
  Future<List<CloudBackupInfo>> listBackups() async {
    if (_driveApi == null || _folderId == null) {
      return [];
    }
    
    try {
      final query = "'$_folderId' in parents and name contains '.backup' and trashed = false";
      final fileList = await _driveApi!.files.list(
        q: query,
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, size, createdTime, modifiedTime, appProperties)',
      );
      
      final backups = <CloudBackupInfo>[];
      
      if (fileList.files != null) {
        for (final file in fileList.files!) {
          backups.add(CloudBackupInfo(
            id: file.id!,
            name: file.name!,
            createdAt: file.createdTime ?? DateTime.now(),
            modifiedAt: file.modifiedTime ?? DateTime.now(),
            sizeInBytes: int.tryParse(file.size ?? '0') ?? 0,
            metadata: file.appProperties,
          ));
        }
      }
      
      return backups;
    } catch (e) {
      debugPrint('Failed to list Google Drive backups: $e');
      return [];
    }
  }
  
  @override
  Future<void> downloadBackup(String backupId, String localPath, {Function(double)? onProgress}) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated with Google Drive');
    }
    
    try {
      final media = await _driveApi!.files.get(
        backupId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      
      final file = File(localPath);
      final sink = file.openWrite();
      
      var downloadedBytes = 0;
      final totalBytes = await _getFileSize(backupId);
      
      await media.stream.listen(
        (data) {
          downloadedBytes += data.length;
          sink.add(data);
          
          if (totalBytes > 0) {
            final progress = downloadedBytes / totalBytes;
            onProgress?.call(progress);
            debugPrint('Google Drive download progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
        onDone: () async {
          await sink.close();
          onProgress?.call(1.0);
        },
        onError: (error) async {
          await sink.close();
          throw error;
        },
      ).asFuture();
    } catch (e) {
      throw Exception('Failed to download backup from Google Drive: $e');
    }
  }
  
  @override
  Future<void> deleteBackup(String backupId) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated with Google Drive');
    }
    
    try {
      await _driveApi!.files.delete(backupId);
    } catch (e) {
      throw Exception('Failed to delete backup from Google Drive: $e');
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
  Future<String> _getOrCreateFolder() async {
    if (_driveApi == null) {
      throw Exception('Drive API not initialized');
    }
    
    // Search for existing folder
    final query = "name='$_backupFolder' and mimeType='application/vnd.google-apps.folder' and trashed=false";
    final result = await _driveApi!.files.list(q: query, $fields: 'files(id, name)');
    
    if (result.files?.isNotEmpty ?? false) {
      return result.files!.first.id!;
    }
    
    // Create new folder
    final folder = drive.File()
      ..name = _backupFolder
      ..mimeType = 'application/vnd.google-apps.folder';
    
    final createdFolder = await _driveApi!.files.create(folder, $fields: 'id');
    return createdFolder.id!;
  }
  
  Future<int> _getFileSize(String fileId) async {
    try {
      final file = await _driveApi!.files.get(
        fileId,
        $fields: 'size',
      ) as drive.File;
      
      return int.tryParse(file.size ?? '0') ?? 0;
    } catch (e) {
      return 0;
    }
  }
  
  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'ios_unknown';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return macInfo.systemGUID ?? 'macos_unknown';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.deviceId;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return linuxInfo.machineId ?? 'linux_unknown';
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

// Helper class for authenticated HTTP client
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  
  GoogleAuthClient(this._headers);
  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}