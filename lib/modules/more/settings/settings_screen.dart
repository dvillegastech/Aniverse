import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/providers/l10n_providers.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nLocalizations(context);
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
                    // Pattern overlay
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
                                l10n!.settings,
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
                  title: 'General',
                  items: [
                    _SettingsItem(
                      title: l10n!.appearance,
                      subtitle: l10n.appearance_subtitle,
                      icon: Icons.color_lens_rounded,
                      iconColor: Colors.purple,
                      onTap: () => context.push('/appearance'),
                    ),
                    _SettingsItem(
                      title: l10n.downloads,
                      subtitle: l10n.downloads_subtitle,
                      icon: Icons.download_outlined,
                      iconColor: Colors.blue,
                      onTap: () => context.push('/downloads'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsSection(
                  context,
                  title: 'Content',
                  items: [
                    _SettingsItem(
                      title: l10n.reader,
                      subtitle: l10n.reader_subtitle,
                      icon: Icons.chrome_reader_mode_rounded,
                      iconColor: Colors.orange,
                      onTap: () => context.push('/readerMode'),
                    ),
                    _SettingsItem(
                      title: l10n.player,
                      subtitle: l10n.reader_subtitle,
                      icon: Icons.play_circle_outline_outlined,
                      iconColor: Colors.red,
                      onTap: () => context.push('/playerMode'),
                    ),
                    _SettingsItem(
                      title: l10n.browse,
                      subtitle: l10n.browse_subtitle,
                      icon: Icons.explore_rounded,
                      iconColor: Colors.green,
                      onTap: () => context.push('/browseS'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsSection(
                  context,
                  title: 'Sync & Data',
                  items: [
                    _SettingsItem(
                      title: l10n.tracking,
                      subtitle: '',
                      icon: Icons.sync_outlined,
                      iconColor: Colors.teal,
                      onTap: () => context.push('/track'),
                    ),
                    _SettingsItem(
                      title: l10n.syncing,
                      subtitle: l10n.syncing_subtitle,
                      icon: Icons.cloud_sync_outlined,
                      iconColor: Colors.indigo,
                      onTap: () => context.push('/sync'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsSection(
                  context,
                  title: 'About',
                  items: [
                    _SettingsItem(
                      title: l10n.about,
                      subtitle: '',
                      icon: Icons.info_outline,
                      iconColor: Colors.grey,
                      onTap: () => context.push('/about'),
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
  
  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<_SettingsItem> items,
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
                  return _buildSettingsTile(
                    context,
                    title: item.title,
                    subtitle: item.subtitle,
                    icon: item.icon,
                    iconColor: item.iconColor,
                    onTap: item.onTap,
                    showDivider: !isLast,
                  );
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
