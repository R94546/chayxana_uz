import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/theme_provider.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'add_choyxona_screen.dart';
import 'tables_management_screen.dart';
import 'menu_management_screen.dart';
import 'active_orders_screen.dart';
import 'choyxonas_list_screen.dart';
import 'bookings_list_screen.dart';
import 'reviews_list_screen.dart';
import 'clients_list_screen.dart';
import 'analytics_screen.dart';

/// Админ панель владельца для добавления чайхан
class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('owner_dashboard'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => _showLanguageDialog(context),
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => _showThemeDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.getBackgroundGradient(isDark),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Приветствие
                _buildWelcomeCard(),

                const SizedBox(height: 24),

                // Статистика (с реальными данными)
                _buildStatsGrid(),

                const SizedBox(height: 24),

                // Быстрые действия
                Text(
                  'quick_actions'.tr(),
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),

                const SizedBox(height: 16),

                _buildQuickActions(context),

                const SizedBox(height: 24),

                // Coming soon
                _buildComingSoonSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'welcome'.tr(),
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'manage_choyxonas'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textWhite.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('choyxonas').snapshots(),
      builder: (context, choyxonasSnapshot) {
        final choyxonasCount = choyxonasSnapshot.hasData
            ? choyxonasSnapshot.data!.docs.length
            : 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
          builder: (context, bookingsSnapshot) {
            final bookingsCount = bookingsSnapshot.hasData
                ? bookingsSnapshot.data!.docs.length
                : 0;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
              builder: (context, reviewsSnapshot) {
                final reviewsCount = reviewsSnapshot.hasData
                    ? reviewsSnapshot.data!.docs.length
                    : 0;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'user')
                      .snapshots(),
                  builder: (context, usersSnapshot) {
                    final usersCount = usersSnapshot.hasData
                        ? usersSnapshot.data!.docs.length
                        : 0;

                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          context: context,
                          icon: Icons.restaurant,
                          title: 'choyxonas'.tr(),
                          value: choyxonasCount.toString(),
                          color: AppColors.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChoyxonasListScreen(),
                            ),
                          ),
                        ),
                        _buildStatCard(
                          context: context,
                          icon: Icons.calendar_today,
                          title: 'bookings'.tr(),
                          value: bookingsCount.toString(),
                          color: AppColors.accent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookingsListScreen(),
                            ),
                          ),
                        ),
                        _buildStatCard(
                          context: context,
                          icon: Icons.star,
                          title: 'reviews'.tr(),
                          value: reviewsCount.toString(),
                          color: AppColors.starGold,
                          onTap: () {
                            if (choyxonasSnapshot.hasData && 
                                choyxonasSnapshot.data!.docs.isNotEmpty) {
                              final choyxonaId = choyxonasSnapshot.data!.docs.first.id;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReviewsListScreen(
                                    choyxonaId: choyxonaId,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('add_choyxona_first'.tr())),
                              );
                            }
                          },
                        ),
                        _buildStatCard(
                          context: context,
                          icon: Icons.people,
                          title: 'clients'.tr(),
                          value: usersCount.toString(),
                          color: AppColors.success,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ClientsListScreen(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getCardBg(Theme.of(context).brightness == Brightness.dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? AppColors.darkCardBorder 
              : color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: color,
                ),
              ),
              Text(
                title,
                style: AppTextStyles.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        _buildActionTile(
          context: context,
          icon: Icons.add_business,
          title: 'add_choyxona'.tr(),
          subtitle: 'add_choyxona_subtitle'.tr(),
          color: AppColors.primary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AddChoyxonaScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          context: context,
          icon: Icons.table_bar,
          title: 'tables'.tr(),
          subtitle: 'tables_subtitle'.tr(),
          color: AppColors.success,
          onTap: () {
            // Получаем первую чайхану владельца
            FirebaseFirestore.instance
                .collection('choyxonas')
                .limit(1)
                .get()
                .then((snapshot) {
              if (snapshot.docs.isNotEmpty) {
                final choyxonaId = snapshot.docs.first.id;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TablesManagementScreen(
                      choyxonaId: choyxonaId,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('add_choyxona_first'.tr()),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            });
          },
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          context: context,
          icon: Icons.restaurant_menu,
          title: 'menu_management'.tr(),
          subtitle: 'menu_management_subtitle'.tr(),
          color: AppColors.accent,
          onTap: () {
            // Получаем первую чайхану владельца
            FirebaseFirestore.instance
                .collection('choyxonas')
                .limit(1)
                .get()
                .then((snapshot) {
              if (snapshot.docs.isNotEmpty) {
                final doc = snapshot.docs.first;
                final choyxonaId = doc.id;
                final choyxonaName = (doc.data() as Map<String, dynamic>)['name'] ?? 'Чайхана';
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MenuManagementScreen(
                      choyxonaId: choyxonaId,
                      choyxonaName: choyxonaName,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('add_choyxona_first'.tr()),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            });
          },
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          context: context,
          icon: Icons.receipt_long,
          title: 'active_orders'.tr(),
          subtitle: 'active_orders_subtitle'.tr(),
          color: AppColors.secondary,
          onTap: () {
            // Получаем первую чайхану владельца
            FirebaseFirestore.instance
                .collection('choyxonas')
                .limit(1)
                .get()
                .then((snapshot) {
              if (snapshot.docs.isNotEmpty) {
                final choyxonaId = snapshot.docs.first.id;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ActiveOrdersScreen(
                      choyxonaId: choyxonaId,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('add_choyxona_first'.tr()),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            });
          },
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          context: context,
          icon: Icons.analytics,
          title: 'analytics'.tr(),
          subtitle: 'analytics_subtitle'.tr(),
          color: AppColors.info,
          onTap: () {
            _showComingSoon(context, 'feature_coming_soon'.tr());
          },
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getCardBg(Theme.of(context).brightness == Brightness.dark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.darkCardBorder 
                  : Colors.transparent
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
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
                      color: AppColors.getTextPrimary(Theme.of(context).brightness == Brightness.dark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardBg(Theme.of(context).brightness == Brightness.dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.construction,
            size: 48,
            color: AppColors.accent,
          ),
          const SizedBox(height: 16),
          Text(
            'coming_soon_title'.tr(),
            style: AppTextStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'coming_soon_desc'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Выход',
          style: AppTextStyles.titleLarge,
        ),
        content: Text(
          'Вы уверены что хотите выйти?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await AuthService().signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: AppColors.textWhite,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('select_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(context, 'Русский', const Locale('ru')),
            _buildLanguageOption(context, "O'zbekcha", const Locale('uz')),
            _buildLanguageOption(context, 'English', const Locale('en')),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String name, Locale locale) {
    final isSelected = context.locale == locale;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      onTap: () {
        context.setLocale(locale);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('language_changed'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('select_theme'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.light_mode, 
                color: !themeProvider.isDarkMode ? AppColors.primary : Colors.orange,
              ),
              title: Text('light_theme'.tr()),
              trailing: !themeProvider.isDarkMode 
                  ? const Icon(Icons.check, color: AppColors.primary) 
                  : null,
              onTap: () {
                themeProvider.setTheme(ThemeMode.light);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('theme_changed'.tr()),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.dark_mode, 
                color: themeProvider.isDarkMode ? AppColors.primary : Colors.indigo,
              ),
              title: Text('dark_theme'.tr()),
              trailing: themeProvider.isDarkMode 
                  ? const Icon(Icons.check, color: AppColors.primary) 
                  : null,
              onTap: () {
                themeProvider.setTheme(ThemeMode.dark);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('theme_changed'.tr()),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
