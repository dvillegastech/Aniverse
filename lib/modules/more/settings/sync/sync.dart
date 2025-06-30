import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:mangayomi/main.dart';
import 'package:mangayomi/models/changed.dart';
import 'package:mangayomi/modules/more/settings/sync/providers/sync_providers.dart';
import 'package:mangayomi/utils/date.dart';
import 'package:mangayomi/models/sync_preference.dart';
import 'package:mangayomi/modules/more/settings/sync/widgets/sync_listile.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/services/sync_server.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncProvider = ref.watch(synchingProvider(syncId: 1));
    final changedParts = ref.watch(synchingProvider(syncId: 1).notifier);
    final autoSyncFrequency = ref
        .watch(synchingProvider(syncId: 1))
        .autoSyncFrequency;
    final l10n = l10nLocalizations(context)!;
    final autoSyncOptions = {
      l10n.sync_auto_off: 0,
      l10n.sync_auto_30_seconds: 30,
      l10n.sync_auto_1_minute: 60,
      l10n.sync_auto_5_minutes: 300,
      l10n.sync_auto_10_minutes: 600,
      l10n.sync_auto_30_minutes: 1800,
      l10n.sync_auto_1_hour: 3600,
      l10n.sync_auto_3_hours: 10800,
      l10n.sync_auto_6_hours: 21600,
      l10n.sync_auto_12_hours: 43200,
    };
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
                                l10nLocalizations(context)!.syncing,
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
          stream: isar.syncPreferences.filter().syncIdIsNotNull().watch(
            fireImmediately: true,
          ),
          builder: (context, snapshot) {
                  SyncPreference syncPreference = snapshot.data?.isNotEmpty ?? false
                      ? snapshot.data?.first ?? SyncPreference()
                      : SyncPreference();
                  final bool isLogged = syncPreference.authToken?.isNotEmpty ?? false;
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildSettingsSection(
                        context,
                        title: 'Sync Settings',
                        items: [
                          _SettingsSwitchItem(
                            title: context.l10n.sync_on,
                            subtitle: '',
                            icon: Icons.sync_rounded,
                            iconColor: Colors.blue,
                            value: syncProvider.syncOn,
                            onChanged: !isLogged
                                ? null
                                : (value) {
                                    ref
                                        .read(SynchingProvider(syncId: 1).notifier)
                                        .setSyncOn(value);
                                  },
                          ),
                          _SettingsItem(
                            title: l10n.sync_auto,
                            subtitle: autoSyncOptions.entries
                                .where((o) => o.value == autoSyncFrequency)
                                .first
                                .key,
                            icon: Icons.schedule_rounded,
                            iconColor: Colors.green,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(l10n.sync_auto),
                                    content: SizedBox(
                                      width: context.width(0.8),
                                      child: SuperListView.builder(
                                        shrinkWrap: true,
                                        itemCount: autoSyncOptions.length,
                                        itemBuilder: (context, index) {
                                          final optionName = autoSyncOptions.keys
                                              .elementAt(index);
                                          final optionValue = autoSyncOptions.values
                                              .elementAt(index);
                                          return RadioListTile(
                                            dense: true,
                                            contentPadding: const EdgeInsets.all(0),
                                            value: optionValue,
                                            groupValue: autoSyncFrequency,
                                            onChanged: (value) {
                                              ref
                                                  .read(
                                                    synchingProvider(syncId: 1).notifier,
                                                  )
                                                  .setAutoSyncFrequency(value!);
                                              Navigator.pop(context);
                                            },
                                            title: Text(optionName),
                                          );
                                        },
                                      ),
                                    ),
                                    actions: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                              l10n.cancel,
                                              style: TextStyle(
                                                color: context.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(context, l10n.sync_auto_warning),
                      const SizedBox(height: 16),
                      _buildSettingsSection(
                        context,
                        title: 'Services',
                        items: [
                          _SettingsItem(
                            title: 'SyncServer',
                            subtitle: isLogged ? 'Connected' : 'Not connected',
                            icon: Icons.cloud_sync_rounded,
                            iconColor: isLogged ? Colors.green : Colors.grey,
                            onTap: () async {
                              _showDialogLogin(context, ref);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(context, l10n.syncing_subtitle),
                const SizedBox(height: 16),
                _buildSyncStatusSection(context, syncPreference, ref, l10n),
                const SizedBox(height: 16),
                _buildSyncActionsSection(context, isLogged, ref, l10n),
                const SizedBox(height: 24),
                _buildPendingChangesSection(context, changedParts, l10n),
                const SizedBox(height: 16),
                _buildSettingsSection(
                  context,
                  title: 'Snapshots',
                  items: [
                    _SettingsItem(
                      title: l10n.sync_browse_snapshots,
                      subtitle: '',
                      icon: Icons.history_rounded,
                      iconColor: Colors.purple,
                      onTap: !isLogged
                          ? () {}
                          : () async {
                              final snapshots = await ref
                                  .read(
                                    syncServerProvider(syncId: 1).notifier,
                                  )
                                  .getSnapshots(l10n);
                              if (context.mounted) {
                                _showSnapshotsDialog(context, snapshots, ref, l10n);
                              }
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                    ],
                  );
                }),
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
    required ValueChanged<bool>? onChanged,
    bool showDivider = true,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onChanged != null ? () => onChanged(!value) : null,
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
  
  Widget _buildInfoSection(BuildContext context, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
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
                color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSyncStatusSection(BuildContext context, SyncPreference syncPreference, WidgetRef ref, dynamic l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.withValues(alpha: 0.2),
                            Colors.blue.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Sync History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatusRow(
                  context,
                  Icons.sync_rounded,
                  l10n.last_sync,
                  "${dateFormat((syncPreference.lastSync ?? 0).toString(), ref: ref, context: context)} ${dateFormatHour((syncPreference.lastSync ?? 0).toString(), context)}",
                ),
                const SizedBox(height: 8),
                _buildStatusRow(
                  context,
                  Icons.cloud_upload_rounded,
                  l10n.last_upload,
                  "${dateFormat((syncPreference.lastUpload ?? 0).toString(), ref: ref, context: context)} ${dateFormatHour((syncPreference.lastUpload ?? 0).toString(), context)}",
                ),
                const SizedBox(height: 8),
                _buildStatusRow(
                  context,
                  Icons.cloud_download_rounded,
                  l10n.last_download,
                  "${dateFormat((syncPreference.lastDownload ?? 0).toString(), ref: ref, context: context)} ${dateFormatHour((syncPreference.lastDownload ?? 0).toString(), context)}",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.primaryColor.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSyncActionsSection(BuildContext context, bool isLogged, WidgetRef ref, dynamic l10n) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              'Actions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey.shade900.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (theme.brightness == Brightness.dark
                          ? Colors.black
                          : Colors.grey)
                      .withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            context,
                            Icons.sync_rounded,
                            l10n.sync_button_sync,
                            Colors.blue,
                            isLogged
                                ? () {
                                    ref
                                        .read(
                                          syncServerProvider(syncId: 1).notifier,
                                        )
                                        .startSync(l10n, false);
                                  }
                                : null,
                          ),
                          _buildActionButton(
                            context,
                            Icons.save_as_rounded,
                            l10n.sync_button_snapshot,
                            Colors.green,
                            isLogged
                                ? () => _showConfirmDialog(
                                      context,
                                      l10n.sync_confirm_snapshot,
                                      () {
                                        ref
                                            .read(
                                              syncServerProvider(syncId: 1).notifier,
                                            )
                                            .createSnapshot(l10n);
                                      },
                                      l10n,
                                    )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            context,
                            Icons.cloud_upload_rounded,
                            l10n.sync_button_upload,
                            Colors.orange,
                            isLogged
                                ? () => _showConfirmDialog(
                                      context,
                                      l10n.sync_confirm_upload,
                                      () {
                                        ref
                                            .read(
                                              syncServerProvider(syncId: 1).notifier,
                                            )
                                            .uploadToServer(l10n);
                                      },
                                      l10n,
                                    )
                                : null,
                          ),
                          _buildActionButton(
                            context,
                            Icons.cloud_download_rounded,
                            l10n.sync_button_download,
                            Colors.purple,
                            isLogged
                                ? () => _showConfirmDialog(
                                      context,
                                      l10n.sync_confirm_download,
                                      () {
                                        ref
                                            .read(
                                              syncServerProvider(syncId: 1).notifier,
                                            )
                                            .downloadFromServer(
                                              l10n,
                                              false,
                                              true,
                                            );
                                      },
                                      l10n,
                                    )
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback? onPressed,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = onPressed != null;
    
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isEnabled
                  ? [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.1),
                    ]
                  : [
                      Colors.grey.withValues(alpha: 0.2),
                      Colors.grey.withValues(alpha: 0.1),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEnabled
                  ? color.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Icon(
                  icon,
                  color: isEnabled ? color : Colors.grey,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isEnabled
                ? (isDark ? Colors.white70 : Colors.black87)
                : Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  void _showConfirmDialog(
    BuildContext context,
    String title,
    VoidCallback onConfirm,
    dynamic l10n,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                onConfirm();
                Navigator.pop(dialogContext);
              },
              child: Text(l10n.dialog_confirm),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildPendingChangesSection(BuildContext context, dynamic changedParts, dynamic l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final pendingItems = [
      _PendingItem(
        title: l10n.sync_pending_manga,
        icon: Icons.book_rounded,
        color: Colors.blue,
        count: changedParts.getChangedParts([
          ActionType.addItem,
          ActionType.removeItem,
          ActionType.updateItem,
        ]).length,
      ),
      _PendingItem(
        title: l10n.sync_pending_chapter,
        icon: Icons.list_rounded,
        color: Colors.green,
        count: changedParts.getChangedParts([
          ActionType.addChapter,
          ActionType.removeChapter,
          ActionType.updateChapter,
        ]).length,
      ),
      _PendingItem(
        title: l10n.sync_pending_category,
        icon: Icons.category_rounded,
        color: Colors.orange,
        count: changedParts.getChangedParts([
          ActionType.addCategory,
          ActionType.removeCategory,
          ActionType.renameCategory,
        ]).length,
      ),
      _PendingItem(
        title: l10n.sync_pending_history,
        icon: Icons.history_rounded,
        color: Colors.purple,
        count: changedParts.getChangedParts([
          ActionType.addHistory,
          ActionType.clearHistory,
          ActionType.removeHistory,
          ActionType.updateHistory,
        ]).length,
      ),
      _PendingItem(
        title: l10n.sync_pending_update,
        icon: Icons.update_rounded,
        color: Colors.red,
        count: changedParts.getChangedParts([
          ActionType.addUpdate,
          ActionType.clearUpdates,
        ]).length,
      ),
      _PendingItem(
        title: l10n.sync_pending_extension,
        icon: Icons.extension_rounded,
        color: Colors.indigo,
        count: changedParts.getChangedParts([
          ActionType.addExtension,
          ActionType.clearExtension,
          ActionType.removeExtension,
          ActionType.updateExtension,
        ]).length,
      ),
      _PendingItem(
        title: l10n.sync_pending_track,
        icon: Icons.track_changes_rounded,
        color: Colors.teal,
        count: changedParts.getChangedParts([
          ActionType.addTrack,
          ActionType.removeTrack,
          ActionType.updateTrack,
        ]).length,
      ),
    ];
    
    final totalChanges = pendingItems.fold<int>(0, (sum, item) => sum + item.count);
    final hasChanges = totalChanges > 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  'Pending Changes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasChanges 
                        ? Colors.orange.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasChanges 
                          ? Colors.orange.withValues(alpha: 0.3)
                          : Colors.green.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    hasChanges ? '$totalChanges' : 'Synced',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasChanges ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
              ],
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
                  children: pendingItems.map((item) {
                    final isLast = pendingItems.last == item;
                    final hasItemChanges = item.count > 0;
                    
                    return Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: hasItemChanges ? () {
                              // Could show details of changes
                            } : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: hasItemChanges
                                            ? [
                                                item.color.withValues(alpha: 0.2),
                                                item.color.withValues(alpha: 0.1),
                                              ]
                                            : [
                                                Colors.grey.withValues(alpha: 0.1),
                                                Colors.grey.withValues(alpha: 0.05),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        item.icon,
                                        size: 20,
                                        color: hasItemChanges ? item.color : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: hasItemChanges
                                            ? (isDark ? Colors.white : Colors.black87)
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 32),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: hasItemChanges
                                          ? item.color.withValues(alpha: 0.15)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${item.count}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: hasItemChanges ? item.color : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 72,
                            color: theme.dividerColor.withValues(alpha: 0.3),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showSnapshotsDialog(BuildContext context, List<dynamic> snapshots, WidgetRef ref, dynamic l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.sync_snapshots),
          content: SizedBox(
            width: context.width(0.9),
            height: context.height(0.6),
            child: snapshots.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_off_rounded,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No snapshots found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : SuperListView.separated(
                    shrinkWrap: true,
                    itemCount: snapshots.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final snapshot = snapshots[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800.withValues(alpha: 0.7)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.purple.withValues(alpha: 0.2),
                                          Colors.purple.withValues(alpha: 0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.save_rounded,
                                      color: Colors.purple,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "${dateFormat((snapshot.createdAt!).toString(), ref: ref, context: context)} ${dateFormatHour((snapshot.createdAt!).toString(), context)}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      _showConfirmDialog(
                                        context,
                                        l10n.sync_load_snapshot,
                                        () async {
                                          await ref
                                              .read(
                                                syncServerProvider(syncId: 1).notifier,
                                              )
                                              .downloadSnapshot(
                                                l10n,
                                                snapshot.uuid!,
                                              );
                                        },
                                        l10n,
                                      );
                                    },
                                    icon: const Icon(Icons.cloud_download_rounded, size: 18),
                                    label: Text('Load'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      _showConfirmDialog(
                                        context,
                                        l10n.sync_delete_snapshot,
                                        () async {
                                          await ref
                                              .read(
                                                syncServerProvider(syncId: 1).notifier,
                                              )
                                              .deleteSnapshot(
                                                l10n,
                                                snapshot.uuid!,
                                              );
                                        },
                                        l10n,
                                      );
                                    },
                                    icon: Icon(
                                      Icons.delete_rounded,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    label: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
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
  final ValueChanged<bool>? onChanged;
  
  const _SettingsSwitchItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onChanged,
  });
}

class _PendingItem {
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  
  const _PendingItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
  });
}

void _showDialogLogin(BuildContext context, WidgetRef ref) {
  final serverController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String server = "";
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
            l10n.login_into("SyncServer"),
            style: const TextStyle(fontSize: 30),
          ),
          content: SizedBox(
            height: 400,
            width: MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: TextFormField(
                    controller: serverController,
                    autofocus: true,
                    onChanged: (value) => setState(() {
                      server = value;
                    }),
                    decoration: InputDecoration(
                      hintText: l10n.sync_server,
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
                      hintText: l10n.sync_password,
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
                const SizedBox(height: 30),
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
                                  .read(syncServerProvider(syncId: 1).notifier)
                                  .login(l10n, server, email, password);
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
