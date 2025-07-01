import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/modules/widgets/custom_extended_image_provider.dart';
import 'package:mangayomi/utils/constant.dart';
import 'package:mangayomi/modules/manga/download/download_page_widget.dart';
import 'package:mangayomi/utils/extensions/chapter.dart';
import 'package:mangayomi/utils/headers.dart';

class UpdateChapterListTileWidget extends ConsumerWidget {
  final Chapter chapter;
  final bool sourceExist;
  const UpdateChapterListTileWidget({
    required this.chapter,
    required this.sourceExist,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manga = chapter.manga.value!;
    final theme = Theme.of(context);
    final isRead = chapter.isRead ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isRead
            ? theme.colorScheme.surface.withValues(alpha: 0.5)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead
              ? theme.dividerColor.withValues(alpha: 0.3)
              : theme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            chapter.pushToReaderView(context, ignoreIsRead: true);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Cover image with read indicator
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GestureDetector(
                        onTap: () {
                          context.push(
                            '/manga-reader/detail',
                            extra: manga.id,
                          );
                        },
                        child: Container(
                          width: 50,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: manga.customCoverImage != null
                                  ? MemoryImage(
                                      manga.customCoverImage as Uint8List,
                                    ) as ImageProvider
                                  : CustomExtendedNetworkImageProvider(
                                      toImgUrl(
                                        manga.customCoverFromTracker ??
                                            manga.imageUrl!,
                                      ),
                                      headers: ref.watch(
                                        headersProvider(
                                          source: manga.source!,
                                          lang: manga.lang!,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          child: isRead
                              ? Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.black.withValues(alpha: 0.4),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    // Read indicator
                    if (isRead)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manga.name!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isRead
                              ? theme.textTheme.bodyLarge!.color!.withValues(alpha: 0.6)
                              : theme.textTheme.bodyLarge!.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chapter.name!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isRead
                                    ? Colors.grey
                                    : theme.primaryColor,
                              ),
                            ),
                          ),
                          if (isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Read',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Download button
                if (sourceExist) ChapterPageDownload(chapter: chapter),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
