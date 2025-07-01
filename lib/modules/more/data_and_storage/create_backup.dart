import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/auto_backup.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/backup.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/restore.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/providers/storage_provider.dart';
import 'package:mangayomi/services/cloud_backup/cloud_sync_manager.dart';
import 'package:mangayomi/services/cloud_backup/cloud_backup_service.dart';

class CreateBackup extends ConsumerStatefulWidget {
  const CreateBackup({super.key});

  @override
  ConsumerState<CreateBackup> createState() => _CreateBackupState();
}

class _CreateBackupState extends ConsumerState<CreateBackup> {
  late final List<(String, int)> _libraryList = _getLibraryList(context);
  late final List<(String, int)> _settingsList = _getSettingsList(context);
  late final List<(String, int)> _extensionList = _getExtensionsList(context);
  
  CloudProvider? _selectedProvider;
  bool _isAuthenticating = false;
  bool _isSyncing = false;
  
  @override
  void initState() {
    super.initState();
    _loadCloudSettings();
  }
  
  Future<void> _loadCloudSettings() async {
    final cloudSync = ref.read(cloudSyncManagerProvider);
    final provider = await cloudSync.getSelectedProvider();
    if (mounted) {
      setState(() {
        _selectedProvider = provider;
      });
    }
  }

  void _set(int index, List<int> indexList) {
    if (indexList.contains(index)) {
      ref
          .read(backupFrequencyOptionsStateProvider.notifier)
          .set(indexList.where((e) => e != index).toList());
    } else {
      ref.read(backupFrequencyOptionsStateProvider.notifier).set([
        ...indexList,
        index,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final indexList = ref.watch(backupFrequencyOptionsStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Modern SliverAppBar with gradient
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor.withValues(alpha: 0.8),
                      theme.primaryColor.withValues(alpha: 0.4),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: Image.asset(
                          'assets/app_icons/icon.png',
                          repeat: ImageRepeat.repeat,
                          scale: 8.0,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Text(
                                l10n.create_backup,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Library section
                _buildSectionHeader(
                  context,
                  title: l10n.library,
                  icon: Icons.library_books_outlined,
                ),
                const SizedBox(height: 8),
                _buildSelectionCard(
                  context,
                  items: _libraryList,
                  indexList: indexList,
                  isDark: isDark,
                ),
                // Settings section
                _buildSectionHeader(
                  context,
                  title: l10n.settings,
                  icon: Icons.settings_outlined,
                ),
                const SizedBox(height: 8),
                _buildSelectionCard(
                  context,
                  items: _settingsList,
                  indexList: indexList,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                
                // Extensions section
                _buildSectionHeader(
                  context,
                  title: l10n.extensions,
                  icon: Icons.extension_outlined,
                ),
                const SizedBox(height: 8),
                _buildSelectionCard(
                  context,
                  items: _extensionList,
                  indexList: indexList,
                  isDark: isDark,
                ),
                const SizedBox(height: 32),
                
                // Cloud backup options
                _buildCloudBackupSection(context, isDark),
                const SizedBox(height: 24),
                
                // Create backup button
                _buildCreateBackupButton(context, indexList, isDark),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.headlineSmall?.color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSelectionCard(
    BuildContext context, {
    required List<(String, int)> items,
    required List<int> indexList,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: items.map((item) {
                final (label, idx) = item;
                final isSelected = indexList.contains(idx);
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _set(idx, indexList),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? theme.primaryColor
                                    : theme.dividerColor,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                                color: isSelected
                                    ? theme.primaryColor
                                    : theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCloudBackupSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_outlined,
                color: theme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Cloud Backup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.headlineSmall?.color,
                ),
              ),
              const Spacer(),
              if (_isSyncing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCloudOption(
                  context,
                  icon: Icons.cloud,
                  title: 'iCloud',
                  subtitle: Platform.isIOS || Platform.isMacOS ? 'Available' : 'iOS/macOS only',
                  enabled: Platform.isIOS || Platform.isMacOS,
                  isSelected: _selectedProvider == CloudProvider.icloud,
                  onTap: () => _handleCloudProviderSelection(CloudProvider.icloud),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCloudOption(
                  context,
                  icon: Icons.drive_file_rename_outline,
                  title: 'Google Drive',
                  subtitle: 'All platforms',
                  enabled: true,
                  isSelected: _selectedProvider == CloudProvider.googleDrive,
                  onTap: () => _handleCloudProviderSelection(CloudProvider.googleDrive),
                ),
              ),
            ],
          ),
          if (_selectedProvider != null) ...[
            const SizedBox(height: 16),
            _buildSyncControls(context),
          ],
        ],
      ),
    );
  }
  
  Future<void> _handleCloudProviderSelection(CloudProvider provider) async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
    });
    
    try {
      final cloudSync = ref.read(cloudSyncManagerProvider);
      final service = cloudSync.getService(provider);
      
      if (service == null || !service.isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${service?.serviceName ?? provider.name} not available')),
          );
        }
        return;
      }
      
      // Check if already authenticated
      bool isAuthenticated = await service.isAuthenticated();
      
      // If not authenticated, try to authenticate
      if (!isAuthenticated) {
        isAuthenticated = await service.authenticate();
      }
      
      if (isAuthenticated) {
        await cloudSync.setSelectedProvider(provider);
        setState(() {
          _selectedProvider = provider;
        });
        
        // Auto sync is disabled to prevent Navigator disposal errors
        await cloudSync.setAutoSyncEnabled(false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected to ${service.serviceName}')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to authenticate with ${service.serviceName}')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }
  
  Widget _buildSyncControls(BuildContext context) {
    
    return Column(
      children: [
        ListTile(
          title: const Text('Auto Sync'),
          subtitle: const Text('Auto sync is disabled for stability. Use manual sync instead.'),
          trailing: const Icon(Icons.info_outline),
          enabled: false,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: _isSyncing ? null : _performManualSync,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSyncing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.sync, size: 20),
                    const SizedBox(width: 8),
                    const Text('Sync Now'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonal(
                onPressed: _disconnectCloud,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Disconnect'),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Check for newer backups button
        if (_selectedProvider != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _checkForNewerBackups,
              icon: const Icon(Icons.cloud_download, size: 20),
              label: const Text('Check for Newer Backups'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _performIntelligentSync,
              icon: const Icon(Icons.sync_alt, size: 20),
              label: const Text('Smart Sync (Bidirectional)'),
            ),
          ),
        ],

        // Sync status information
        if (_selectedProvider != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sync Information',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• "Check for Newer Backups" - Manually check if there are newer backups in the cloud',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• "Smart Sync" - Automatically detects changes and syncs bidirectionally',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• The app automatically checks for newer backups on startup',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],

        // Diagnostic button for iCloud
        if (_selectedProvider == CloudProvider.icloud) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _runICloudDiagnostics,
              icon: const Icon(Icons.bug_report, size: 20),
              label: const Text('Run iCloud Diagnostics'),
            ),
          ),
        ],
      ],
    );
  }
  
