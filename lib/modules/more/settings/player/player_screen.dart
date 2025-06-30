import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/modules/more/settings/player/providers/player_state_provider.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/utils/language.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:mangayomi/l10n/generated/app_localizations.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultSubtitleLang = ref.watch(defaultSubtitleLangStateProvider);
    final markEpisodeAsSeenType = ref.watch(markEpisodeAsSeenTypeStateProvider);
    final defaultSkipIntroLength = ref.watch(
      defaultSkipIntroLengthStateProvider,
    );
    final defaultDoubleTapToSkipLength = ref.watch(
      defaultDoubleTapToSkipLengthStateProvider,
    );
    final defaultPlayBackSpeed = ref.watch(defaultPlayBackSpeedStateProvider);
    final useLibass = ref.watch(useLibassStateProvider);
    final hwdecMode = ref.watch(hwdecModeStateProvider(rawValue: true));

    final fullScreenPlayer = ref.watch(fullScreenPlayerStateProvider);
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
                                context.l10n.player,
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
                  ref,
                  title: 'Playback',
                  items: [
                    _SettingsItem(
                      title: context.l10n.default_subtitle_language,
                      subtitle: completeLanguageName(defaultSubtitleLang.toLanguageTag()),
                      icon: Icons.subtitles_outlined,
                      iconColor: Colors.blue,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(context.l10n.default_subtitle_language),
                              content: SizedBox(
                                width: context.width(0.8),
                                child: SuperListView.builder(
                                  shrinkWrap: true,
                                  itemCount: AppLocalizations.supportedLocales.length,
                                  itemBuilder: (context, index) {
                                    final locale =
                                        AppLocalizations.supportedLocales[index];
                                    return RadioListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.all(0),
                                      value: locale,
                                      groupValue: defaultSubtitleLang,
                                      onChanged: (value) {
                                        ref
                                            .read(
                                              defaultSubtitleLangStateProvider.notifier,
                                            )
                                            .setLocale(locale);
                                        Navigator.pop(context);
                                      },
                                      title: Text(
                                        completeLanguageName(locale.toLanguageTag()),
                                      ),
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
                                        context.l10n.cancel,
                                        style: TextStyle(color: context.primaryColor),
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
                    _SettingsItem(
                      title: context.l10n.markEpisodeAsSeenSetting,
                      subtitle: "$markEpisodeAsSeenType%",
                      icon: Icons.check_circle_outline,
                      iconColor: Colors.green,
                      onTap: () {
                        final values = [100, 95, 90, 85, 80, 75, 70];
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(context.l10n.markEpisodeAsSeenSetting),
                              content: SizedBox(
                                width: context.width(0.8),
                                child: SuperListView.builder(
                                  shrinkWrap: true,
                                  itemCount: values.length,
                                  itemBuilder: (context, index) {
                                    return RadioListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.all(0),
                                      value: values[index],
                                      groupValue: markEpisodeAsSeenType,
                                      onChanged: (value) {
                                        ref
                                            .read(
                                              markEpisodeAsSeenTypeStateProvider
                                                  .notifier,
                                            )
                                            .set(value!);
                                        Navigator.pop(context);
                                      },
                                      title: Row(children: [Text("${values[index]}%")]),
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
                                        context.l10n.cancel,
                                        style: TextStyle(color: context.primaryColor),
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
                    _SettingsItem(
                      title: context.l10n.default_skip_intro_length,
                      subtitle: "${defaultSkipIntroLength}s",
                      icon: Icons.skip_next_rounded,
                      iconColor: Colors.orange,
                      onTap: () {
                        int currentIntValue = defaultSkipIntroLength;
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(context.l10n.default_skip_intro_length),
                              content: StatefulBuilder(
                                builder: (context, setState) => SizedBox(
                                  height: 200,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      NumberPicker(
                                        value: currentIntValue,
                                        minValue: 1,
                                        maxValue: 255,
                                        step: 1,
                                        haptics: true,
                                        textMapper: (numberText) => "${numberText}s",
                                        onChanged: (value) =>
                                            setState(() => currentIntValue = value),
                                      ),
                                    ],
                                  ),
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
                                        context.l10n.cancel,
                                        style: TextStyle(color: context.primaryColor),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        ref
                                            .read(
                                              defaultSkipIntroLengthStateProvider
                                                  .notifier,
                                            )
                                            .set(currentIntValue);
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        context.l10n.ok,
                                        style: TextStyle(color: context.primaryColor),
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
                    _SettingsItem(
                      title: context.l10n.default_skip_forward_skip_length,
                      subtitle: "${defaultDoubleTapToSkipLength}s",
                      icon: Icons.fast_forward_rounded,
                      iconColor: Colors.purple,
                      onTap: () {
                        final values = [30, 20, 10, 5, 3, 1];
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                context.l10n.default_skip_forward_skip_length,
                              ),
                              content: SizedBox(
                                width: context.width(0.8),
                                child: SuperListView.builder(
                                  shrinkWrap: true,
                                  itemCount: values.length,
                                  itemBuilder: (context, index) {
                                    return RadioListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.all(0),
                                      value: values[index],
                                      groupValue: defaultDoubleTapToSkipLength,
                                      onChanged: (value) {
                                        ref
                                            .read(
                                              defaultDoubleTapToSkipLengthStateProvider
                                                  .notifier,
                                            )
                                            .set(value!);
                                        Navigator.pop(context);
                                      },
                                      title: Row(children: [Text("${values[index]}s")]),
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
                                        context.l10n.cancel,
                                        style: TextStyle(color: context.primaryColor),
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
                    _SettingsItem(
                      title: context.l10n.default_playback_speed_length,
                      subtitle: "x$defaultPlayBackSpeed",
                      icon: Icons.speed_rounded,
                      iconColor: Colors.red,
                      onTap: () {
                        final values = [0.25, 0.5, 0.75, 1.0, 1.25, 1.50, 1.75, 2.0];
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(context.l10n.default_playback_speed_length),
                              content: SizedBox(
                                width: context.width(0.8),
                                child: SuperListView.builder(
                                  shrinkWrap: true,
                                  itemCount: values.length,
                                  itemBuilder: (context, index) {
                                    return RadioListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.all(0),
                                      value: values[index],
                                      groupValue: defaultPlayBackSpeed,
                                      onChanged: (value) {
                                        ref
                                            .read(
                                              defaultPlayBackSpeedStateProvider
                                                  .notifier,
                                            )
                                            .set(value!);
                                        Navigator.pop(context);
                                      },
                                      title: Row(children: [Text("x${values[index]}")]),
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
                                        context.l10n.cancel,
                                        style: TextStyle(color: context.primaryColor),
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
                _buildSettingsSection(
                  context,
                  ref,
                  title: 'Advanced Settings',
                  items: [
                    _SettingsSwitchItem(
                      title: context.l10n.use_libass,
                      subtitle: context.l10n.use_libass_info,
                      icon: Icons.subtitles_outlined,
                      iconColor: Colors.indigo,
                      value: useLibass,
                      onChanged: (value) {
                        ref.read(useLibassStateProvider.notifier).set(value);
                      },
                    ),
                    _SettingsSwitchItem(
                      title: context.l10n.full_screen_player,
                      subtitle: context.l10n.full_screen_player_info,
                      icon: Icons.fullscreen_rounded,
                      iconColor: Colors.deepOrange,
                      value: fullScreenPlayer,
                      onChanged: (value) {
                        ref.read(fullScreenPlayerStateProvider.notifier).set(value);
                      },
                    ),
                    _SettingsItem(
                      title: context.l10n.hwdec,
                      subtitle: hwdecMode,
                      icon: Icons.memory_rounded,
                      iconColor: Colors.teal,
                      onTap: () {
                        final values = [
                          ("no", ""),
                          ("auto", ""),
                          ("d3d11va", "(Windows 8+)"),
                          ("d3d11va-copy", "(Windows 8+)"),
                          ("videotoolbox", "(iOS 9.0+)"),
                          ("videotoolbox-copy", "(iOS 9.0+)"),
                          ("nvdec", "(CUDA)"),
                          ("nvdec-copy", "(CUDA)"),
                          ("mediacodec", "- HW (Android)"),
                          ("mediacodec-copy", "- HW+ (Android)"),
                          ("crystalhd", ""),
                        ];
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(context.l10n.hwdec),
                              content: SizedBox(
                                width: context.width(0.8),
                                child: SuperListView.builder(
                                  shrinkWrap: true,
                                  itemCount: values.length,
                                  itemBuilder: (context, index) {
                                    return RadioListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.all(0),
                                      value: values[index].$1,
                                      groupValue: hwdecMode,
                                      onChanged: (value) {
                                        ref
                                            .read(hwdecModeStateProvider(rawValue: true).notifier)
                                            .set(value!);
                                        Navigator.pop(context);
                                      },
                                      title: Row(
                                        children: [
                                          Text(
                                            "${values[index].$1} ${values[index].$2}",
                                          ),
                                        ],
                                      ),
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
                                        context.l10n.cancel,
                                        style: TextStyle(color: context.primaryColor),
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
                _buildAniSkipSection(context, ref),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsSection(
    BuildContext context,
    WidgetRef ref, {
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
  
  Widget _buildAniSkipSection(BuildContext context, WidgetRef ref) {
    final enableAniSkip = ref.watch(enableAniSkipStateProvider);
    final enableAutoSkip = ref.watch(enableAutoSkipStateProvider);
    final aniSkipTimeoutLength = ref.watch(aniSkipTimeoutLengthStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                'AniSkip',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: theme.primaryColor.withValues(alpha: 0.6),
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
                children: [
                  _buildSwitchTile(
                    context,
                    title: context.l10n.enable_aniskip,
                    subtitle: context.l10n.aniskip_requires_info,
                    icon: Icons.skip_next_outlined,
                    iconColor: Colors.cyan,
                    value: enableAniSkip,
                    onChanged: (value) {
                      ref.read(enableAniSkipStateProvider.notifier).set(value);
                    },
                    showDivider: enableAniSkip,
                  ),
                  if (enableAniSkip) ...[
                    _buildSwitchTile(
                      context,
                      title: context.l10n.enable_auto_skip,
                      subtitle: '',
                      icon: Icons.auto_mode_rounded,
                      iconColor: Colors.amber,
                      value: enableAutoSkip,
                      onChanged: (value) {
                        ref.read(enableAutoSkipStateProvider.notifier).set(value);
                      },
                      showDivider: true,
                    ),
                    _buildSettingsTile(
                      context,
                      title: context.l10n.aniskip_button_timeout,
                      subtitle: "${aniSkipTimeoutLength}s",
                      icon: Icons.timer_outlined,
                      iconColor: Colors.deepPurple,
                      onTap: () {
                        final values = [5, 6, 7, 8, 9, 10];
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                context.l10n.aniskip_button_timeout,
                              ),
                              content: SizedBox(
                                width: context.width(0.8),
                                child: SuperListView.builder(
                                  shrinkWrap: true,
                                  itemCount: values.length,
                                  itemBuilder: (context, index) {
                                    return RadioListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.all(0),
                                      value: values[index],
                                      groupValue: aniSkipTimeoutLength,
                                      onChanged: (value) {
                                        ref
                                            .read(
                                              aniSkipTimeoutLengthStateProvider
                                                  .notifier,
                                            )
                                            .set(value!);
                                        Navigator.pop(context);
                                      },
                                      title: Row(
                                        children: [Text("${values[index]}s")],
                                      ),
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
                                        context.l10n.cancel,
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
                      showDivider: false,
                    ),
                  ],
                ],
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
