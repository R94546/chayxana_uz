import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Экран настроек уведомлений
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _bookingReminders = true;
  bool _promotions = false;
  bool _newChoyxonas = true;
  bool _reviewResponses = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _bookingReminders = prefs.getBool('booking_reminders') ?? true;
      _promotions = prefs.getBool('promotions') ?? false;
      _newChoyxonas = prefs.getBool('new_choyxonas') ?? true;
      _reviewResponses = prefs.getBool('review_responses') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('notifications'.tr()),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: ListView(
        children: [
          // Заголовок секции
          _buildSectionHeader('notification_methods'.tr()),

          // Push уведомления
          _buildSwitchTile(
            context,
            icon: Icons.notifications_active,
            title: 'push_notifications'.tr(),
            subtitle: 'push_notifications_desc'.tr(),
            value: _pushNotifications,
            onChanged: (value) {
              setState(() => _pushNotifications = value);
              _saveSetting('push_notifications', value);
            },
          ),

          // Email уведомления
          _buildSwitchTile(
            context,
            icon: Icons.email_outlined,
            title: 'email_notifications'.tr(),
            subtitle: 'email_notifications_desc'.tr(),
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
              _saveSetting('email_notifications', value);
            },
          ),

          const Divider(height: 32),

          // Заголовок секции
          _buildSectionHeader('notification_types'.tr()),

          // Напоминания о бронировании
          _buildSwitchTile(
            context,
            icon: Icons.event_available,
            title: 'booking_reminders'.tr(),
            subtitle: 'booking_reminders_desc'.tr(),
            value: _bookingReminders,
            onChanged: (value) {
              setState(() => _bookingReminders = value);
              _saveSetting('booking_reminders', value);
            },
          ),

          // Новые чайханы
          _buildSwitchTile(
            context,
            icon: Icons.restaurant_menu,
            title: 'new_choyxonas_notify'.tr(),
            subtitle: 'new_choyxonas_desc'.tr(),
            value: _newChoyxonas,
            onChanged: (value) {
              setState(() => _newChoyxonas = value);
              _saveSetting('new_choyxonas', value);
            },
          ),

          // Ответы на отзывы
          _buildSwitchTile(
            context,
            icon: Icons.comment_outlined,
            title: 'review_responses'.tr(),
            subtitle: 'review_responses_desc'.tr(),
            value: _reviewResponses,
            onChanged: (value) {
              setState(() => _reviewResponses = value);
              _saveSetting('review_responses', value);
            },
          ),

          // Промоакции
          _buildSwitchTile(
            context,
            icon: Icons.local_offer_outlined,
            title: 'promotions'.tr(),
            subtitle: 'promotions_desc'.tr(),
            value: _promotions,
            onChanged: (value) {
              setState(() => _promotions = value);
              _saveSetting('promotions', value);
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
