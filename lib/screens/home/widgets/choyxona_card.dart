import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/design/choy_tokens.dart';
import '../../../models/choyxona_model.dart';
import '../../../services/location_service.dart';

/// 🍵 Choyxona kartasi — premium redizayn (Faza 4).
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
    final c = ChoyColors.of(context);
    final isOpen = choyxona.isOpenNow();
    final distance = LocationService.instance.getDistanceString(
      choyxona.address.latitude,
      choyxona.address.longitude,
    );

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
          onTap: onTap,
          borderRadius: ChoyRadius.all(ChoyRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(ChoySpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhoto(c),
                const SizedBox(width: ChoySpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        choyxona.name,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: ChoySpace.sm),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: ChoyPalette.star, size: 17),
                          const SizedBox(width: 3),
                          Text(
                            choyxona.rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '(${choyxona.reviewCount})',
                              style: TextStyle(
                                  color: c.textMuted, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: c.textMuted, size: 15),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              distance.isNotEmpty
                                  ? distance
                                  : choyxona.address.city,
                              style: TextStyle(
                                  color: c.textSecondary, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: ChoySpace.md),
                      _StatusPill(isOpen: isOpen),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(ChoyColors c) {
    final bool isNew = choyxona.reviewCount < 3;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: ChoyRadius.all(ChoyRadius.lg),
          child: SizedBox(
            width: 104,
            height: 104,
            child: choyxona.mainImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: choyxona.mainImage,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: c.surfaceVariant),
                    errorWidget: (_, __, ___) => Container(
                      color: c.surfaceVariant,
                      child: Icon(Icons.local_cafe_rounded,
                          color: c.textMuted),
                    ),
                  )
                : Container(
                    color: c.surfaceVariant,
                    child: Icon(Icons.local_cafe_rounded,
                        color: c.textMuted),
                  ),
          ),
        ),
        if (isNew)
          Positioned(
            top: 7,
            left: 7,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ChoyPalette.gold,
                borderRadius: ChoyRadius.all(ChoyRadius.sm),
              ),
              child: Text(
                'new_badge'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOpen});
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? ChoyPalette.success : ChoyPalette.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: ChoyRadius.all(ChoyRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'open'.tr() : 'closed'.tr(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
