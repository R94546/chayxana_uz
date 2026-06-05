import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';

/// 🗂️ Category Cards (Visual Match 1:1)
/// Updated gradients based on latest images:
/// 0. Hammasi: Green
/// 1. An'anaviy: Purple
/// 2. Zamonaviy: Pink
/// 3. Premium: Yellow/Gold
class CategoryCards extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final Map<String, int> categoryCounts;

  const CategoryCards({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.categoryCounts = const {},
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = [
      {'value': 'all', 'label': 'category_all'.tr(), 'icon': Icons.menu},
      {'value': 'traditional', 'label': 'category_traditional'.tr(), 'icon': Icons.wb_sunny_outlined},
      {'value': 'modern', 'label': 'category_modern'.tr(), 'icon': Icons.rocket_launch},
      {'value': 'premium', 'label': 'category_premium'.tr(), 'icon': Icons.workspace_premium},
    ];

    return SizedBox(
      height: 100, 
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final value = cat['value'] as String;
          final isSelected = selectedCategory == value;
          final count = categoryCounts[value] ?? 0;

          return GestureDetector(
            onTap: () => onCategorySelected(value),
            child: isDark
                ? _buildDarkCard(cat, index, count)
                : _buildLightCard(cat, isSelected, count),
          );
        },
      ),
    );
  }

  /// 🌙 DARK MODE: Colorful Gradients from Images
  Widget _buildDarkCard(Map<String, dynamic> cat, int index, int count) {
    LinearGradient gradient;
    Color textColor;
    
    switch (index) {
      case 0: // Hammasi - Blue (черный текст для контраста)
        gradient = AppColors.categoryEmeraldGradient;
        textColor = const Color(0xFF1A202C); // Черный
        break;
      case 1: // An'anaviy - Purple
        gradient = AppColors.categoryPurpleGradient;
        textColor = Colors.white;
        break;
      case 2: // Zamonaviy - Pink
        gradient = AppColors.categoryPinkGradient;
        textColor = Colors.white;
        break;
      default: // Premium - Yellow (черный текст для контраста)
        gradient = AppColors.categoryYellowGradient;
        textColor = const Color(0xFF1A202C); // Черный
        break;
    }

    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            cat['icon'] as IconData,
            color: textColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            cat['label'] as String,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            NumberFormat('#,###').format(count),
            style: TextStyle(
              color: textColor.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// ☀️ LIGHT MODE: Green Active / White Inactive
  Widget _buildLightCard(Map<String, dynamic> cat, bool isSelected, int count) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: isSelected ? AppColors.lightActiveCategoryGradient : null,
        color: isSelected ? null : AppColors.lightInactiveCategoryBg,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? null
            : Border.all(color: AppColors.lightInactiveCategoryBorder),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.lightPrimary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            cat['icon'] as IconData,
            color: isSelected
                ? Colors.white
                : AppColors.lightInactiveCategoryIcon,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            cat['label'] as String,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : AppColors.lightInactiveCategoryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            NumberFormat('#,###').format(count),
            style: TextStyle(
              color: isSelected
                  ? Colors.white.withOpacity(0.9)
                  : AppColors.lightMutedText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
