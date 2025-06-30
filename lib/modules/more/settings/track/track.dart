import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:mangayomi/main.dart';
import 'package:mangayomi/models/track_preference.dart';
import 'package:mangayomi/modules/more/settings/track/providers/track_providers.dart';
import 'package:mangayomi/modules/more/settings/track/widgets/track_listile.dart';
import 'package:mangayomi/modules/more/widgets/list_tile_widget.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/services/trackers/anilist.dart';
import 'package:mangayomi/services/trackers/kitsu.dart';
import 'package:mangayomi/services/trackers/myanimelist.dart';
import 'package:mangayomi/utils/constant.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';

class TrackScreen extends ConsumerWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateProgressAfterReading = ref.watch(
      updateProgressAfterReadingStateProvider,
    );
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
                                l10n.tracking,
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
                StreamBuilder(
          stream: isar.trackPreferences.filter().syncIdIsNotNull().watch(
            fireImmediately: true,
          ),
          builder: (context, snapshot) {
            List<TrackPreference>? entries = snapshot.hasData
                ? snapshot.data
                : [];
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildSettingsSection(
                      context,
                      title: 'General Settings',
                      items: [
                        _SettingsSwitchItem(
                          title: context.l10n.updateProgressAfterReading,
                          subtitle: '',
                          icon: Icons.auto_mode_rounded,
                          iconColor: Colors.blue,
                          value: updateProgressAfterReading,
                          onChanged: (value) {
                            ref
                                .read(updateProgressAfterReadingStateProvider.notifier)
                                .set(value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsSection(
                      context,
                      title: 'Services',
                      items: [
                        _SettingsItem(
                          title: 'AniList',
                          subtitle: _getServiceStatus(entries!, 2),
                          imagePath: trackInfos(2).$1,
                          iconColor: trackInfos(2).$3,
                          onTap: () async {
                            await ref.read(anilistProvider(syncId: 2).notifier).login();
                          },
                        ),
                        _SettingsItem(
                          title: 'Kitsu',
                          subtitle: _getServiceStatus(entries, 3),
                          imagePath: trackInfos(3).$1,
                          iconColor: trackInfos(3).$3,
                          onTap: () async {
                            _showDialogLogin(context, ref);
                          },
                        ),
                        _SettingsItem(
                          title: 'MyAnimeList',
                          subtitle: _getServiceStatus(entries, 1),
                          imagePath: trackInfos(1).$1,
                          iconColor: trackInfos(1).$3,
                          onTap: () async {
                            await ref
                                .read(
                                  myAnimeListProvider(
                                    syncId: 1,
                                    itemType: null,
                                  ).notifier,
                                )
                                .login();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoSection(context, l10n.tracking_warning_info),
                    const SizedBox(height: 16),
                    _buildSettingsSection(
                      context,
                      title: 'Management',
                      items: [
                        _SettingsItem(
                          title: l10n.manage_trackers,
                          subtitle: '',
                          icon: Icons.settings_rounded,
                          iconColor: Colors.grey,
                          onTap: () => context.push('/manageTrackers'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                );
          },
        ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _getServiceStatus(List<TrackPreference> entries, int syncId) {
    final preference = entries.firstWhere(
      (element) => element.syncId == syncId,
      orElse: () => TrackPreference()..syncId = syncId,
    );
    return preference.oAuth != null && preference.oAuth!.isNotEmpty 
        ? 'Logged in' 
        : 'Not logged in';
  }

  Widget _buildInfoSection(BuildContext context, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: theme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
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
                      imagePath: item.imagePath,
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
    IconData? icon,
    required Color iconColor,
    String? imagePath,
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
                    child: imagePath != null
                        ? Image.asset(
                            imagePath,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          )
                        : Icon(
                            icon!,
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
}

class _SettingsItem {
  final String title;
  final String subtitle;
  final IconData? icon;
  final Color iconColor;
  final String? imagePath;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.title,
    required this.subtitle,
    this.icon,
    required this.iconColor,
    this.imagePath,
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

void _showDialogLogin(BuildContext context, WidgetRef ref) {
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  String email = "";
  String password = "";
  String errorMessage = "";
  bool isLoading = false;
  bool obscureText = true;
  final l10n = l10nLocalizations(context)!;
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(
            l10n.login_into("Kitsu"),
            style: const TextStyle(fontSize: 30),
          ),
          content: SizedBox(
            height: 300,
            width: MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: TextFormField(
                    controller: emailController,
                    autofocus: true,
                    onChanged: (value) => setState(() {
                      email = value;
                    }),
                    decoration: InputDecoration(
                      hintText: l10n.email_adress,
                      filled: false,
                      contentPadding: const EdgeInsets.all(12),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(width: 0.4),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: TextFormField(
                    controller: passwordController,
                    obscureText: obscureText,
                    onChanged: (value) => setState(() {
                      password = value;
                    }),
                    decoration: InputDecoration(
                      hintText: l10n.password,
                      suffixIcon: IconButton(
                        onPressed: () => setState(() {
                          obscureText = !obscureText;
                        }),
                        icon: Icon(
                          obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      filled: false,
                      contentPadding: const EdgeInsets.all(12),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(width: 0.4),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(errorMessage, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SizedBox(
                    width: context.width(1),
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              setState(() {
                                isLoading = true;
                              });
                              final res = await ref
                                  .read(kitsuProvider(syncId: 3).notifier)
                                  .login(email, password);
                              if (!res.$1) {
                                setState(() {
                                  isLoading = false;
                                  errorMessage = res.$2;
                                });
                              } else {
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : Text(l10n.login),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
