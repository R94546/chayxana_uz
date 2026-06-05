import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../widgets/ethereal_components.dart';
import 'customer_list_screen.dart';
import 'customer_detail_screen.dart';

/// 🎯 CRM Dashboard - Ethereal Design
/// Beautiful customer relationship management hub
class CrmDashboardScreen extends StatefulWidget {
  const CrmDashboardScreen({super.key});

  @override
  State<CrmDashboardScreen> createState() => _CrmDashboardScreenState();
}

class _CrmDashboardScreenState extends State<CrmDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentCustomers = [];
  List<Map<String, dynamic>> _topCustomers = [];
  List<Map<String, dynamic>> _recentPayments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // --- CRM DATA ---
      final usersSnapshot = await firestore.collection('users').get();
      final users = usersSnapshot.docs;

      int totalUsers = users.length;
      int newUsersThisWeek = 0;
      int activeUsers = 0;
      
      final weekAgo = now.subtract(const Duration(days: 7));
      
      for (final doc in users) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null && createdAt.isAfter(weekAgo)) {
          newUsersThisWeek++;
        }
        if ((data['bookingCount'] ?? 0) > 0) {
          activeUsers++;
        }
      }

      final recentUsersSnapshot = await firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final bookingsSnapshot = await firestore.collection('bookings').count().get();
      final totalBookings = bookingsSnapshot.count ?? 0;

      final topUsersSnapshot = await firestore
          .collection('users')
          .orderBy('bookingCount', descending: true)
          .limit(5)
          .get();

      // --- FINANCE DATA ---
      // Revenue this month
      final monthSubsQuery = await firestore
          .collection('subscriptions')
          .where('paymentStatus', isEqualTo: 'paid')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      double periodRevenue = 0;
      for (final doc in monthSubsQuery.docs) {
        periodRevenue += (doc.data()['price'] as num?)?.toDouble() ?? 0;
      }

      // Total revenue
      final allSubsQuery = await firestore
          .collection('subscriptions')
          .where('paymentStatus', isEqualTo: 'paid')
          .get();

      double totalRevenue = 0;
      for (final doc in allSubsQuery.docs) {
        totalRevenue += (doc.data()['price'] as num?)?.toDouble() ?? 0;
      }

      // Active subs
      final activeSubsCount = await firestore
          .collection('subscriptions')
          .where('isActive', isEqualTo: true)
          .where('plan', isEqualTo: 'premium')
          .count()
          .get();

      // Recent payments
      final recentPaymentsSnapshot = await firestore
          .collection('subscriptions')
          .where('paymentStatus', isEqualTo: 'paid')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      setState(() {
        _stats = {
          // CRM
          'totalUsers': totalUsers,
          'newUsersThisWeek': newUsersThisWeek,
          'activeUsers': activeUsers,
          'totalBookings': totalBookings,
          'conversionRate': totalUsers > 0 
              ? ((activeUsers / totalUsers) * 100).toStringAsFixed(1)
              : '0',
          // Finance
          'periodRevenue': periodRevenue,
          'totalRevenue': totalRevenue,
          'activeSubscriptions': activeSubsCount.count ?? 0,
          'mrr': (activeSubsCount.count ?? 0) * 300000.0,
        };
        
        _recentCustomers = recentUsersSnapshot.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();

        _topCustomers = topUsersSnapshot.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();

        _recentPayments = recentPaymentsSnapshot.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.etherealPurpleGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_graph, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'CRM & Moliya',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkBackgroundGradient,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.etherealPurple))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.etherealPurple,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Finance Overview
                      _buildRevenueCard(),
                      const SizedBox(height: 24),

                      // Stats Grid
                      _buildStatsGrid(context),
                      const SizedBox(height: 32),

                      // Quick Actions
                      _buildQuickActions(context),
                      const SizedBox(height: 32),

                      // Recent Payments
                      _buildSectionTitle('Oxirgi To\'lovlar', Icons.receipt_long),
                      const SizedBox(height: 16),
                      _buildPaymentHistory(),
                      const SizedBox(height: 32),

                      // Recent Customers
                      _buildSectionTitle('Yangi Mijozlar', Icons.person_add),
                      const SizedBox(height: 16),
                      _buildRecentCustomers(),
                      const SizedBox(height: 32),

                      // Top Customers
                      _buildSectionTitle('Top Mijozlar', Icons.star),
                      const SizedBox(height: 16),
                      _buildTopCustomers(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.etherealPurple,
            AppColors.etherealDeepBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.etherealPurple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Joriy Oy Daromadi',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _formatMoney(_stats['periodRevenue'] ?? 0),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Jami daromad: ${_formatMoney(_stats['totalRevenue'] ?? 0)}',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.etherealGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.etherealGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: AppColors.etherealGreen, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'MRR: ${_formatMoney(_stats['mrr'] ?? 0)}',
                      style: GoogleFonts.outfit(color: AppColors.etherealGreen, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    if (_recentPayments.isEmpty) {
      return _buildEmptyState('To\'lovlar yo\'q');
    }

    return Column(
      children: _recentPayments.map((payment) {
        final price = (payment['price'] as num?)?.toDouble() ?? 0;
        final createdAt = (payment['createdAt'] as Timestamp?)?.toDate();
        final choyxonaId = payment['choyxonaId'] ?? '';

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('choyxonas').doc(choyxonaId).get(),
          builder: (context, snapshot) {
            final choyxonaName = snapshot.data?.get('name') ?? 'Choyxona';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.glassWhite.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.etherealGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle, color: AppColors.etherealGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          choyxonaName,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (createdAt != null)
                          Text(
                            _formatDate(createdAt),
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _formatMoney(price),
                    style: GoogleFonts.outfit(
                      color: AppColors.etherealGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} M so\'m';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} K so\'m';
    }
    return '${amount.toStringAsFixed(0)} so\'m';
  }

  Widget _buildStatsGrid(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final crossAxisCount = isDesktop ? 4 : 2;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isDesktop ? 1.5 : 1.1,
      children: [
        _buildStatCard(
          title: 'Faol Obunalar',
          value: '${_stats['activeSubscriptions'] ?? 0}',
          icon: Icons.diamond,
          gradient: AppColors.etherealPurpleGradient,
        ),
        _buildStatCard(
          title: 'Yangi Mijozlar',
          value: '+${_stats['newUsersThisWeek'] ?? 0}',
          icon: Icons.person_add,
          gradient: AppColors.etherealGreenGradient,
        ),
        _buildStatCard(
          title: 'Jami Mijozlar',
          value: '${_stats['totalUsers'] ?? 0}',
          icon: Icons.people,
          gradient: AppColors.etherealOrangeGradient,
        ),
        _buildStatCard(
          title: 'Konversiya',
          value: '${_stats['conversionRate'] ?? 0}%',
          icon: Icons.analytics,
          gradient: LinearGradient(
            colors: [AppColors.etherealAqua, AppColors.etherealDeepBlue],
          ),
        ),
      ],
    );
  }

  // ... kept helper methods ...

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.last.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.list_alt,
            label: 'Barcha Mijozlar',
            color: AppColors.etherealPurple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerListScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.analytics,
            label: 'Analitika',
            color: AppColors.etherealAqua,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Batafsil analitika tez kunda! 🚀')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.etherealPurple, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCustomers() {
    if (_recentCustomers.isEmpty) {
      return _buildEmptyState('Hozircha mijozlar yo\'q');
    }

    return Column(
      children: _recentCustomers.map((customer) {
        return _buildCustomerTile(customer, isRecent: true);
      }).toList(),
    );
  }

  Widget _buildTopCustomers() {
    if (_topCustomers.isEmpty) {
      return _buildEmptyState('Hozircha bronlar yo\'q');
    }

    return Column(
      children: _topCustomers.asMap().entries.map((entry) {
        return _buildCustomerTile(entry.value, rank: entry.key + 1);
      }).toList(),
    );
  }

  Widget _buildCustomerTile(Map<String, dynamic> customer, {bool isRecent = false, int? rank}) {
    final name = customer['displayName'] ?? customer['email']?.split('@').first ?? 'Noma\'lum';
    final email = customer['email'] ?? '';
    final bookings = customer['bookingCount'] ?? 0;
    final createdAt = (customer['createdAt'] as Timestamp?)?.toDate();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerDetailScreen(
            customerId: customer['id'],
            customerData: customer,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.glassWhite.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            if (rank != null)
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: rank == 1 
                      ? AppColors.etherealOrangeGradient
                      : rank == 2 
                          ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade600])
                          : LinearGradient(colors: [Colors.brown.shade300, Colors.brown.shade500]),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              )
            else
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.etherealPurple.withOpacity(0.2),
                child: Text(
                  name[0].toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: AppColors.etherealPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    email,
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.etherealAqua, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$bookings',
                      style: GoogleFonts.outfit(
                        color: AppColors.etherealAqua,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (isRecent && createdAt != null)
                  Text(
                    _formatDate(createdAt),
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Text(
        message,
        style: GoogleFonts.outfit(
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Bugun';
    if (diff.inDays == 1) return 'Kecha';
    if (diff.inDays < 7) return '${diff.inDays} kun oldin';
    return '${date.day}.${date.month}.${date.year}';
  }
}
