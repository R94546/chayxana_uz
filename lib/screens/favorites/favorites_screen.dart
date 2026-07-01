import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/design/choy_tokens.dart';
import '../../core/design/choy_components.dart';
import '../../core/utils/responsive_layout.dart';
import '../../services/favorites_service.dart';
import '../../services/auth_service.dart';
import '../../models/choyxona_model.dart';
import '../choyxona_details/choyxona_details_screen.dart';

/// Экран избранных чайхан с возможностью удаления
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favoritesService = FavoritesService();
  final _authService = AuthService();

  /// Показать диалог подтверждения удаления
  Future<void> _confirmRemoveFavorite(Choyxona choyxona) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('remove_from_favorites'.tr()),
        content: Text(
          '${'remove_favorite_confirm'.tr()} "${choyxona.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoyPalette.danger,
            ),
            child: Text('remove'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && _authService.currentUser != null) {
      await _favoritesService.toggleFavorite(
        _authService.currentUser!.uid,
        choyxona.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('removed_from_favorites'.tr()),
            backgroundColor: ChoyPalette.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('favorites'.tr()),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: StreamBuilder<List<String>>(
        stream: _authService.currentUser != null 
            ? _favoritesService.getFavorites(_authService.currentUser!.uid)
            : Stream.value([]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          final favoriteIds = snapshot.data!;

          if (favoriteIds.isEmpty) {
            return _buildEmptyState(context);
          }

          final idsToFetch = favoriteIds.take(10).toList();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('choyxonas')
                .where(FieldPath.documentId, whereIn: idsToFetch)
                .snapshots(),
            builder: (context, choyxonaSnapshot) {
              if (choyxonaSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ));
              }

              if (!choyxonaSnapshot.hasData || choyxonaSnapshot.data!.docs.isEmpty) {
                return _buildEmptyState(context);
              }

              final choyxonas = choyxonaSnapshot.data!.docs
                  .map((doc) => Choyxona.fromFirestore(doc))
                  .toList();

              // Responsive: Grid on wider screens, List on mobile
              final crossAxisCount = ResponsiveLayout.getGridCrossAxisCount(
                context,
                mobile: 1,
                tablet: 2,
                desktop: 4,
              );
              final horizontalPadding = ResponsiveLayout.getHorizontalPadding(context);

              if (crossAxisCount > 1) {
                return GridView.builder(
                  padding: EdgeInsets.all(horizontalPadding),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: choyxonas.length,
                  itemBuilder: (context, index) {
                    final choyxona = choyxonas[index];
                    return _buildFavoriteCard(choyxona);
                  },
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: choyxonas.length,
                itemBuilder: (context, index) {
                  final choyxona = choyxonas[index];
                  return _buildFavoriteCard(choyxona);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFavoriteCard(Choyxona choyxona) {
    final c = ChoyColors.of(context);
    final isOpen = choyxona.isOpenNow();
    return Container(
      margin: const EdgeInsets.only(bottom: ChoySpace.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: ChoyRadius.all(ChoyRadius.xl),
        border: Border.all(color: c.border),
        boxShadow: ChoyShadow.card(c.isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChoyxonaDetailsScreen(choyxona: choyxona),
            ),
          ),
          borderRadius: ChoyRadius.all(ChoyRadius.xl),
          child: Column(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(ChoyRadius.xl)),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: choyxona.mainImage.isNotEmpty
                          ? Image.network(
                              choyxona.mainImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: c.surfaceVariant,
                                child: Icon(Icons.local_cafe_rounded,
                                    size: 48, color: c.textMuted),
                              ),
                            )
                          : Container(
                              color: c.surfaceVariant,
                              child: Icon(Icons.local_cafe_rounded,
                                  size: 48, color: c.textMuted),
                            ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: ChoyStatusBadge(
                        label: isOpen ? 'open'.tr() : 'closed'.tr(),
                        tone: isOpen
                            ? ChoyStatusTone.success
                            : ChoyStatusTone.danger,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _confirmRemoveFavorite(choyxona),
                          borderRadius: ChoyRadius.all(ChoyRadius.pill),
                          child: Container(
                            padding: const EdgeInsets.all(8),
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
                            child: const Icon(Icons.favorite,
                                color: ChoyPalette.danger, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(ChoySpace.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            choyxona.name,
                            style: TextStyle(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 17),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 14, color: c.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  choyxona.address.fullAddress,
                                  style: TextStyle(
                                      color: c.textSecondary, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ChoyPalette.star.withValues(alpha: 0.12),
                        borderRadius: ChoyRadius.all(ChoyRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: ChoyPalette.star),
                          const SizedBox(width: 3),
                          Text(
                            choyxona.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: ChoyPalette.star,
                                fontWeight: FontWeight.w700),
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ChoyEmptyState(
      icon: Icons.favorite_border_rounded,
      title: 'no_favorites'.tr(),
      message: 'add_favorites_text'.tr(),
      action: ChoyButton(
        label: 'explore'.tr(),
        icon: Icons.explore_rounded,
        expanded: false,
        onPressed: () =>
            DefaultTabController.maybeOf(context)?.animateTo(0),
      ),
    );
  }
}