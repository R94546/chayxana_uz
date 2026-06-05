import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import '../owner/menu_management_screen.dart';
import '../owner/tables_management_screen.dart';
import 'choyxona_bookings_screen.dart';
import 'choyxona_analytics_screen.dart';
import 'choyxona_reviews_screen.dart';
import '../owner/edit_choyxona_screen.dart'; // Import Edit Screen
import '../../services/data_sync_provider.dart'; // Import Data Sync
import '../promotions/promotion_editor_screen.dart';
import '../reports/reports_screen.dart';
import '../reports/cash_register_report_screen.dart';
import 'combined_analytics_screen.dart';

/// Dashboard для администраторов чайханы
class ChoyxonaAdminDashboard extends StatefulWidget {
  const ChoyxonaAdminDashboard({super.key});

  @override
  State<ChoyxonaAdminDashboard> createState() => _ChoyxonaAdminDashboardState();
}

class _ChoyxonaAdminDashboardState extends State<ChoyxonaAdminDashboard> {
  bool _isLoading = true;
  UserModel? _user;
  Map<String, dynamic> _choyxona = {};
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await AuthService().getCurrentUserData();
      
      // DEBUG: Выводим информацию о пользователе
      print('=== ChoyxonaAdminDashboard DEBUG ===');
      print('User loaded: ${user != null}');
      if (user != null) {
        print('User ID: ${user.userId}');
        print('User Email: ${user.email}');
        print('User Role: ${user.role}');
        print('ChoyxonaId: "${user.choyxonaId}"');
        print('ChoyxonaId is null: ${user.choyxonaId == null}');
        print('ChoyxonaId isEmpty: ${user.choyxonaId?.isEmpty ?? true}');
      }
      print('=====================================');
      
