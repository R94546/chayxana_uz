import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/responsive_layout.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import '../booking/booking_history_screen.dart';
import '../settings/notifications_screen.dart';
import '../settings/help_support_screen.dart';
import '../settings/language_screen.dart';
import '../favorites/favorites_screen.dart';
import 'edit_profile_screen.dart';
import 'my_reviews_screen.dart';

/// Экран профиля пользователя
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;
  int _reviewsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUserData();
    
    // Подсчёт отзывов пользователя
    int reviewsCount = 0;
    if (user != null) {
      try {
        final reviewsSnapshot = await FirebaseFirestore.instance
            .collection('reviews')
            .where('userId', isEqualTo: user.userId)
            .count()
            .get();
        reviewsCount = reviewsSnapshot.count ?? 0;
      } catch (e) {
        print('Error loading reviews count: $e');
      }
    }
    
    setState(() {
      _currentUser = user;
      _reviewsCount = reviewsCount;
      _isLoading = false;
    });
  }

  /// Перейти на экран редактирования профиля
  void _openEditProfile() async {
    if (_currentUser == null) return;
    
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: _currentUser!),
      ),
    );
    
    // Перезагружаем данные если были изменения
    if (result == true) {
      _loadUserData();
    }
  }

  /// Показать избранные чайханы
  void _showFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FavoritesScreen(),
      ),
    );
  }

  /// Показать отзывы пользователя
  void _showReviews() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MyReviewsScreen(),
      ),
    );
  }

  /// Показать историю посещений
  void _showVisits() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BookingHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('profile'.tr()),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _openEditProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: isDesktop
                  ? _buildDesktopLayout(context)
                  : _buildMobileLayout(context),
            ),
    );
  }

  /// Desktop: Two-column layout
  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column: Profile header and stats
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildProfileHeader(context),
                    const SizedBox(height: 24),
                    _buildStatsSection(context),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right column: Menu
              Expanded(
                flex: 2,
                child: _buildMenuSection(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mobile: Vertical layout
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildProfileHeader(context),
          const SizedBox(height: 24),
          _buildStatsSection(context),
          const SizedBox(height: 24),
          _buildMenuSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkPrimaryGradient : AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Аватар
          GestureDetector(
            onTap: _openEditProfile,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textWhite,
                      width: 4,
                    ),
                  ),
                  child: _currentUser?.photoUrl.isNotEmpty == true
                      ? ClipOval(
                          child: Image.network(
                            _currentUser!.photoUrl,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            _currentUser?.initials ?? '?',
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: AppColors.textWhite,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textWhite,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Имя
          Text(
            _currentUser?.fullName ?? 'user'.tr(),
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textWhite,
            ),
          ),
          
          const SizedBox(height: 4),

          // Email
          Text(
            _currentUser?.email ?? '',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textWhite.withOpacity(0.9),
            ),
          ),

          const SizedBox(height: 8),

          // Роль
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.textWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getRoleLabel(_currentUser?.role ?? 'client'),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.restaurant,
              label: 'visits'.tr(),
              value: '${_currentUser?.totalBookings ?? 0}',
              color: Theme.of(context).primaryColor,
              onTap: _showVisits,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.favorite,
              label: 'favorites'.tr(),
              value: '${_currentUser?.favoriteChoyxonas.length ?? 0}',
              color: AppColors.error,
              onTap: _showFavorites,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.titleLarge.copyWith(color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.history,
            title: 'booking_history'.tr(),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BookingHistoryScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            context,
            icon: Icons.notifications_outlined,
            title: 'notifications'.tr(),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            context,
            icon: Icons.language,
            title: 'language'.tr(),
            subtitle: context.locale.languageCode == 'ru' ? 'Русский' : context.locale.languageCode == 'uz' ? "O'zbekcha" : 'English',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LanguageScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          
          // Dark Mode Toggle
          ListTile(
            leading: Icon(
              isDark ? Icons.dark_mode : Icons.dark_mode_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
            title: Text(
              'dark_theme'.tr(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            trailing: Switch(
              value: isDark,
              onChanged: (value) => themeProvider.toggleTheme(),
              activeColor: AppColors.accent,
            ),
          ),
          
          const Divider(height: 1),
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: 'help_support'.tr(),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            title: 'about_app'.tr(),
            subtitle: '${'version'.tr()} 1.0.0',
            onTap: () => _showAboutDialog(),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: 'logout'.tr(),
            textColor: AppColors.error,
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: textColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).dividerColor,
      ),
      onTap: onTap,
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'owner_role'.tr();
      case 'admin':
        return 'admin_role'.tr();
      case 'client':
      default:
        return 'client_role'.tr();
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.restaurant,
                color: AppColors.textWhite,
              ),
            ),
            const SizedBox(width: 12),
            Text('Choyxona UZ', style: AppTextStyles.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'version'.tr()}: 1.0.0', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'app_description'.tr(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'logout_title'.tr(),
          style: AppTextStyles.titleLarge.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: Text(
          'logout_confirm_message'.tr(),
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('stay'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('exit'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );



    if (confirmed == true && mounted) {
      await _authService.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }
}