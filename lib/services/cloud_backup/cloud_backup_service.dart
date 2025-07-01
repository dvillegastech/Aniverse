import 'package:flutter/material.dart';

abstract class CloudBackupService {
  // Authentication
  Future<bool> isAuthenticated();
  Future<bool> authenticate();
  Future<void> signOut();
  
  // Backup operations
  Future<void> uploadBackup(String localPath, {Function(double)? onProgress});
  Future<List<CloudBackupInfo>> listBackups();
  Future<void> downloadBackup(String backupId, String localPath, {Function(double)? onProgress});
  Future<void> deleteBackup(String backupId);
  
  // Sync operations
  Future<CloudBackupInfo?> getLatestBackup();
  Future<bool> hasNewerBackup(DateTime lastSyncTime);
  
  // Service info
  String get serviceName;
  IconData get serviceIcon;
  bool get isAvailable;
}

class CloudBackupInfo {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final int sizeInBytes;
  final Map<String, dynamic>? metadata;
  
  CloudBackupInfo({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    required this.sizeInBytes,
    this.metadata,
  });
  
  bool isNewerThan(DateTime date) => modifiedAt.isAfter(date);
}

enum CloudProvider {
  icloud,
  googleDrive,
}