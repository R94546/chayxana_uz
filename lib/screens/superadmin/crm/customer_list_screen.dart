import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import 'customer_detail_screen.dart';

/// 👥 Customer List Screen - Searchable/Filterable
class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'createdAt';
  bool _sortDesc = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Barcha Mijozlar',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white70),
            color: AppColors.darkCardBg,
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortDesc = !_sortDesc;
                } else {
                  _sortBy = value;
                  _sortDesc = true;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'createdAt',
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: _sortBy == 'createdAt' ? AppColors.etherealPurple : Colors.white54,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text('Sana bo\'yicha', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'bookingCount',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _sortBy == 'bookingCount' ? AppColors.etherealPurple : Colors.white54,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text('Bronlar bo\'yicha', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'displayName',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      color: _sortBy == 'displayName' ? AppColors.etherealPurple : Colors.white54,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text('Ism bo\'yicha', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkBackgroundGradient,
        ),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.glassWhite.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.outfit(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Mijoz qidirish...',
                    hintStyle: GoogleFonts.outfit(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white38),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
            ),

            // Customer List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy(_sortBy, descending: _sortDesc)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.etherealPurple),
                    );
                  }

                  final allUsers = snapshot.data!.docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    data['id'] = d.id;
                    return data;
                  }).toList();

                  // Filter by search query
                  final filteredUsers = allUsers.where((user) {
                    if (_searchQuery.isEmpty) return true;
                    final name = (user['displayName'] ?? '').toString().toLowerCase();
                    final email = (user['email'] ?? '').toString().toLowerCase();
                    final phone = (user['phone'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery.toLowerCase()) ||
                        email.contains(_searchQuery.toLowerCase()) ||
                        phone.contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, color: Colors.white24, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'Mijoz topilmadi',
                            style: GoogleFonts.outfit(color: Colors.white38),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      return _buildCustomerCard(filteredUsers[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final name = customer['displayName'] ?? customer['email']?.split('@').first ?? 'Noma\'lum';
    final email = customer['email'] ?? '';
    final phone = customer['phone'] ?? '';
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.glassWhite.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.etherealPurple.withOpacity(0.2),
              child: Text(
                name[0].toUpperCase(),
                style: GoogleFonts.outfit(
                  color: AppColors.etherealPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          email,
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (phone.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.phone, color: Colors.white38, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Stats Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bookings > 0 
                        ? AppColors.etherealAqua.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: bookings > 0 ? AppColors.etherealAqua : Colors.grey,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$bookings bron',
                        style: GoogleFonts.outfit(
                          color: bookings > 0 ? AppColors.etherealAqua : Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (createdAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${createdAt.day}.${createdAt.month}.${createdAt.year}',
                      style: GoogleFonts.outfit(
                        color: Colors.white24,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
