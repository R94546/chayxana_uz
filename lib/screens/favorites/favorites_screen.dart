import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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
              backgroundColor: AppColors.error,
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
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                    return _buildFavoriteCard(choyxona, isDark);
                  },
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: choyxonas.length,
                itemBuilder: (context, index) {
                  final choyxona = choyxonas[index];
                  return _buildFavoriteCard(choyxona, isDark);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFavoriteCard(Choyxona choyxona, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChoyxonaDetailsScreen(choyxona: choyxona),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Изображение
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.network(
                    choyxona.mainImage,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 150,
                      color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                      child: const Icon(Icons.restaurant, size: 48),
                    ),
                  ),
                  // Статус
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: choyxona.isOpenNow() ? AppColors.success : AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        choyxona.isOpenNow() ? 'open'.tr() : 'closed'.tr(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                  // Кнопка удаления из избранного
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _confirmRemoveFavorite(choyxona),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: AppColors.error,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Информация
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          choyxona.name,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, 
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                choyxona.address.fullAddress,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Рейтинг
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.starGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 16, color: AppColors.starGold),
                        const SizedBox(width: 4),
                        Text(
                          choyxona.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.starGold,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkError : AppColors.error).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 60,
                color: isDark ? AppColors.darkError : AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'no_favorites'.tr(),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'add_favorites_text'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                DefaultTabController.of(context)?.animateTo(0);
              },
              icon: const Icon(Icons.explore),
              label: Text('explore'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}