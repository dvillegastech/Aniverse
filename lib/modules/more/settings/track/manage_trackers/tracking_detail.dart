import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:mangayomi/main.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/track.dart';
import 'package:mangayomi/models/track_preference.dart';
import 'package:mangayomi/modules/manga/detail/widgets/tracker_widget.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/utils/constant.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class TrackingDetail extends StatefulWidget {
  final TrackPreference trackerPref;
  const TrackingDetail({super.key, required this.trackerPref});

  @override
  State<TrackingDetail> createState() => _TrackingDetailState();
}

class _TrackingDetailState extends State<TrackingDetail>
    with TickerProviderStateMixin {
  late TabController _tabBarController;
  @override
  void initState() {
    super.initState();
    _tabBarController = TabController(length: 2, vsync: this);
    _tabBarController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nLocalizations(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trackerName = widget.trackerPref.syncId == -1
        ? 'Local'
        : trackInfos(widget.trackerPref.syncId!).$2;
    
    return DefaultTabController(
      animationDuration: Duration.zero,
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
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
          ),
          title: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, double value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Text(
                    trackerName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56.0),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.grey.shade900 : Colors.white).withValues(alpha: 0.9),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                controller: _tabBarController,
                tabs: [
                  Tab(text: l10n.manga),
                  Tab(text: l10n.anime),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabBarController,
          children: [
            TrackingTab(
              itemType: ItemType.manga,
              syncId: widget.trackerPref.syncId!,
            ),
            TrackingTab(
              itemType: ItemType.anime,
              syncId: widget.trackerPref.syncId!,
            ),
          ],
        ),
      ),
    );
  }
}

class TrackingTab extends StatelessWidget {
  final ItemType itemType;
  final int syncId;
  const TrackingTab({super.key, required this.itemType, required this.syncId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: isar.tracks
          .filter()
          .idIsNotNull()
          .itemTypeEqualTo(itemType)
          .syncIdEqualTo(syncId)
          .watch(fireImmediately: true),
      builder: (context, snapshot) {
        List<Track>? trackRes = snapshot.hasData ? snapshot.data : [];
        final mediaIds = trackRes!.map((e) => e.mediaId).toSet().toList();
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: SuperListView.separated(
            padding: const EdgeInsets.all(0),
            itemCount: mediaIds.length,
            primary: false,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final mediaId = mediaIds[index];
              final track = trackRes.firstWhere(
                (element) => element.mediaId == mediaId,
              );
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade900.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.grey)
                          .withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: ExpansionTile(
                      backgroundColor: Colors.transparent,
                      collapsedBackgroundColor: Colors.transparent,
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                  Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              itemType == ItemType.manga 
                                  ? Icons.book_rounded 
                                  : Icons.movie_rounded,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              track.title!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white 
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TrackingWidget(
                            itemType: itemType,
                            syncId: syncId,
                            mediaId: mediaId!,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (_, index) {
              return const Divider();
            },
          ),
        );
      },
    );
  }
}

class TrackingWidget extends StatelessWidget {
  final int syncId;
  final ItemType itemType;
  final int mediaId;
  const TrackingWidget({
    super.key,
    required this.mediaId,
    required this.itemType,
    required this.syncId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: isar.tracks
          .filter()
          .idIsNotNull()
          .mediaIdEqualTo(mediaId)
          .itemTypeEqualTo(itemType)
          .watch(fireImmediately: true),
      builder: (context, snapshot) {
        List<Track>? trackRes = [];
        List<Track> res = snapshot.data ?? [];
        for (var track in res) {
          if (!trackRes
              .map((e) => e.mediaId)
              .toList()
              .contains(track.mediaId)) {
            trackRes.add(track);
          }
        }
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: SuperListView.separated(
            padding: const EdgeInsets.all(0),
            itemCount: trackRes.length,
            primary: false,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final track = trackRes[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800.withValues(alpha: 0.5)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: TrackerWidget(
                  mangaId: track.mangaId!,
                  syncId: track.syncId!,
                  trackRes: track,
                  itemType: itemType,
                  hide: true,
                ),
              );
            },
            separatorBuilder: (_, index) {
              return const Divider();
            },
          ),
        );
      },
    );
  }
}
