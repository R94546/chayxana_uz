import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';

/// 🔍 Glassmorphic Search Bar
/// Dark: Glass effect with rgba(255,255,255,0.12) background
/// Light: White background with border and shadow
class GlassmorphicSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const GlassmorphicSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ☀️ LIGHT MODE: White background with border and shadow
    if (!isDark) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.lightSearchBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightSearchBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000), // rgba(0,0,0,0.08)
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: _buildTextField(isDark),
      );
    }

    // 🌙 DARK MODE: Glassmorphism effect
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.darkGlassBg, // rgba(255,255,255,0.12)
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkGlassBorder), // rgba(255,255,255,0.20)
          ),
          child: _buildTextField(isDark),
        ),
      ),
    );
  }

  Widget _buildTextField(bool isDark) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightHeadingText,
        fontSize: 16,
      ),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'search_by_name_or_address'.tr(),
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkTextMuted : AppColors.lightPlaceholder,
          fontSize: 16,
        ),
        prefixIcon: Icon(
          Icons.search,
          // 🟢 Search icon: Lime (#A8FF35) in dark, Emerald (#10B981) in light
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          size: 24,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                onPressed: onClear,
              )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
