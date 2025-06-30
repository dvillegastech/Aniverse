import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/modules/more/settings/reader/providers/reader_state_provider.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultReadingMode = ref.watch(defaultReadingModeStateProvider);
    final animatePageTransitions = ref.watch(
      animatePageTransitionsStateProvider,
    );
    final doubleTapAnimationSpeed = ref.watch(
      doubleTapAnimationSpeedStateProvider,
    );
    final pagePreloadAmount = ref.watch(pagePreloadAmountStateProvider);
    final scaleType = ref.watch(scaleTypeStateProvider);
    final backgroundColor = ref.watch(backgroundColorStateProvider);
    final usePageTapZones = ref.watch(usePageTapZonesStateProvider);
    final fullScreenReader = ref.watch(fullScreenReaderStateProvider);

    final cropBorders = ref.watch(cropBordersStateProvider);
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
                          Icons.chrome_reader_mode_rounded,
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
                                context.l10n.reader,
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
                // Reading Settings Section
                _buildSectionCard(
                  context,
                  title: 'Reading Settings',
                  icon: Icons.auto_stories,
                  iconColor: Colors.blue,
                  children: [
                    _buildEnhancedListTile(
                      context,
                      title: context.l10n.default_reading_mode,
                      subtitle: getReaderModeName(defaultReadingMode, context),
                      icon: Icons.view_carousel,
                      onTap: () => _showReadingModeDialog(context, ref, defaultReadingMode),
                    ),
                    _buildEnhancedListTile(
                      context,
                      title: context.l10n.double_tap_animation_speed,
                      subtitle: getAnimationSpeedName(doubleTapAnimationSpeed, context),
                      icon: Icons.speed,
                      onTap: () => _showAnimationSpeedDialog(context, ref, doubleTapAnimationSpeed),
                    ),
                    _buildEnhancedListTile(
                      context,
                      title: context.l10n.background_color,
                      subtitle: getBackgroundColorName(backgroundColor, context),
                      icon: Icons.format_paint,
                      onTap: () => _showBackgroundColorDialog(context, ref, backgroundColor),
                    ),
                    _buildEnhancedListTile(
                      context,
                      title: context.l10n.page_preload_amount,
                      subtitle: context.l10n.page_preload_amount_subtitle,
                      icon: Icons.cloud_download,
                      onTap: () => _showPagePreloadDialog(context, ref, pagePreloadAmount),
                    ),
                    _buildEnhancedListTile(
                      context,
                      title: context.l10n.scale_type,
                      subtitle: getScaleTypeNames(context)[scaleType.index],
                      icon: Icons.aspect_ratio,
                      onTap: () => _showScaleTypeDialog(context, ref, scaleType),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Display Settings Section
                _buildSectionCard(
                  context,
                  title: 'Display Settings',
                  icon: Icons.display_settings,
                  iconColor: Colors.purple,
                  children: [
                    _buildEnhancedSwitchTile(
                      context,
                      title: context.l10n.fullscreen,
                      icon: Icons.fullscreen,
                      value: fullScreenReader,
                      onChanged: (value) {
                        ref.read(fullScreenReaderStateProvider.notifier).set(value);
                      },
                    ),
                    _buildEnhancedSwitchTile(
                      context,
                      title: context.l10n.animate_page_transitions,
                      icon: Icons.animation,
                      value: animatePageTransitions,
                      onChanged: (value) {
                        ref
                            .read(animatePageTransitionsStateProvider.notifier)
                            .set(value);
                      },
                    ),
                    _buildEnhancedSwitchTile(
                      context,
                      title: context.l10n.crop_borders,
                      icon: Icons.crop,
                      value: cropBorders,
                      onChanged: (value) {
                        ref.read(cropBordersStateProvider.notifier).set(value);
                      },
                    ),
                    _buildEnhancedSwitchTile(
                      context,
                      title: context.l10n.use_page_tap_zones,
                      icon: Icons.touch_app,
                      value: usePageTapZones,
                      onChanged: (value) {
                        ref.read(usePageTapZonesStateProvider.notifier).set(value);
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
  
  void _showReadingModeDialog(BuildContext context, WidgetRef ref, ReaderMode currentMode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.default_reading_mode),
          content: SizedBox(
            width: context.width(0.8),
            child: SuperListView.builder(
              shrinkWrap: true,
              itemCount: ReaderMode.values.length,
              itemBuilder: (context, index) {
                return RadioListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.all(0),
                  value: ReaderMode.values[index],
                  groupValue: currentMode,
                  onChanged: (value) {
                    ref
                        .read(defaultReadingModeStateProvider.notifier)
                        .set(value!);
                    Navigator.pop(context);
                  },
                  title: Text(
                    getReaderModeName(
                      ReaderMode.values[index],
                      context,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.l10n.cancel,
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showAnimationSpeedDialog(BuildContext context, WidgetRef ref, int currentSpeed) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.double_tap_animation_speed),
          content: SizedBox(
            width: context.width(0.8),
            child: SuperListView.builder(
              shrinkWrap: true,
              itemCount: 3,
              itemBuilder: (context, index) {
                return RadioListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.all(0),
                  value: index,
                  groupValue: currentSpeed,
                  onChanged: (value) {
                    ref
                        .read(doubleTapAnimationSpeedStateProvider.notifier)
                        .set(value!);
                    Navigator.pop(context);
                  },
                  title: Text(getAnimationSpeedName(index, context)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.l10n.cancel,
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showBackgroundColorDialog(BuildContext context, WidgetRef ref, BackgroundColor currentColor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.background_color),
          content: SizedBox(
            width: context.width(0.8),
            child: SuperListView.builder(
              shrinkWrap: true,
              itemCount: BackgroundColor.values.length,
              itemBuilder: (context, index) {
                return RadioListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.all(0),
                  value: BackgroundColor.values[index],
                  groupValue: currentColor,
                  onChanged: (value) {
                    ref
                        .read(backgroundColorStateProvider.notifier)
                        .set(value!);
                    Navigator.pop(context);
                  },
                  title: Text(
                    getBackgroundColorName(
                      BackgroundColor.values[index],
                      context,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.l10n.cancel,
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showPagePreloadDialog(BuildContext context, WidgetRef ref, int currentAmount) {
    List<int> numbers = [4, 6, 8, 10, 12, 14, 16, 18, 20];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.page_preload_amount),
          content: SizedBox(
            width: context.width(0.8),
            child: SuperListView.builder(
              shrinkWrap: true,
              itemCount: numbers.length,
              itemBuilder: (context, index) {
                return RadioListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.all(0),
                  value: numbers[index],
                  groupValue: currentAmount,
                  onChanged: (value) {
                    ref
                        .read(pagePreloadAmountStateProvider.notifier)
                        .set(value!);
                    Navigator.pop(context);
                  },
                  title: Text(numbers[index].toString()),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.l10n.cancel,
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showScaleTypeDialog(BuildContext context, WidgetRef ref, ScaleType currentType) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.scale_type),
          content: SizedBox(
            width: context.width(0.8),
            child: SuperListView.builder(
              shrinkWrap: true,
              itemCount: getScaleTypeNames(context).length,
              itemBuilder: (context, index) {
                return RadioListTile(
                  contentPadding: const EdgeInsets.all(0),
                  value: index,
                  groupValue: currentType.index,
                  onChanged: (value) {
                    ref
                        .read(scaleTypeStateProvider.notifier)
                        .set(ScaleType.values[value!]);
                    Navigator.pop(context);
                  },
                  title: Text(
                    getScaleTypeNames(context)[index].toString(),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.l10n.cancel,
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }
}

String getReaderModeName(ReaderMode readerMode, BuildContext context) {
  return switch (readerMode) {
    ReaderMode.vertical => context.l10n.reading_mode_vertical,
    ReaderMode.verticalContinuous =>
      context.l10n.reading_mode_vertical_continuous,
    ReaderMode.ltr => context.l10n.reading_mode_left_to_right,
    ReaderMode.rtl => context.l10n.reading_mode_right_to_left,
    ReaderMode.horizontalContinuous => context.l10n.horizontal_continious,
    _ => context.l10n.reading_mode_webtoon,
  };
}

String getBackgroundColorName(
  BackgroundColor backgroundColor,
  BuildContext context,
) {
  return switch (backgroundColor) {
    BackgroundColor.white => context.l10n.white,
    BackgroundColor.grey => context.l10n.grey,
    BackgroundColor.black => context.l10n.black,
    _ => context.l10n.automaic,
  };
}

Color? getBackgroundColor(BackgroundColor backgroundColor) {
  return switch (backgroundColor) {
    BackgroundColor.white => Colors.white,
    BackgroundColor.grey => Colors.grey,
    BackgroundColor.black => Colors.black,
    _ => null,
  };
}

String getColorFilterBlendModeName(
  ColorFilterBlendMode backgroundColor,
  BuildContext context,
) {
  return switch (backgroundColor) {
    ColorFilterBlendMode.none => context.l10n.blend_mode_default,
    ColorFilterBlendMode.multiply => context.l10n.blend_mode_multiply,
    ColorFilterBlendMode.screen => context.l10n.blend_mode_screen,
    ColorFilterBlendMode.overlay => context.l10n.blend_mode_overlay,
    ColorFilterBlendMode.colorDodge => context.l10n.blend_mode_colorDodge,
    ColorFilterBlendMode.lighten => context.l10n.blend_mode_lighten,
    ColorFilterBlendMode.colorBurn => context.l10n.blend_mode_colorBurn,
    ColorFilterBlendMode.difference => context.l10n.blend_mode_difference,
    ColorFilterBlendMode.saturation => context.l10n.blend_mode_saturation,
    ColorFilterBlendMode.softLight => context.l10n.blend_mode_softLight,
    ColorFilterBlendMode.plus => context.l10n.blend_mode_plus,
    ColorFilterBlendMode.exclusion => context.l10n.blend_mode_exclusion,
    _ => context.l10n.blend_mode_darken,
  };
}

BlendMode? getColorFilterBlendMode(
  ColorFilterBlendMode backgroundColor,
  BuildContext context,
) {
  return switch (backgroundColor) {
    ColorFilterBlendMode.none => null,
    ColorFilterBlendMode.multiply => BlendMode.multiply,
    ColorFilterBlendMode.screen => BlendMode.screen,
    ColorFilterBlendMode.overlay => BlendMode.overlay,
    ColorFilterBlendMode.colorDodge => BlendMode.colorDodge,
    ColorFilterBlendMode.lighten => BlendMode.lighten,
    ColorFilterBlendMode.colorBurn => BlendMode.colorBurn,
    ColorFilterBlendMode.difference => BlendMode.difference,
    ColorFilterBlendMode.saturation => BlendMode.saturation,
    ColorFilterBlendMode.softLight => BlendMode.softLight,
    ColorFilterBlendMode.plus => BlendMode.plus,
    ColorFilterBlendMode.exclusion => BlendMode.exclusion,
    _ => BlendMode.darken,
  };
}

String getAnimationSpeedName(int type, BuildContext context) {
  return switch (type) {
    0 => context.l10n.no_animation,
    1 => context.l10n.normal,
    _ => context.l10n.fast,
  };
}

List<String> getScaleTypeNames(BuildContext context) {
  return [
    context.l10n.scale_type_fit_screen,
    context.l10n.scale_type_stretch,
    context.l10n.scale_type_fit_width,
    context.l10n.scale_type_fit_height,
    // l10n.scale_type_original_size,
    // l10n.scale_type_smart_fit,
  ];
}
