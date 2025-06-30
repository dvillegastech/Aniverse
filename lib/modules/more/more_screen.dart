import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/modules/more/widgets/incognito_mode_widget.dart';
import 'package:mangayomi/providers/l10n_providers.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nLocalizations(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.grey.shade900,
                        Colors.black,
                        Colors.grey.shade900,
                      ]
                    : [
                        Colors.grey.shade50,
                        Colors.white,
                        Colors.grey.shade100,
                      ],
              ),
            ),
          ),
          // Pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/app_icons/icon.png',
                repeat: ImageRepeat.repeat,
                scale: 8.0,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: AppBar().preferredSize.height + 20),
                // Animated logo section
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  curve: Curves.easeOutBack,
                  builder: (context, double scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 30),
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.primaryColor.withValues(alpha: 0.1),
                              theme.primaryColor.withValues(alpha: 0.05),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.grey.shade900 : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withValues(alpha: 0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            "assets/app_icons/icon.png",
                            color: theme.primaryColor,
                            fit: BoxFit.cover,
                            height: 80,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Main content with cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Incognito mode card
                      _buildCard(
                        context,
                        child: const IncognitoModeWidget(),
                      ),
                      const SizedBox(height: 16),
                      // Quick actions section
                      _buildCard(
                        context,
                        child: Column(
                          children: [
                            _buildEnhancedListTile(
                              context,
                              onTap: () => context.push('/downloadQueue'),
                              icon: Icons.download_outlined,
                              title: l10n!.download_queue,
                              iconColor: Colors.blue,
                            ),
                            _buildEnhancedListTile(
                              context,
                              onTap: () => context.push('/categories', extra: (false, 0)),
                              icon: Icons.label_outline_rounded,
                              title: l10n.categories,
                              iconColor: Colors.orange,
                            ),
                            _buildEnhancedListTile(
                              context,
                              onTap: () => context.push('/statistics'),
                              icon: Icons.query_stats_outlined,
                              title: l10n.statistics,
                              iconColor: Colors.green,
                            ),
                            _buildEnhancedListTile(
                              context,
                              onTap: () => context.push('/dataAndStorage'),
                              icon: Icons.storage,
                              title: l10n.data_and_storage,
                              iconColor: Colors.purple,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Settings section
                      _buildCard(
                        context,
                        child: Column(
                          children: [
                            _buildEnhancedListTile(
                              context,
                              onTap: () => context.push('/settings'),
                              icon: Icons.settings_outlined,
                              title: l10n.settings,
                              iconColor: Colors.grey,
                            ),
                            _buildEnhancedListTile(
                              context,
                              onTap: () => context.push('/about'),
                              icon: Icons.info_outline,
                              title: l10n.about,
                              iconColor: Colors.teal,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCard(BuildContext context, {required Widget child}) {
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
          child: child,
        ),
      ),
    );
  }
  
  Widget _buildEnhancedListTile(
    BuildContext context, {
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    required Color iconColor,
    bool showDivider = true,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
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
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 72,
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}
