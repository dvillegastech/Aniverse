import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/modules/more/settings/appearance/appearance_screen.dart';
import 'package:mangayomi/modules/more/settings/reader/providers/reader_state_provider.dart';
import 'package:mangayomi/providers/l10n_providers.dart';

class CustomNavigationSettings extends ConsumerStatefulWidget {
  const CustomNavigationSettings({super.key});

  @override
  ConsumerState<CustomNavigationSettings> createState() =>
      _CustomNavigationSettingsState();
}

class _CustomNavigationSettingsState
    extends ConsumerState<CustomNavigationSettings> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final navigationOrder = ref.watch(navigationOrderStateProvider);
    final hideItems = ref.watch(hideItemsStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final navigationIcons = {
      "/MangaLibrary": Icons.book_rounded,
      "/AnimeLibrary": Icons.movie_rounded,
      "/NovelLibrary": Icons.menu_book_rounded,
      "/updates": Icons.update_rounded,
      "/history": Icons.history_rounded,
      "/browse": Icons.explore_rounded,
      "/more": Icons.more_horiz_rounded,
      "/trackerLibrary": Icons.track_changes_rounded,
    };
    
    final navigationColors = {
      "/MangaLibrary": Colors.blue,
      "/AnimeLibrary": Colors.red,
      "/NovelLibrary": Colors.green,
      "/updates": Colors.orange,
      "/history": Colors.purple,
      "/browse": Colors.cyan,
      "/more": Colors.grey,
      "/trackerLibrary": Colors.indigo,
    };
    
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
                                l10n.reorder_navigation,
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
            sliver: SliverReorderableList(
              itemCount: navigationOrder.length,
              itemBuilder: (context, index) {
                final navigation = navigationOrder[index];
                final isRequired = ["/more", "/browse", "/history"].contains(navigation);
                final isVisible = !hideItems.contains(navigation);
                
                return Material(
                  key: ValueKey('navigation_$navigation'),
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
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
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.drag_handle_rounded,
                                    color: theme.primaryColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      navigationColors[navigation]!.withValues(alpha: 0.2),
                                      navigationColors[navigation]!.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  navigationIcons[navigation]!,
                                  color: navigationColors[navigation],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      navigationItems[navigation]!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    if (isRequired) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Required',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Switch(
                                value: isVisible,
                                onChanged: isRequired
                                    ? null
                                    : (value) {
                                        final temp = hideItems.toList();
                                        if (!value && !hideItems.contains(navigation)) {
                                          temp.add(navigation);
                                        } else if (value) {
                                          temp.remove(navigation);
                                        }
                                        ref.read(hideItemsStateProvider.notifier).set(temp);
                                      },
                                activeColor: navigationColors[navigation],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  final draggedItem = navigationOrder[oldIndex];
                  for (var i = oldIndex; i < newIndex - 1; i++) {
                    navigationOrder[i] = navigationOrder[i + 1];
                  }
                  navigationOrder[newIndex - 1] = draggedItem;
                } else {
                  final draggedItem = navigationOrder[oldIndex];
                  for (var i = oldIndex; i > newIndex; i--) {
                    navigationOrder[i] = navigationOrder[i - 1];
                  }
                  navigationOrder[newIndex] = draggedItem;
                }
                ref
                    .read(navigationOrderStateProvider.notifier)
                    .set(navigationOrder);
              },
            ),
          ),
        ],
      ),
    );
  }
}
