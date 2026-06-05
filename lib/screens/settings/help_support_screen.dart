import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Экран помощи и поддержки
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('help_support'.tr()),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Контактная информация
          _buildSectionHeader(context, 'contact_us'.tr()),
          const SizedBox(height: 12),

          _buildContactCard(
            context,
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'support@choyxona.uz',
            onTap: () => _launchEmail('rustamabduvahobov5127@gmail.com'),
          ),

          const SizedBox(height: 12),

          _buildContactCard(
            context,
            icon: Icons.phone_outlined,
            title: 'phone'.tr(),
            subtitle: '+998 90 835 23 07',
            onTap: () => _launchPhone('+998908352307'),
          ),

          const SizedBox(height: 12),

          _buildContactCard(
            context,
            icon: Icons.telegram,
            title: 'Telegram',
            subtitle: '@r5834',
            onTap: () => _launchTelegram('choyxona_support'),
          ),

          const SizedBox(height: 32),

          // FAQ
          _buildSectionHeader(context, 'faq'.tr()),
          const SizedBox(height: 12),

          _buildFAQCard(
            context,
            question: 'faq_book_table'.tr(),
            answer: 'faq_book_table_answer'.tr(),
          ),

          const SizedBox(height: 12),

          _buildFAQCard(
            context,
            question: 'faq_cancel_booking'.tr(),
            answer: 'faq_cancel_booking_answer'.tr(),
          ),

          const SizedBox(height: 12),

          _buildFAQCard(
            context,
            question: 'faq_add_favorite'.tr(),
            answer: 'faq_add_favorite_answer'.tr(),
          ),

          const SizedBox(height: 12),

          _buildFAQCard(
            context,
            question: 'faq_leave_review'.tr(),
            answer: 'faq_leave_review_answer'.tr(),
          ),

          const SizedBox(height: 32),

          // Социальные сети
          _buildSectionHeader(context, 'social_media'.tr()),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(
                context,
                icon: Icons.telegram,
                label: 'Telegram',
                onTap: () => _launchTelegram('@R5834'),
              ),
              _buildSocialButton(
                context,
                icon: Icons.facebook,
                label: 'Facebook',
                onTap: () => _launchUrl('https://facebook.com/choyxona.uz'),
              ),
              _buildSocialButton(
                context,
                icon: Icons.language,
                label: 'Instagram',
                onTap: () => _launchUrl('https://instagram.com/iuwewilldie'),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Дополнительная информация
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 48,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'support_hours'.tr(),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'support_hours_time'.tr(),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'average_response_time'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: AppTextStyles.headlineSmall.copyWith(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.darkShadow : AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).dividerColor,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQCard(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(32),
              child: Icon(
                icon,
                size: 28,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Choyxona UZ',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchTelegram(String username) async {
    final Uri telegramUri = Uri.parse('https://t.me/$username');
    if (await canLaunchUrl(telegramUri)) {
      await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
