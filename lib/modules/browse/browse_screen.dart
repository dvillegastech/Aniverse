import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:mangayomi/main.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/modules/more/settings/reader/providers/reader_state_provider.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/providers/storage_provider.dart';
import 'package:mangayomi/modules/browse/extension/extension_screen.dart';
import 'package:mangayomi/modules/browse/sources/sources_screen.dart';
import 'package:mangayomi/modules/library/widgets/search_text_form_field.dart';
import 'package:mangayomi/services/fetch_sources_list.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  late final hideItems = ref.watch(hideItemsStateProvider);
  
  // Simplified: Only two main sections
  bool _showExtensions = false;
  ItemType _selectedType = ItemType.manga;
  final _textEditingController = TextEditingController();
  bool _isSearch = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  _checkPermission() async {
    await StorageProvider().requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nLocalizations(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Determine available types
    final availableTypes = <ItemType>[];
    if (!hideItems.contains("/MangaLibrary")) availableTypes.add(ItemType.manga);
    if (!hideItems.contains("/AnimeLibrary")) availableTypes.add(ItemType.anime);
    if (!hideItems.contains("/NovelLibrary")) availableTypes.add(ItemType.novel);
    
    if (availableTypes.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Ensure selected type is available
    if (!availableTypes.contains(_selectedType)) {
      _selectedType = availableTypes.first;
    }
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 180,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top bar with title and actions
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Text(
                        l10n.browse,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      if (_showExtensions) ...[
                        if (_isSearch)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _isSearch = false;
                                _textEditingController.clear();
                              });
                            },
                          )
                        else ...[
                          IconButton(
                            icon: const Icon(Icons.add_rounded, color: Colors.white),
                            onPressed: () {
                              context.push('/createExtension');
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.search_rounded, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _isSearch = true;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.translate_rounded, color: Colors.white),
                            onPressed: () {
                              context.push('/ExtensionLang', extra: _selectedType);
                            },
                          ),
                        ],
                      ] else ...[
                        IconButton(
                          icon: const Icon(Icons.travel_explore_rounded, color: Colors.white),
                          onPressed: () {
                            context.push('/globalSearch', extra: _selectedType);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
                          onPressed: () {
                            context.push('/sourceFilter', extra: _selectedType);
                          },
                        ),
                      ],
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _showExtensions ? 'Manage your extensions' : 'Discover new content',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Type selector chips
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: availableTypes.map((type) {
                      final isSelected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedType = type;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected 
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getTypeIcon(type),
                                    size: 18,
                                    color: isSelected 
                                        ? theme.primaryColor 
                                        : Colors.white.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getTypeName(type, l10n),
                                    style: TextStyle(
                                      color: isSelected 
                                          ? theme.primaryColor 
                                          : Colors.white,
                                      fontWeight: isSelected 
                                          ? FontWeight.bold 
                                          : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: theme.primaryColor,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Toggle between Sources and Extensions
          Container(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSectionButton(
                    context,
                    title: 'Sources',
                    icon: Icons.language_rounded,
                    isSelected: !_showExtensions,
                    onTap: () {
                      setState(() {
                        _showExtensions = false;
                        _isSearch = false;
                        _textEditingController.clear();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Stack(
                    children: [
                      _buildSectionButton(
                        context,
                        title: 'Extensions',
                        icon: Icons.extension_rounded,
                        isSelected: _showExtensions,
                        onTap: () {
                          setState(() {
                            _showExtensions = true;
                            _isSearch = false;
                            _textEditingController.clear();
                          });
                        },
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: _buildUpdateBadge(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Search bar (only for extensions)
          if (_showExtensions && _isSearch)
            Container(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.grey.shade800
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _textEditingController,
                  autofocus: true,
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Search extensions...',
                    prefixIcon: Icon(Icons.search, color: theme.hintColor),
                    suffixIcon: _textEditingController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: theme.hintColor),
                            onPressed: () {
                              _textEditingController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showExtensions
                  ? ExtensionScreen(
                      key: ValueKey('extension_$_selectedType'),
                      query: _textEditingController.text,
                      itemType: _selectedType,
                    )
                  : SourcesScreen(
                      key: ValueKey('source_$_selectedType'),
                      itemType: _selectedType,
                      tabIndex: (index) {
                        setState(() {
                          _showExtensions = true;
                        });
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.primaryColor
                  : isDark 
                      ? Colors.grey.shade700 
                      : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? theme.primaryColor : theme.hintColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected 
                      ? theme.primaryColor 
                      : isDark ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(ItemType type) {
    switch (type) {
      case ItemType.manga:
        return Icons.book_rounded;
      case ItemType.anime:
        return Icons.movie_rounded;
      case ItemType.novel:
        return Icons.menu_book_rounded;
    }
  }

  String _getTypeName(ItemType type, dynamic l10n) {
    switch (type) {
      case ItemType.manga:
        return 'Manga';
      case ItemType.anime:
        return 'Anime';
      case ItemType.novel:
        return 'Novel';
    }
  }

  Widget _buildUpdateBadge() {
    return StreamBuilder(
      stream: isar.sources
          .filter()
          .idIsNotNull()
          .and()
          .isActiveEqualTo(true)
          .itemTypeEqualTo(_selectedType)
          .watch(fireImmediately: true),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final entries = snapshot.data!
              .where((element) =>
                  compareVersions(element.version!, element.versionLast!) < 0)
              .toList();
          
          if (entries.isNotEmpty) {
            return Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                entries.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}