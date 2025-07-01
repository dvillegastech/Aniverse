import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/auto_backup.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/backup.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/providers/storage_provider.dart';

class CreateBackup extends ConsumerStatefulWidget {
  const CreateBackup({super.key});

  @override
  ConsumerState<CreateBackup> createState() => _CreateBackupState();
}

class _CreateBackupState extends ConsumerState<CreateBackup> {
  late final List<(String, int)> _libraryList = _getLibraryList(context);
  late final List<(String, int)> _settingsList = _getSettingsList(context);
  late final List<(String, int)> _extensionList = _getExtensionsList(context);

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
                  subtitle: 'iOS only',
                  enabled: Platform.isIOS,
                  onTap: () {
                    // TODO: Implement iCloud backup
                  },
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
                  onTap: () {
                    // TODO: Implement Google Drive backup
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCloudOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: isDark
            ? Colors.grey.shade800
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: enabled
                      ? theme.primaryColor
                      : theme.disabledColor,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: enabled
                        ? theme.textTheme.bodyLarge?.color
                        : theme.disabledColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.hintColor,
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