  Future<void> _performManualSync() async {
    setState(() {
      _isSyncing = true;
    });
    
    try {
      final cloudSync = ref.read(cloudSyncManagerProvider);
      final result = await cloudSync.performSync(manual: true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Sync completed'),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }
  
  Future<void> _disconnectCloud() async {
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Cloud Service'),
        content: const Text('Are you sure you want to disconnect? Your backups will remain in the cloud.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    
    if (shouldDisconnect == true) {
      final cloudSync = ref.read(cloudSyncManagerProvider);
      await cloudSync.setSelectedProvider(null);
      await cloudSync.setAutoSyncEnabled(false);
      cloudSync.stopAutoSync();
      
      setState(() {
        _selectedProvider = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cloud service disconnected')),
        );
      }
    }
  }

  Future<void> _runICloudDiagnostics() async {
    if (_selectedProvider != CloudProvider.icloud) return;

    try {
      final cloudSync = ref.read(cloudSyncManagerProvider);
      final service = cloudSync.getService(CloudProvider.icloud);

      if (service == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('iCloud service not available')),
          );
        }
        return;
      }

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Running diagnostics...'),
              ],
            ),
          ),
        );
      }

      // Run diagnostics
      final isAuth = await service.isAuthenticated();
      final backups = await service.listBackups();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('iCloud Diagnostics'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Authentication: ${isAuth ? "✅ Connected" : "❌ Not connected"}'),
                  const SizedBox(height: 8),
                  Text('Backups found: ${backups.length}'),
                  const SizedBox(height: 8),
                  const Text('Container ID: iCloud.com.dvillegas.mangayomi'),
                  const SizedBox(height: 8),
                  const Text('Backup folder: Documents/Aniverse/Backups'),
                  const SizedBox(height: 8),
                  const Text('Expected location in Files app: iCloud Drive > Aniverse > Documents > Aniverse > Backups'),
                  const SizedBox(height: 16),
                  const Text('Check the console logs for detailed diagnostic information.'),
                  if (backups.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Recent backups:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...backups.take(3).map((backup) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• ${backup.name}'),
                    )),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Diagnostics failed: $e')),
        );
      }
    }
  }

  Future<void> _checkForNewerBackups() async {
    if (_selectedProvider == null) return;

    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Checking for newer backups...'),
              ],
            ),
          ),
        );
      }

      final cloudSync = ref.read(cloudSyncManagerProvider);
      final newerBackup = await cloudSync.checkForNewerBackup();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (newerBackup != null) {
          // Show dialog with newer backup found
          final shouldRestore = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Newer Backup Found'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('A newer backup was found in the cloud:'),
                  const SizedBox(height: 12),
                  Text('📁 ${newerBackup.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('📅 ${_formatDate(newerBackup.modifiedAt)}'),
                  const SizedBox(height: 8),
                  Text('📊 ${(newerBackup.sizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB'),
                  const SizedBox(height: 16),
                  const Text('Would you like to restore this backup? This will replace your current data.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Restore'),
                ),
              ],
            ),
          );

          if (shouldRestore == true) {
            await _restoreBackup(newerBackup);
          }
        } else {
          // No newer backup found
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Your data is up to date. No newer backups found.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check for backups: $e')),
        );
      }
    }
  }

  Future<void> _restoreBackup(CloudBackupInfo backup) async {
    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Restoring backup: ${backup.name}'),
                const SizedBox(height: 8),
                const Text('Please wait...'),
              ],
            ),
          ),
        );
      }

      final cloudSync = ref.read(cloudSyncManagerProvider);
      final localPath = await cloudSync.downloadBackupForRestore(backup);

      if (localPath != null && mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Use the restore provider to restore the backup
        ref.read(doRestoreProvider(path: localPath, context: context));

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Backup restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download backup for restoration')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore backup: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _performIntelligentSync() async {
    if (_selectedProvider == null) return;

    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Performing smart sync...'),
              ],
            ),
          ),
        );
      }

      final cloudSync = ref.read(cloudSyncManagerProvider);
      final result = await cloudSync.performIntelligentSync();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (result.success) {
          if (result.requiresUserAction && result.downloadedBackupPath != null) {
            // Show dialog asking if user wants to restore the newer backup
            final shouldRestore = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Newer Backup Available'),
                content: const Text('A newer backup was found in the cloud. Would you like to restore it? This will replace your current data.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Keep Local Data'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Restore Cloud Data'),
                  ),
                ],
              ),
            );

            if (shouldRestore == true && mounted) {
              // Restore the downloaded backup
              ref.read(doRestoreProvider(path: result.downloadedBackupPath!, context: context));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Backup restored successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${result.message ?? "Smart sync completed successfully!"}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ ${result.message ?? "Smart sync failed"}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to perform smart sync: $e')),
        );
      }
    }
  }

  Future<void> _showCloudBackups() async {
    if (_selectedProvider == null) return;

    try {
      final cloudSync = ref.read(cloudSyncManagerProvider);
      final service = cloudSync.getService(_selectedProvider!);

      if (service == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cloud service not available')),
          );
        }
        return;
      }

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Loading backups...'),
              ],
            ),
          ),
        );
      }

      final backups = await service.listBackups();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${service.serviceName} Backups'),
            content: SizedBox(
              width: double.maxFinite,
              child: backups.isEmpty
                  ? const Text('No backups found in the cloud.')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: backups.length,
                      itemBuilder: (context, index) {
                        final backup = backups[index];
                        return ListTile(
                          leading: const Icon(Icons.backup),
                          title: Text(backup.name),
                          subtitle: Text(
                            'Size: ${(backup.sizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB\n'
                            'Created: ${backup.createdAt.toLocal().toString().split('.')[0]}',
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load backups: $e')),
        );
      }
    }
  }

  Widget _buildCloudOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: isSelected
            ? theme.primaryColor.withValues(alpha: 0.1)
            : isDark
                ? Colors.grey.shade800
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.primaryColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Icon(
                      icon,
                      size: 32,
                      color: enabled
                          ? (isSelected ? theme.primaryColor : theme.iconTheme.color)
                          : theme.disabledColor,
                    ),
                    if (isSelected)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                    color: enabled
                        ? (isSelected ? theme.primaryColor : theme.textTheme.bodyLarge?.color)
                        : theme.disabledColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? theme.primaryColor.withValues(alpha: 0.7) : theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCreateBackupButton(
    BuildContext context,
    List<int> indexList,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            String? result;
            if (Platform.isIOS) {
              result = (await StorageProvider().getIosBackupDirectory())!.path;
            } else {
              result = await FilePicker.platform.getDirectoryPath();
            }

            if (result != null && context.mounted) {
              ref.watch(
                doBackUpProvider(
                  list: indexList,
                  path: result,
                  context: context,
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.backup_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.create,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<(String, int)> _getLibraryList(BuildContext context) {
  final l10n = context.l10n;
  return [
    (l10n.library_entries, 0),
    (l10n.categories, 1),
    (l10n.chapters_and_episode, 2),
    (l10n.tracking, 3),
    (l10n.history, 4),
    (l10n.updates, 5),
  ];
}

List<(String, int)> _getSettingsList(BuildContext context) {
  final l10n = context.l10n;
  return [
    (l10n.app_settings, 6),
    (l10n.sources_settings, 7),
    (l10n.include_sensitive_settings, 8),
  ];
}

List<(String, int)> _getExtensionsList(BuildContext context) {
  final l10n = context.l10n;
  return [(l10n.extensions, 9)];
}
