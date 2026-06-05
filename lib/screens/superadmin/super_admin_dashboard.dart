import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/responsive_layout.dart';
import '../../services/auth_service.dart';
import '../../widgets/ethereal_components.dart';
import '../auth/login_screen.dart';
import 'all_choyxonas_screen.dart';
import 'subscriptions_screen.dart';
import 'all_users_screen.dart';
import 'all_bookings_screen.dart';

import 'platform_settings_screen.dart';

import 'crm/crm_dashboard_screen.dart';

/// 🌌 Super Admin Dashboard - Ethereal Design
class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadPlatformStats();
  }

  Future<void> _loadPlatformStats() async {
    int choyxonasCount = 0;
    int usersCount = 0;
    int bookingsCount = 0;
    int todayBookings = 0;
    int activeSubscriptions = 0;
    double totalRevenue = 0;

    try {
      final firestore = FirebaseFirestore.instance;
      
      // Load counts (fetching QuerySnapshot size is more reliable without specific index)
      final choyxonasSnapshot = await firestore.collection('choyxonas').get();
      choyxonasCount = choyxonasSnapshot.size;

      final usersSnapshot = await firestore.collection('users').get();
      usersCount = usersSnapshot.size;

      final bookingsSnapshot = await firestore.collection('bookings').get();
      bookingsCount = bookingsSnapshot.size;

      // Today's bookings
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayBookingsSnapshot = await firestore
          .collection('bookings')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .get();
      todayBookings = todayBookingsSnapshot.docs.length;

      // Subscriptions & Revenue
      final activeSubscriptionsSnapshot = await firestore
          .collection('subscriptions')
          .where('isActive', isEqualTo: true)
          .get();
      activeSubscriptions = activeSubscriptionsSnapshot.size;
      
      for (final doc in activeSubscriptionsSnapshot.docs) {
        final price = (doc.data()['price'] as num?)?.toDouble() ?? 0;
        totalRevenue += price;
      }

    } catch (e) {
      debugPrint('Error loading stats: $e');
      // If error occurs, we still want to show what we have (even if 0) 
      // instead of infinite loading or clearing everything blankly without explanation.
    }

    if (mounted) {
      setState(() {
        _stats = {
          'choyxonasCount': choyxonasCount,
          'usersCount': usersCount,
          'bookingsCount': bookingsCount,
          'todayBookings': todayBookings,
          'activeSubscriptions': activeSubscriptions,
          'totalRevenue': totalRevenue,
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ethereal theme is dark by default
    final isDark = true;

    return Scaffold(
      backgroundColor: AppColors.darkBgTop,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.etherealLime.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.admin_panel_settings, color: AppColors.etherealLime),
            ),
            const SizedBox(width: 12),
            Text(
              'Super Admin',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadPlatformStats();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.etherealPink),
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.etherealLime))
              : RefreshIndicator(
                  onRefresh: _loadPlatformStats,
                  color: AppColors.etherealLime,
                  backgroundColor: AppColors.darkCardBg,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Section
                        _buildWelcomeSection(),
                        const SizedBox(height: 24),

                        // Management Grid (stats are now in tiles)
                        Text(
                          'Boshqaruv',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildMenuGrid(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return EtherealCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xush kelibsiz, Admin! 👋',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choyxona UZ platformasi sizning nazoratingiz ostida. Bugungi statistika ajoyib ko\'rinmoqda.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStats(BuildContext context) {
    // Responsive grid columns
    final crossAxisCount = ResponsiveLayout.getGridCrossAxisCount(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16, // Increased spacing
      mainAxisSpacing: 16,
      childAspectRatio: 1.0, 
      children: [
        _buildCompactStatCard(
          title: 'Umumiy Daromad',
          value: _formatMoney(_stats['totalRevenue'] ?? 0),
          icon: Icons.account_balance_wallet,
          gradient: AppColors.etherealGreenGradient,
        ),
        _buildCompactStatCard(
          title: 'Faol Obunalar',
          value: '${_stats['activeSubscriptions'] ?? 0}',
          icon: Icons.diamond,
          gradient: AppColors.etherealPurpleGradient,
        ),
        _buildCompactStatCard(
          title: 'Bugungi Bronlar',
          value: '${_stats['todayBookings'] ?? 0}',
          subtitle: 'Jami: ${_stats['bookingsCount'] ?? 0}',
          icon: Icons.calendar_today,
          gradient: AppColors.etherealOrangeGradient,
        ),
        _buildCompactStatCard(
          title: 'Foydalanuvchilar',
          value: '${_stats['usersCount'] ?? 0}',
          icon: Icons.people_alt,
          gradient: LinearGradient(
            colors: [AppColors.etherealAqua, AppColors.etherealDeepBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  }

  /// Compact stat card with improved Ethereal design
  Widget _buildCompactStatCard({
    required String title,
    required String value,
    required IconData icon,
    required LinearGradient gradient,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.last.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          
          // Value & Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.restaurant,
        'title': 'Choyxonalar',
        'subtitle': 'Jami:',
        'count': _stats['choyxonasCount'] ?? 0,
        'color': AppColors.etherealLime,
        'screen': const AllChoyxonasScreen(),
        'bgImage': 'assets/images/admin/choyxonalar_bg.png',
      },

      {
        'icon': Icons.auto_graph,
        'title': 'CRM & Moliya',
        'subtitle': 'Jami Daromad:',
        'count': _stats['totalRevenue'] ?? 0,
        'isMoney': true,
        'color': AppColors.etherealPurple,
        'screen': const CrmDashboardScreen(),
        'bgImage': 'assets/images/admin/crm_bg.png',
      },
      {
        'icon': Icons.diamond,
        'title': 'Obunalar',
        'subtitle': 'Faol:',
        'count': _stats['activeSubscriptions'] ?? 0,
        'color': AppColors.etherealPink,
        'screen': const SubscriptionsScreen(),
        'bgImage': 'assets/images/admin/obunalar_bg.png',
      },
      {
        'icon': Icons.people,
        'title': 'Foydalanuvchilar',
        'subtitle': 'Jami:',
        'count': _stats['usersCount'] ?? 0,
        'color': AppColors.etherealAqua,
        'screen': const AllUsersScreen(),
        'bgImage': 'assets/images/admin/users_bg.png',
      },
      {
        'icon': Icons.calendar_month,
        'title': 'Bronlar',
        'subtitle': 'Bugun:',
        'count': _stats['todayBookings'] ?? 0,
        'color': AppColors.etherealOrange,
        'screen': const AllBookingsScreen(),
        'bgImage': 'assets/images/admin/bronlar_bg.png',
      },
      {
        'icon': Icons.settings_suggest,
        'title': 'Sozlamalar',
        'subtitle': 'Platforma sozlamalari',
        'count': null,
        'color': Colors.white,
        'screen': const PlatformSettingsScreen(),
        'bgImage': 'assets/images/admin/sozlamalar_bg.png',
      },
    ];

    final crossAxisCount = ResponsiveLayout.getGridCrossAxisCount(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final count = item['count'];
        final isMoney = item['isMoney'] == true;
        
        return _buildEtherealMenuItem(
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          subtitle: item['subtitle'] as String,
          color: item['color'] as Color,
          bgImage: item['bgImage'] as String?,
          count: count != null 
              ? (isMoney ? _formatMoney((count as num).toDouble()) : '$count')
              : null,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => item['screen'] as Widget),
            );
          },
        );
      },
    );
  }

  Widget _buildEtherealMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? count,
    String? bgImage,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              if (bgImage != null)
                Image.asset(
                  bgImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.darkCardBg,
                  ),
                ),
              // Dark overlay for readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top row: icon and badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        if (count != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withOpacity(0.4)),
                            ),
                            child: Text(
                              count,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Bottom: title and subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          count != null ? '$subtitle $count' : subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCardBg,
        title: Text('Chiqish', style: GoogleFonts.outfit(color: Colors.white)),
        content: Text(
          'Haqiqatan ham tizimdan chiqmoqchimisiz?',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.etherealPink),
            child: const Text('Chiqish', style: TextStyle(color: Colors.white)),
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
