import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/promotion_model.dart';
import '../../services/promotion_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 🎉 Экран списка акций и скидок (для клиентов)
class PromotionsListScreen extends StatelessWidget {
  final String? choyxonaId; // null = все акции
  
  const PromotionsListScreen({super.key, this.choyxonaId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final promotionService = PromotionService();

    return Scaffold(
      appBar: AppBar(
        title: Text('promotions'.tr()),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.getBackgroundGradient(isDark),
        ),
        child: StreamBuilder<List<Promotion>>(
          stream: choyxonaId != null
              ? promotionService.getActiveChoyxonaPromotions(choyxonaId!)
              : promotionService.getActivePromotions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('error_loading'.tr(), style: AppTextStyles.bodyLarge),
                  ],
                ),
              );
            }
            
            final promotions = snapshot.data ?? [];
            
            if (promotions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 80,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'no_promotions'.tr(),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'check_back_later'.tr(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: promotions.length,
              itemBuilder: (context, index) {
                return _PromotionCard(
                  promotion: promotions[index],
                  isDark: isDark,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Карточка акции
class _PromotionCard extends StatelessWidget {
  final Promotion promotion;
  final bool isDark;
  
  const _PromotionCard({required this.promotion, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.getCardBg(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkCardBorder : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Изображение
          if (promotion.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: promotion.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 160,
                  color: isDark ? AppColors.darkCardBg : Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 160,
                  color: isDark ? AppColors.darkCardBg : Colors.grey[200],
                  child: Icon(Icons.image, size: 48, color: AppColors.getTextSecondary(isDark)),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок и скидка
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        promotion.title,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.getTextPrimary(isDark),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '-${promotion.discountPercent}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Описание
                Text(
                  promotion.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.getTextSecondary(isDark),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Промокод (если есть)
                if (promotion.promoCode != null && promotion.promoCode!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBgMiddle : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.getPrimary(isDark),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.confirmation_number_outlined,
                          size: 18,
                          color: AppColors.getPrimary(isDark),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'promo_code'.tr(),
                          style: TextStyle(
                            color: AppColors.getTextSecondary(isDark),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          promotion.promoCode!,
                          style: TextStyle(
                            color: AppColors.getPrimary(isDark),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Даты и оставшиеся дни
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${dateFormat.format(promotion.startDate)} - ${dateFormat.format(promotion.endDate)}',
                      style: TextStyle(
                        color: AppColors.getTextSecondary(isDark),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDaysColor(promotion.daysRemaining),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${promotion.daysRemaining} ${'days_left'.tr()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getDaysColor(int days) {
    if (days <= 3) return AppColors.error;
    if (days <= 7) return AppColors.warning;
    return AppColors.success;
  }
}