      if (user == null || user.choyxonaId == null || user.choyxonaId!.isEmpty) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
        return;
      }


      // Загрузить данные чайханы
      final choyxonaDoc = await FirebaseFirestore.instance
          .collection('choyxonas')
          .doc(user.choyxonaId)
          .get();

      // Статистика - оборачиваем в try-catch чтобы ошибки индексов не ломали загрузку
      int todayBookingsCount = 0;
      int pendingBookingsCount = 0;
      int totalBookingsCount = 0;
      int reviewsCount = 0;

      try {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        // Бронирования сегодня - может требовать индекс
        try {
          final todayBookings = await FirebaseFirestore.instance
              .collection('bookings')
              .where('choyxonaId', isEqualTo: user.choyxonaId)
              .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
              .count()
              .get();
          todayBookingsCount = todayBookings.count ?? 0;
        } catch (e) {
          print('Today bookings query failed (index may be needed): $e');
        }

        // Ожидающие подтверждения
        try {
          final pendingBookings = await FirebaseFirestore.instance
              .collection('bookings')
              .where('choyxonaId', isEqualTo: user.choyxonaId)
              .where('status', isEqualTo: 'pending')
              .count()
              .get();
          pendingBookingsCount = pendingBookings.count ?? 0;
        } catch (e) {
          print('Pending bookings query failed: $e');
        }

        // Всего бронирований
        try {
          final totalBookings = await FirebaseFirestore.instance
              .collection('bookings')
              .where('choyxonaId', isEqualTo: user.choyxonaId)
              .count()
              .get();
          totalBookingsCount = totalBookings.count ?? 0;
        } catch (e) {
          print('Total bookings query failed: $e');
        }

        // Отзывы
        try {
          final reviews = await FirebaseFirestore.instance
              .collection('reviews')
              .where('choyxonaId', isEqualTo: user.choyxonaId)
              .count()
              .get();
          reviewsCount = reviews.count ?? 0;
        } catch (e) {
          print('Reviews query failed: $e');
        }
      } catch (e) {
        print('Stats loading error: $e');
      }

      setState(() {
        _user = user;
        _choyxona = choyxonaDoc.data() ?? {};
        _stats = {
          'todayBookings': todayBookingsCount,
          'pendingBookings': pendingBookingsCount,
          'totalBookings': totalBookingsCount,
          'reviewsCount': reviewsCount,
          'rating': _choyxona['rating'] ?? 0.0,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null || _user!.choyxonaId == null || _user!.choyxonaId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Панель управления'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Вы не привязаны к чайхане',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Обратитесь к Super Admin',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Выйти'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isViewOnly = _user!.isViewOnly;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_choyxona['name'] ?? 'Моя чайхана'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.getBackgroundGradient(isDark),
        ),
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Роль пользователя
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isViewOnly
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isViewOnly ? Colors.orange : Colors.purple,
                    ),
                  ),
                  child: Text(
                    isViewOnly ? 'view_only_mode'.tr() : 'admin_mode'.tr(),
                    style: TextStyle(
                      color: isViewOnly ? Colors.orange : Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Статистика
                _buildStatsGrid(isDark),
                const SizedBox(height: 24),

                // Ожидающие брони (alert)
                if ((_stats['pendingBookings'] ?? 0) > 0)
                  _buildPendingAlert(isDark),

                // Меню управления
                Text(
                  'management'.tr(),
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuGrid(context, isDark, isViewOnly),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.today,
          title: 'Сегодня',
          value: '${_stats['todayBookings'] ?? 0}',
          color: AppColors.getPrimary(isDark),
          isDark: isDark,
        ),
        _buildStatCard(
          icon: Icons.hourglass_empty,
          title: 'Ожидают',
          value: '${_stats['pendingBookings'] ?? 0}',
          color: AppColors.warning,
          isDark: isDark,
        ),
        _buildStatCard(
          icon: Icons.calendar_month,
          title: 'Всего',
          value: '${_stats['totalBookings'] ?? 0}',
          color: AppColors.success,
          isDark: isDark,
        ),
        _buildStatCard(
          icon: Icons.star,
          title: 'Рейтинг',
          value: (_stats['rating'] as num?)?.toStringAsFixed(1) ?? '0.0',
          subtitle: '${_stats['reviewsCount'] ?? 0} отзывов',
          color: AppColors.starGold,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBg(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.titleLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle ?? title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getTextSecondary(isDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAlert(bool isDark) {
    // Use StreamBuilder for real-time updates
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('choyxonaId', isEqualTo: _user!.choyxonaId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data?.docs.length ?? 0;
        
        if (pendingCount == 0) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warning),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active, color: AppColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$pendingCount ta bron kutilmoqda',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Tasdiqlash yoki rad etish uchun bosing',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChoyxonaBookingsScreen(choyxonaId: _user!.choyxonaId!),
                  ),
                ).then((_) => _loadData()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuGrid(BuildContext context, bool isDark, bool isViewOnly) {
    final menuItems = [
      {
        'icon': Icons.calendar_today,
        'title': 'Бронирования',
        'color': Theme.of(context).primaryColor,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChoyxonaBookingsScreen(choyxonaId: _user!.choyxonaId!),
          ),
        ),
      },
      if (!isViewOnly) {
        'icon': Icons.restaurant_menu,
        'title': 'Меню',
        'color': AppColors.success,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MenuManagementScreen(
              choyxonaId: _user!.choyxonaId!,
              choyxonaName: _choyxona['name'] ?? '',
            ),
          ),
        ),
      },
      if (!isViewOnly) {
        'icon': Icons.table_bar,
        'title': 'Xonalar',
        'color': AppColors.info,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TablesManagementScreen(choyxonaId: _user!.choyxonaId!),
          ),
        ),
      },
      {
        'icon': Icons.star,
        'title': 'Отзывы',
        'color': AppColors.starGold,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChoyxonaReviewsScreen(choyxonaId: _user!.choyxonaId!),
          ),
        ),
      },
      {
        'icon': Icons.analytics,
        'title': 'Tahlil & Kassa',
        'color': Colors.purple,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CombinedAnalyticsScreen(
              choyxonaId: _user!.choyxonaId!,
              choyxonaName: _choyxona['name'] ?? '',
            ),
          ),
        ),
      },
      if (!isViewOnly) {
        'icon': Icons.settings,
        'title': 'Инфо',
        'color': AppColors.getTextSecondary(isDark),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditChoyxonaScreen(
              choyxonaId: _user!.choyxonaId!,
              choyxonaData: _choyxona,
            ),
          ),
        ).then((_) => _loadData()),
      },
      if (!isViewOnly) {
        'icon': Icons.local_offer,
        'title': 'promotions'.tr(),
        'color': AppColors.warning,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PromotionEditorScreen(
              choyxonaId: _user!.choyxonaId!,
            ),
          ),
        ),
      },
      if (!isViewOnly) {
        'icon': Icons.picture_as_pdf,
        'title': 'reports'.tr(),
        'color': Colors.red,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportsScreen(
              choyxonaId: _user!.choyxonaId!,
              choyxonaName: _choyxona['name'] ?? '',
            ),
          ),
        ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return _buildMenuTile(
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          color: item['color'] as Color,
          onTap: item['onTap'] as VoidCallback,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getCardBg(isDark),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти?'),
        content: const Text('Вы уверены что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService().signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
