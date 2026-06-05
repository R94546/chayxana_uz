import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = context.locale;

    return Scaffold(
      appBar: AppBar(
        title: Text('language'.tr()),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLanguageCard(
            context,
            title: 'lang_russian'.tr(),
            subtitle: 'Русский',
            locale: const Locale('ru'),
            isSelected: currentLocale.languageCode == 'ru',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildLanguageCard(
            context,
            title: 'lang_uzbek'.tr(),
            subtitle: 'O\'zbekcha',
            locale: const Locale('uz'),
            isSelected: currentLocale.languageCode == 'uz',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildLanguageCard(
            context,
            title: 'lang_english'.tr(),
            subtitle: 'English',
            locale: const Locale('en'),
            isSelected: currentLocale.languageCode == 'en',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required Locale locale,
        required bool isSelected,
        required bool isDark,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await context.setLocale(locale);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : (isDark ? AppColors.darkBorder : AppColors.border),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? (isDark
                      ? AppColors.darkPrimaryGradient
                      : AppColors.primaryGradient)
                      : null,
                  color: isSelected
                      ? null
                      : Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.language,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}