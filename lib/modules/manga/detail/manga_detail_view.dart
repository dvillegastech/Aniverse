import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:draggable_menu/draggable_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:mangayomi/eval/model/m_bridge.dart';
import 'package:mangayomi/main.dart';
import 'package:mangayomi/models/category.dart';
import 'package:mangayomi/models/changed.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/download.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/track.dart';
import 'package:mangayomi/models/track_preference.dart';
import 'package:mangayomi/models/track_search.dart';
import 'package:mangayomi/modules/library/library_screen.dart';
import 'package:mangayomi/modules/library/providers/local_archive.dart';
import 'package:mangayomi/modules/manga/detail/providers/track_state_providers.dart';
import 'package:mangayomi/modules/manga/detail/widgets/tracker_search_widget.dart';
import 'package:mangayomi/modules/manga/detail/widgets/tracker_widget.dart';
import 'package:mangayomi/modules/manga/reader/providers/reader_controller_provider.dart';
import 'package:mangayomi/modules/more/settings/appearance/providers/pure_black_dark_mode_state_provider.dart';
import 'package:mangayomi/modules/more/settings/sync/providers/sync_providers.dart';
import 'package:mangayomi/modules/more/settings/track/widgets/track_listile.dart';
import 'package:mangayomi/modules/widgets/category_selection_dialog.dart';
import 'package:mangayomi/modules/widgets/custom_draggable_tabbar.dart';
import 'package:mangayomi/modules/widgets/custom_extended_image_provider.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/providers/storage_provider.dart';
import 'package:mangayomi/utils/extensions/string_extensions.dart';
import 'package:mangayomi/utils/utils.dart';
import 'package:mangayomi/utils/cached_network.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/utils/extensions/others.dart';
import 'package:mangayomi/utils/global_style.dart';
import 'package:mangayomi/utils/headers.dart';
import 'package:mangayomi/modules/manga/detail/providers/isar_providers.dart';
import 'package:mangayomi/modules/manga/detail/providers/state_providers.dart';
import 'package:mangayomi/modules/manga/detail/widgets/readmore.dart';
import 'package:mangayomi/modules/manga/detail/widgets/chapter_filter_list_tile_widget.dart';
import 'package:mangayomi/modules/manga/detail/widgets/chapter_list_tile_widget.dart';
import 'package:mangayomi/modules/manga/detail/widgets/chapter_sort_list_tile_widget.dart';
import 'package:mangayomi/modules/manga/download/providers/download_provider.dart';
import 'package:mangayomi/modules/widgets/error_text.dart';
import 'package:mangayomi/modules/widgets/progress_center.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import '../../../utils/constant.dart';
import 'package:path/path.dart' as p;

class MangaDetailView extends ConsumerStatefulWidget {
  final Function(bool) isExtended;
  final Widget? titleDescription;
  final List<Color>? backButtonColors;
  final Widget? action;
  final Manga? manga;
  final bool sourceExist;
  final Function(bool) checkForUpdate;
  final ItemType itemType;

  const MangaDetailView({
    super.key,
    required this.isExtended,
    this.titleDescription,
    this.backButtonColors,
    this.action,
    required this.sourceExist,
    required this.manga,
    required this.checkForUpdate,
    required this.itemType,
  });

  @override
  ConsumerState<MangaDetailView> createState() => _MangaDetailViewState();
}

