import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Экран настроек платформы (Super Admin)
class PlatformSettingsScreen extends StatelessWidget {
  const PlatformSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Настройки платформы'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Подписки', [
            _buildSettingTile(
              context,
              icon: Icons.diamond,
              title: 'Цена подписки',
              subtitle: '300,000 сум/месяц',
              onTap: () => _editSubscriptionPrice(context),
            ),
            _buildSettingTile(
              context,
              icon: Icons.hourglass_empty,
              title: 'Пробный период',
              subtitle: '7 дней',
              onTap: () => _editTrialPeriod(context),
            ),
          ], isDark),

          const SizedBox(height: 16),

          _buildSection('Категории', [
            _buildSettingTile(
              context,
              icon: Icons.category,
              title: 'Категории чайхан',
              subtitle: 'Традиционная, Современная, и т.д.',
              onTap: () => _editCategories(context),
            ),
            _buildSettingTile(
              context,
              icon: Icons.location_city,
              title: 'Города',
              subtitle: 'Ташкент, Самарканд, и т.д.',
              onTap: () => _editCities(context),
            ),
          ], isDark),

          const SizedBox(height: 16),

          _buildSection('Уведомления', [
            _buildSettingTile(
              context,
              icon: Icons.notifications,
              title: 'Push уведомления',
              subtitle: 'Настройка уведомлений',
              onTap: () {},
            ),
            _buildSettingTile(
              context,
              icon: Icons.email,
              title: 'Email уведомления',
              subtitle: 'Отключено',
              onTap: () {},
            ),
          ], isDark),

          const SizedBox(height: 16),

          _buildSection('Данные', [
            _buildSettingTile(
              context,
              icon: Icons.backup,
              title: 'Резервное копирование',
              subtitle: 'Экспорт данных',
              onTap: () {},
            ),
            _buildSettingTile(
              context,
              icon: Icons.analytics,
              title: 'Аналитика',
              subtitle: 'Подробная статистика',
              onTap: () {},
            ),
          ], isDark),

          const SizedBox(height: 16),

          _buildSection('Информация', [
            _buildSettingTile(
              context,
              icon: Icons.info,
              title: 'О платформе',
              subtitle: 'Choyxona UZ v1.0.0',
              onTap: () => _showAbout(context),
            ),
          ], isDark),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.darkTextLight : AppColors.textLight,
      ),
      onTap: onTap,
    );
  }

  void _editSubscriptionPrice(BuildContext context) {
    final controller = TextEditingController(text: '300000');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Цена подписки'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Цена в сумах',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              // Сохранить в настройки
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Цена обновлена'), backgroundColor: AppColors.success),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _editTrialPeriod(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Пробный период'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('3 дня'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('7 дней'),
              trailing: const Icon(Icons.check, color: AppColors.success),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('14 дней'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _editCategories(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Категории'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('🏛️ Традиционная')),
            const ListTile(title: Text('✨ Современная')),
            const ListTile(title: Text('⚡ Быстрая')),
            const ListTile(title: Text('👑 Премиум')),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Добавить категорию'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _editCities(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Города'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('📍 Ташкент')),
            const ListTile(title: Text('📍 Самарканд')),
            const ListTile(title: Text('📍 Бухара')),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Добавить город'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Choyxona UZ',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.restaurant, color: Colors.white),
      ),
      children: [
        const Text('Платформа бронирования столов в чайханах Узбекистана.'),
        const SizedBox(height: 16),
        const Text('© 2024 Choyxona UZ'),
      ],
    );
  }
}
