import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;

import '../../../models/choyxona_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/favorites_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/location_service.dart';

/// 🪟 Choyxona Card (Visual Match 1:1)
/// Updated "Ochiq" status pill color -> Neon Lime with Black text
class ChoyxonaCard extends StatelessWidget {
  final Choyxona choyxona;
  final VoidCallback onTap;

  const ChoyxonaCard({
    super.key,
    required this.choyxona,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Outer Container
    Widget content = Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getCardBg(isDark),
        borderRadius: BorderRadius.circular(isDark ? 20 : 16),
        border: isDark ? Border.all(color: AppColors.darkCardBorder) : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
            blurRadius: isDark ? 24 : 16,
            offset: Offset(0, isDark ? 8 : 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Photo (Left Side)
          _buildPhoto(isDark),

          const SizedBox(width: 12),

          // 2. Info (Right Side)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  choyxona.name,
                  style: TextStyle(
                    color: AppColors.getTextPrimary(isDark),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Rating & Reviews
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.starGold, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      choyxona.rating.toStringAsFixed(1), 
                      style: TextStyle(
                        color: AppColors.getTextPrimary(isDark),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${choyxona.reviewCount} ta sharh',
                        style: TextStyle(
                          color: AppColors.getTextSecondary(isDark),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),

                // Location -> Distance
                Builder(
                  builder: (context) {
                    final distance = LocationService.instance.getDistanceString(
                      choyxona.address.latitude,
                      choyxona.address.longitude,
                    );
                    return Row(
                      children: [
                        Icon(
                          Icons.location_on, 
                          color: AppColors.getTextSecondary(isDark), 
                          size: 16
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distance.isNotEmpty ? distance : choyxona.address.city, 
                          style: TextStyle(
                            color: AppColors.getTextSecondary(isDark),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Open/Closed Status Pill
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: choyxona.isOpenNow() 
                          ? (isDark ? AppColors.statusBg : AppColors.lightPrimary)
                          : (isDark ? AppColors.error : Colors.red),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      choyxona.isOpenNow() ? 'open'.tr() : 'closed'.tr(), 
                      style: TextStyle(
                        color: choyxona.isOpenNow() 
                            ? (isDark ? AppColors.statusText : Colors.white)
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Apply Blur for Dark Mode
    if (isDark) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: GestureDetector(onTap: onTap, child: content),
        ),
      );
    } else {
      content = GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }

  Widget _buildPhoto(bool isDark) {
    final bool isNew = choyxona.reviewCount < 3;
    
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 120, 
            height: 120, 
            child: choyxona.mainImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: choyxona.mainImage,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[300]),
                    errorWidget: (_, __, ___) => Container(color: Colors.grey[300]),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
          ),
        ),
        if (isDark)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),
        // "Yangi" badge for new choyxonas
        if (isNew)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E), // Green-500
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'new_badge'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}