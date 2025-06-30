import 'dart:ui';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mangayomi/main.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/modules/more/settings/appearance/providers/flex_scheme_color_state_provider.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class ThemeSelector extends ConsumerStatefulWidget {
  const ThemeSelector({super.key, this.contentPadding});
  final EdgeInsetsGeometry? contentPadding;

  @override
  ConsumerState<ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends ConsumerState<ThemeSelector> {
  @override
  Widget build(BuildContext context) {
    int selected = isar.settings.getSync(227)!.flexSchemeColorIndex!;
    const double height = 64;
    const double width = height * 1.3;
    final ThemeData theme = Theme.of(context);
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final bool isDark = !isLight;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SuperListView.builder(
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: ThemeAA.schemes.length,
        itemBuilder: (BuildContext context, int index) {
          final isSelected = selected == index;
          final flexColor = isLight
              ? ThemeAA.schemes[index].light
              : ThemeAA.schemes[index].dark;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selected = index;
                });
                isLight
                    ? ref
                          .read(
                            flexSchemeColorStateProvider.notifier,
                          )
                          .setTheme(
                            ThemeAA.schemes[selected].light,
                            selected,
                          )
                    : ref
                          .read(
                            flexSchemeColorStateProvider.notifier,
                          )
                          .setTheme(
                            ThemeAA.schemes[selected].dark,
                            selected,
                          );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? theme.primaryColor
                              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          width: isSelected ? 3 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          children: [
                            // Background with gradient
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    flexColor.primary,
                                    flexColor.primaryContainer ?? flexColor.primary.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                            ),
                            // Color preview grid
                            Positioned.fill(
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      color: flexColor.primary,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            color: flexColor.secondary,
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            color: flexColor.tertiary ?? flexColor.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Glass effect overlay
                            if (isSelected)
                              Positioned.fill(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                                  child: Container(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                              ),
                            // Selected indicator
                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: flexColor.primary,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: isSelected ? 13 : 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? theme.primaryColor
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      child: Text(
                        ThemeAA.schemes[index].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
