import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../core/design/choy_tokens.dart';
import '../../core/design/choy_components.dart';
import '../../core/theme/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import '../owner/menu_management_screen.dart';
import 'rooms_management_screen.dart';
import 'choyxona_bookings_screen.dart';
import 'choyxona_reviews_screen.dart';
import '../owner/edit_choyxona_screen.dart';
import '../promotions/promotion_editor_screen.dart';
import '../reports/reports_screen.dart';
import 'combined_analytics_screen.dart';

/// 🍵 Admin dashboard — premium choyxona redizayn (Faza 4).
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

      // Статистика — оборачиваем в try-catch чтобы ошибки индексов не ломали загрузку
      int todayBookingsCount = 0;
      int pendingBookingsCount = 0;
      int totalBookingsCount = 0;
      int reviewsCount = 0;

      try {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        try {
          final todayBookings = await FirebaseFirestore.instance
              .collection('bookings')
              .where('choyxonaId', isEqualTo: user.choyxonaId)
              .where('createdAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
              .count()
              .get();
          todayBookingsCount = todayBookings.count ?? 0;
        } catch (e) {
          debugPrint('Today bookings query failed (index may be needed): $e');
        }

        try {
          final pendingBookings = await FirebaseFirestore.instance
              .collection('bookings')
              .where('choyxonaId', isEqualTo: user.choyxonaId)
              .where('status', isEqualTo: 'pending')
              .count()
              .get();
          pendingBookingsCount = pendingBookings.count ?? 0;
        } catch (e) {
          debugPrint('Pending bookings query failed: $e');
        }

        try {
          final totalBookings = await FirebaseFirestore.instance
              .collection('bookings')
              .where('choyxonaId', isEqualTo: user.choyxonaId)
              .count()
              .get();
          totalBookingsCount = totalBookings.count ?? 0;
        } catch (e) {
          debugPrint('Total bookings query failed: $e');
        }

        try {
          final reviews = await FirebaseFirestore.instance
              .collection('reviews')
              .where('choyxonaId', isEqualTo: user.choyxonaId)
              .count()
              .get();
          reviewsCount = reviews.count ?? 0;
        } catch (e) {
          debugPrint('Reviews query failed: $e');
        }
      } catch (e) {
        debugPrint('Stats loading error: $e');
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
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(child: CircularProgressIndicator(color: c.primary)),
      );
    }

    if (_user == null ||
        _user!.choyxonaId == null ||
        _user!.choyxonaId!.isEmpty) {
      return Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          title: Text('admin_panel'.tr()),
          automaticallyImplyLeading: false,
        ),
        body: ChoyEmptyState(
          icon: Icons.link_off_rounded,
          title: 'not_bound_title'.tr(),
          message: 'not_bound_msg'.tr(),
          action: ChoyButton(
            label: 'logout'.tr(),
            icon: Icons.logout_rounded,
            variant: ChoyButtonVariant.ghost,
            expanded: false,
            onPressed: _handleLogout,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(_choyxona['name'] ?? 'my_choyxona'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
          IconButton(
            icon: Icon(c.isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded),
            onPressed: () => Provider.of<ThemeProvider>(context, listen: false)
                .toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: c.primary,
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(ChoySpace.lg),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ChoyStatusBadge(
                label: 'admin_mode'.tr(),
                tone: ChoyStatusTone.info,
                icon: Icons.shield_outlined,
              ),
            ),
            const SizedBox(height: ChoySpace.lg),
            _buildStatsGrid(c),
            const SizedBox(height: ChoySpace.xl),
            if ((_stats['pendingBookings'] ?? 0) > 0) _buildPendingAlert(c),
            ChoySectionHeader(title: 'management'.tr()),
            const SizedBox(height: ChoySpace.md),
            _buildMenuGrid(context),
            const SizedBox(height: ChoySpace.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ChoyColors c) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: ChoySpace.md,
      mainAxisSpacing: ChoySpace.md,
      childAspectRatio: 1.6,
      children: [
        _statCard(c,
            icon: Icons.today_rounded,
            title: 'today'.tr(),
            value: '${_stats['todayBookings'] ?? 0}',
            color: c.primary),
        _statCard(c,
            icon: Icons.hourglass_top_rounded,
            title: 'pending'.tr(),
            value: '${_stats['pendingBookings'] ?? 0}',
            color: ChoyPalette.warning),
        _statCard(c,
            icon: Icons.calendar_month_rounded,
            title: 'total'.tr(),
            value: '${_stats['totalBookings'] ?? 0}',
            color: ChoyPalette.success),
        _statCard(c,
            icon: Icons.star_rounded,
            title: 'rating'.tr(),
            value: (_stats['rating'] as num?)?.toStringAsFixed(1) ?? '0.0',
            subtitle: '${_stats['reviewsCount'] ?? 0} ${'reviews'.tr()}',
            color: ChoyPalette.star),
      ],
    );
  }

  Widget _statCard(
    ChoyColors c, {
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return ChoyCard(
      padding: const EdgeInsets.all(ChoySpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: ChoyRadius.all(ChoyRadius.md),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
              Text(subtitle ?? title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: c.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAlert(ChoyColors c) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('choyxonaId', isEqualTo: _user!.choyxonaId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data?.docs.length ?? 0;
        if (pendingCount == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: ChoySpace.lg),
          child: ChoyCard(
            color: ChoyPalette.warning.withValues(alpha: 0.10),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ChoyxonaBookingsScreen(choyxonaId: _user!.choyxonaId!),
              ),
            ).then((_) => _loadData()),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: ChoyPalette.warning),
                const SizedBox(width: ChoySpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'pending_bookings_waiting'.tr(args: ['$pendingCount']),
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: c.textPrimary),
                      ),
                      Text('tap_to_review'.tr(),
                          style: TextStyle(
                              fontSize: 12, color: c.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final id = _user!.choyxonaId!;
    final name = _choyxona['name'] ?? '';
    final menuItems = <Map<String, dynamic>>[
      {
        'icon': Icons.calendar_today_rounded,
        'title': 'bookings'.tr(),
        'color': ChoyPalette.tea,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ChoyxonaBookingsScreen(choyxonaId: id)),
            ).then((_) => _loadData()),
      },
      {
        'icon': Icons.restaurant_menu_rounded,
        'title': 'menu'.tr(),
        'color': ChoyPalette.success,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      MenuManagementScreen(choyxonaId: id, choyxonaName: name)),
            ),
      },
      {
        'icon': Icons.meeting_room_rounded,
        'title': 'rooms_management'.tr(),
        'color': ChoyPalette.info,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => RoomsManagementScreen(choyxonaId: id)),
            ),
      },
      {
        'icon': Icons.star_rounded,
        'title': 'reviews'.tr(),
        'color': ChoyPalette.gold,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ChoyxonaReviewsScreen(choyxonaId: id)),
            ),
      },
      {
        'icon': Icons.analytics_rounded,
        'title': 'analytics_cashier'.tr(),
        'color': const Color(0xFF8B5CF6),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CombinedAnalyticsScreen(
                      choyxonaId: id, choyxonaName: name)),
            ),
      },
      {
        'icon': Icons.info_outline_rounded,
        'title': 'info'.tr(),
        'color': ChoyPalette.clay,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => EditChoyxonaScreen(
                      choyxonaId: id, choyxonaData: _choyxona)),
            ).then((_) => _loadData()),
      },
      {
        'icon': Icons.local_offer_rounded,
        'title': 'promotions'.tr(),
        'color': ChoyPalette.warning,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PromotionEditorScreen(choyxonaId: id)),
            ),
      },
      {
        'icon': Icons.receipt_long_rounded,
        'title': 'reports'.tr(),
        'color': ChoyPalette.teaDark,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ReportsScreen(choyxonaId: id, choyxonaName: name)),
            ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: ChoySpace.md,
        mainAxisSpacing: ChoySpace.md,
        childAspectRatio: 1.5,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return _menuTile(
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          color: item['color'] as Color,
          onTap: item['onTap'] as VoidCallback,
        );
      },
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final c = ChoyColors.of(context);
    return ChoyCard(
      onTap: onTap,
      padding: const EdgeInsets.all(ChoySpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: ChoyRadius.all(ChoyRadius.md),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('logout'.tr()),
        content: Text('logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('logout'.tr(),
                style: const TextStyle(color: ChoyPalette.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService().signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
