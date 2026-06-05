import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// 👤 Customer Detail Screen - Full profile with history
class CustomerDetailScreen extends StatelessWidget {
  final String customerId;
  final Map<String, dynamic> customerData;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    required this.customerData,
  });

  @override
  Widget build(BuildContext context) {
    final name = customerData['displayName'] ?? customerData['email']?.split('@').first ?? 'Noma\'lum';
    final email = customerData['email'] ?? '';
    final phone = customerData['phone'] ?? '';
    final bookings = customerData['bookingCount'] ?? 0;
    final favorites = customerData['favoriteCount'] ?? 0;
    final createdAt = (customerData['createdAt'] as Timestamp?)?.toDate();

    return Scaffold(
      backgroundColor: AppColors.darkBgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkBackgroundGradient,
        ),
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              backgroundColor: Colors.transparent,
              expandedHeight: 220,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.etherealPurpleGradient,
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            name[0].toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          email,
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        icon: Icons.calendar_today,
                        value: '$bookings',
                        label: 'Bronlar',
                        color: AppColors.etherealAqua,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatBox(
                        icon: Icons.favorite,
                        value: '$favorites',
                        label: 'Sevimlilar',
                        color: AppColors.etherealPink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatBox(
                        icon: Icons.schedule,
                        value: createdAt != null 
                            ? '${DateTime.now().difference(createdAt).inDays}'
                            : '0',
                        label: 'Kun',
                        color: AppColors.etherealOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Contact Info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSection(
                  title: 'Aloqa',
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.email, 'Email', email),
                      if (phone.isNotEmpty)
                        _buildInfoRow(Icons.phone, 'Telefon', phone),
                      if (createdAt != null)
                        _buildInfoRow(
                          Icons.calendar_month,
                          'Ro\'yxatdan o\'tgan',
                          '${createdAt.day}.${createdAt.month}.${createdAt.year}',
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Booking History
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildSection(
                  title: 'Bronlar Tarixi',
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('userId', isEqualTo: customerId)
                        .orderBy('createdAt', descending: true)
                        .limit(10)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: AppColors.etherealPurple),
                          ),
                        );
                      }

                      final bookingDocs = snapshot.data!.docs;

                      if (bookingDocs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'Hozircha bronlar yo\'q',
                              style: GoogleFonts.outfit(color: Colors.white38),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: bookingDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildBookingTile(data);
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassWhite.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.etherealPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.etherealPurple, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTile(Map<String, dynamic> booking) {
    final date = (booking['date'] as Timestamp?)?.toDate();
    final status = booking['status'] ?? 'pending';
    final guestCount = booking['guestCount'] ?? 0;
    final choyxonaName = booking['choyxonaName'] ?? 'Noma\'lum';

    Color statusColor;
    String statusText;
    switch (status) {
      case 'confirmed':
        statusColor = AppColors.success;
        statusText = 'Tasdiqlangan';
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusText = 'Bekor qilingan';
        break;
      case 'completed':
        statusColor = AppColors.etherealAqua;
        statusText = 'Yakunlangan';
        break;
      default:
        statusColor = AppColors.warning;
        statusText = 'Kutilmoqda';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Date
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.etherealPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  date != null ? '${date.day}' : '--',
                  style: GoogleFonts.outfit(
                    color: AppColors.etherealPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  date != null ? _monthName(date.month) : '',
                  style: GoogleFonts.outfit(
                    color: AppColors.etherealPurple,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Info
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
                Text(
                  '$guestCount mehmon',
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.outfit(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyn', 'Iyl', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek'];
    return months[month - 1];
  }
}
