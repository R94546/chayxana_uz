import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Экран выбора языка
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final List<Map<String, dynamic>> _languages = [
    {
      'code': 'ru',
      'locale': const Locale('ru'),
      'name': 'Русский',
      'nativeName': 'Русский',
      'flag': '🇷🇺',
    },
    {
      'code': 'uz',
      'locale': const Locale('uz'),
      'name': 'Uzbek',
      'nativeName': 'O\'zbekcha',
      'flag': '🇺🇿',
    },
    {
      'code': 'en',
      'locale': const Locale('en'),
      'name': 'English',
      'nativeName': 'English',
      'flag': '🇬🇧',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = context.locale;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('language'.tr()),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'select_language'.tr(),
              style: AppTextStyles.titleMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),

          // Список языков
          ..._languages.map((language) {
            return _buildLanguageCard(
              context,
              code: language['code'] as String,
              locale: language['locale'] as Locale,
              name: language['name'] as String,
              nativeName: language['nativeName'] as String,
              flag: language['flag'] as String,
              isSelected: currentLocale.languageCode == language['code'],
            );
          }),

          const SizedBox(height: 24),

          // Информация
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'language_change_note'.tr(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context, {
    required String code,
    required Locale locale,
    required String name,
    required String nativeName,
    required String flag,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).dividerColor,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              flag,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
        title: Text(
          nativeName,
          style: AppTextStyles.titleMedium.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          name,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        trailing: isSelected
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              )
            : Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).dividerColor,
              ),
        onTap: () => _changeLanguage(context, locale, code),
      ),
    );
  }

  Future<void> _changeLanguage(BuildContext context, Locale locale, String code) async {
    // Применяем локаль через EasyLocalization
    await context.setLocale(locale);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getSuccessMessage(code),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );

      // Возвращаемся назад после смены языка
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  String _getSuccessMessage(String languageCode) {
    switch (languageCode) {
      case 'uz':
        return 'Til o\'zgartirildi!';
      case 'en':
        return 'Language changed!';
      case 'ru':
      default:
        return 'Язык изменён!';
    }
  }
}
