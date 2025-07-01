import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marquee/marquee.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/utils/date.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/utils/extensions/chapter.dart';
import 'package:mangayomi/utils/extensions/string_extensions.dart';
import 'package:mangayomi/modules/manga/detail/providers/state_providers.dart';
import 'package:mangayomi/modules/manga/download/download_page_widget.dart';
import 'package:mangayomi/utils/chapter_recognition.dart';

class ChapterListTileWidget extends ConsumerWidget {
  final Chapter chapter;
  final List<Chapter> chapterList;
  final bool sourceExist;
  const ChapterListTileWidget({
    required this.chapterList,
    required this.chapter,
    required this.sourceExist,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLongPressed = ref.watch(isLongPressedStateProvider);
    final l10n = l10nLocalizations(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chapterList.contains(chapter)
            ? theme.primaryColor.withValues(alpha: 0.2)
            : chapter.isRead!
                ? (isDark 
                    ? Colors.grey.shade900.withValues(alpha: 0.5)
                    : Colors.grey.shade100.withValues(alpha: 0.8))
                : (isDark
                    ? Colors.grey.shade900.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.9)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chapterList.contains(chapter)
              ? theme.primaryColor.withValues(alpha: 0.5)
              : theme.dividerColor.withValues(alpha: 0.1),
          width: chapterList.contains(chapter) ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onLongPress: () {
            if (!isLongPressed) {
              ref.read(chaptersListStateProvider.notifier).update(chapter);
              ref
                  .read(isLongPressedStateProvider.notifier)
                  .update(!isLongPressed);
            } else {
              ref.read(chaptersListStateProvider.notifier).update(chapter);
            }
          },
          onTap: () async {
            if (isLongPressed) {
              ref.read(chaptersListStateProvider.notifier).update(chapter);
            } else {
              chapter.pushToReaderView(context, ignoreIsRead: true);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Read indicator
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: chapter.isRead!
                        ? theme.primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: chapter.isRead!
                          ? theme.primaryColor.withValues(alpha: 0.3)
                          : theme.dividerColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: chapter.isRead!
                        ? Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: theme.primaryColor,
                          )
                        : Text(
                            ChapterRecognition().parseChapterNumber(
                              chapter.manga.value?.name ?? '',
                              chapter.name ?? '',
                            ).toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium!.color,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (chapter.isBookmarked!)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.bookmark_rounded,
                                size: 16,
                                color: theme.primaryColor,
                              ),
                            ),
                          Flexible(
                            child: _buildTitle(
                              chapter.name!,
                              context,
                              isRead: chapter.isRead!,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if ((chapter.manga.value!.isLocalArchive ?? false) == false &&
                              chapter.dateUpload != null &&
                              chapter.dateUpload!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                dateFormat(
                                  chapter.dateUpload!,
                                  ref: ref,
                                  context: context,
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: chapter.isRead!
                                      ? theme.hintColor.withValues(alpha: 0.6)
                                      : theme.hintColor,
                                ),
                              ),
                            ),
                          if (!chapter.isRead! &&
                              chapter.lastPageRead!.isNotEmpty &&
                              chapter.lastPageRead != "1")
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                chapter.manga.value!.itemType == ItemType.anime
                                    ? l10n.episode_progress(
                                        Duration(
                                          milliseconds: int.parse(chapter.lastPageRead!),
                                        ).toString().substringBefore("."),
                                      )
                                    : l10n.page(
                                        chapter.manga.value!.itemType == ItemType.manga
                                            ? chapter.lastPageRead!
                                            : "${((double.tryParse(chapter.lastPageRead!) ?? 0) * 100).toStringAsFixed(0)} %",
                                      ),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                          if (chapter.scanlator?.isNotEmpty ?? false)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  chapter.scanlator!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: chapter.isRead!
                                        ? theme.hintColor.withValues(alpha: 0.6)
                                        : theme.hintColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Download button
                if (sourceExist && !(chapter.manga.value!.isLocalArchive ?? false))
                  ChapterPageDownload(chapter: chapter),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(String text, BuildContext context, {required bool isRead}) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Make sure that (constraints.maxWidth - (35 + 5)) is strictly positive.
        final double availableWidth = constraints.maxWidth - (35 + 5);
        final textStyle = TextStyle(
          fontSize: 14,
          fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
          color: isRead
              ? theme.textTheme.bodyMedium!.color!.withValues(alpha: 0.6)
              : theme.textTheme.bodyMedium!.color,
        );
        
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: textStyle),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(
          maxWidth: availableWidth > 0 ? availableWidth : 1.0,
        );

        final isOverflowing = textPainter.didExceedMaxLines;

        if (isOverflowing) {
          return SizedBox(
            height: 20,
            child: Marquee(
              text: text,
              style: textStyle,
              blankSpace: 40.0,
              velocity: 30.0,
              pauseAfterRound: const Duration(seconds: 1),
              startPadding: 10.0,
            ),
          );
        } else {
          return Text(
            text,
            style: textStyle,
            overflow: TextOverflow.ellipsis,
          );
        }
      },
    );
  }
}
