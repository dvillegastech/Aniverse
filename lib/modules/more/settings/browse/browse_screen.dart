import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:mangayomi/eval/model/m_bridge.dart';
import 'package:mangayomi/main.dart';
import 'package:mangayomi/models/changed.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/history.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/models/update.dart';
import 'package:mangayomi/modules/more/settings/sync/providers/sync_providers.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';

class BrowseSScreen extends ConsumerWidget {
  const BrowseSScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlyIncludePinnedSource = ref.watch(
      onlyIncludePinnedSourceStateProvider,
    );
    final checkForExtensionUpdates = ref.watch(
      checkForExtensionsUpdateStateProvider,
    );
    final autoUpdateExtensions = ref.watch(autoUpdateExtensionsStateProvider);
    final l10n = l10nLocalizations(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
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
                                l10n.browse,
                                style: const TextStyle(
                                  fontSize: 32,
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
                const SizedBox(height: 8),
                _buildSettingsSection(
                  context,
                  title: 'Extensions',
                  items: [
                    _SettingsItem(
                      title: l10n.manga_extensions_repo,
                      subtitle: l10n.manage_manga_repo_urls,
                      icon: Icons.extension_rounded,
                      iconColor: Colors.orange,
                      onTap: () {
                        context.push(
                          "/SourceRepositories",
                          extra: ItemType.manga,
                        );
                      },
                    ),
                    _SettingsItem(
                      title: l10n.anime_extensions_repo,
                      subtitle: l10n.manage_anime_repo_urls,
                      icon: Icons.movie_rounded,
                      iconColor: Colors.red,
                      onTap: () {
                        context.push(
                          "/SourceRepositories",
                          extra: ItemType.anime,
                        );
                      },
                    ),
                    _SettingsItem(
                      title: l10n.novel_extensions_repo,
                      subtitle: l10n.manage_novel_repo_urls,
                      icon: Icons.book_rounded,
                      iconColor: Colors.green,
                      onTap: () {
                        context.push(
                          "/SourceRepositories",
                          extra: ItemType.novel,
                        );
                      },
                    ),
                    _SettingsSwitchItem(
                      title: l10n.check_for_extension_updates,
                      subtitle: '',
                      icon: Icons.update_rounded,
                      iconColor: Colors.blue,
                      value: checkForExtensionUpdates,
                      onChanged: (value) {
                        ref
                            .read(checkForExtensionsUpdateStateProvider.notifier)
                            .set(value);
                      },
                    ),
                    if (checkForExtensionUpdates)
                      _SettingsSwitchItem(
                        title: l10n.auto_extensions_updates,
                        subtitle: l10n.auto_extensions_updates_subtitle,
                        icon: Icons.autorenew_rounded,
                        iconColor: Colors.cyan,
                        value: autoUpdateExtensions,
                        onChanged: (value) {
                          ref
                              .read(autoUpdateExtensionsStateProvider.notifier)
                              .set(value);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsSection(
                  context,
                  title: 'Global Search',
                  items: [
                    _SettingsSwitchItem(
                      title: l10n.only_include_pinned_sources,
                      subtitle: '',
                      icon: Icons.push_pin_rounded,
                      iconColor: Colors.purple,
                      value: onlyIncludePinnedSource,
                      onChanged: (value) {
                        ref
                            .read(onlyIncludePinnedSourceStateProvider.notifier)
                            .set(value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsSection(
                  context,
                  title: 'Database',
                  items: [
                    _SettingsItem(
                      title: l10n.clean_database,
                      subtitle: l10n.clean_database_desc,
                      icon: Icons.cleaning_services_rounded,
                      iconColor: Colors.amber,
                      onTap: () => _showCleanNonLibraryDialog(context, l10n),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDangerSection(context, l10n),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<dynamic> items,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
        ),
        Container(
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
                children: items.map((item) {
                  final isLast = items.last == item;
                  if (item is _SettingsItem) {
                    return _buildSettingsTile(
                      context,
                      title: item.title,
                      subtitle: item.subtitle,
                      icon: item.icon,
                      iconColor: item.iconColor,
                      onTap: item.onTap,
                      showDivider: !isLast,
                    );
                  } else if (item is _SettingsSwitchItem) {
                    return _buildSwitchTile(
                      context,
                      title: item.title,
                      subtitle: item.subtitle,
                      icon: item.icon,
                      iconColor: item.iconColor,
                      value: item.value,
                      onChanged: item.onChanged,
                      showDivider: !isLast,
                    );
                  }
                  return const SizedBox.shrink();
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
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
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
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
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 76,
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
      ],
    );
  }
  
  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
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
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Switch(
                    value: value,
                    onChanged: onChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 76,
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
      ],
    );
  }
  
  Widget _buildDangerSection(BuildContext context, dynamic l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showClearAllSourcesDialog(context, l10n),
                icon: const Icon(Icons.delete_sweep_rounded),
                label: Text(
                  l10n.clear_all_sources,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  
  const _SettingsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });
}

class _SettingsSwitchItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;
  
  const _SettingsSwitchItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onChanged,
  });
}

void _showClearAllSourcesDialog(BuildContext context, dynamic l10n) {
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n.clear_all_sources),
        content: Text(l10n.clear_all_sources_msg),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 15),
              Consumer(
                builder: (context, ref, child) => TextButton(
                  onPressed: () {
                    isar.writeTxnSync(() {
                      isar.sources.clearSync();
                      ref
                          .read(synchingProvider(syncId: 1).notifier)
                          .addChangedPart(
                            ActionType.clearHistory,
                            null,
                            "{}",
                            false,
                          );
                    });

                    Navigator.pop(ctx);
                    botToast(l10n.sources_cleared);
                  },
                  child: Text(l10n.ok),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

void _showCleanNonLibraryDialog(BuildContext context, dynamic l10n) {
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n.clean_database),
        content: Text(l10n.clean_database_desc),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 15),
              Consumer(
                builder: (context, ref, child) => TextButton(
                  onPressed: () {
                    final mangasList = isar.mangas
                        .filter()
                        .favoriteEqualTo(false)
                        .findAllSync();
                    isar.writeTxnSync(() {
                      for (var manga in mangasList) {
                        final histories = isar.historys
                            .filter()
                            .mangaIdEqualTo(manga.id)
                            .findAllSync();
                        for (var history in histories) {
                          isar.historys.deleteSync(history.id!);
                        }

                        for (var chapter in manga.chapters) {
                          isar.updates
                              .filter()
                              .mangaIdEqualTo(chapter.mangaId)
                              .chapterNameEqualTo(chapter.name)
                              .deleteAllSync();
                          isar.chapters.deleteSync(chapter.id!);
                        }
                        isar.mangas.deleteSync(manga.id!);
                        ref
                            .read(synchingProvider(syncId: 1).notifier)
                            .addChangedPart(
                              ActionType.removeItem,
                              manga.id,
                              "{}",
                              false,
                            );
                      }
                    });

                    Navigator.pop(ctx);
                    botToast(l10n.cleaned_database(mangasList.length));
                  },
                  child: Text(l10n.ok),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
