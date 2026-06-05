import 'package:flutter/material.dart';
import '../../../models/choyxona_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HeaderInfoSection extends StatelessWidget {
  final Choyxona choyxona;

  const HeaderInfoSection({
    super.key,
    required this.choyxona,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Hero(
            tag: 'choyxona_title_${choyxona.id}',
            child: Material(
              color: Colors.transparent,
              child: Text(
                choyxona.name,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Cuisine & Category
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...choyxona.cuisine.take(3).map((cuisine) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isDark 
                        ? AppColors.darkGoldGradient 
                        : AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    cuisine,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              _buildStatChip(
                context,
                icon: Icons.star,
                value: choyxona.rating.toStringAsFixed(1),
                label: '${choyxona.reviewCount} reviews',
                color: isDark ? AppColors.darkSuccess : AppColors.success,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                context,
                icon: Icons.payments_outlined,
                value: choyxona.priceRange,
                label: 'Price',
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                context,
                icon: choyxona.isOpenNow() 
                    ? Icons.check_circle 
                    : Icons.cancel,
                value: choyxona.isOpenNow() ? 'Open' : 'Closed',
                label: 'Now',
                color: choyxona.isOpenNow()
                    ? (isDark ? AppColors.darkSuccess : AppColors.success)
                    : (isDark ? AppColors.darkError : AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
