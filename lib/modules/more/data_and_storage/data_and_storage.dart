import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/eval/model/m_bridge.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/auto_backup.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/restore.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/storage_usage.dart';
import 'package:mangayomi/modules/more/settings/downloads/providers/downloads_state_provider.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class DataAndStorage extends ConsumerWidget {
  const DataAndStorage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupFrequency = ref.watch(backupFrequencyStateProvider);
    final autoBackupLocation = ref.watch(autoBackupLocationStateProvider);
    final downloadLocationState = ref.watch(downloadLocationStateProvider);
    final totalChapterCacheSize = ref.watch(totalChapterCacheSizeStateProvider);
    final clearChapterCacheOnAppLaunch = ref.watch(
      clearChapterCacheOnAppLaunchStateProvider,
    );
    final l10n = l10nLocalizations(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140.0,
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
                    // Pattern overlay
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          Icons.storage,
                          size: 150,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Title
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
                                l10n.data_and_storage,
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
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Download Location Section
                _buildSectionCard(
                  context,
                  title: 'Download Settings',
                  icon: Icons.download_outlined,
                  iconColor: Colors.blue,
                  children: [
                    _buildEnhancedListTile(
                      context,
                      title: l10n.download_location,
                      subtitle: downloadLocationState.$2.isEmpty
                          ? downloadLocationState.$1
                          : downloadLocationState.$2,
                      icon: Icons.folder_outlined,
                      onTap: () => _showDownloadLocationDialog(context, ref, l10n),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: theme.primaryColor.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.download_location_info,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Backup & Restore Section
                _buildSectionCard(
                  context,
                  title: l10n.backup_and_restore,
                  icon: Icons.backup_outlined,
                  iconColor: Colors.green,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              context,
                              icon: Icons.save_alt,
                              label: l10n.create_backup,
                              color: Colors.blue,
                              onTap: () => context.push('/createBackup'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              context,
                              icon: Icons.restore,
                              label: l10n.restore_backup,
                              color: Colors.orange,
                              onTap: () => _showRestoreDialog(context, ref, l10n),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildEnhancedListTile(
                      context,
                      title: l10n.backup_frequency,
                      subtitle: _getBackupFrequencyList(context)[backupFrequency],
                      icon: Icons.schedule,
                      onTap: () => _showBackupFrequencyDialog(context, ref, l10n, backupFrequency),
                    ),
                    if (!Platform.isIOS)
                      _buildEnhancedListTile(
                        context,
                        title: l10n.backup_location,
                        subtitle: autoBackupLocation.$2.isEmpty
                            ? autoBackupLocation.$1
                            : autoBackupLocation.$2,
                        icon: Icons.folder_special,
                        onTap: () async {
                          String? result = await FilePicker.platform.getDirectoryPath();
                          if (result != null) {
                            ref
                                .read(autoBackupLocationStateProvider.notifier)
                                .set(result);
                          }
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: theme.primaryColor.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.backup_and_restore_warning_info,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Storage Section
                _buildSectionCard(
                  context,
                  title: l10n.storage,
                  icon: Icons.storage,
                  iconColor: Colors.purple,
                  children: [
                    _buildEnhancedListTile(
                      context,
                      title: l10n.clear_chapter_and_episode_cache,
                      subtitle: totalChapterCacheSize,
                      icon: Icons.cleaning_services,
                      onTap: () => ref
                          .read(totalChapterCacheSizeStateProvider.notifier)
                          .clearCache(),
                    ),
                    _buildEnhancedSwitchTile(
                      context,
                      title: context.l10n.clear_chapter_or_episode_cache_on_app_launch,
                      icon: Icons.auto_delete,
                      value: clearChapterCacheOnAppLaunch,
                      onChanged: (value) {
                        ref
                            .read(clearChapterCacheOnAppLaunchStateProvider.notifier)
                            .set(value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            iconColor.withValues(alpha: 0.2),
                            iconColor.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEnhancedListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: theme.primaryColor.withValues(alpha: 0.7),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEnhancedSwitchTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: theme.primaryColor.withValues(alpha: 0.7),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: theme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showDownloadLocationDialog(BuildContext context, WidgetRef ref, dynamic l10n) {
    final downloadLocationState = ref.watch(downloadLocationStateProvider);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.download_location),
          content: SizedBox(
            width: context.width(0.8),
            child: SuperListView(
              shrinkWrap: true,
              children: [
                RadioListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.all(0),
                  value: downloadLocationState.$2.isEmpty
                      ? downloadLocationState.$1
                      : downloadLocationState.$2,
                  groupValue: downloadLocationState.$1,
                  onChanged: (value) {
                    ref
                        .read(
                          downloadLocationStateProvider.notifier,
                        )
                        .set("");
                    Navigator.pop(context);
                  },
                  title: Text(downloadLocationState.$1),
                ),
                RadioListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.all(0),
                  value: downloadLocationState.$2.isEmpty
                      ? downloadLocationState.$1
                      : downloadLocationState.$2,
                  groupValue: downloadLocationState.$2,
                  onChanged: (value) async {
                    String? result = await FilePicker.platform
                        .getDirectoryPath();

                    if (result != null) {
                      ref
                          .read(
                            downloadLocationStateProvider.notifier,
                          )
                          .set(result);
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  title: Text(l10n.custom_location),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.cancel,
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showRestoreDialog(BuildContext context, WidgetRef ref, dynamic l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.restore_backup),
          content: SizedBox(
            width: context.width(0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.restore_backup_warning_title,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.cancel,
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    allowMultiple: false,
                  );

                  if (result != null && context.mounted) {
                    ref.watch(
                      doRestoreProvider(
                        path: result.files.first.path!,
                        context: context,
                      ),
                    );
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                } catch (_) {
                  botToast("Error");
                  Navigator.pop(context);
                }
              },
              child: Text(
                l10n.ok,
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showBackupFrequencyDialog(BuildContext context, WidgetRef ref, dynamic l10n, int currentValue) {
    final list = _getBackupFrequencyList(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.backup_frequency),
          content: SizedBox(
            width: context.width(0.8),
            child: SuperListView.builder(
              shrinkWrap: true,
              itemCount: list.length,
              itemBuilder: (context, index) {
                return RadioListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.all(0),
                  value: index,
                  groupValue: currentValue,
                  onChanged: (value) {
                    ref
                        .read(backupFrequencyStateProvider.notifier)
                        .set(value!);
                    Navigator.pop(context);
                  },
                  title: Text(list[index]),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.cancel,
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }
}

List<String> _getBackupFrequencyList(BuildContext context) {
  final l10n = l10nLocalizations(context)!;
  return [
    l10n.off,
    l10n.every_6_hours,
    l10n.every_12_hours,
    l10n.daily,
    l10n.every_2_days,
    l10n.weekly,
  ];
}