class _MangaDetailViewState extends ConsumerState<MangaDetailView>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        ref.read(offetProvider.notifier).state = _scrollController.offset;
      });
  }

  final offetProvider = StateProvider((ref) => 0.0);
  bool _expanded = false;
  ScrollController _scrollController = ScrollController();
  late final isLocalArchive = widget.manga!.isLocalArchive ?? false;
  @override
  Widget build(BuildContext context) {
    final isLongPressed = ref.watch(isLongPressedStateProvider);
    final chapterNameList = ref.watch(chaptersListStateProvider);
    final scanlators = ref.watch(scanlatorsFilterStateProvider(widget.manga!));
    final reverse = ref
        .watch(sortChapterStateProvider(mangaId: widget.manga!.id!))
        .reverse!;
    final filterUnread = ref.watch(
      chapterFilterUnreadStateProvider(mangaId: widget.manga!.id!),
    );
    final filterBookmarked = ref.watch(
      chapterFilterBookmarkedStateProvider(mangaId: widget.manga!.id!),
    );
    final filterDownloaded = ref.watch(
      chapterFilterDownloadedStateProvider(mangaId: widget.manga!.id!),
    );
    final sortChapter =
        ref.watch(sortChapterStateProvider(mangaId: widget.manga!.id!)).index
            as int;
    final chapters = ref.watch(
      getChaptersStreamProvider(mangaId: widget.manga!.id!),
    );
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction == ScrollDirection.forward) {
          widget.isExtended(true);
        }
        if (notification.direction == ScrollDirection.reverse) {
          widget.isExtended(false);
        }
        return true;
      },
      child: chapters.when(
        data: (data) {
          List<Chapter> chapters = _filterAndSortChapter(
            data: data.reversed.toList(),
            filterUnread: filterUnread,
            filterBookmarked: filterBookmarked,
            filterDownloaded: filterDownloaded,
            sortChapter: sortChapter,
            filterScanlator: scanlators.$2,
          );
          ref.read(chaptersListttStateProvider.notifier).set(chapters);
          return _buildWidget(
            chapters: chapters,
            reverse: reverse,
            chapterList: chapterNameList,
            isLongPressed: isLongPressed,
          );
        },
        error: (Object error, StackTrace stackTrace) {
          return ErrorText(error);
        },
        loading: () {
          return _buildWidget(
            chapters: widget.manga!.chapters.toList().reversed.toList(),
            reverse: reverse,
            chapterList: chapterNameList,
            isLongPressed: isLongPressed,
          );
        },
      ),
    );
  }

  List<Chapter> _getFilteredAndSortedChapters() {
    final filterScanlator = ref.read(
      scanlatorsFilterStateProvider(widget.manga!),
    );
    final filterUnread = ref.read(
      chapterFilterUnreadStateProvider(mangaId: widget.manga!.id!),
    );
    final filterBookmarked = ref.read(
      chapterFilterBookmarkedStateProvider(mangaId: widget.manga!.id!),
    );
    final filterDownloaded = ref.read(
      chapterFilterDownloadedStateProvider(mangaId: widget.manga!.id!),
    );
    final sortChapter =
        ref.read(sortChapterStateProvider(mangaId: widget.manga!.id!)).index
            as int;
    final chapters = isar.chapters
        .filter()
        .idIsNotNull()
        .mangaIdEqualTo(widget.manga!.id!)
        .findAllSync();
    return _filterAndSortChapter(
      data: chapters,
      filterUnread: filterUnread,
      filterBookmarked: filterBookmarked,
      filterDownloaded: filterDownloaded,
      sortChapter: sortChapter,
      filterScanlator: filterScanlator.$2,
    );
  }

  List<Chapter> _filterAndSortChapter({
    required List<Chapter> data,
    required int filterUnread,
    required int filterBookmarked,
    required int filterDownloaded,
    required int sortChapter,
    required List<String> filterScanlator,
  }) {
    List<Chapter>? chapterList;
    chapterList = data
        .where(
          (element) => filterUnread == 1
              ? element.isRead == false
              : filterUnread == 2
              ? element.isRead == true
              : true,
        )
        .where(
          (element) => filterBookmarked == 1
              ? element.isBookmarked == true
              : filterBookmarked == 2
              ? element.isBookmarked == false
              : true,
        )
        .where((element) {
          final modelChapDownload = isar.downloads
              .filter()
              .idEqualTo(element.id)
              .findAllSync();
          return filterDownloaded == 1
              ? modelChapDownload.isNotEmpty &&
                    modelChapDownload.first.isDownload == true
              : filterDownloaded == 2
              ? !(modelChapDownload.isNotEmpty &&
                    modelChapDownload.first.isDownload == true)
              : true;
        })
        .where((element) => !filterScanlator.contains(element.scanlator))
        .toList();
    List<Chapter> chapters = sortChapter == 1
        ? chapterList.reversed.toList()
        : chapterList;
    if (sortChapter == 0) {
      chapters.sort((a, b) {
        return (a.scanlator == null ||
                b.scanlator == null ||
                a.dateUpload == null ||
                b.dateUpload == null)
            ? 0
            : a.scanlator!.compareTo(b.scanlator!) |
                  a.dateUpload!.compareTo(b.dateUpload!);
      });
    } else if (sortChapter == 2) {
      chapters.sort((a, b) {
        return (a.dateUpload == null || b.dateUpload == null)
            ? 0
            : int.parse(a.dateUpload!).compareTo(int.parse(b.dateUpload!));
      });
    } else if (sortChapter == 3) {
      chapters.sort((a, b) {
        return (a.name == null || b.name == null)
            ? 0
            : a.name!.compareTo(b.name!);
      });
    }
    return chapterList;
  }

  Widget _buildWidget({
    required List<Chapter> chapters,
    required bool reverse,
    required List<Chapter> chapterList,
    required bool isLongPressed,
  }) {
    final checkCategoryList = isar.categorys
        .filter()
        .idIsNotNull()
        .and()
        .forItemTypeEqualTo(widget.manga!.itemType)
        .isNotEmptySync();
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        // Enhanced background that moves with scroll
        Consumer(
          builder: (context, ref, child) {
            final offset = ref.watch(offetProvider);

            return Positioned(
              top: -offset * 0.5, // Move background up as user scrolls down
              child: Container(
                width: context.width(1),
                height: 400 + offset.abs() * 0.3, // Adjust height based on scroll
                child: Stack(
                  children: [
                    // Background image with parallax effect
                    widget.manga!.customCoverImage != null
                        ? Image.memory(
                            widget.manga!.customCoverImage as Uint8List,
                            width: context.width(1),
                            height: 400 + offset.abs() * 0.3,
                            fit: BoxFit.cover,
                          )
                        : cachedNetworkImage(
                            headers: widget.manga!.isLocalArchive!
                                ? null
                                : ref.watch(
                                    headersProvider(
                                      source: widget.manga!.source!,
                                      lang: widget.manga!.lang!,
                                    ),
                                  ),
                            imageUrl: toImgUrl(
                              widget.manga!.customCoverFromTracker ??
                                  widget.manga!.imageUrl ??
                                  "",
                            ),
                            width: context.width(1),
                            height: 400 + offset.abs() * 0.3,
                            fit: BoxFit.cover,
                          ),
                    // Enhanced gradient overlay
                    Container(
                      width: context.width(1),
                      height: 400 + offset.abs() * 0.3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.4, 0.7, 1.0],
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.6),
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                    // Smooth transition to background
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: context.width(1),
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.6, 1.0],
                            colors: [
                              Colors.transparent,
                              theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                              theme.scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(AppBar().preferredSize.height),
            child: Consumer(
              builder: (context, ref, child) {
                final l10n = l10nLocalizations(context)!;
                final isNotFiltering = ref.watch(
                  chapterFilterResultStateProvider(manga: widget.manga!),
                );
                final isLongPressed = ref.watch(isLongPressedStateProvider);
                final offset = ref.watch(offetProvider);
                
                return isLongPressed
                    ? Container(
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AppBar(
                          title: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.primaryColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${chapterList.length} selected',
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          leading: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () {
                                ref
                                    .read(chaptersListStateProvider.notifier)
                                    .clear();

                                ref
                                    .read(isLongPressedStateProvider.notifier)
                                    .update(!isLongPressed);
                              },
                              icon: const Icon(Icons.close_rounded),
                              iconSize: 20,
                            ),
                          ),
                          actions: [
                            Container(
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () {
                                  for (var chapter in chapters) {
                                    ref
                                        .read(chaptersListStateProvider.notifier)
                                        .selectAll(chapter);
                                  }
                                },
                                icon: const Icon(Icons.select_all_rounded),
                                iconSize: 20,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () {
                                  if (chapters.length == chapterList.length) {
                                    for (var chapter in chapters) {
                                      ref
                                          .read(
                                            chaptersListStateProvider.notifier,
                                          )
                                          .selectSome(chapter);
                                    }
                                    ref
                                        .read(isLongPressedStateProvider.notifier)
                                        .update(false);
                                  } else {
                                    for (var chapter in chapters) {
                                      ref
                                          .read(
                                            chaptersListStateProvider.notifier,
                                          )
                                          .selectSome(chapter);
                                    }
                                  }
                                },
                                icon: const Icon(Icons.deselect_rounded),
                                iconSize: 20,
                              ),
                            ),
                          ],
                        ),
                      )
                    : AppBar(
                        title: offset > 200
                            ? TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface.withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(25),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          widget.manga!.name!,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: theme.textTheme.titleLarge?.color,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : null,
                        backgroundColor: offset == 0.0
                            ? Colors.transparent
                            : offset < 100
                                ? theme.scaffoldBackgroundColor.withValues(
                                    alpha: offset / 100,
                                  )
                                : theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        actions: [
                          if (!isLocalArchive) ...[
                            Container(
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: offset > 50 ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ] : null,
                              ),
                              child: PopupMenuButton(
                                popUpAnimationStyle: popupAnimationStyle,
                                icon: Icon(
                                  Icons.download_rounded,
                                  color: theme.primaryColor,
                                ),
                              itemBuilder: (context) {
                                return [
                                  PopupMenuItem<int>(
                                    value: 0,
                                    child: Text(
                                      widget.itemType != ItemType.anime
                                          ? context.l10n.next_chapter
                                          : context.l10n.next_episode,
                                    ),
                                  ),
                                  PopupMenuItem<int>(
                                    value: 1,
                                    child: Text(
                                      widget.itemType != ItemType.anime
                                          ? context.l10n.next_5_chapters
                                          : context.l10n.next_5_episodes,
                                    ),
                                  ),
                                  PopupMenuItem<int>(
                                    value: 2,
                                    child: Text(
                                      widget.itemType != ItemType.anime
                                          ? context.l10n.next_10_chapters
                                          : context.l10n.next_10_episodes,
                                    ),
                                  ),
                                  PopupMenuItem<int>(
                                    value: 3,
                                    child: Text(
                                      widget.itemType != ItemType.anime
                                          ? context.l10n.next_25_chapters
                                          : context.l10n.next_25_episodes,
                                    ),
                                  ),
                                  PopupMenuItem<int>(
                                    value: 4,
                                    child: Text(
                                      widget.itemType != ItemType.anime
                                          ? context.l10n.unread
                                          : context.l10n.unwatched,
                                    ),
                                  ),
                                  PopupMenuItem<int>(
                                    value: 5,
                                    child: Text(
                                      widget.itemType != ItemType.anime
                                          ? context.l10n.all_chapters
                                          : context.l10n.all_episodes,
                                    ),
                                  ),
                                ];
                              },
                              onSelected: (value) {
                                final chapters =
                                    _getFilteredAndSortedChapters();
                                if (value == 0 ||
                                    value == 1 ||
                                    value == 2 ||
                                    value == 3) {
                                  final lastChapterReadIndex = chapters
                                      .lastIndexWhere(
                                        (element) => element.isRead == true,
                                      );
                                  if (lastChapterReadIndex == -1 ||
                                      chapters.length == 1) {
                                    final chapter = chapters.first;
                                    final entry = isar.downloads
                                        .filter()
                                        .idEqualTo(chapter.id)
                                        .findFirstSync();
                                    if (entry == null || !entry.isDownload!) {
                                      ref.watch(
                                        addDownloadToQueueProvider(
                                          chapter: chapter,
                                        ),
                                      );
                                      ref.watch(processDownloadsProvider());
                                    }
                                  } else {
                                    final length = switch (value) {
                                      0 => 1,
                                      1 => 5,
                                      2 => 10,
                                      _ => 25,
                                    };
                                    for (var i = 1; i < length + 1; i++) {
                                      if (chapters.length > 1 &&
                                          chapters.elementAtOrNull(
                                                lastChapterReadIndex + i,
                                              ) !=
                                              null) {
                                        final chapter =
                                            chapters[lastChapterReadIndex + i];
                                        final entry = isar.downloads
                                            .filter()
                                            .idEqualTo(chapter.id)
                                            .findFirstSync();
                                        if (entry == null ||
                                            !entry.isDownload!) {
                                          ref.watch(
                                            addDownloadToQueueProvider(
                                              chapter: chapter,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                    ref.watch(processDownloadsProvider());
                                  }
                                } else if (value == 4) {
                                  final List<Chapter> unreadChapters =
                                      _getFilteredAndSortedChapters()
                                          .where(
                                            (element) =>
                                                !(element.isRead ?? false),
                                          )
                                          .toList();
                                  isar.chapters
                                      .filter()
                                      .idIsNotNull()
                                      .mangaIdEqualTo(widget.manga!.id!)
                                      .isReadEqualTo(false)
                                      .findAllSync();
                                  for (var chapter in unreadChapters) {
                                    final entry = isar.downloads
                                        .filter()
                                        .idEqualTo(chapter.id)
                                        .findFirstSync();
                                    if (entry == null || !entry.isDownload!) {
                                      ref.watch(
                                        addDownloadToQueueProvider(
                                          chapter: chapter,
                                        ),
                                      );
                                    }
                                  }
                                  ref.watch(processDownloadsProvider());
                                } else if (value == 5) {
                                  final List<Chapter> allChapters =
                                      _getFilteredAndSortedChapters();
                                  for (var chapter in allChapters) {
                                    final entry = isar.downloads
                                        .filter()
                                        .idEqualTo(chapter.id)
                                        .findFirstSync();
                                    if (entry == null || !entry.isDownload!) {
                                      ref.watch(
                                        addDownloadToQueueProvider(
                                          chapter: chapter,
                                        ),
                                      );
                                    }
                                  }
                                  ref.watch(processDownloadsProvider());
                                }
                              },
                              ),
                            ),
                          ],
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: offset > 50 ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: IconButton(
                              onPressed: () {
                                _showDraggableMenu();
                              },
                              icon: Icon(
                                Icons.tune_rounded,
                                color: isNotFiltering ? theme.primaryColor : Colors.amber,
                              ),
                              iconSize: 22,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: offset > 50 ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: PopupMenuButton(
                              popUpAnimationStyle: popupAnimationStyle,
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: theme.primaryColor,
                              ),
                            itemBuilder: (context) {
                              return [
                                if (!isLocalArchive)
                                  PopupMenuItem<int>(
                                    value: 0,
                                    child: Text(l10n.refresh),
                                  ),
                                if (widget.manga!.favorite! &&
                                    checkCategoryList)
                                  PopupMenuItem<int>(
                                    value: 1,
                                    child: Text(l10n.set_categories),
                                  ),
                                if (!isLocalArchive)
                                  PopupMenuItem<int>(
                                    value: 2,
                                    child: Text(l10n.share),
                                  ),
                                PopupMenuItem<int>(
                                  value: 3,
                                  child: Text(l10n.migrate),
                                ),
                              ];
                            },
                            onSelected: (value) {
                              switch (value) {
                                case 0:
                                  widget.checkForUpdate(true);
                                  break;
                                case 1:
                                  showCategorySelectionDialog(
                                    context: context,
                                    ref: ref,
                                    itemType: widget.manga!.itemType,
                                    singleManga: widget.manga!,
                                  );
                                  break;
                                case 2:
                                  final source = getSource(
                                    widget.manga!.lang!,
                                    widget.manga!.source!,
                                  );
                                  final url =
                                      "${source!.baseUrl}${widget.manga!.link!.getUrlWithoutDomain}";
                                  Share.share(url);
                                  break;
                                case 3:
                                  context.push("/migrate", extra: widget.manga);
                                  break;
                              }
                            },
                            ),
                          ),
                        ],
                      );
              },
            ),
          ),
          body: SafeArea(
            child: Row(
              children: [
                if (context.isTablet)
                  SizedBox(
                    width: context.width(0.5),
                    height: context.height(1),
                    child: SingleChildScrollView(
                      child: _bodyContainer(chapterLength: chapters.length),
                    ),
                  ),
                Expanded(
                  child: Scrollbar(
                    interactive: true,
                    thickness: 12,
                    radius: const Radius.circular(10),
                    controller: _scrollController,
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.only(top: 0, bottom: 60),
                          sliver: SuperSliverList.builder(
                            itemCount: chapters.length + 1,
                            itemBuilder: (context, index) {
                              final l10n = l10nLocalizations(context)!;
                              int finalIndex = index - 1;
                              if (index == 0) {
                                return context.isTablet
                                    ? Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              mainAxisAlignment: isLocalArchive
                                                  ? MainAxisAlignment
                                                        .spaceBetween
                                                  : MainAxisAlignment.start,
                                              children: [
                                                Container(
                                                  height: chapters.isEmpty
                                                      ? context.height(1)
                                                      : null,
                                                  color: Theme.of(
                                                    context,
                                                  ).scaffoldBackgroundColor,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    child: Text(
                                                      widget.manga!.itemType !=
                                                              ItemType.anime
                                                          ? l10n.n_chapters(
                                                              chapters.length,
                                                            )
                                                          : l10n.n_episodes(
                                                              chapters.length,
                                                            ),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (isLocalArchive)
                                                  ElevatedButton.icon(
                                                    style: ElevatedButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            5,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              5,
                                                            ),
                                                      ),
                                                    ),
                                                    icon: Icon(
                                                      Icons.add,
                                                      color: context
                                                          .secondaryColor,
                                                    ),
                                                    label: Text(
                                                      widget.manga!.itemType !=
                                                              ItemType.anime
                                                          ? l10n.add_chapters
                                                          : l10n.add_episodes,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: context
                                                            .secondaryColor,
                                                      ),
                                                    ),
                                                    onPressed: () async {
                                                      final manga =
                                                          widget.manga;
                                                      if (manga!.source ==
                                                          "torrent") {
                                                        addTorrent(
                                                          context,
                                                          manga: manga,
                                                        );
                                                      } else {
                                                        await ref.watch(
                                                          importArchivesFromFileProvider(
                                                            itemType:
                                                                manga.itemType,
                                                            manga,
                                                            init: false,
                                                          ).future,
                                                        );
                                                      }
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : _bodyContainer(
                                        chapterLength: chapters.length,
                                      );
                              }
                              int reverseIndex =
                                  chapters.length -
                                  chapters.reversed.toList().indexOf(
                                    chapters.reversed.toList()[finalIndex],
                                  ) -
                                  1;
                              final indexx = reverse
                                  ? reverseIndex
                                  : finalIndex;
                              return ChapterListTileWidget(
                                chapter: chapters[indexx],
                                chapterList: chapterList,
                                sourceExist: widget.sourceExist,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Consumer(
            builder: (context, ref, child) {
              final chap = ref.watch(chaptersListStateProvider);
              bool getLength1 = chap.length == 1;
              bool checkFirstBookmarked =
                  chap.isNotEmpty && chap.first.isBookmarked! && getLength1;
              bool checkReadBookmarked =
                  chap.isNotEmpty && chap.first.isRead! && getLength1;
              final l10n = l10nLocalizations(context)!;
              return AnimatedContainer(
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                ),
                duration: const Duration(milliseconds: 300),
                height: isLongPressed ? 80 : 0,
                width: context.width(1),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  final chapters = ref.watch(
                                    chaptersListStateProvider,
                                  );
                                  isar.writeTxnSync(() {
                                    for (var chapter in chapters) {
                                      chapter.isBookmarked = !chapter.isBookmarked!;
                                      isar.chapters.putSync(
                                        chapter..manga.value = widget.manga,
                                      );
                                      chapter.manga.saveSync();
                                      ref
                                          .read(synchingProvider(syncId: 1).notifier)
                                          .addChangedPart(
                                            ActionType.updateChapter,
                                            chapter.id,
                                            chapter.toJson(),
                                            false,
                                          );
                                    }
                                  });
                                  ref
                                      .read(isLongPressedStateProvider.notifier)
                                      .update(false);
                                  ref
                                      .read(chaptersListStateProvider.notifier)
                                      .clear();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: checkFirstBookmarked
                                        ? Colors.red.withValues(alpha: 0.1)
                                        : theme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: checkFirstBookmarked
                                          ? Colors.red.withValues(alpha: 0.3)
                                          : theme.primaryColor.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Tooltip(
                                    message: checkFirstBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
                                    child: Icon(
                                      checkFirstBookmarked
                                          ? Icons.bookmark_remove_rounded
                                          : Icons.bookmark_add_rounded,
                                      color: checkFirstBookmarked
                                          ? Colors.red
                                          : theme.primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  final chapters = ref.watch(
                                    chaptersListStateProvider,
                                  );
                                  isar.writeTxnSync(() {
                                    for (var chapter in chapters) {
                                      chapter.isRead = !chapter.isRead!;
                                      if (!chapter.isRead!) {
                                        chapter.lastPageRead = "1";
                                      }
                                      isar.chapters.putSync(
                                        chapter..manga.value = widget.manga,
                                      );
                                      chapter.manga.saveSync();
                                      if (chapter.isRead!) {
                                        chapter.updateTrackChapterRead(ref);
                                      }
                                      ref
                                          .read(synchingProvider(syncId: 1).notifier)
                                          .addChangedPart(
                                            ActionType.updateChapter,
                                            chapter.id,
                                            chapter.toJson(),
                                            false,
                                          );
                                    }
                                  });
                                  ref
                                      .read(isLongPressedStateProvider.notifier)
                                      .update(false);
                                  ref
                                      .read(chaptersListStateProvider.notifier)
                                      .clear();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: checkReadBookmarked
                                        ? Colors.orange.withValues(alpha: 0.1)
                                        : Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: checkReadBookmarked
                                          ? Colors.orange.withValues(alpha: 0.3)
                                          : Colors.green.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Tooltip(
                                    message: checkReadBookmarked ? 'Mark as Unread' : 'Mark as Read',
                                    child: Icon(
                                      checkReadBookmarked
                                          ? Icons.remove_done_rounded
                                          : Icons.done_all_rounded,
                                      color: checkReadBookmarked
                                          ? Colors.orange
                                          : Colors.green,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (getLength1)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    int index = chapters.indexOf(chap.first);
                                    chapters[index + 1].updateTrackChapterRead(ref);
                                    isar.writeTxnSync(() {
                                      for (
                                        var i = index + 1;
                                        i < chapters.length;
                                        i++
                                      ) {
                                        if (!chapters[i].isRead!) {
                                          chapters[i].isRead = true;
                                          chapters[i].lastPageRead = "1";
                                          isar.chapters.putSync(
                                            chapters[i]..manga.value = widget.manga,
                                          );
                                          chapters[i].manga.saveSync();
                                          ref
                                              .read(
                                                synchingProvider(syncId: 1).notifier,
                                              )
                                              .addChangedPart(
                                                ActionType.updateChapter,
                                                chapters[i].id,
                                                chapters[i].toJson(),
                                                false,
                                              );
                                        }
                                      }
                                      ref
                                          .read(isLongPressedStateProvider.notifier)
                                          .update(false);
                                      ref
                                          .read(chaptersListStateProvider.notifier)
                                          .clear();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.blue.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Tooltip(
                                      message: 'Read All',
                                      child: Stack(
                                        children: [
                                          Icon(
                                            Icons.done_all_rounded,
                                            color: Colors.blue,
                                            size: 24,
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Icon(
                                              Icons.arrow_downward_rounded,
                                              size: 8,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (!isLocalArchive)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    for (var chapter in ref.watch(
                                      chaptersListStateProvider,
                                    )) {
                                      final entries = isar.downloads
                                          .filter()
                                          .idEqualTo(chapter.id)
                                          .findAllSync();
                                      if (entries.isEmpty ||
                                          !entries.first.isDownload!) {
                                        ref.read(
                                          addDownloadToQueueProvider(
                                            chapter: chapter,
                                          ),
                                        );
                                      }
                                    }
                                    ref.watch(processDownloadsProvider());

                                    ref
                                        .read(isLongPressedStateProvider.notifier)
                                        .update(false);
                                    ref
                                        .read(chaptersListStateProvider.notifier)
                                        .clear();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.purple.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Tooltip(
                                      message: 'Download',
                                      child: Icon(
                                        Icons.download_rounded,
                                        color: Colors.purple,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (isLocalArchive)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          title: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_outline_rounded,
                                                color: Colors.red,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(l10n.delete_chapters),
                                            ],
                                          ),
                                          actions: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 16, vertical: 8),
                                                  ),
                                                  child: Text(l10n.cancel),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    isar.writeTxnSync(() {
                                                      for (var chapter in ref.watch(
                                                        chaptersListStateProvider,
                                                      )) {
                                                        isar.chapters.deleteSync(
                                                          chapter.id!,
                                                        );
                                                      }
                                                    });
                                                    ref
                                                        .read(
                                                          isLongPressedStateProvider
                                                              .notifier,
                                                        )
                                                        .update(false);
                                                    ref
                                                        .read(
                                                          chaptersListStateProvider
                                                              .notifier,
                                                        )
                                                        .clear();
                                                    if (mounted) {
                                                      Navigator.pop(context);
                                                    }
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 16, vertical: 8),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  child: Text(l10n.delete),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Tooltip(
                                      message: 'Delete',
                                      child: Icon(
                                        Icons.delete_rounded,
                                        color: Colors.red,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDraggableMenu() {
    final scanlators = ref.watch(scanlatorsFilterStateProvider(widget.manga!));
    final l10n = l10nLocalizations(context)!;
    customDraggableTabBar(
      tabs: [
        Tab(text: l10n.filter),
        Tab(text: l10n.sort),
        Tab(text: l10n.display),
      ],
      children: [
        Consumer(
          builder: (context, ref, chil) {
            return Column(
              children: [
                if (!isLocalArchive)
                  ListTileChapterFilter(
                    label: l10n.downloaded,
                    type: ref.watch(
                      chapterFilterDownloadedStateProvider(
                        mangaId: widget.manga!.id!,
                      ),
                    ),
                    onTap: () {
                      ref
                          .read(
                            chapterFilterDownloadedStateProvider(
                              mangaId: widget.manga!.id!,
                            ).notifier,
                          )
                          .update();
                    },
                  ),
                ListTileChapterFilter(
                  label: widget.itemType != ItemType.anime
                      ? l10n.unread
                      : l10n.unwatched,
                  type: ref.watch(
                    chapterFilterUnreadStateProvider(
                      mangaId: widget.manga!.id!,
                    ),
                  ),
                  onTap: () {
                    ref
                        .read(
                          chapterFilterUnreadStateProvider(
                            mangaId: widget.manga!.id!,
                          ).notifier,
                        )
                        .update();
                  },
                ),
                ListTileChapterFilter(
                  label: l10n.bookmarked,
                  type: ref.watch(
                    chapterFilterBookmarkedStateProvider(
                      mangaId: widget.manga!.id!,
                    ),
                  ),
                  onTap: () {
                    ref
                        .read(
                          chapterFilterBookmarkedStateProvider(
                            mangaId: widget.manga!.id!,
                          ).notifier,
                        )
                        .update();
                  },
                ),
                if (scanlators.$1.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return Consumer(
                                    builder: (context, ref, child) {
                                      final scanlators = ref.watch(
                                        scanlatorsFilterStateProvider(
                                          widget.manga!,
                                        ),
                                      );
                                      return AlertDialog(
                                        title: Text(
                                          l10n.filter_scanlator_groups,
                                        ),
                                        content: SizedBox(
                                          width: context.width(0.8),
                                          child: SuperListView.builder(
                                            shrinkWrap: true,
                                            itemCount: scanlators.$1.length,
                                            itemBuilder: (context, index) {
                                              return ListTileChapterFilter(
                                                label: scanlators.$1[index],
                                                type:
                                                    scanlators.$3.contains(
                                                      scanlators.$1[index],
                                                    )
                                                    ? 2
                                                    : 0,
                                                onTap: () {
                                                  ref
                                                      .read(
                                                        scanlatorsFilterStateProvider(
                                                          widget.manga!,
                                                        ).notifier,
                                                      )
                                                      .setFilteredList(
                                                        scanlators.$1[index],
                                                      );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                        actions: [
                                          Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        TextButton(
                                                          onPressed: () {
                                                            ref
                                                                .read(
                                                                  scanlatorsFilterStateProvider(
                                                                    widget
                                                                        .manga!,
                                                                  ).notifier,
                                                                )
                                                                .set([]);
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                          },
                                                          child: Text(
                                                            l10n.reset,
                                                            style: TextStyle(
                                                              color: context
                                                                  .primaryColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      TextButton(
                                                        onPressed: () async {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                        },
                                                        child: Text(
                                                          l10n.cancel,
                                                          style: TextStyle(
                                                            color: context
                                                                .primaryColor,
                                                          ),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          ref
                                                              .read(
                                                                scanlatorsFilterStateProvider(
                                                                  widget.manga!,
                                                                ).notifier,
                                                              )
                                                              .set(
                                                                scanlators.$3,
                                                              );
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                        },
                                                        child: Text(
                                                          l10n.filter,
                                                          style: TextStyle(
                                                            color: context
                                                                .primaryColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Text(l10n.filter_scanlator_groups),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        Consumer(
          builder: (context, ref, chil) {
            final reverse = ref
                .read(
                  sortChapterStateProvider(mangaId: widget.manga!.id!).notifier,
                )
                .isReverse();
            final scanlators = ref.watch(
              scanlatorsFilterStateProvider(widget.manga!),
            );
            final reverseChapter = ref.watch(
              sortChapterStateProvider(mangaId: widget.manga!.id!),
            );
            return Column(
              children: [
                if (scanlators.$1.isNotEmpty)
                  ListTileChapterSort(
                    label: _getSortNameByIndex(0, context),
                    reverse: reverse,
                    onTap: () {
                      ref
                          .read(
                            sortChapterStateProvider(
                              mangaId: widget.manga!.id!,
                            ).notifier,
                          )
                          .set(0);
                    },
                    showLeading: reverseChapter.index == 0,
                  ),
                for (var i = 1; i < 4; i++)
                  ListTileChapterSort(
                    label: _getSortNameByIndex(i, context),
                    reverse: reverse,
                    onTap: () {
                      ref
                          .read(
                            sortChapterStateProvider(
                              mangaId: widget.manga!.id!,
                            ).notifier,
                          )
                          .set(i);
                    },
                    showLeading: reverseChapter.index == i,
                  ),
              ],
            );
          },
        ),
        Consumer(
          builder: (context, ref, chil) {
            return Column(
              children: [
                RadioListTile(
                  dense: true,
                  title: Text(l10n.source_title),
                  value: "e",
                  groupValue: "e",
                  selected: true,
                  onChanged: (value) {},
                ),
                RadioListTile(
                  dense: true,
                  title: Text(
                    widget.itemType != ItemType.anime
                        ? l10n.chapter_number
                        : l10n.episode_number,
                  ),
                  value: "ej",
                  groupValue: "e",
                  selected: false,
                  onChanged: (value) {},
                ),
              ],
            );
          },
        ),
      ],
      context: context,
      vsync: this,
    );
  }

  String _getSortNameByIndex(int index, BuildContext context) {
    final l10n = l10nLocalizations(context)!;
    if (index == 0) {
      return l10n.by_scanlator;
    } else if (index == 1) {
      return widget.itemType != ItemType.anime
          ? l10n.by_chapter_number
          : l10n.by_episode_number;
    } else if (index == 2) {
      return l10n.by_upload_date;
    }
    return l10n.by_name;
  }

  Widget _bodyContainer({required int chapterLength}) {
    final l10n = l10nLocalizations(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        // Cover and title section with modern styling
        Container(
          margin: const EdgeInsets.only(top: 120),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Glassmorphic card for main info
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade900.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Column(
                      children: [
                        // Title section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(160, 16, 16, 8),
                          child: _titles(),
                        ),
                        // Action buttons
                        if (!isLocalArchive) _actionFavouriteAndWebview(),
                      ],
                    ),
                  ),
                ),
              ),
              // Cover card positioned on top
              Positioned(
                left: 16,
                top: -40, // Moved up more
                child: _coverCard(),
              ),
              // Edit button for local archive
              if (isLocalArchive)
                Positioned(
                  top: 8,
                  right: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        _editLocalArchiveInfos();
                      },
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Description and genres section
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.manga!.description != null) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 20,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.description,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ReadMoreWidget(
                            text: widget.manga!.description!,
                            onChanged: (value) {
                              setState(() {
                                _expanded = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (widget.manga!.genre!.isNotEmpty)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ),
                  ],
                  if (widget.manga!.genre!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 20,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Genres',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _expanded || context.isTablet
                              ? Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (var i = 0; i < widget.manga!.genre!.length; i++)
                                      _buildGenreChip(i, isDark),
                                  ],
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      for (var i = 0; i < widget.manga!.genre!.length; i++)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: _buildGenreChip(i, isDark),
                                        ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Chapter header section
        if (!context.isTablet)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(16),
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
            child: Row(
              mainAxisAlignment: isLocalArchive
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.manga!.itemType != ItemType.anime
                            ? Icons.library_books_outlined
                            : Icons.video_library_outlined,
                        size: 20,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.manga!.itemType != ItemType.anime
                          ? l10n.n_chapters(chapterLength)
                          : l10n.n_episodes(chapterLength),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (isLocalArchive)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.add,
                      size: 18,
                    ),
                    label: Text(
                      widget.manga!.itemType != ItemType.anime
                          ? l10n.add_chapters
                          : l10n.add_episodes,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () async {
                      final manga = widget.manga;
                      if (manga!.source == "torrent") {
                        addTorrent(context, manga: manga);
                      } else {
                        await ref.watch(
                          importArchivesFromFileProvider(
                            itemType: manga.itemType,
                            manga,
                            init: false,
                          ).future,
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildGenreChip(int index, bool isDark) {
    final theme = Theme.of(context);
    final l10n = l10nLocalizations(context)!;
    
    return PopupMenuButton(
      popUpAnimationStyle: popupAnimationStyle,
      itemBuilder: (context) {
        return [
          PopupMenuItem<int>(
            height: 40,
            value: 0,
            child: Text(context.l10n.genre_search_library),
          ),
          PopupMenuItem<int>(
            height: 40,
            value: 1,
            child: Text(context.l10n.genre_search_source),
          ),
        ];
      },
      onSelected: (value) async {
        final source = getSource(
          widget.manga!.lang!,
          widget.manga!.source!,
        );
        if (source == null) {
          botToast(l10n.source_not_added);
          return;
        }
        if (value == 0) {
          final genre = widget.manga!.genre![index];
          switch (widget.manga!.itemType) {
            case ItemType.manga:
              context.pushReplacement('/MangaLibrary', extra: genre);
              break;
            case ItemType.anime:
              context.pushReplacement('/AnimeLibrary', extra: genre);
              break;
            case ItemType.novel:
              context.pushReplacement('/NovelLibrary', extra: genre);
              break;
          }
        } else {
          context.pushReplacement('/mangaHome', extra: (source, false));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withValues(alpha: 0.15),
              theme.primaryColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          widget.manga!.genre![index],
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _coverCard() {
    final imageProvider = widget.manga!.customCoverImage != null
        ? MemoryImage(widget.manga!.customCoverImage as Uint8List)
              as ImageProvider
        : CustomExtendedNetworkImageProvider(
            toImgUrl(
              widget.manga!.customCoverFromTracker ??
                  widget.manga!.imageUrl ??
                  "",
            ),
            headers: widget.manga!.isLocalArchive!
                ? null
                : ref.watch(
                    headersProvider(
                      source: widget.manga!.source!,
                      lang: widget.manga!.lang!,
                    ),
                  ),
          );

    return Hero(
      tag: 'manga_cover_${widget.manga!.id}',
      child: GestureDetector(
        onTap: () {
          _openImage(imageProvider);
        },
        child: Container(
          width: 130,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Main image
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Subtle gradient overlay for depth
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
                // Tap indicator overlay
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openImage(imageProvider),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _titles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SelectableText(
          widget.manga!.name!,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        widget.titleDescription!,
      ],
    );
  }

  Widget _actionFavouriteAndWebview() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade800.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.grey.shade700.withValues(alpha: 0.5)
              : Colors.grey.shade300.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              // Favorite button
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: widget.action!,
                ),
              ),

              // Divider
              Container(
                width: 1,
                height: 40,
                color: isDark
                    ? Colors.grey.shade600.withValues(alpha: 0.3)
                    : Colors.grey.shade400.withValues(alpha: 0.3),
              ),

              // Tracking button
              if (widget.itemType != ItemType.novel)
                Expanded(
                  child: StreamBuilder(
                    stream: isar.trackPreferences
                        .filter()
                        .syncIdIsNotNull()
                        .watch(fireImmediately: true),
                    builder: (context, snapshot) {
                      List<TrackPreference>? entries = snapshot.hasData
                          ? snapshot.data!
                          : [];
                      if (entries.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _trackingDraggableMenu(entries),
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 60,
                            child: StreamBuilder(
                              stream: isar.tracks
                                  .filter()
                                  .idIsNotNull()
                                  .mangaIdEqualTo(widget.manga!.id!)
                                  .watch(fireImmediately: true),
                              builder: (context, snapshot) {
                                final l10n = l10nLocalizations(context)!;
                                List<Track>? trackRes = snapshot.hasData
                                    ? snapshot.data
                                    : [];
                                bool isNotEmpty = trackRes!.isNotEmpty;
                                Color color = isNotEmpty
                                    ? theme.primaryColor
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.7);

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isNotEmpty
                                            ? Icons.sync_alt_rounded
                                            : Icons.sync_outlined,
                                        size: 18,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isNotEmpty
                                          ? trackRes.length == 1
                                                ? l10n.one_tracker
                                                : l10n.n_tracker(trackRes.length)
                                          : l10n.tracking,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: color,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Divider
              if (widget.itemType != ItemType.novel)
                Container(
                  width: 1,
                  height: 40,
                  color: isDark
                      ? Colors.grey.shade600.withValues(alpha: 0.3)
                      : Colors.grey.shade400.withValues(alpha: 0.3),
                ),

              // WebView button
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final manga = widget.manga!;
                      final source = getSource(
                        widget.manga!.lang!,
                        widget.manga!.source!,
                      );
                      final url = "${source!.baseUrl}${widget.manga!.link!.getUrlWithoutDomain}";

                      Map<String, dynamic> data = {
                        'url': url,
                        'sourceId': source.id.toString(),
                        'title': manga.name!,
                      };
                      context.push("/mangawebview", extra: data);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 60,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.language_rounded,
                              size: 18,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'WebView',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: theme.primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openImage(ImageProvider imageProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: PhotoViewGallery.builder(
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  itemCount: 1,
                  builder: (context, index) {
                    return PhotoViewGalleryPageOptions(
                      imageProvider: imageProvider,
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: 2.0,
                    );
                  },
                  loadingBuilder: (context, event) {
                    return const ProgressCenter();
                  },
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: StreamBuilder(
                        stream: isar.trackPreferences
                            .filter()
                            .syncIdIsNotNull()
                            .watch(fireImmediately: true),
                        builder: (context, snapshot) {
                          List<TrackPreference>? entries = snapshot.hasData
                              ? snapshot.data!
                              : [];
                          if (entries.isEmpty) {
                            return Container();
                          }
                          return Column(
                            children: entries
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: MaterialButton(
                                      padding: const EdgeInsets.all(0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      onPressed: () async {
                                        final trackSearch =
                                            await trackersSearchraggableMenu(
                                                  context,
                                                  itemType:
                                                      widget.manga!.itemType,
                                                  track: Track(
                                                    status:
                                                        TrackStatus.planToRead,
                                                    syncId: e.syncId!,
                                                    title: widget.manga!.name!,
                                                  ),
                                                )
                                                as TrackSearch?;
                                        if (trackSearch != null) {
                                          isar.writeTxnSync(() {
                                            isar.mangas.putSync(
                                              widget.manga!
                                                ..customCoverImage = null
                                                ..customCoverFromTracker =
                                                    trackSearch.coverUrl,
                                            );
                                            ref
                                                .read(
                                                  synchingProvider(
                                                    syncId: 1,
                                                  ).notifier,
                                                )
                                                .addChangedPart(
                                                  ActionType.updateItem,
                                                  widget.manga!.id,
                                                  widget.manga!.toJson(),
                                                  false,
                                                );
                                          });
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            botToast(
                                              context.l10n.cover_updated,
                                              second: 3,
                                            );
                                          }
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: trackInfos(e.syncId!).$3,
                                        ),
                                        width: 45,
                                        height: 50,
                                        child: Image.asset(
                                          trackInfos(e.syncId!).$1,
                                          height: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: context.width(1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: context.isLight
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.close),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: context.isLight
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final bytes = await imageProvider
                                          .getBytes(context);
                                      if (bytes != null) {
                                        await Share.shareXFiles([
                                          XFile.fromData(
                                            bytes,
                                            name: widget.manga!.name,
                                            mimeType: 'image/png',
                                          ),
                                        ]);
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(Icons.share),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      final dir = await StorageProvider()
                                          .getGalleryDirectory();
                                      if (context.mounted) {
                                        final bytes = await imageProvider
                                            .getBytes(context);
                                        if (bytes != null && context.mounted) {
                                          final file = File(
                                            p.join(
                                              dir!.path,
                                              "${widget.manga!.name}.png",
                                            ),
                                          );
                                          file.writeAsBytesSync(bytes);
                                          botToast(
                                            context.l10n.cover_saved,
                                            second: 3,
                                          );
                                        }
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(Icons.save_outlined),
                                    ),
                                  ),
                                  PopupMenuButton(
                                    popUpAnimationStyle: popupAnimationStyle,
                                    itemBuilder: (context) {
                                      return [
                                        if (widget.manga!.customCoverImage !=
                                                null ||
                                            widget
                                                    .manga!
                                                    .customCoverFromTracker !=
                                                null)
                                          PopupMenuItem<int>(
                                            value: 0,
                                            child: Text(context.l10n.delete),
                                          ),
                                        PopupMenuItem<int>(
                                          value: 1,
                                          child: Text(context.l10n.edit),
                                        ),
                                      ];
                                    },
                                    onSelected: (value) async {
                                      final manga = widget.manga!;
                                      if (value == 0) {
                                        isar.writeTxnSync(() {
                                          isar.mangas.putSync(
                                            manga
                                              ..customCoverImage = null
                                              ..customCoverFromTracker = null,
                                          );
                                          ref
                                              .read(
                                                synchingProvider(
                                                  syncId: 1,
                                                ).notifier,
                                              )
                                              .addChangedPart(
                                                ActionType.updateItem,
                                                manga.id,
                                                manga.toJson(),
                                                false,
                                              );
                                        });
                                        Navigator.pop(context);
                                      } else if (value == 1) {
                                        FilePickerResult? result =
                                            await FilePicker.platform.pickFiles(
                                              type: FileType.custom,
                                              allowedExtensions: [
                                                'png',
                                                'jpg',
                                                'jpeg',
                                              ],
                                            );
                                        if (result != null && context.mounted) {
                                          if (result.files.first.size <
                                              5000000) {
                                            final customCoverImage = File(
                                              result.files.first.path!,
                                            ).readAsBytesSync();
                                            isar.writeTxnSync(() {
                                              isar.mangas.putSync(
                                                manga
                                                  ..customCoverImage =
                                                      customCoverImage,
                                              );
                                              ref
                                                  .read(
                                                    synchingProvider(
                                                      syncId: 1,
                                                    ).notifier,
                                                  )
                                                  .addChangedPart(
                                                    ActionType.updateItem,
                                                    manga.id,
                                                    manga.toJson(),
                                                    false,
                                                  );
                                            });
                                            botToast(
                                              context.l10n.cover_updated,
                                              second: 3,
                                            );
                                          }
                                        }
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        color: !context.isLight
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editLocalArchiveInfos() {
    final l10n = l10nLocalizations(context)!;
    TextEditingController? name = TextEditingController(
      text: widget.manga!.name!,
    );
    TextEditingController? description = TextEditingController(
      text: widget.manga!.description!,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.edit),
          content: SizedBox(
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Text(l10n.name),
                      ),
                      TextFormField(controller: name),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Text(l10n.description),
                      ),
                      TextFormField(controller: description),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 15),
                TextButton(
                  onPressed: () {
                    isar.writeTxnSync(() {
                      final manga = widget.manga!;
                      manga.description = description.text;
                      manga.name = name.text;
                      isar.mangas.putSync(manga);
                      ref
                          .read(synchingProvider(syncId: 1).notifier)
                          .addChangedPart(
                            ActionType.updateItem,
                            manga.id,
                            manga.toJson(),
                            false,
                          );
                    });
                    Navigator.pop(context);
                  },
                  child: Text(l10n.edit),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _trackingDraggableMenu(List<TrackPreference>? entries) {
    DraggableMenu.open(
      context,
      DraggableMenu(
        ui: ClassicDraggableMenu(
          radius: 20,
          barItem: Container(),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        allowToShrink: true,
        child: Material(
          color: context.isLight
              ? Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9)
              : !ref.watch(pureBlackDarkModeStateProvider)
              ? Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SuperListView.separated(
              padding: const EdgeInsets.all(0),
              itemCount: entries!.length,
              primary: false,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return StreamBuilder(
                  stream: isar.tracks
                      .filter()
                      .idIsNotNull()
                      .syncIdEqualTo(entries[index].syncId)
                      .mangaIdEqualTo(widget.manga!.id!)
                      .watch(fireImmediately: true),
                  builder: (context, snapshot) {
                    List<Track>? trackRes = snapshot.hasData
                        ? snapshot.data
                        : [];
                    return trackRes!.isNotEmpty
                        ? TrackerWidget(
                            mangaId: widget.manga!.id!,
                            syncId: entries[index].syncId!,
                            trackRes: trackRes.first,
                            itemType: widget.manga!.itemType,
                          )
                        : TrackListile(
                            text: l10nLocalizations(context)!.add_tracker,
                            onTap: () async {
                              final trackSearch =
                                  await trackersSearchraggableMenu(
                                        context,
                                        itemType: widget.manga!.itemType,
                                        track: Track(
                                          status: TrackStatus.planToRead,
                                          syncId: entries[index].syncId!,
                                          title: widget.manga!.name!,
                                        ),
                                      )
                                      as TrackSearch?;
                              if (trackSearch != null) {
                                await ref
                                    .read(
                                      trackStateProvider(
                                        track: null,
                                        itemType: widget.manga!.itemType,
                                      ).notifier,
                                    )
                                    .setTrackSearch(
                                      trackSearch,
                                      widget.manga!.id!,
                                      entries[index].syncId!,
                                    );
                              }
                            },
                            id: entries[index].syncId!,
                            entries: const [],
                          );
                  },
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return const Divider();
              },
            ),
          ),
        ),
      ),
    );
  }
}
