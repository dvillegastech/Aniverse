import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/eval/model/m_bridge.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/modules/widgets/progress_center.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:url_launcher/url_launcher.dart';

class SourceRepositories extends ConsumerStatefulWidget {
  final ItemType itemType;
  const SourceRepositories({required this.itemType, super.key});

  @override
  ConsumerState<SourceRepositories> createState() => _SourceRepositoriesState();
}

class _SourceRepositoriesState extends ConsumerState<SourceRepositories> {
  List<Repo> _entries = [];
  String urlInput = "";
  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nLocalizations(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final repositories = ref.watch(
      extensionsRepoStateProvider(widget.itemType),
    );
    final data = AsyncValue.data(repositories);
    
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
                                switch (widget.itemType) {
                                  ItemType.manga => l10n.manage_manga_repo_urls,
                                  ItemType.anime => l10n.manage_anime_repo_urls,
                                  _ => l10n.manage_novel_repo_urls,
                                },
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
          SliverFillRemaining(
            child: data.when(
              data: (data) {
                if (data.isEmpty) {
                  _entries = [];
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.source_outlined,
                            size: 80,
                            color: theme.primaryColor.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.empty_extensions_repo,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                _entries = data;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SuperListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final repo = _entries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                theme.primaryColor.withValues(alpha: 0.2),
                                                theme.primaryColor.withValues(alpha: 0.1),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.source_rounded,
                                            color: theme.primaryColor,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                repo.name ??
                                                    repo.jsonUrl ??
                                                    "Invalid source - remove it",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (repo.jsonUrl != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  repo.jsonUrl!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      border: Border(
                                        top: BorderSide(
                                          color: theme.dividerColor.withValues(alpha: 0.1),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (repo.website != null)
                                          _buildActionButton(
                                            context,
                                            icon: Icons.open_in_new_rounded,
                                            tooltip: 'Visit website',
                                            onPressed: () {
                                              _launchInBrowser(Uri.parse(repo.website!));
                                            },
                                          ),
                                        _buildActionButton(
                                          context,
                                          icon: Icons.content_copy_rounded,
                                          tooltip: 'Copy URL',
                                          onPressed: () async {
                                            if (repo.jsonUrl != null) {
                                              await Clipboard.setData(
                                                ClipboardData(text: repo.jsonUrl!),
                                              );
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('URL copied to clipboard'),
                                                  behavior: SnackBarBehavior.floating,
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        _buildActionButton(
                                          context,
                                          icon: Icons.delete_outline_rounded,
                                          tooltip: 'Remove repository',
                                          color: Colors.red,
                                          onPressed: () {
                                            _showRemoveDialog(context, index);
                                          },
                                        ),
                                      ],
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
                );
              },
              error: (Object error, StackTrace stackTrace) {
                _entries = [];
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 80,
                          color: Colors.red.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.empty_extensions_repo,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: theme.primaryColor,
        label: Row(
          children: [
            const Icon(Icons.add_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              l10n.add,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 20,
            color: color ?? theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
  
  void _showRemoveDialog(BuildContext context, int index) {
    final l10n = l10nLocalizations(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.remove_extensions_repo,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to remove this repository?',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final mangaRepos = ref
                    .read(extensionsRepoStateProvider(widget.itemType))
                    .toList();
                mangaRepos.removeWhere((url) => url == _entries[index]);
                ref
                    .read(extensionsRepoStateProvider(widget.itemType).notifier)
                    .set(mangaRepos);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
  }
  
  void _showAddDialog(BuildContext context) {
    final l10n = l10nLocalizations(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool isLoading = false;
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor.withValues(alpha: 0.2),
                          theme.primaryColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_link_rounded,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.add_extensions_repo,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.url,
                    onChanged: (value) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.url_cannot_be_empty;
                      }
                      if (!value.endsWith('.json')) {
                        return l10n.url_must_end_with_dot_json;
                      }
                      try {
                        final uri = Uri.parse(value);
                        if (!uri.isAbsolute) {
                          return l10n.invalid_url_format;
                        }
                        return null;
                      } catch (e) {
                        return l10n.invalid_url_format;
                      }
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintText: l10n.url_must_end_with_dot_json,
                      prefixIcon: Icon(
                        Icons.link_rounded,
                        color: theme.primaryColor,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.1),
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.primaryColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: controller.text.isEmpty || !controller.text.endsWith(".json")
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          try {
                            final mangaRepos = ref
                                .read(extensionsRepoStateProvider(widget.itemType))
                                .toList();
                            final repo = await ref.read(
                              getRepoInfosProvider(jsonUrl: controller.text).future,
                            );
                            if (repo == null) {
                              botToast(l10n.unsupported_repo);
                              setState(() => isLoading = false);
                              return;
                            }
                            mangaRepos.add(repo);
                            ref
                                .read(extensionsRepoStateProvider(widget.itemType).notifier)
                                .set(mangaRepos);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e, s) {
                            setState(() => isLoading = false);
                            botToast('$e\n$s');
                          }
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                          ),
                        )
                      : Text(l10n.add),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
