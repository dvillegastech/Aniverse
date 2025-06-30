import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mangayomi/modules/more/settings/appearance/providers/app_font_family.dart';
import 'package:mangayomi/modules/more/settings/appearance/providers/theme_mode_state_provider.dart';
import 'package:mangayomi/modules/more/settings/appearance/widgets/follow_system_theme_button.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/utils/date.dart';
import 'package:mangayomi/modules/more/settings/appearance/providers/date_format_state_provider.dart';
import 'package:mangayomi/modules/more/settings/appearance/providers/pure_black_dark_mode_state_provider.dart';
import 'package:mangayomi/modules/more/settings/appearance/widgets/blend_level_slider.dart';
import 'package:mangayomi/modules/more/settings/appearance/widgets/dark_mode_button.dart';
import 'package:mangayomi/modules/more/settings/appearance/widgets/theme_selector.dart';
import 'package:mangayomi/l10n/generated/app_localizations.dart';
import 'package:mangayomi/utils/language.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

final navigationItems = {
  "/MangaLibrary": "Manga",
  "/AnimeLibrary": "Anime",
  "/NovelLibrary": "Novel",
  "/updates": "Updates",
  "/history": "History",
  "/browse": "Browse",
  "/more": "More",
  "/trackerLibrary": "Tracking",
};

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final IconData? icon;
  final Color? iconColor;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
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
                      if (icon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                (iconColor ?? theme.primaryColor).withValues(alpha: 0.2),
                                (iconColor ?? theme.primaryColor).withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: iconColor ?? theme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
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
      ),
    );
  }
}

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = l10nLocalizations(context);
    final pureBlackDarkMode = ref.watch(pureBlackDarkModeStateProvider);
    final isDarkTheme = ref.watch(themeModeStateProvider);
    bool followSystemTheme = ref.watch(followSystemThemeStateProvider);
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
                          Icons.color_lens_rounded,
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
                                l10n!.appearance,
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
                SettingsSection(
                  title: l10n!.theme,
                  icon: Icons.palette_outlined,
                  iconColor: Colors.purple,
                  children: [
                    const FollowSystemThemeButton(),
                    if (!followSystemTheme) const DarkModeButton(),
                    const ThemeSelector(),
                    if (isDarkTheme)
                      _buildEnhancedSwitchTile(
                        context,
                        title: l10n.pure_black_dark_mode,
                        icon: Icons.dark_mode,
                        value: pureBlackDarkMode,
                        onChanged: (value) {
                          ref
                              .read(pureBlackDarkModeStateProvider.notifier)
                              .set(value);
                        },
                      ),
                    if (!pureBlackDarkMode || !isDarkTheme)
                      const BlendLevelSlider(),
                  ],
                ),
                SettingsSection(
                  title: l10n.appearance,
                  icon: Icons.tune,
                  iconColor: Colors.blue,
                  children: [
                    _buildLanguageTile(context, ref, l10n),
                    _buildFontTile(context, ref, l10n),
                    _buildEnhancedListTile(
                      context,
                      title: l10n.reorder_navigation,
                      subtitle: l10n.reorder_navigation_description,
                      icon: Icons.drag_handle,
                      onTap: () => context.push("/customNavigationSettings"),
                    ),
                  ],
                ),
                SettingsSection(
                  title: l10n.timestamp,
                  icon: Icons.schedule,
                  iconColor: Colors.orange,
                  children: [
                    _buildRelativeTimestampTile(context, ref, l10n),
                    _buildDateFormatTile(context, ref, l10n),
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

  Widget _buildLanguageTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final l10nLocale = ref.watch(l10nLocaleStateProvider);
    return _buildEnhancedListTile(
      context,
      title: l10n.app_language,
      subtitle: completeLanguageName(l10nLocale.toLanguageTag()),
      icon: Icons.language,
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(l10n.app_language),
              content: SizedBox(
                width: context.width(0.8),
                child: SuperListView.builder(
                  shrinkWrap: true,
                  itemCount: AppLocalizations.supportedLocales.length,
                  itemBuilder: (context, index) {
                    final locale = AppLocalizations.supportedLocales[index];
                    return RadioListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.all(0),
                      value: locale,
                      groupValue: l10nLocale,
                      onChanged: (value) {
                        ref
                            .read(l10nLocaleStateProvider.notifier)
                            .setLocale(locale);
                        Navigator.pop(context);
                      },
                      title: Text(completeLanguageName(locale.toLanguageTag())),
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
    );
  }

  Widget _buildFontTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final appFontFamily = ref.watch(appFontFamilyProvider);
    final appFontFamilySub = appFontFamily == null
        ? context.l10n.default0
        : GoogleFonts.asMap().entries
              .toList()
              .firstWhere(
                (element) => element.value().fontFamily! == appFontFamily,
              )
              .key;
    return _buildEnhancedListTile(
      context,
      title: context.l10n.font,
      subtitle: appFontFamilySub,
      icon: Icons.text_fields,
      onTap: () {
        String textValue = "";
        final controller = ScrollController();
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(context.l10n.font),
              content: StatefulBuilder(
                builder: (context, setState) {
                  return SizedBox(
                    width: context.width(0.8),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          child: TextField(
                            onChanged: (v) {
                              setState(() {
                                textValue = v;
                              });
                            },
                            decoration: InputDecoration(
                              isDense: true,
                              filled: false,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: context.secondaryColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: context.primaryColor,
                                ),
                              ),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(),
                              ),
                              hintText: l10n.search,
                            ),
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            List values = GoogleFonts.asMap().entries.toList();
                            values = values
                                .where(
                                  (values) => values.key.toLowerCase().contains(
                                    textValue.toLowerCase(),
                                  ),
                                )
                                .toList();
                            return Flexible(
                              child: Scrollbar(
                                interactive: true,
                                thickness: 12,
                                radius: const Radius.circular(10),
                                controller: controller,
                                child: CustomScrollView(
                                  controller: controller,
                                  slivers: [
                                    SliverPadding(
                                      padding: const EdgeInsets.all(0),
                                      sliver: SuperSliverList.builder(
                                        itemCount: values.length,
                                        itemBuilder: (context, index) {
                                          final value = values[index];
                                          return RadioListTile(
                                            dense: true,
                                            contentPadding:
                                                const EdgeInsets.all(0),
                                            value: value.value().fontFamily,
                                            groupValue: appFontFamily,
                                            onChanged: (value) {
                                              ref
                                                  .read(
                                                    appFontFamilyProvider
                                                        .notifier,
                                                  )
                                                  .set(value);
                                              Navigator.pop(context);
                                            },
                                            title: Text(value.key),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        ref.read(appFontFamilyProvider.notifier).set(null);
                        Navigator.pop(context);
                      },
                      child: Text(
                        l10n.default0,
                        style: TextStyle(color: context.primaryColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                      child: Text(
                        l10n.cancel,
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
    );
  }

  Widget _buildRelativeTimestampTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final relativeTimestamps = ref.watch(relativeTimesTampsStateProvider);
    return _buildEnhancedListTile(
      context,
      title: l10n.relative_timestamp,
      subtitle: relativeTimestampsList(context)[relativeTimestamps],
      icon: Icons.access_time,
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(l10n.relative_timestamp),
              content: SizedBox(
                width: context.width(0.8),
                child: SuperListView.builder(
                  shrinkWrap: true,
                  itemCount: relativeTimestampsList(context).length,
                  itemBuilder: (context, index) {
                    return RadioListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.all(0),
                      value: index,
                      groupValue: relativeTimestamps,
                      onChanged: (value) {
                        ref
                            .read(relativeTimesTampsStateProvider.notifier)
                            .set(value!);
                        Navigator.pop(context);
                      },
                      title: Row(
                        children: [
                          Text(relativeTimestampsList(context)[index]),
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
                        l10n.cancel,
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
    );
  }

  Widget _buildDateFormatTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final dateFormatState = ref.watch(dateFormatStateProvider);
    return _buildEnhancedListTile(
      context,
      title: l10n.date_format,
      subtitle: "$dateFormatState (${dateFormat(context: context, DateTime.now().millisecondsSinceEpoch.toString(), useRelativeTimesTamps: false, dateFormat: dateFormatState, ref: ref)})",
      icon: Icons.calendar_today,
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(l10n.date_format),
              content: SizedBox(
                width: context.width(0.8),
                child: SuperListView.builder(
                  shrinkWrap: true,
                  itemCount: dateFormatsList.length,
                  itemBuilder: (context, index) {
                    return RadioListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.all(0),
                      value: dateFormatsList[index],
                      groupValue: dateFormatState,
                      onChanged: (value) {
                        ref.read(dateFormatStateProvider.notifier).set(value!);
                        Navigator.pop(context);
                      },
                      title: Row(
                        children: [
                          Text(
                            "${dateFormatsList[index]} (${dateFormat(context: context, DateTime.now().millisecondsSinceEpoch.toString(), useRelativeTimesTamps: false, dateFormat: dateFormatsList[index], ref: ref)})",
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
                        l10n.cancel,
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
}
