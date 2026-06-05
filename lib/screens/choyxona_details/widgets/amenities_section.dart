import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AmenitiesSection extends StatelessWidget {
  final List<String> features;

  const AmenitiesSection({
    super.key,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: features.map((feature) {
              return _buildAmenityChip(context, feature);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(BuildContext context, String amenity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    IconData icon;
    switch (amenity.toLowerCase()) {
      case 'wifi':
        icon = Icons.wifi;
        break;
      case 'parking':
        icon = Icons.local_parking;
        break;
      case 'ac':
        icon = Icons.ac_unit;
        break;
      case 'outdoor seating':
        icon = Icons.deck;
        break;
      case 'live music':
        icon = Icons.music_note;
        break;
      default:
        icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.border),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            amenity,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
